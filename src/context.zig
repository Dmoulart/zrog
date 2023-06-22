const Zecs = @import("zecs");
const rl = @import("raylib");

const Chunks = @import("./map/chunks.zig");
const Chunk = @import("./map/chunk.zig");

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
        Zecs.Component("Mover", struct {
            move_freq: f32, // Can move every n turn
            last_move: u128,
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
            "ScreenPosition",
            struct {
                x: c_int,
                y: c_int,
            },
        ),
        Zecs.Component(
            "Panel",
            struct {
                width: c_int,
                height: c_int,
                background_color: rl.Color,
                text: []const u8,
            },
        ),
        Zecs.Tag("FPSCounter"),
        Zecs.Tag("Chunk"),
        Zecs.Tag("Input"),
        Zecs.Tag("Terrain"),
    },
    .Resources = struct {
        screen_height: c_int = 800,
        screen_width: c_int = 1200,
        dt: i64 = 0,
        turn: u128 = 0,
        camera: Zecs.Entity = 0,
        player: Zecs.Entity = 0,
        // chunk accessor
        chunks: *Chunks = undefined,
    },
    .capacity = 200_002,
});
