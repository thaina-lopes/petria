import os
import glob
import re

def fix_audio_buses(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = []
    lines = content.split('\n')
    
    in_music_node = False
    in_sfx_node = False
    
    for line in lines:
        if line.startswith('[node '):
            in_music_node = False
            in_sfx_node = False
            
            if 'type="AudioStreamPlayer' in line or 'type="AudioStreamPlayer2D' in line:
                name_match = re.search(r'name="([^"]+)"', line)
                if name_match:
                    name = name_match.group(1)
                    if name in ["Music", "Music2"]:
                        in_music_node = True
                    elif name in ["AudioStreamPlayer2D", "PlatformSound", "ClickSound"]:
                        in_sfx_node = True

        new_content.append(line)
        
        if in_music_node and line.startswith('[node '):
            new_content.append('bus = &"Music"')
            in_music_node = False
            
        elif in_sfx_node and line.startswith('[node '):
            new_content.append('bus = &"SFX"')
            in_sfx_node = False

    # write back
    if content != '\n'.join(new_content):
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_content))
        print(f"Fixed: {file_path}")

for file_path in glob.glob('c:/Users/thain/Documents/petria/**/*.tscn', recursive=True):
    fix_audio_buses(file_path)
