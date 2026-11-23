"""Build a Godot 4.1 PCK directly from the reconstructed project tree.

Usage: python tools/build_pck.py <project_dir> <output.pck>
"""
import os
import sys
import struct
import hashlib

MAGIC = 0x43504447  # GDPC
VERSION = 2
ALIGN = 16
GODOT = (4, 1, 1)

SKIP_NAMES = {'.git', 'tools', 'build', 'export_presets.cfg', '_manifest.json',
              'dump_textures.gd', 'gen_etc2.gd', 'etc2_pairs.json', 'check.gd',
              'save_settings.gd', 'conv_test.gd', 'diag.gd', 'props.gd', 'enum_test.gd'}


def collect(root):
    files = []
    for dp, dn, fn in os.walk(root):
        dn[:] = [d for d in dn if d not in SKIP_NAMES]
        for f in fn:
            if f in SKIP_NAMES:
                continue
            full = os.path.join(dp, f)
            rel = os.path.relpath(full, root).replace('\\', '/')
            if rel.startswith('build/'):
                continue
            files.append(('res://' + rel, full))
    files.sort(key=lambda x: x[0])
    return files


def build(root, out):
    files = collect(root)
    directory = bytearray()
    data = bytearray()
    entries = []
    for res_path, full in files:
        blob = open(full, 'rb').read()
        entries.append((res_path, len(data), len(blob), blob))
        data += blob
        data += b'\0' * ((ALIGN - len(blob) % ALIGN) % ALIGN)

    # Directory is written before data, so compute its size first.
    for res_path, ofs, size, blob in entries:
        p = res_path.encode('utf-8')
        pad = (4 - len(p) % 4) % 4
        directory += struct.pack('<I', len(p) + pad) + p + b'\0' * pad
        directory += struct.pack('<QQ', ofs, size)
        directory += hashlib.md5(blob).digest()
        directory += struct.pack('<I', 0)

    header = bytearray()
    header += struct.pack('<6I', MAGIC, VERSION, *GODOT, 0)
    header += struct.pack('<Q', 0)  # file_base placeholder
    header += b'\0' * 64  # reserved
    header += struct.pack('<I', len(entries))

    header_size = len(header) + len(directory)
    file_base = (header_size + ALIGN - 1) // ALIGN * ALIGN
    # Offsets in the directory are relative to file_base.
    for res_path, ofs, size, blob in entries:
        pass
    # Offsets in the directory are relative to file_base (start of file data).
    header[24:32] = struct.pack('<Q', file_base)

    with open(out, 'wb') as f:
        f.write(header)
        f.write(directory)
        f.write(b'\0' * (file_base - len(header) - len(directory)))
        for _, _, _, blob in entries:
            f.write(blob)
            pad = (ALIGN - len(blob) % ALIGN) % ALIGN
            f.write(b'\0' * pad)
    print('PCK:', len(entries), 'files,', os.path.getsize(out), 'bytes, file_base', file_base)


if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2])
