class_name SteamNet extends Node

# Self-hosted replacement for GodotSteam. It keeps the exact API shape used by
# the original multiplayer scripts, but transports packets over WebSocket via
# our own relay server instead of Steam P2P.

signal join_requested
signal lobby_chat_update(lobby_id: int, change_id: int, making_change_id: int, chat_state: int)
signal lobby_created(connect_result: int, lobby_id: int)
signal lobby_joined(lobby_id: int, permissions: int, locked: bool, response: int)
signal persona_state_change(steam_id: int, flag: int)
signal p2p_session_request(remote_id: int)
signal p2p_session_connect_fail(steam_id: int, session_error: int)
signal lobby_match_list(list: Array)
signal avatar_loaded(avatar_id: int, avatar_size: int, avatar_buffer: PackedByteArray)
signal leaderboard_find_result(handle: int, found: int)
signal leaderboard_score_uploaded
signal leaderboard_scores_downloaded(message: String, handle: int, results: Array)

const PACKET_READ_LIMIT: int = 32
const P2P_SEND_RELIABLE: int = 0
const LOBBY_TYPE_FRIENDS_ONLY: int = 0
const LOBBY_TYPE_PUBLIC: int = 1
const LOBBY_DISTANCE_FILTER_CLOSE: int = 0
const LOBBY_DISTANCE_FILTER_FAR: int = 1
const LOBBY_DISTANCE_FILTER_WORLDWIDE: int = 2
const LEADERBOARD_DATA_REQUEST_GLOBAL: int = 0
const LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER: int = 1
const LEADERBOARD_DATA_REQUEST_FRIENDS: int = 2
const CHAT_ROOM_ENTER_RESPONSE_SUCCESS: int = 0
const CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: int = 1
const CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: int = 2
const CHAT_ROOM_ENTER_RESPONSE_FULL: int = 3
const CHAT_ROOM_ENTER_RESPONSE_ERROR: int = 4
const CHAT_ROOM_ENTER_RESPONSE_BANNED: int = 5
const CHAT_ROOM_ENTER_RESPONSE_LIMITED: int = 6
const CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: int = 7
const CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: int = 8
const CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: int = 9
const CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: int = 10
const CHAT_MEMBER_STATE_CHANGE_ENTERED: int = 1
const CHAT_MEMBER_STATE_CHANGE_LEFT: int = 2
const CHAT_MEMBER_STATE_CHANGE_KICKED: int = 3
const CHAT_MEMBER_STATE_CHANGE_BANNED: int = 4

var ws: WebSocketPeer = null
var server_url: String = ""
var logged_in := false
var STEAM_ID: int = 0
var STEAM_NAME: String = "Player"
var LOBBY_ID: int = 0
var HOST_ID: int = 0
var LOBBY_MEMBERS: Array = []
var USER_ID_LIST_TO_IGNORE: Array[int] = []

var _incoming: Array = []
var _outgoing: Array = []
var _rooms: Dictionary = {}
var _room_data: Dictionary = {}
var _reconnect_at := 0.0
var _ping_at := 0.0
var _nickname: String = "Player"

func _ready() -> void:
	server_url = str(ProjectSettings.get_setting("net/server_url", "ws://buckshot-129-146-71-78.nip.io/ws"))
	_nickname = "Player" + str(randi_range(100, 999))
	STEAM_NAME = _nickname
	await get_tree().create_timer(1.5, false).timeout
	_connect()

func _connect() -> void:
	if ws != null:
		ws.close()
	ws = WebSocketPeer.new()
	ws.connect_to_url(server_url)
	logged_in = false
	print("[Net] connecting to ", server_url)

func _process(_delta: float) -> void:
	if ws == null:
		return
	ws.poll()
	var state := ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		if !logged_in:
			logged_in = true
			_send_raw({"t": "hello", "name": _nickname})
			print("[Net] connected as ", STEAM_ID)
		while true:
			var packet := ws.get_packet()
			if packet.is_empty():
				break
			_handle_message(packet.get_string_from_utf8())
		if !_outgoing.is_empty():
			_send_raw(_outgoing.pop_front())
		if Time.get_ticks_msec() / 1000.0 > _ping_at:
			_ping_at = Time.get_ticks_msec() / 1000.0 + 20.0
			_send_raw({"t": "ping"})
	elif state == WebSocketPeer.STATE_CLOSED:
		# The relay assigns a new id on every connection and removes the old
		# client from its room, so every piece of session state is now stale.
		var had_lobby := LOBBY_ID != 0
		_reset_session_state()
		if had_lobby:
			lobby_joined.emit(0, 0, false, CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST)
			persona_state_change.emit(0, 0)
		var now := Time.get_ticks_msec() / 1000.0
		if now >= _reconnect_at:
			_reconnect_at = now + 3.0
			_connect()

func _send_raw(msg: Dictionary) -> void:
	if ws == null or ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		_outgoing.append(msg)
		return
	ws.send(JSON.stringify(msg).to_utf8_buffer())

func _reset_session_state() -> void:
	LOBBY_ID = 0
	HOST_ID = 0
	LOBBY_MEMBERS.clear()
	_rooms.clear()
	_room_data.clear()
	_incoming.clear()
	_outgoing.clear()
	logged_in = false

func _handle_message(text: String) -> void:
	var msg = JSON.parse_string(text)
	if typeof(msg) != TYPE_DICTIONARY:
		return
	var t := str(msg.get("t", ""))
	match t:
		"welcome":
			STEAM_ID = int(msg.get("id", 0))
			# GlobalSteam snapshots this in _ready(), before the relay has
			# answered. Without this sync the host always looks like id 0.
			var global_steam := get_node_or_null("/root/GlobalSteam")
			if global_steam != null:
				global_steam.STEAM_ID = STEAM_ID
				global_steam.STEAM_NAME = STEAM_NAME
				global_steam.ONLINE = true
			print("[Net] assigned id ", STEAM_ID)
		"room.list":
			var ids: Array = []
			_rooms.clear()
			for r in msg.get("rooms", []):
				var id = int(r.get("id", 0))
				ids.append(id)
				_rooms[id] = r
			lobby_match_list.emit(ids)
		"lobby.created":
			lobby_created.emit(1, int(msg.get("id", 0)))
		"lobby.joined":
			var id := int(msg.get("id", 0))
			var response := int(msg.get("response", 0))
			if id == 0 and str(msg.get("reason", "")) == "host_left":
				_reset_session_state()
				# Not a successful join: the room was dissolved.
				lobby_joined.emit(0, 0, false, CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST)
				persona_state_change.emit(0, 0)
			elif response == CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
				LOBBY_ID = id
				HOST_ID = int(msg.get("host_id", 0))
				lobby_joined.emit(id, 0, false, response)
			else:
				# A failed join must not leave a non-zero lobby id behind.
				lobby_joined.emit(id, 0, false, response)
		"room.snapshot":
			LOBBY_ID = int(msg.get("id", 0))
			HOST_ID = int(msg.get("host_id", 0))
			LOBBY_MEMBERS.clear()
			for m in msg.get("members", []):
				LOBBY_MEMBERS.append({
					"steam_id": int(m.get("id", 0)),
					"steam_name": str(m.get("name", "Player")),
				})
			_room_data[int(msg.get("id", 0))] = msg.get("data", {})
			persona_state_change.emit(0, 0)
		"lobby.chat":
			if LOBBY_ID == 0:
				LOBBY_ID = int(msg.get("room_id", 0))
			lobby_chat_update.emit(
				LOBBY_ID,
				int(msg.get("change_id", 0)),
				int(msg.get("changer_id", 0)),
				int(msg.get("state", 0))
			)
		"packet":
			var raw := Marshalls.base64_to_raw(str(msg.get("data", "")))
			if !raw.is_empty():
				_incoming.append({"steam_id_remote": int(msg.get("from", 0)), "data": raw})
		"room.start":
			pass
		"pong":
			pass

# --- Steam-like API used by the original scripts ---------------------------
func steamInit(_offline: bool = false) -> Dictionary:
	return {}

func loggedOn() -> bool:
	return true # the UI enables the online button as soon as a server URL is set

func getSteamID() -> int:
	return STEAM_ID

func getPersonaName() -> String:
	return STEAM_NAME

func setPersonaName(name: String) -> void:
	STEAM_NAME = name
	_nickname = name
	if logged_in:
		_send_raw({"t": "hello", "name": name})

func run_callbacks() -> void:
	pass

func allowP2PPacketRelay(_allow: bool) -> bool:
	return true

func isSteamRunningOnSteamDeck() -> bool:
	return false

func getAvailableP2PPacketSize(_channel: int = 0) -> int:
	if _incoming.is_empty():
		return 0
	return ( _incoming[0].get("data") as PackedByteArray ).size()

func readP2PPacket(_size: int, _channel: int = 0) -> Dictionary:
	if _incoming.is_empty():
		return {}
	return _incoming.pop_front()

func sendP2PPacket(target: int, packet_data: PackedByteArray, _send_type: int = 0, _channel: int = 0) -> void:
	if LOBBY_ID == 0:
		return
	var data_b64 := Marshalls.raw_to_base64(packet_data)
	var msg := {"t": "packet", "data": data_b64}
	if target != 0:
		msg["to"] = target
	_send_raw(msg)

func acceptP2PSessionWithUser(_remote_id: int) -> void:
	pass

func closeP2PSessionWithUser(_remote_id: int) -> void:
	pass

func createLobby(_type: int, limit: int) -> void:
	_send_raw({"t": "room.create", "limit": limit, "room_name": STEAM_NAME + "'s game"})

func joinLobby(id: int) -> void:
	_send_raw({"t": "room.join", "id": id})

func leaveLobby(_id: int) -> void:
	_send_raw({"t": "room.leave"})
	LOBBY_ID = 0
	HOST_ID = 0
	LOBBY_MEMBERS.clear()

func requestLobbyList() -> void:
	_send_raw({"t": "room.list"})

func addRequestLobbyListResultCountFilter(_n: int) -> void:
	pass

func addRequestLobbyListDistanceFilter(_f: int) -> void:
	pass

func getLobbyData(id: int, key: String) -> String:
	var room = _rooms.get(id, null)
	if room == null:
		return ""
	if key == "member_count":
		return str(room.get("member_count", 0))
	if key == "player_limit":
		return str(room.get("player_limit", 0))
	var data = _room_data.get(id, {})
	return str(data.get(key, room.get(key, "")))

func setLobbyData(id: int, key: String, value: String) -> void:
	if id == 0:
		return
	_send_raw({"t": "lobby.setdata", "key": key, "value": value})

func setLobbyType(_id: int, type: int) -> void:
	if LOBBY_ID == 0:
		return
	_send_raw({"t": "room.visibility", "public": type == LOBBY_TYPE_PUBLIC})

func setLobbyJoinable(_id: int, joinable: bool) -> void:
	# The relay hides a room from the public list (and locks it) once the
	# match has started. Creation calls joinable=true, which needs no message.
	if !joinable and LOBBY_ID != 0:
		_send_raw({"t": "room.start"})

func setLobbyMemberLimit(id: int, limit: int) -> void:
	setLobbyData(id, "player_limit", str(limit))
	if LOBBY_ID != 0:
		_send_raw({"t": "room.limit", "limit": limit})

func getNumLobbyMembers(_id: int) -> int:
	return LOBBY_MEMBERS.size()

func getLobbyMemberByIndex(_id: int, index: int) -> int:
	if index < 0 or index >= LOBBY_MEMBERS.size():
		return 0
	return int(LOBBY_MEMBERS[index].get("steam_id", 0))

func getLobbyOwner(_id: int) -> int:
	return HOST_ID

func getFriendPersonaName(friend_id: int) -> String:
	for member in LOBBY_MEMBERS:
		if int(member.get("steam_id", 0)) == friend_id:
			return str(member.get("steam_name", "Player"))
	for id in _rooms.keys():
		var room = _rooms[id]
		if int(room.get("host_id", 0)) == friend_id:
			return str(room.get("name", "Player"))
	return "Player" + str(friend_id)

func getPlayerAvatar(_size: int, _id: int) -> void:
	# The relay has no account avatars. Emitting a fake buffer would crash
	# MP_IngameLobbyUI's Image.create_from_data call.
	pass

func findLeaderboard(_name: String) -> void:
	# No leaderboards on the relay; keep the callback signature valid.
	leaderboard_find_result.emit(0, 0)

func setLeaderboardDetailsMax(_n: int) -> int:
	return 0

func uploadLeaderboardScore(_handle: int, _score: int, _force: bool, _details: Array) -> void:
	pass

func downloadLeaderboardEntries(_handle: int, _r1: int, _r2: int) -> void:
	leaderboard_scores_downloaded.emit("", 0, [])

func getLeaderboardEntryCount(_handle: int) -> int:
	return 0

func setAchievement(_name: String) -> void:
	pass

func clearAchievement(_name: String) -> void:
	pass

func storeStats() -> void:
	pass

func activateGameOverlayInviteDialog(_id: int) -> void:
	# There is no Steam overlay; copy the numeric relay id so the other
	# player can use the existing "join with lobby id" UI.
	DisplayServer.clipboard_set(str(LOBBY_ID))
	print("[Net] invite: lobby id ", LOBBY_ID, " copied to clipboard")
