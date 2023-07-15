const Zecs = @import("zecs");
const rl = @import("raylib");

// const Zecs = @import("../libs/zecs/src/main.zig");

const Chunks = @import("./map/chunks.zig");
const Chunk = @import("./map/chunk.zig");

const FieldsOfViews = @import("./fov/fields-of-view.zig").FieldsOfViews;

// pub const World = Zecs.Context(.{
//     .components = .{
//         Zecs.Component(
//             "Position",
//             struct {
//                 x: i32,
//                 y: i32,
//             },
//         ),
//         Zecs.Component("Lifetime", struct {
//             duration: u16,
//         }),
//         Zecs.Component(comptime component_name: []const u8, comptime T: type)
//         Zecs.Component(
//             "Glyph",
//             struct {
//                 x: i32,
//                 y: i32,
//             },
//         ),
//     },
//     .Resources = struct {

//     },
//     .capacity = 1_000_000
// });

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
            "Glyph",
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
            "Vision",
            struct {
                range: i32,
            },
        ),
        Zecs.Component(
            "Health",
            struct {
                points: i32 = 10,
            },
        ),
        Zecs.Tag("Chunk"),
        Zecs.Tag("Input"),
        Zecs.Tag("Terrain"),
        Zecs.Tag("Enemy"),
    },
    .Resources = struct {
        headless: bool = false,
        screen_height: c_int = 800,
        screen_width: c_int = 1200,
        dt: i64 = 0,
        turn: u128 = 0,
        camera: Zecs.Entity = 0,
        player: Zecs.Entity = 0,
        // chunk accessor
        chunks: *Chunks = undefined,
        fields_of_views: *FieldsOfViews = undefined,
    },
    .capacity = 200_002,
});
