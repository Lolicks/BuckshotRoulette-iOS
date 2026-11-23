# Offline stub of GodotSteam singleton. No network, no Steamworks.
extends Node

signal join_requested
signal lobby_chat_update
signal lobby_created
signal lobby_joined
signal persona_state_change
signal p2p_session_request
signal p2p_session_connect_fail
signal lobby_match_list
signal avatar_loaded
signal leaderboard_find_result
signal leaderboard_score_uploaded
signal leaderboard_scores_downloaded

const CHAT_MEMBER_STATE_CHANGE_BANNED: int = 0
const CHAT_MEMBER_STATE_CHANGE_ENTERED: int = 1
const CHAT_MEMBER_STATE_CHANGE_KICKED: int = 2
const CHAT_MEMBER_STATE_CHANGE_LEFT: int = 3
const CHAT_ROOM_ENTER_RESPONSE_BANNED: int = 4
const CHAT_ROOM_ENTER_RESPONSE_CLAN_DISABLED: int = 5
const CHAT_ROOM_ENTER_RESPONSE_COMMUNITY_BAN: int = 6
const CHAT_ROOM_ENTER_RESPONSE_DOESNT_EXIST: int = 7
const CHAT_ROOM_ENTER_RESPONSE_ERROR: int = 8
const CHAT_ROOM_ENTER_RESPONSE_FULL: int = 9
const CHAT_ROOM_ENTER_RESPONSE_LIMITED: int = 10
const CHAT_ROOM_ENTER_RESPONSE_MEMBER_BLOCKED_YOU: int = 11
const CHAT_ROOM_ENTER_RESPONSE_NOT_ALLOWED: int = 12
const CHAT_ROOM_ENTER_RESPONSE_SUCCESS: int = 13
const CHAT_ROOM_ENTER_RESPONSE_YOU_BLOCKED_MEMBER: int = 14
const LEADERBOARD_DATA_REQUEST_FRIENDS: int = 15
const LEADERBOARD_DATA_REQUEST_GLOBAL: int = 16
const LEADERBOARD_DATA_REQUEST_GLOBAL_AROUND_USER: int = 17
const LOBBY_DISTANCE_FILTER_CLOSE: int = 18
const LOBBY_DISTANCE_FILTER_FAR: int = 19
const LOBBY_DISTANCE_FILTER_WORLDWIDE: int = 20
const LOBBY_TYPE_FRIENDS_ONLY: int = 21
const LOBBY_TYPE_PUBLIC: int = 22
const P2P_SEND_RELIABLE: int = 23

func _ready() -> void:
	pass

func acceptP2PSessionWithUser(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func activateGameOverlayInviteDialog(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func addRequestLobbyListDistanceFilter(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func addRequestLobbyListResultCountFilter(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func allowP2PPacketRelay(_a0=null, _a1=null, _a2=null, _a3=null) -> bool:
	return false

func clearAchievement(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func closeP2PSessionWithUser(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func createLobby(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func downloadLeaderboardEntries(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func findLeaderboard(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func getAvailableP2PPacketSize(_a0=null, _a1=null, _a2=null, _a3=null) -> int:
	return 0

func getFriendPersonaName(_a0=null, _a1=null, _a2=null, _a3=null) -> String:
	return ""

func getLeaderboardEntryCount(_a0=null, _a1=null, _a2=null, _a3=null) -> int:
	return 0

func getLobbyData(_a0=null, _a1=null, _a2=null, _a3=null) -> String:
	return ""

func getLobbyMemberByIndex(_a0=null, _a1=null, _a2=null, _a3=null) -> int:
	return 0

func getLobbyOwner(_a0=null, _a1=null, _a2=null, _a3=null) -> int:
	return 0

func getPersonaName(_a0=null, _a1=null, _a2=null, _a3=null) -> String:
	return ""

func getPlayerAvatar(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func getSteamID(_a0=null, _a1=null, _a2=null, _a3=null) -> int:
	return 0

func isSteamRunningOnSteamDeck(_a0=null, _a1=null, _a2=null, _a3=null) -> bool:
	return false

func joinLobby(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func leaveLobby(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func loggedOn(_a0=null, _a1=null, _a2=null, _a3=null) -> bool:
	return false

func readP2PPacket(_a0=null, _a1=null, _a2=null, _a3=null) -> Dictionary:
	return {}

func requestLobbyList(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func run_callbacks(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func sendP2PPacket(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func setAchievement(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func setLeaderboardDetailsMax(_a0=null, _a1=null, _a2=null, _a3=null) -> int:
	return 0

func setLobbyData(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func setLobbyJoinable(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func setLobbyMemberLimit(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func setLobbyType(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func steamInit(_a0=null, _a1=null, _a2=null, _a3=null) -> Dictionary:
	return {}

func storeStats(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass

func uploadLeaderboardScore(_a0=null, _a1=null, _a2=null, _a3=null) -> void:
	pass
