import bpy
import bpy.ops as O


class Cutter:
    def __init__(self, scene, fps, text_scale,
                 left_show, left_name, left_club, left_init_pts, left_color,
                 right_show, right_name, right_club, right_init_pts, right_color,
                 phase):
        self.scene = scene
        self.sequencer = self.scene.sequence_editor
        
        self.font_name = None
        self.flash_length = 0.45
        self.fadeout_length = 2
        self.extra_black_length = 1
        self.points_start = 2
        
        self.fps = fps
        self.text_scale = text_scale
        self.left_show = left_show
        self.left_name = left_name
        self.left_club = left_club
        self.right_show = right_show
        self.right_name = right_name
        self.right_club = right_club
        self.phase = phase
        self.sides = {'l': 'left', 'r': 'right'}
        self.colors = {'l': left_color, 'r': right_color}
        self.colormap = {'red': (1.0, 0.003922, 0.003922, 1.0),
                         'blue': (0.094118, 0.509804, 1.0, 1.0),
                         'green': (0.0, 0.879993, 0.05956, 1.0)}
        self.channels = {'l': 4, 'r': 3}
        self.pts = {'l': left_init_pts, 'r': right_init_pts}
        
        self.scene.frame_current = 1
    
    def secs2frames(self, secs):
        return int(self.fps * secs)
    
    def move_markers(self, frames, from_frame=0, incl=True):
        if incl:
            for m in self.scene.timeline_markers:
                if m.frame >= from_frame:
                    m.frame += frames
        else:
            for m in self.scene.timeline_markers:
                if m.frame > from_frame:
                    m.frame += frames
    
    def get_av_at_frame(self, f):
        v = [s for s in self.sequencer.sequences
             if (s.type == 'MOVIE' and
                 s.channel == 2 and
                 s.frame_final_start < f < s.frame_final_end)][0]
        a = [s for s in self.sequencer.sequences
             if (s.type == 'SOUND' and
                 s.channel == 1 and
                 s.frame_final_start < f < s.frame_final_end)][0]
        return v, a

    def start(self):
        # add text
        if self.left_show and self.right_show:
            self.add_text('left-name')
            self.add_text('left-club')
            self.add_text('vs')
            self.add_text('right-name')
            self.add_text('right-club')
            self.add_text('phase', self.phase)
        elif self.left_show:
            self.add_text('vs', single=True)
            self.add_text('left-name', single=True)
            self.add_text('left-club', single=True)
            self.add_text('phase', self.phase, single=True)
        elif self.right_show:
            self.add_text('vs', single=True)
            self.add_text('right-name', single=True)
            self.add_text('right-club', single=True)
            self.add_text('phase', self.phase, single=True)
        
        # align video
        start = self.scene.timeline_markers['start']
        # get the video and audio strip, there must be only one each
        vids = [s for s in self.sequencer.sequences if s.type == 'MOVIE']
        auds = [s for s in self.sequencer.sequences if s.type == 'SOUND']
        if len(vids) > 1 or len(auds) > 1:
            raise ValueError('More than one sound/movie sequence')
        v, a = vids[0], auds[0]
        
        # trim the start to the start frame
        v.frame_offset_start = start.frame - v.frame_start
        a.frame_offset_start = start.frame - a.frame_start
        # move the strips to frame 45 where the video is going to start
        start_frames = self.secs2frames(1.5)
        print('Start frames: ', start_frames)
        v.frame_start = start_frames - v.frame_offset_start
        a.frame_start = start_frames - a.frame_offset_start
        # move all markers so that they are still aligned with the correct places
        self.move_markers(start_frames - start.frame)
        # add fade in
        fadein_frames = self.secs2frames(2)
        print('Fede-in frames: ', fadein_frames)
        v.blend_alpha = 0
        v.keyframe_insert(data_path='blend_alpha', frame=start_frames)
        v.blend_alpha = 1
        v.keyframe_insert(data_path='blend_alpha', frame=fadein_frames)
        a.volume = 0
        a.keyframe_insert(data_path='volume', frame=start_frames)
        a.volume = 1
        a.keyframe_insert(data_path='volume', frame=fadein_frames)
    
    def add_text(self, name, text=None, frame_start=None, frame_end=None, frame_fadeout=None, single=False):
        if name == 'left-name':
            text = self.left_name
            channel = 10
            color = self.colormap[self.colors['l']]
            font_size = 369
            location = (0.5, 0.737)
            if single:
                location = (0.5, 0.435)
            align_x = 'CENTER'
            align_y = 'BOTTOM'
            frame_start = 1
            frame_fadeout = self.secs2frames(1.5)
            frame_end = self.secs2frames(2)
        elif name == 'left-club':
            text = self.left_club
            channel = 9
            color = self.colormap[self.colors['l']]
            font_size = 197
            location = (0.5, 0.647)
            if single:
                location = (0.5, 0.336)
            align_x = 'CENTER'
            align_y = 'BOTTOM'
            frame_start = 1
            frame_fadeout = self.secs2frames(1.5)
            frame_end = self.secs2frames(2)
        elif name == 'vs':
            text = 'vs'
            channel = 8
            color = (1, 1, 1, 1)
            font_size = 247
            location = (0.5, 0.4874)
            if single:
                location = (0.5, 0.6674)
            align_x = 'CENTER'
            align_y = 'BOTTOM'
            frame_start = 1
            frame_fadeout = self.secs2frames(1.5)
            frame_end = self.secs2frames(2)
        elif name == 'right-name':
            text = self.right_name
            channel = 7
            color = self.colormap[self.colors['r']]
            font_size = 369
            location = (0.5, 0.285)
            if single:
                location = (0.5, 0.435)
            align_x = 'CENTER'
            align_y = 'BOTTOM'
            frame_start = 1
            frame_fadeout = self.secs2frames(1.5)
            frame_end = self.secs2frames(2)
        elif name == 'right-club':
            text = self.right_club
            channel = 6
            color = self.colormap[self.colors['r']]
            font_size = 197
            location = (0.5, 0.186)
            if single:
                location = (0.5, 0.336)
            align_x = 'CENTER'
            align_y = 'BOTTOM'
            frame_start = 1
            frame_fadeout = self.secs2frames(1.5)
            frame_end = self.secs2frames(2)
        elif name == 'phase':
            channel = 5
            color = (1, 1, 1, 1)
            font_size = 197
            location = (0.5, 0.0415)
            if single:
                location = (0.5, 0.1)
            align_x = 'CENTER'
            align_y = 'BOTTOM'
            frame_start = 1
            frame_fadeout = self.secs2frames(1.5)
            frame_end = self.secs2frames(2)
        elif name == 'l-point':
            channel = self.channels['l']
            color = self.colormap[self.colors['l']]
            font_size = 369
            location = (0.0507, 0.993)
            align_x = 'LEFT'
            align_y = 'TOP'
        elif name == 'l-point-final':
            channel = self.channels['l']
            color = self.colormap[self.colors['l']]
            font_size = 593
            location = (0.0507, 0.865)
            align_x = 'LEFT'
            align_y = 'CENTER'
        elif name == 'r-point':
            channel = self.channels['r']
            color = self.colormap[self.colors['r']]
            font_size = 369
            location = (1 - 0.0507, 0.993)
            align_x = 'RIGHT'
            align_y = 'TOP'
        elif name == 'r-point-final':
            channel = self.channels['r']
            color = self.colormap[self.colors['r']]
            font_size = 593
            location = (1 - 0.0507, 0.865)
            align_x = 'RIGHT'
            align_y = 'CENTER'
        else:
            raise ValueError('Invalid text type')
        if text is None or frame_start is None or frame_end is None:
            return
        t = self.scene.sequence_editor.sequences.new_effect(
            name=name,
            type='TEXT',
            channel=channel,
            frame_start=int(frame_start),
            frame_end=(frame_end)
        )
        t.blend_type = 'ALPHA_OVER'
        t.font_size = font_size * self.text_scale
        t.font = bpy.data.fonts[self.font_name]
        t.location = location
        t.text = text
        t.color = color
        t.align_x = align_x
        t.align_y = align_y
        t.blend_alpha = 1
        if frame_fadeout is not None:
            t.keyframe_insert(data_path='blend_alpha', frame=frame_start)
            t.keyframe_insert(data_path='blend_alpha', frame=frame_fadeout)
            t.blend_alpha = 0
            t.keyframe_insert(data_path='blend_alpha', frame=frame_end)
        return t
    
    def cutout(self, frame_out, frame_in):
        # get video and audio strips at frame_out
        v, a = self.get_av_at_frame(frame_out)
        # select strips
        v.select = True
        a.select = True
        # cut at frame_out and select right side
        O.sequencer.split(frame=frame_out, type='SOFT', side='RIGHT')
        # cut the right side at frame_in and select left side, i.e. the part to be removed
        O.sequencer.split(frame=frame_in, type='SOFT', side='LEFT')
        # remove the mid part
        O.sequencer.delete()
        # collect all video and audio strips
        vids = [s for s in self.sequencer.sequences if s.type == 'MOVIE']
        auds = [s for s in self.sequencer.sequences if s.type == 'SOUND']
        # sort them by start frame
        vids.sort(key=lambda s: s.frame_final_start)
        auds.sort(key=lambda s: s.frame_final_start)
        # find video and audio strip that follows the previous video and audio strip
        vas = list(zip(vids, auds))
        next_v, next_a = None, None
        for va, va_next in zip(vas, vas[1:]):
            if va[0] == v and va[1] == a:
                v, a = va
                next_v, next_a = va_next
                break
        return v, a, next_v, next_a
    
    def place_flash(self, frame):
        f = self.scene.sequence_editor.sequences.new_effect(
            name='flash',
            type='COLOR',
            channel=5,
            frame_start=frame - self.secs2frames(self.flash_length / 2),
            frame_end=frame + self.secs2frames(self.flash_length / 2)
        )
        f.color = (1, 1, 1)
        f.blend_type = 'ALPHA_OVER'
        f.blend_alpha = 0
        f.keyframe_insert(data_path='blend_alpha', frame=frame - self.secs2frames(self.flash_length / 2))
        f.keyframe_insert(data_path='blend_alpha', frame=frame + self.secs2frames(self.flash_length / 2))
        f.blend_alpha = 1
        f.keyframe_insert(data_path='blend_alpha', frame=frame)
    
    def cut(self, n=float('inf')):
        cut_markers = [m for m in self.scene.timeline_markers if m.name == 'c']
        cut_markers.sort(key=lambda m: m.frame)
        to_delete = []
        if len(cut_markers) % 2 != 0:
            raise ValueError('Odd number of cut markers')
        for i in range(min(n, len(cut_markers) // 2)):
            m_out = cut_markers[2 * i]
            m_in = cut_markers[2 * i + 1]
            v_prev, a_prev, v_post, a_post = self.cutout(m_out.frame, m_in.frame)
            print(v_prev, a_prev, v_post, a_post)
            df = m_in.frame - m_out.frame
            v_post.frame_start -= df
            a_post.frame_start -= df
            self.move_markers(m_out.frame - m_in.frame, from_frame=m_in.frame, incl=False)
            self.place_flash(m_out.frame)
            to_delete.append(m_out)
            to_delete.append(m_in)
            m_out.frame = -1
            m_in.frame = -1
        for m in to_delete:
            self.scene.timeline_markers.remove(m)
    
    def end(self):
        end = self.scene.timeline_markers['end']
        # get the video and audio strip at end
        v, a = self.get_av_at_frame(end.frame)
        # trim the end to the end frame + 60 (fade out length)
        v.frame_final_end = end.frame + self.secs2frames(self.fadeout_length)
        a.frame_final_end = end.frame + self.secs2frames(self.fadeout_length)
        # add sound fade out
        a.volume = 1
        a.keyframe_insert(data_path='volume', frame=end.frame)
        a.volume = 0
        a.keyframe_insert(data_path='volume', frame=end.frame + self.secs2frames(self.fadeout_length))
        # put fade out black
        fo = self.scene.sequence_editor.sequences.new_effect(
            name='fadeout',
            type='COLOR',
            channel=5,
            frame_start=end.frame,
            frame_end=end.frame + self.secs2frames(self.fadeout_length) + self.secs2frames(self.extra_black_length)
        )
        fo.color = (0, 0, 0)
        fo.blend_type = 'ALPHA_OVER'
        fo.blend_alpha = 0
        fo.keyframe_insert(data_path='blend_alpha', frame=end.frame)
        fo.blend_alpha = 1
        fo.keyframe_insert(data_path='blend_alpha', frame=end.frame + self.secs2frames(self.fadeout_length))
        # set scene end frame
        self.scene.frame_end = fo.frame_final_end
    
    def points(self, n=float('inf')):
        # put initial numbers
        strips = {}
        added = []
        for s in 'lr':
            strip = self.add_text('{}-point'.format(s), str(self.pts[s]), self.secs2frames(self.points_start) + 1, self.secs2frames(self.points_start) + 2)
            strips[s] = strip
            added.append(strip)
        last = []
        # iterate over markers
        for m in sorted(self.scene.timeline_markers, key=lambda x: x.frame):
            if n == 0:
                break
            if m.name in ['start', 'end', 'c']:
                continue
            n -= 1
            added.extend(last)
            last = []
            addto = set()
            for s in m.name:
                if s in ['l', 'r']:
                    addto.add(s)
                    self.pts[s] += 1
            for s in addto:
                strips[s].frame_final_end = m.frame
                strip = self.add_text('{}-point'.format(s), str(self.pts[s]), m.frame, m.frame + 1)
                strips[s] = strip
                last.append(strip)
        m = self.scene.timeline_markers['end']
        for s in 'rl':
            strips[s].frame_final_end = m.frame + self.secs2frames(self.fadeout_length)
        if self.pts['r'] > self.pts['l']:
            s = 'r'
        elif self.pts['r'] < self.pts['l']:
            s = 'l'
        else:
            s = None
        if s is not None:
            fs = strips[s].frame_start
            last.remove(strips[s])
            O.sequencer.select_all(action='DESELECT')
            strips[s].select = True
            O.sequencer.delete()
            strip = self.add_text('{}-point-final'.format(s), str(self.pts[s]), fs, m.frame + self.secs2frames(self.fadeout_length))
            last.append(strip)
        added.extend(last)
        for s in added:
            s.select = True
        
    def run(self):
        font = bpy.data.fonts.load('//../assets/fonts/eb-garamond/EBGaramondSC12-Regular.otf', check_existing=True)
        self.font_name = font.name
        self.start()
        self.cut()
        self.end()
        self.points()



class SEQUENCER_OT_hema_cut(bpy.types.Operator):
    """Cuts the HEMA bout video according to the marks."""
    bl_idname = 'sequencer.hema_cut'
    bl_label = 'HEMA bout cut'
    bl_options = {'REGISTER', 'UNDO'}
    
    fps: bpy.props.FloatProperty(
        name='FPS',
        description='Source video framerate',
        default=30.0,
        min=1.0,
        step=1.0,
        precision=2
    )
    text_scale: bpy.props.FloatProperty(
        name='Text size scale',
        description='1 = text for 4K video',
        default=1.0,
        min=0.001,
        max=1.0,
        precision=3
    )
    show_left: bpy.props.BoolProperty(
        name='Show',
        description='Show the fencer in video text'
    )
    name_left: bpy.props.StringProperty(
        name='Name',
        default='Jan Žegklitz'
    )
    club_left: bpy.props.StringProperty(
        name='Club',
        default='SHŠ Krkavci'
    )
    color_left: bpy.props.EnumProperty(
        items=[('red', 'red', '', 0), ('blue', 'blue', '', 1), ('green', 'green', '', 2)],
        name='Color'
    )
    init_pts_left: bpy.props.IntProperty(
        name='Init points',
        default=0,
        min=0,
        soft_max=7
    )
    show_right: bpy.props.BoolProperty(
        name='Show',
        description='Show the fencer in video text'
    )
    name_right: bpy.props.StringProperty(
        name='Name',
        default='Jan Žegklitz'
    )
    club_right: bpy.props.StringProperty(
        name='Club',
        default='SHŠ Krkavci'
    )
    color_right: bpy.props.EnumProperty(
        items=[('red', 'red', '', 0), ('blue', 'blue', '', 1), ('green', 'green', '', 2)],
        name='Color'
    )
    init_pts_right: bpy.props.IntProperty(
        name='Init points',
        default=0,
        min=0,
        soft_max=7
    )
    phase: bpy.props.StringProperty(
        name='Phase',
        description='Phase of the tournament',
        default='pool 1'
    )
    
    @classmethod
    def poll(cls, context):
        return context.area.type == 'SEQUENCE_EDITOR'

    def draw(self, context):
        layout = self.layout
        col = layout.column()
        
        #row = col.row()
        col.prop(self, 'fps')
        col.prop(self, 'phase')
        col.prop(self, 'text_scale')
        
        s = 0.3

        row = col.split(align=True)
        row.alignment = 'RIGHT'
        row.label(text='Left fencer init pts')
        row.prop(self, 'init_pts_left', text='')
        row = col.split(align=True)
        row.alignment = 'RIGHT'
        row.label(text='Color')
        row.prop(self, 'color_left', text='')
        row = col.split(align=True)
        row.alignment = 'RIGHT'
        row.label(text='show text')
        row.prop(self, 'show_left', text='')
        left = col.column()
        left.enabled = self.show_left
        row = left.split(align=True)
        row.alignment = 'RIGHT'
        row.label(text='Name')
        row.prop(self, 'name_left', text='')
        row = left.split(align=True)
        row.alignment = 'RIGHT'
        row.label(text='Club')
        row.prop(self, 'club_left', text='')
        
        row = col.split(align=True)
        row.alignment = 'RIGHT'
        row.label(text='Right fencer init pts')
        row.prop(self, 'init_pts_right', text='')
        row = col.split(align=True)
        row.alignment = 'RIGHT'
        row.label(text='Color')
        row.prop(self, 'color_right', text='')
        row = col.split(align=True)
        row.alignment = 'RIGHT'
        row.label(text='show text')
        row.prop(self, 'show_right', text='')
        left = col.column()
        left.enabled = self.show_right
        row = left.split(align=True)
        row.alignment = 'RIGHT'
        row.label(text='Name')
        row.prop(self, 'name_right', text='')
        row = left.split(align=True)
        row.alignment = 'RIGHT'
        row.label(text='Club')
        row.prop(self, 'club_right', text='')

    def execute(self, context):
        print('LSh: {}, LN: {}, LCl: {}, LCo: {}, RSH: {}, RN: {}, RCl: {}, RCo: {}, PH: {}, FPS: {}, TS: {}'.format(
            self.show_left,
            self.name_left,
            self.club_left,
            self.color_left,
            self.show_right,
            self.name_right,
            self.club_right,
            self.color_right,
            self.phase,
            self.fps,
            self.text_scale
        ))
        try:
            c = Cutter(
                scene=context.scene,
                fps=self.fps,
                text_scale=self.text_scale,
                left_show=self.show_left,
                left_name=self.name_left,
                left_club=self.club_left,
                left_color=self.color_left,
                left_init_pts=self.init_pts_left,
                right_show=self.show_right,
                right_name=self.name_right,
                right_club=self.club_right,
                right_color=self.color_right,
                right_init_pts=self.init_pts_right,
                phase=self.phase
            )
            c.run()
        except Exception as e:
            import traceback
            print('cancelled')
            traceback.print_exc()
            return {'CANCELLED'}
        else:
            return {'FINISHED'}


def register():
    bpy.utils.register_class(SEQUENCER_OT_hema_cut)


def unregister():
    bpy.utils.unregister_class(SEQUENCER_OT_hema_cut)


if __name__ == '__main__':
    register()
