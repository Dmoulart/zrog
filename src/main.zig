const std = @import("std");
const rl = @import("raylib");

const Zecs = @import("zecs");
const Ecs = @import("./context.zig").Ecs;

const ts = std.time.milliTimestamp;

const createCamera = @import("./graphics/camera.zig").createCamera;
const createPlayer = @import("./player/create-player.zig").createPlayer;

const render = @import("./graphics/renderer.zig").render;
const updateCamera = @import("./graphics/camera.zig").updateCamera;
const movement = @import("./physics/movement.zig").movement;
const moveCommands = @import("./input/move-commands.zig").moveCommands;

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
    rl.SetTargetFPS(60);

    var x: i32 = 0;
    var y: i32 = 0;

    // Fill map
    while (y < 50) : (y += 1) {
        while (x < 50) : (x += 1) {
            var block = world.createEmpty();
            world.attach(block, .Transform);
            world.attach(block, .Sprite);

            world.write(block, .Sprite, .{
                .char = ".",
                .color = rl.GREEN,
            });
            world.write(block, .Transform, .{
                .x = x,
                .y = y,
                .z = 0,
            });
        }
        x = 0;
    }

    _ = createCamera(&world);
    _ = createPlayer(&world);

    try loop(&world);
}

fn loop(world: *Ecs) anyerror!void {
    world.addSystem(movement);
    world.addSystem(moveCommands);
    world.addSystem(updateCamera);
    world.addSystem(render);

    // Main game loop
    while (!rl.WindowShouldClose()) {
        var loop_start = ts();

        world.step();

        world.setResource(.dt, ts() - loop_start);
    }

    rl.CloseWindow();
}
