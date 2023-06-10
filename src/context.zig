const Zecs = @import("zecs");
const rl = @import("raylib");

pub const Ecs = Zecs.Context(.{
    .components = .{
        Zecs.Component("Transform", struct {
            x: f32,
            y: f32,
            z: f32,
        }),
        Zecs.Component("Velocity", struct {
            x: f32,
            y: f32,
        }),
        Zecs.Component("Sprite", struct {
            char: *const [1:0]u8,
            color: rl.Color,
        }),
        Zecs.Component(
            "Camera",
            rl.Camera2D,
        ),
        Zecs.Component(
            "Input",
            struct { field: bool }, // Cannot make tag component :(
        ),
    },
    .Resources = struct {
        dt: f32 = 0,
        TIME_FACTOR: f32 = 0.01,
        camera: Zecs.Entity = 0,
        screen_height: c_int = 1200,
        screen_width: c_int = 800,
        player: Zecs.Entity = 0,
    },
    .capacity = 10_000,
});
