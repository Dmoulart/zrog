const std = @import("std");
const rl = @import("raylib");

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const BoundingBox = @import("../math/bounding-box.zig").BoundingBox;
const CellularAutomaton = @import("../generation/cellular-automaton.zig").CellularAutomaton;

const RndGen = std.rand.DefaultPrng;

pub fn generate(world: *Ecs, offset_x: i32, offset_y: i32, width: u32, height: u32) void {
    var y: i32 = 0;
    var x: i32 = 0;

    createTerrain(world, offset_x + x, offset_y + y, width, height);

    createTrees(world, offset_x + x, offset_y + y, width, height);
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

pub fn createTrees(world: *Ecs, x: i32, y: i32, width: u32, height: u32) void {
    _ = y;
    _ = x;
    var automaton = CellularAutomaton.init(
        world.allocator,
        @intCast(usize, width),
        @intCast(usize, height),
    ) catch unreachable;

    automaton.map(populateCellularAutomaton);

    automaton.update(0);

    // automaton.each(world, mapLivingCellToTree);

    var col: usize = 0;
    while (col < automaton.height - 1) : (col += 1) {
        var row: usize = 0;

        while (row < automaton.width - 1) : (row += 1) {
            mapLivingCellToTree(world, row, col, automaton.get(row, col));
        }
    }
}

pub fn populateCellularAutomaton(x: usize, y: usize, state: *CellularAutomaton.Cells) CellularAutomaton.Cells {
    _ = x;
    _ = state;
    _ = y;
    var rnd = RndGen.init(0);
    var alive = rnd.random().boolean();
    return if (alive) .alive else .dead;
}

pub fn mapLivingCellToTree(world: *Ecs, x: usize, y: usize, state: *CellularAutomaton.Cells) void {
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
