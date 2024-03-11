# toggle -small
import bpy
from bpy.types import MovieSequence

C = bpy.context

for s in filter(lambda x: isinstance(x, MovieSequence), C.scene.sequence_editor.sequences):
    if s.filepath.endswith('-small.MP4'):
        s.filepath = s.filepath.replace('-small.MP4', '.MP4')
    else:
        s.filepath = s.filepath.replace('.MP4', '-small.MP4')
