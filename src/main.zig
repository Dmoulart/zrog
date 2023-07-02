const std = @import("std");
const rl = @import("raylib");

const Zecs = @import("zecs");
const Ecs = @import("./context.zig").Ecs;

const timestamp = std.time.milliTimestamp;

const createCamera = @import("./graphics/camera.zig").createCamera;
const createPlayer = @import("./player/create-player.zig").createPlayer;

const Chunks = @import("./map/chunks.zig");
const Chunk = @import("./map/chunk.zig");
const Moon = @import("./map/moon.zig");

const prerender = @import("./graphics/renderer.zig").prerender;
const render = @import("./graphics/renderer.zig").render;
const renderTerrain = @import("./graphics/renderer.zig").renderTerrain;
const postrender = @import("./graphics/renderer.zig").postrender;

const updateCamera = @import("./graphics/camera.zig").updateCamera;
const movement = @import("./physics/movement.zig").movement;
const moveCommands = @import("./input/move-commands.zig").moveCommands;

const renderUI = @import("./ui/ui-renderer.zig").renderUI;
const fieldsOfview = @import("./fov/fields-of-view.zig").fieldsOfview;

const Timer = @import("./perfs/timer.zig");
const Timers = @import("./perfs/timers.zig");

const astar = @import("./geo//pathfinding/a-star.zig").astar;
const Position = @import("./geo//pathfinding/a-star.zig").Position;
const Grid = @import("./geo//pathfinding/a-star.zig").Grid;

pub fn main() !void {
    var grid = [10][10]u8{
        [_]u8{ 0, 0, 1, 0, 1, 0, 0, 1, 1, 0 },
        [_]u8{ 0, 0, 1, 0, 1, 0, 1, 0, 0, 0 },
        [_]u8{ 1, 0, 1, 0, 1, 0, 1, 0, 0, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 1, 0, 1, 0, 0 },
        [_]u8{ 0, 0, 1, 1, 1, 0, 0, 0, 0, 0 },
        [_]u8{ 0, 0, 1, 0, 1, 0, 1, 0, 1, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 0, 0, 0, 1, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 1, 0, 0, 1, 0 },
        [_]u8{ 0, 0, 0, 1, 0, 0, 0, 0, 1, 0 },
    };

    var start_x: u8 = 0;
    var start_y: u8 = 0;

    var end_x: u8 = 4;
    var end_y: u8 = 4;
    Timers.start("path");

    var path_positions: [15]Position = undefined;
    var path = try astar(
        &grid,
        .{ .x = start_x, .y = start_y },
        .{ .x = end_x, .y = end_y },
        path_positions[0..],
        std.heap.page_allocator,
    );
    Timers.end("path");

    var y: usize = 0;
    while (y < 10) : (y += 1) {
        std.debug.print("\n", .{});
        var x: usize = 0;
        while (x < 10) : (x += 1) {
            var is_path = false;
            for (path) |node| {
                if (node.x == x and node.y == y) {
                    is_path = true;
                    break;
                }
            }
            if (grid[@intCast(usize, x)][@intCast(usize, y)] == 1) {
                std.debug.print("x ", .{});
            } else if (x == start_x and y == start_y) {
                std.debug.print("S ", .{});
            } else if (x == end_x and y == end_y) {
                std.debug.print("E ", .{});
            } else if (is_path) {
                std.debug.print("o ", .{});
            } else {
                std.debug.print(". ", .{});
            }
        }
    }
}

pub fn main2() !void {
    Timers.start("init");
    // Creation
    try Ecs.setup(std.heap.page_allocator);
    defer Ecs.unsetup();

    var world = try Ecs.init(.{
        .allocator = std.heap.page_allocator,
    });
    defer world.deinit();

    // Initialization
    var chunks = Chunks.create(std.heap.page_allocator);
    defer chunks.destroy();

    for (chunks.chunks) |*row| {
        for (row) |*maybe_chunk| {
            if (maybe_chunk.*) |*chunk| {
                Moon.generate(&world, chunk);
            }
        }
    }
    world.setResource(.chunks, chunks);

    const screen_width = world.getResource(.screen_width);
    const screen_height = world.getResource(.screen_height);

    rl.InitWindow(screen_width, screen_height, "Zrog");
    rl.SetTargetFPS(60);

    _ = createCamera(&world);
    _ = createPlayer(&world);

    try loop(&world);
}

fn loop(world: *Ecs) anyerror!void {
    world.addSystem(movement);
    world.addSystem(moveCommands);
    world.addSystem(updateCamera);
    world.addSystem(fieldsOfview);

    world.addSystem(prerender);
    world.addSystem(render);
    world.addSystem(renderUI);
    world.addSystem(postrender);

    // Main game loop
    while (!rl.WindowShouldClose()) {
        var loop_start = timestamp();

        // update turn number
        var turn = world.getResource(.turn);
        world.setResource(.turn, turn + 1);

        world.step();

        var dt = timestamp() - loop_start;

        world.setResource(.dt, dt);
    }

    rl.CloseWindow();
}
