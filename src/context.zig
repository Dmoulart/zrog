const Zecs = @import("zecs");
const Rl = @import("raylib");

pub const Ecs = Zecs.Context(.{
    .components = .{
        Zecs.Component("Transform", struct {
            x: f32,
            y: f32,
        }),
        Zecs.Component("Velocity", struct {
            x: f32,
            y: f32,
        }),
    },
    .Resources = struct {
        dt: f32 = 0,
        camera: ?*Rl.Camera2D = null,
        camera_entity: Zecs.Entity = 0,
        screen_height: c_int = 1200,
        screen_width: c_int = 800,
    },
    .capacity = 10_000,
});
