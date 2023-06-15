const Zecs = @import("zecs");
const rl = @import("raylib");
const Chunk = @import("./map/chunks.zig");

pub const Ecs = Zecs.Context(.{
    .components = .{
        Zecs.Component("Transform", struct {
            x: i32,
            y: i32,
            z: i32,
        }),
        Zecs.Component("Velocity", struct {
            x: i32,
            y: i32,
        }),
        Zecs.Component(
            "Sprite",
            struct {
                char: *const [1:0]u8,
                color: rl.Color,
            },
        ),
        Zecs.Component(
            "Camera",
            rl.Camera2D,
        ),
        Zecs.Component(
            "Input",
            struct { field: bool }, // Cannot make tag component :(
        ),
        Zecs.Component(
            "Terrain",
            struct {
                height: u32,
                width: u32,
            },
        ),
        Zecs.Component(
            "Chunk",
            struct {
                x: i32,
                y: i32,
            },
        ),
    },
    .Resources = struct {
        dt: i64 = 0,
        TIME_FACTOR: i32 = 1,
        camera: Zecs.Entity = 0,
        screen_height: c_int = 800,
        screen_width: c_int = 1200,
        player: Zecs.Entity = 0,
        chunk: ?*Chunk = null,
    },
    .capacity = 1_000_002,
});
