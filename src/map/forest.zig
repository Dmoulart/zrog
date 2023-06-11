const std = @import("std");
const rl = @import("raylib");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const BoundingBox = @import("../math/bounding-box.zig").BoundingBox;

pub fn generate(world: *Ecs, offset_x: i32, offset_y: i32, width: u32, height: u32) void {
    var y: i32 = 0;
    var x: i32 = 0;

    createTerrain(world, offset_x + x, offset_y + y, width, height);
}

pub fn createTerrain(world: *Ecs, x: i32, y: i32, width: u32, height: u32) void {
    var terrain = world.createEmpty();

    world.attach(terrain, .Transform);
    world.attach(terrain, .Sprite);
    world.attach(terrain, .Terrain);

    world.write(terrain, .Transform, .{
        .x = x,
        .y = y,
        .z = 0,
    });
    world.write(terrain, .Sprite, .{
        .char = ".",
        .color = rl.GREEN,
    });
    world.write(terrain, .Terrain, .{
        .width = width,
        .height = height,
    });
}

pub fn getTerrainBoundingBox(world: *Ecs, terrain: Zecs.Entity) BoundingBox {
    var transform = world.pack(terrain, .Transform);

    var width = world.get(terrain, .Terrain, .width);
    var height = world.get(terrain, .Terrain, .height);

    return BoundingBox{
        .x = transform.x.*,
        .y = transform.y.*,
        .width = width.*,
        .height = height.*,
    };
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
