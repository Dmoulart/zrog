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
    .InChunk,
});
const Cell = Ecs.Type(.{
    .Sprite,
    .Transform,
    .Terrain,
    .InChunk,
});

pub fn generate(world: *Ecs, chunk_x: i32, chunk_y: i32) Chunk {
    world.registerType(Cell);
    world.registerType(Grass);

    var id = world.createEmpty();
    world.attach(id, .Chunk);

    var chunk = Chunk.init(chunk_x, chunk_y, id);

    createTerrain(world, &chunk);

    createTrees(world, &chunk);

    return chunk;
}

pub fn createTerrain(world: *Ecs, chunk: *Chunk) void {
    for (chunk.terrain) |*col, x| {
        for (col) |*entity, y| {
            entity.* = createGrass(
                world,
                chunk.getChunkX() + @intCast(i32, x),
                chunk.getChunkY() + @intCast(i32, y),
                chunk.id,
            );
        }
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

            _ = createTree(
                world,
                @intCast(i32, x + cell_offset_x),
                @intCast(i32, y + cell_offset_y),
                chunk.id,
            );
        }

        x = 0;
    }
}

pub fn createTree(world: *Ecs, x: i32, y: i32, chunk_id: Zecs.Entity) Zecs.Entity {
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
    world.write(tree, .InChunk, .{
        .chunk = chunk_id,
    });

    return tree;
}

pub fn createGrass(world: *Ecs, x: i32, y: i32, chunk_id: Zecs.Entity) Zecs.Entity {
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
    world.set(grass, .InChunk, .chunk, chunk_id);

    return grass;
}
