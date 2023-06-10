const std = @import("std");
const rl = @import("raylib");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

pub fn generate(world: *Ecs, offset_x: i32, offset_y: i32, width: u32, height: u32) void {
    var y: i32 = 0;
    var x: i32 = 0;

    // Terrain
    while (y < height) : (y += 1) {
        while (x < width) : (x += 1) {
            createGrass(world, offset_x + x, offset_y + y);
        }

        x = 0;
    }
}

pub fn createGrass(world: *Ecs, x: i32, y: i32) void {
    var grass = world.createEmpty();
    world.attach(grass, .Transform);
    world.attach(grass, .Sprite);

    world.write(grass, .Sprite, .{
        .char = ".",
        .color = rl.GREEN,
    });
    world.write(grass, .Transform, .{
        .x = x,
        .y = y,
        .z = 0,
    });
}
