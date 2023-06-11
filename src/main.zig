const std = @import("std");
const rl = @import("raylib");

const Zecs = @import("zecs");
const Ecs = @import("./context.zig").Ecs;

const timestamp = std.time.milliTimestamp;

const createCamera = @import("./graphics/camera.zig").createCamera;
const createPlayer = @import("./player/create-player.zig").createPlayer;

const prerender = @import("./graphics/renderer.zig").prerender;
const render = @import("./graphics/renderer.zig").render;
const renderTerrain = @import("./graphics/renderer.zig").renderTerrain;
const postrender = @import("./graphics/renderer.zig").postrender;

const updateCamera = @import("./graphics/camera.zig").updateCamera;
const movement = @import("./physics/movement.zig").movement;
const moveCommands = @import("./input/move-commands.zig").moveCommands;

const Forest = @import("./map/forest.zig");

const Automaton = @import("./map/chunks.zig").MapAutomaton;
var automaton = Automaton.init();

pub fn main() !void {
    // Creation

    try Ecs.setup(std.heap.page_allocator);
    defer Ecs.unsetup();

    var world = try Ecs.init(.{
        .allocator = std.heap.page_allocator,
    });
    defer world.deinit();

    // Initialization

    const screen_width = world.getResource(.screen_width);
    const screen_height = world.getResource(.screen_height);

    rl.InitWindow(screen_width, screen_height, "Zrog");
    rl.SetTargetFPS(10);

    Forest.generate(
        &world,
        0,
        0,
    );

    _ = createCamera(&world);
    _ = createPlayer(&world);

    automaton.debugFill();

    try loop(&world);
}

fn loop(world: *Ecs) anyerror!void {
    world.addSystem(movement);
    world.addSystem(moveCommands);
    world.addSystem(updateCamera);

    // world.addSystem(prerender);
    // world.addSystem(render);
    // world.addSystem(renderTerrain);
    // world.addSystem(postrender);

    // Main game loop
    while (!rl.WindowShouldClose()) {
        var loop_start = timestamp();

        world.step();

        automaton.update(1);

        // clone ?
        var camera = world.clone(world.getResource(.camera), .Camera);

        automaton.debugDraw(camera, 24);

        world.setResource(.dt, timestamp() - loop_start);
    }

    rl.CloseWindow();
}
