const std = @import("std");
const assert = std.debug.assert;

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const BoundingBox = @import("../math/bounding-box.zig");
const Vector = @import("../math/vector.zig").Vector;
const CollisionGrid = @import("./collision-grid.zig").CollisionGrid;

const Self = @This();

// The size of a map chunk in cells.
pub const SIZE = 50;

pub const ChunkCollisionGrid = CollisionGrid(SIZE, SIZE);

pub const Data = enum {
    terrain,
    props,
    beings,
};

// the coordinates of this chunk relative to other chunks
chunks_x: i32,
chunks_y: i32,

bbox: BoundingBox,

terrain: [SIZE * SIZE]Zecs.Entity = undefined,
props: [SIZE * SIZE]Zecs.Entity = undefined,
beings: [SIZE * SIZE]Zecs.Entity = undefined,

pub fn init(x: i32, y: i32) Self {
    var chunk = Self{
        .chunks_x = x,
        .chunks_y = y,
        .bbox = BoundingBox{
            .x = x * SIZE,
            .y = y * SIZE,
            .width = SIZE,
            .height = SIZE,
        },
    };

    // Init terrain and props with 0 values (means no entitiy)
    chunk.clear();
    return chunk;
}

pub fn clear(self: *Self) void {
    var cell_x: usize = 0;
    while (cell_x < SIZE) : (cell_x += 1) {
        @memset(&self.terrain, 0);
        @memset(&self.props, 0);
        @memset(&self.beings, 0);
    }
}

// todo : rename world to global ?
pub fn setFromGlobalPosition(self: *Self, comptime data_field: Data, entity: Zecs.Entity, x: i32, y: i32) void {
    assert(self.bbox.contains(x, y));

    var local_x = self.toLocalX(x);
    var local_y = self.toLocalY(y);

    self.set(data_field, entity, local_x, local_y);
}

pub fn set(self: *Self, comptime data_field: Data, entity: Zecs.Entity, local_x: usize, local_y: usize) void {
    assert(local_x < SIZE and local_y < SIZE);

    var data = &@field(self, @tagName(data_field));
    data[local_x * SIZE + local_y] = entity;
}

// todo : rename world to global ?
pub fn getFromGlobalPosition(self: *Self, comptime data_field: Data, x: i32, y: i32) ?Zecs.Entity {
    var local_x = self.toLocalX(x);
    var local_y = self.toLocalY(y);

    return self.get(data_field, local_x, local_y);
}

pub fn get(self: *Self, comptime data_field: Data, local_x: usize, local_y: usize) ?Zecs.Entity {
    var data = &@field(self, @tagName(data_field));

    assert(local_x < SIZE and local_y < SIZE);

    var prop = data[local_x * SIZE + local_y];

    return if (prop == 0) null else prop;
}

pub fn has(self: *Self, comptime data_field: Data, local_x: usize, local_y: usize) bool {
    var data = &@field(self, @tagName(data_field));

    assert(local_x < SIZE and local_y < SIZE);

    var prop = data[local_x * SIZE + local_y];

    return prop != 0;
}

pub fn deleteFromGlobalPosition(self: *Self, comptime data_field: Data, x: i32, y: i32) void {
    assert(self.bbox.contains(x, y));

    var local_x = self.toLocalX(x);
    var local_y = self.toLocalY(y);

    self.delete(data_field, local_x, local_y);
}

pub fn delete(self: *Self, comptime data_field: Data, local_x: usize, local_y: usize) void {
    assert(local_x < SIZE and local_y < SIZE);

    var data = &@field(self, @tagName(data_field));

    data[local_x * SIZE + local_y] = 0;
}

pub fn generateCollisionGrid(self: *Self) ChunkCollisionGrid {
    var grid: ChunkCollisionGrid = undefined;

    for (&grid, 0..) |*col, x| {
        for (col, 0..) |_, y| {
            const obstacle = self.has(.props, x, y); // or self.has(.beings, x, y);
            col[y] = if (obstacle) 1 else 0;
        }
    }

    return grid;
}

pub fn getGlobalX(self: *Self) i32 {
    return self.chunks_x * SIZE;
}

pub fn getGlobalY(self: *Self) i32 {
    return self.chunks_y * SIZE;
}

pub fn toLocalX(self: *Self, x: i32) usize {
    return @intCast(x - self.getGlobalX());
}

pub fn toLocalY(self: *Self, y: i32) usize {
    return @intCast(y - self.getGlobalY());
}

pub fn toGlobalX(self: *Self, x: i32) i32 {
    return x + self.bbox.x;
}

pub fn toGlobalY(self: *Self, y: i32) i32 {
    return y + self.bbox.y;
}
