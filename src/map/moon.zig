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

const Dust = Ecs.Type(.{
    .Transform,
    .Glyph,
});
const Cell = Ecs.Type(.{
    .Glyph,
    .Transform,
    .Terrain,
});

pub fn generate(world: *Ecs, chunk: *Chunk) void {
    world.registerType(Dust);
    world.registerType(Cell);

    createTerrain(world, chunk);
    createRocks(world, chunk);
}

pub fn createTerrain(world: *Ecs, chunk: *Chunk) void {
    var x: usize = 0;
    var y: usize = 0;

    while (y < Chunk.SIZE) : (y += 1) {
        while (x < Chunk.SIZE) : (x += 1) {
            chunk.set(.terrain, createDust(
                world,
                chunk.getGlobalX() + @as(i32, @intCast(x)),
                chunk.getGlobalY() + @as(i32, @intCast(y)),
            ), x, y);
        }

        x = 0;
    }
}

pub fn createRocks(world: *Ecs, chunk: *Chunk) void {
    automaton.fillWithLivingChanceOf(10);

    automaton.update(2);

    var x: usize = 0;
    var y: usize = 0;

    var cell_offset_x: usize = @intCast(chunk.getGlobalX());
    var cell_offset_y: usize = @intCast(chunk.getGlobalY());

    while (y < automaton.height - 1) : (y += 1) {
        while (x < automaton.width - 1) : (x += 1) {
            var state = automaton.get(x, y);

            if (state == .dead) continue;

            var world_x: i32 = @intCast(x + cell_offset_x);
            var world_y: i32 = @intCast(y + cell_offset_y);

            var rock = createRock(
                world,
                world_x,
                world_y,
            );

            chunk.setFromGlobalPosition(
                .props,
                rock,
                world_x,
                world_y,
            );
        }

        x = 0;
    }
}

pub fn createRock(world: *Ecs, x: i32, y: i32) Zecs.Entity {
    var rock = world.create(Dust);

    world.write(rock, .Glyph, .{
        .char = "0",
        .color = rl.BLUE,
    });
    world.write(rock, .Transform, .{
        .x = x,
        .y = y,
        .z = 0,
    });

    return rock;
}

pub fn createDust(world: *Ecs, x: i32, y: i32) Zecs.Entity {
    var dust = world.create(Cell);

    world.write(dust, .Glyph, .{
        .char = "\"",
        .color = rl.DARKGRAY,
    });
    world.write(dust, .Transform, .{
        .x = x,
        .y = y,
        .z = 0,
    });

    return dust;
}
