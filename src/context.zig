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
        Zecs.Tag("Chunk"),
        Zecs.Component(
            "InChunk",
            struct {
                chunk: Zecs.Entity,
            },
        ),
        Zecs.Tag("Input"),
        Zecs.Tag("Terrain"),
    },
    .Resources = struct {
        screen_height: c_int = 800,
        screen_width: c_int = 1200,
        dt: i64 = 0,
        TIME_FACTOR: i32 = 1,
        camera: Zecs.Entity = 0,
        player: Zecs.Entity = 0,
        _chunks: Chunks = undefined,
        chunks: *Chunks = undefined,
        player_chunk: ?*Chunk = null,
    },
    .capacity = 1_000_002,
});
