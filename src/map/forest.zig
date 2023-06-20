const std = @import("std");
const rl = @import("raylib");

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const BoundingBox = @import("../math/bounding-box.zig");

const Automaton = @import("../generation/cellular-automaton.zig").MapAutomaton;
var automaton = @import("../generation/cellular-automaton.zig").map_automaton;
const Chunk = @import("./chunk.zig");

const RndGen = std.rand.DefaultPrng;
var rnd = RndGen.init(0);

const Grass = Ecs.Type(.{
    .Transform,
    .Sprite,
});
const Cell = Ecs.Type(.{
    .Sprite,
    .Transform,
    .Terrain,
});

pub fn generate(world: *Ecs, chunk: *Chunk) void {
    world.registerType(Grass);
    world.registerType(Cell);

    createTerrain(world, chunk);
    createTrees(world, chunk);
}

pub fn createTerrain(world: *Ecs, chunk: *Chunk) void {
    var x: usize = 0;
    var y: usize = 0;

    while (y < Chunk.SIZE) : (y += 1) {
        while (x < Chunk.SIZE) : (x += 1) {
            chunk.set(.terrain, createGrass(
                world,
                chunk.getChunkX() + @intCast(i32, x),
                chunk.getChunkY() + @intCast(i32, y),
            ), x, y);
        }

        x = 0;
    }
}

pub fn createTrees(world: *Ecs, chunk: *Chunk) void {
    automaton.fillWithLivingChanceOf(4);

    automaton.update(2);

    var x: usize = 0;
    var y: usize = 0;

    var cell_offset_x = @intCast(usize, chunk.getChunkX());
    var cell_offset_y = @intCast(usize, chunk.getChunkY());

    while (y < automaton.height - 1) : (y += 1) {
        while (x < automaton.width - 1) : (x += 1) {
            var state = automaton.get(x, y);

            if (state == .dead) continue;

            var world_x = @intCast(i32, x + cell_offset_x);
            var world_y = @intCast(i32, y + cell_offset_y);

            var tree = createTree(
                world,
                world_x,
                world_y,
            );

            chunk.setFromWorldPosition(
                .props,
                tree,
                world_x,
                world_y,
            );
        }

        x = 0;
    }
}

pub fn createTree(world: *Ecs, x: i32, y: i32) Zecs.Entity {
    var tree = world.create(Grass);

    world.write(tree, .Sprite, .{
        .char = "0",
        .color = rl.BLUE,
    });
    world.write(tree, .Transform, .{
        .x = x,
        .y = y,
        .z = 0,
    });

    return tree;
}

pub fn createGrass(world: *Ecs, x: i32, y: i32) Zecs.Entity {
    var grass = world.create(Cell);

    world.write(grass, .Sprite, .{
        .char = "\"",
        .color = rl.DARKGRAY,
    });
    world.write(grass, .Transform, .{
        .x = x,
        .y = y,
        .z = 0,
    });

    return grass;
}
