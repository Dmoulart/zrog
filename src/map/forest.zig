const std = @import("std");
const rl = @import("raylib");

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const BoundingBox = @import("../math/bounding-box.zig").BoundingBox;

const Automaton = @import("../generation/cellular-automaton.zig").MapAutomaton;
var automaton = @import("../generation/cellular-automaton.zig").map_automaton;
const Chunk = @import("./chunks.zig");

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

pub fn generate(world: *Ecs, offset_x: i32, offset_y: i32) Chunk {
    var id = world.createEmpty();
    world.attach(id, .Chunk);

    var chunk = Chunk.init(offset_x, offset_y, id);

    createTerrain(world, &chunk);

    createTrees(world, &chunk);

    return chunk;
}

pub fn createTerrain(world: *Ecs, chunk: *Chunk) void {
    world.registerType(Cell);
    world.registerType(Grass);

    for (chunk.terrain) |*col, x| {
        for (col) |*entity, y| {
            // register cell id
            entity.* = world.create(Cell);
            // give it some data
            world.write(entity.*, .Sprite, .{
                .char = "\"",
                .color = rl.DARKGRAY,
            });
            world.write(
                entity.*,
                .Transform,
                .{
                    .x = chunk.x + @intCast(i32, x),
                    .y = chunk.y + @intCast(i32, y),
                },
            );
            world.set(entity.*, .InChunk, .chunk, chunk.id);
        }
    }
}

pub fn createTrees(world: *Ecs, chunk: *Chunk) void {
    automaton.fillWithLivingChance(10);

    automaton.update(2);

    var x: usize = 0;
    var y: usize = 0;

    var cell_offset_x = @intCast(usize, chunk.x);
    var cell_offset_y = @intCast(usize, chunk.y);

    while (y < automaton.height - 1) : (y += 1) {
        x = 0;

        while (x < automaton.width - 1) : (x += 1) {
            var state = automaton.get(x, y);

            if (state == .dead) continue;

            createTree(
                world,
                @intCast(i32, x + cell_offset_x),
                @intCast(i32, y + cell_offset_y),
                chunk.id,
            );
        }
    }
}

pub fn createTree(world: *Ecs, x: i32, y: i32, chunk_id: Zecs.Entity) void {
    var grass = world.create(Grass);

    world.write(grass, .Sprite, .{
        .char = "0",
        .color = rl.BLUE,
    });
    world.write(grass, .Transform, .{
        .x = x,
        .y = y,
        .z = 0,
    });
    world.write(grass, .InChunk, .{
        .chunk = chunk_id,
    });
}

// pub fn createTrees(world: *Ecs, offset_x: i32, offset_y: i32) void {
//     automaton.fillWithLivingChance(10);

//     automaton.update(12);

//     var x: usize = 0;
//     var y: usize = 0;

//     var cell_offset_x = @intCast(usize, offset_x);
//     var cell_offset_y = @intCast(usize, offset_y);

//     while (y < automaton.height - 1) : (y += 1) {
//         x = 0;

//         while (x < automaton.width - 1) : (x += 1) {
//             mapLivingCellToTree(
//                 world,
//                 x + cell_offset_x,
//                 y + cell_offset_y,
//                 automaton.getPtr(x, y),
//             );
//         }
//     }
// }

// pub fn mapLivingCellToTree(world: *Ecs, x: usize, y: usize, state: *Automaton.Cells) void {
//     if (state.* == .dead) return;

//     createTree(world, @intCast(i32, x), @intCast(i32, y));
// }

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
