const std = @import("std");
const rl = @import("raylib");

const Zecs = @import("zecs");
const Ecs = @import("./context.zig").Ecs;

const createCamera = @import("./graphics/camera.zig").createCamera;
const createPlayer = @import("./player/create-player.zig").createPlayer;

const render = @import("./graphics/renderer.zig").render;
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

    rl.InitWindow(screen_height, screen_width, "Zrog");
    rl.SetTargetFPS(60);

    var x: f32 = 0;
    var y: f32 = 0;

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
    world.addSystem(render);
    world.addSystem(moveCommands);

    // Main game loop
    while (!rl.WindowShouldClose()) {
        var camera = world.getResource(.camera);
        // clone ?
        var camera_object = world.clone(camera, .Camera);

        rl.BeginDrawing();

        rl.ClearBackground(rl.BLACK);

        rl.BeginMode2D(camera_object);

        var loop_start = std.time.milliTimestamp();

        world.step();

        var dt = @intToFloat(f32, std.time.milliTimestamp() - loop_start);
        world.setResource(.dt, dt);

        rl.EndMode2D();

        rl.EndDrawing();
    }

    rl.CloseWindow();
}
