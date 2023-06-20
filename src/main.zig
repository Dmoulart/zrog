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

// const createFPSCounter = @import("./ui/fps-counter.zig").createFPSCounter;
const renderUI = @import("./ui/ui-renderer.zig").renderUI;

const Timer = @import("./perfs/timer.zig");
const Timers = @import("./perfs/timers.zig");

pub fn main() !void {
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
    // _ = createFPSCounter(&world);

    try loop(&world);
}

fn loop(world: *Ecs) anyerror!void {
    world.addSystem(movement);
    world.addSystem(moveCommands);
    world.addSystem(updateCamera);

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

        std.debug.print("dt {}", .{dt});

        world.setResource(.dt, dt);
    }

    rl.CloseWindow();
}
