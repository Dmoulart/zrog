const std = @import("std");
const rl = @import("raylib");

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const BoundingBox = @import("../math/bounding-box.zig").BoundingBox;

const Automaton = @import("./chunks.zig").MapAutomaton;
var automaton = @import("./chunks.zig").automaton;
const MAP_CHUNK_SIZE = @import("./chunks.zig").MAP_CHUNK_SIZE;

const RndGen = std.rand.DefaultPrng;
var rnd = RndGen.init(0);

pub fn generate(world: *Ecs, offset_x: i32, offset_y: i32) void {
    var y: i32 = 0;
    var x: i32 = 0;

    createTerrain(world, offset_x + x, offset_y + y);

    createTrees(world, offset_x + x, offset_y + y);
}

pub fn createTerrain(world: *Ecs, x: i32, y: i32) void {
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
        .width = MAP_CHUNK_SIZE,
        .height = MAP_CHUNK_SIZE,
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

pub fn createTrees(world: *Ecs, offset_x: i32, offset_y: i32) void {
    automaton.map(liveOrDie);

    automaton.update(12);

    // automaton.each(world, mapLivingCellToTree);

    var cells_x: usize = 0;
    var cells_y: usize = 0;

    var cell_offset_x = @intCast(usize, offset_x);
    var cell_offset_y = @intCast(usize, offset_y);

    while (cells_y < automaton.height - 1) : (cells_y += 1) {
        cells_x = 0;

        while (cells_x < automaton.width - 1) : (cells_x += 1) {
            mapLivingCellToTree(
                world,
                cells_x + cell_offset_x,
                cells_y + cell_offset_y,
                automaton.getPtr(cells_x, cells_y),
            );
        }
    }
}

pub fn liveOrDie(x: usize, y: usize, state: Automaton.Cells) Automaton.Cells {
    _ = x;
    _ = state;
    _ = y;

    var alive = rnd.random().boolean();
    return if (alive) .alive else .dead;
}

pub fn mapLivingCellToTree(world: *Ecs, x: usize, y: usize, state: *Automaton.Cells) void {
    if (state.* == .dead) return;

    createTree(world, @intCast(i32, x), @intCast(i32, y));
}

pub fn createTree(world: *Ecs, x: i32, y: i32) void {
    var grass = world.createEmpty();

    world.attach(grass, .Transform);
    world.attach(grass, .Sprite);

    world.write(grass, .Sprite, .{
        .char = "O",
        .color = rl.YELLOW,
    });
    world.write(grass, .Transform, .{
        .x = x,
        .y = y,
        .z = 0,
    });
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
