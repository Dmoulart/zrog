const std = @import("std");
const assert = std.debug.assert;
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const BoundingBox = @import("../math/bounding-box.zig");

const Self = @This();

// The size of a map chunk in cells.
pub const SIZE = 100;
// pub const MAX_ENTITY_PER_CELL = 10;

// in chunk size
x: i32,
y: i32,

bbox: BoundingBox,

id: Zecs.Entity,

terrain: [SIZE][SIZE]Zecs.Entity = undefined,
props: [SIZE][SIZE]Zecs.Entity = undefined,

pub fn init(x: i32, y: i32, id: Zecs.Entity) Self {
    var chunk = Self{
        .id = id,
        .x = x,
        .y = y,
        .bbox = BoundingBox{
            .x = x * SIZE,
            .y = y * SIZE,
            .width = SIZE,
            .height = SIZE,
        },
    };

    // Init terrain and props with 0 values (means no entitiy)
    var cell_x: usize = 0;
    while (cell_x < SIZE) : (cell_x += 1) {
        std.mem.set(Zecs.Entity, &chunk.terrain[cell_x], 0);
        std.mem.set(Zecs.Entity, &chunk.props[cell_x], 0);
    }

    return chunk;
}

pub fn place(self: *Self, world: *Ecs, entity: Zecs.Entity) void {
    assert(world.contains(entity));

    var transform = world.pack(entity, .Transform);
    assert(self.bbox.contains(transform.x.*, transform.y.*));

    var x = @intCast(usize, transform.x.* - self.getChunkX());
    var y = @intCast(usize, transform.y.* - self.getChunkY());

    self.props[x][y] = entity;
}

pub fn getProp(self: *Self, x: i32, y: i32) ?Zecs.Entity {
    var chunk_x = self.toChunkX(x);
    var chunk_y = self.toChunkY(y);

    assert(chunk_x < SIZE and chunk_y < SIZE);

    var prop = self.props[chunk_x][chunk_y];

    return if (prop == 0) null else prop;
}

pub fn getChunkX(self: *Self) i32 {
    return self.x * SIZE;
}

pub fn getChunkY(self: *Self) i32 {
    return self.y * SIZE;
}

pub fn toChunkX(self: *Self, x: i32) usize {
    return @intCast(usize, x - self.getChunkX());
}
pub fn toChunkY(self: *Self, y: i32) usize {
    return @intCast(usize, y - self.getChunkY());
}
