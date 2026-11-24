"""Create a temporary PC project variant that forces OpenGL (gl_compatibility).

The iOS build uses Forward Plus (Vulkan/MoltenVK). The Windows build for machines
without a Vulkan-capable GPU uses Godot's compatibility renderer. This script is
run in CI; game_pc/ is never committed.
"""
import os
import shutil
import sys

src = sys.argv[1] if len(sys.argv) > 1 else 'game'
dst = sys.argv[2] if len(sys.argv) > 2 else 'game_pc'

if os.path.exists(dst):
    shutil.rmtree(dst)
shutil.copytree(src, dst)

p = os.path.join(dst, 'project.godot')
s = open(p, encoding='utf-8').read()
if 'custom_features=' not in s:
    s = s.replace('config_version=5\n', 'config_version=5\n\ncustom_features="pc_opengl"\n', 1)
else:
    import re
    s = re.sub(r'custom_features="[^"]*"', 'custom_features="pc_opengl"', s, count=1)
if 'renderer/rendering_method=' not in s:
    s = s.replace('[rendering]\n', '[rendering]\n\nrenderer/rendering_method="gl_compatibility"\n', 1)
else:
    import re
    s = re.sub(r'renderer/rendering_method="[^"]*"', 'renderer/rendering_method="gl_compatibility"', s, count=1)
open(p, 'w', encoding='utf-8', newline='\n').write(s)

binary = os.path.join(dst, 'project.binary')
if os.path.exists(binary):
    os.remove(binary)
print('created', dst, 'with OpenGL renderer')
