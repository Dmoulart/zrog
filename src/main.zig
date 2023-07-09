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

const followPlayer = @import("./battle/follow-player.zig").followPlayer;

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
    Timers.start("init");
    // Creation
    try Ecs.setup(std.heap.page_allocator);

    var world = try Ecs.init(.{
        .allocator = std.heap.page_allocator,
    });

    // Initialization
    var chunks = Chunks.create(std.heap.page_allocator);
    defer {
        Ecs.unsetup();
        world.deinit();
        chunks.destroy();
    }

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
    world.addSystem(followPlayer);
    world.addSystem(movement);
    world.addSystem(moveCommands);
    world.addSystem(updateCamera);
    world.addSystem(fieldsOfview);

    world.addSystem(prerender);
    world.addSystem(render);
    world.addSystem(renderUI);
    world.addSystem(postrender);

    var enemy = world.createEmpty();
    world.attach(enemy, .Transform);
    world.write(enemy, .Transform, .{
        .x = 100,
        .y = 100,
    });
    world.attach(enemy, .Velocity);
    world.write(enemy, .Velocity, .{
        .x = 0,
        .y = 0,
    });
    world.attach(enemy, .Glyph);
    world.write(enemy, .Glyph, .{
        .char = "g",
        .color = rl.WHITE,
    });
    world.attach(enemy, .Mover);
    world.write(enemy, .Mover, .{
        .move_freq = 2,
        .last_move = 0,
    });
    world.attach(enemy, .Enemy);

    var chunks = world.getResource(.chunks);
    chunks.set(.beings, enemy, 100, 100);

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
