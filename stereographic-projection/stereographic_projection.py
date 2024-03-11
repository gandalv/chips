import bpy
from math import cos, sin, atan, atan2

bl_info = {'name': 'Stereographic projection',
           'category': 'Object'}


class ObjectStereographicProjection(bpy.types.Operator):
    # blender will use this as a tooltip for menu items and buttons.
    """Stereographic projection"""

    # unique identifier for buttons and menu items to reference
    bl_idname = 'object.stereographic_projection'
    # display name in the interface.
    bl_label = 'Inverse stereographic projection'
    # enable undo for the operator.
    bl_options = {'REGISTER', 'UNDO'}

    radius = bpy.props.FloatProperty(name='radius = distance', default=1.0)
    #distance = radius

    # execute() is called by blender when running the operator.
    def execute(self, context):
        scene = context.scene
        # cursor = scene.cursor_location
        obj = scene.objects.active
        obj_new = obj.copy()
        scene.objects.link(obj_new)

        for v in obj_new.data.vertices:
            v.co = self.transform(v.co)

        # this lets blender know the operator finished successfully.
        return {'FINISHED'}

    def transform(self, coords):
        x, y, z = coords
        polar_r, polar_phi = self.to_polar(x, y)

        theta = self.center_angle(polar_r)
        alpha = 2 * theta

        x_new = self.radius * sin(alpha) * cos(polar_phi)
        y_new = self.radius * sin(alpha) * sin(polar_phi)
        z_new = self.radius - self.radius * cos(alpha)
        return x_new, y_new, z_new

    def to_polar(self, x, y):
        polar_r = (x ** 2 + y ** 2) ** .5
        polar_phi = atan2(y, x)
        return polar_r, polar_phi

    def center_angle(self, polar_r):
        return atan(float(polar_r) / (self.radius + self.radius))


def menu_func(self, context):
    self.layout.operator(ObjectStereographicProjection.bl_idname)


def register():
    bpy.utils.register_class(ObjectStereographicProjection)
    bpy.types.VIEW3D_MT_object.append(menu_func)


def unregister():
    bpy.utils.unregister_class(ObjectStereographicProjection)
    bpy.types.VIEW3D_MT_object.remove(menu_func)


# This allows you to run the script directly from blenders text editor
# to test the addon without having to install it.
if __name__ == "__main__":
    register()
