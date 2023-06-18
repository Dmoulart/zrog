const std = @import("std");
const assert = std.debug.assert;
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const BoundingBox = @import("../math/bounding-box.zig");

const Self = @This();

// The size of a map chunk in cells.
pub const SIZE = 1250;

pub const Data = enum {
    terrain,
    props,
    beings,
};

// in chunk size
x: i32,
y: i32,

bbox: BoundingBox,

id: Zecs.Entity,

terrain: [SIZE][SIZE]Zecs.Entity = undefined,
props: [SIZE][SIZE]Zecs.Entity = undefined,
beings: [SIZE][SIZE]Zecs.Entity = undefined,

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
    chunk.clear();
    return chunk;
}

pub fn create(allocator: std.mem.Allocator, x: i32, y: i32, id: Zecs.Entity) *Self {
    var chunk = allocator.create(Self) catch unreachable;

    chunk.id = id;
    chunk.x = x;
    chunk.y = y;
    chunk.bbox = BoundingBox{
        .x = x * SIZE,
        .y = y * SIZE,
        .width = SIZE,
        .height = SIZE,
    };
    chunk.clear();
}

pub fn clear(self: *Self) void {
    var cell_x: usize = 0;
    while (cell_x < SIZE) : (cell_x += 1) {
        std.mem.set(Zecs.Entity, &self.terrain[cell_x], 0);
        std.mem.set(Zecs.Entity, &self.props[cell_x], 0);
        std.mem.set(Zecs.Entity, &self.beings[cell_x], 0);
    }
}

pub fn setFromWorldPosition(self: *Self, comptime data_field: Data, entity: Zecs.Entity, x: i32, y: i32) void {
    assert(self.bbox.contains(x, y));

    var chunk_x = self.toChunkX(x);
    var chunk_y = self.toChunkY(y);

    self.set(data_field, entity, chunk_x, chunk_y);
}

pub fn set(self: *Self, comptime data_field: Data, entity: Zecs.Entity, chunk_x: usize, chunk_y: usize) void {
    assert(chunk_x < SIZE and chunk_y < SIZE);

    var data = comptime &@field(self, @tagName(data_field));
    data[chunk_x][chunk_y] = entity;
}

pub fn getFromWorldPosition(self: *Self, comptime data_field: Data, x: i32, y: i32) ?Zecs.Entity {
    var chunk_x = self.toChunkX(x);
    var chunk_y = self.toChunkY(y);

    return self.get(data_field, chunk_x, chunk_y);
}

pub fn get(self: *Self, comptime data_field: Data, chunk_x: usize, chunk_y: usize) ?Zecs.Entity {
    var data = comptime &@field(self, @tagName(data_field));

    assert(chunk_x < SIZE and chunk_y < SIZE);

    var prop = data[chunk_x][chunk_y];

    return if (prop == 0) null else prop;
}

pub fn deleteFromWorldPosition(self: *Self, comptime data_field: Data, x: i32, y: i32) void {
    assert(self.bbox.contains(x, y));

    var chunk_x = self.toChunkX(x);
    var chunk_y = self.toChunkY(y);

    self.delete(data_field, chunk_x, chunk_y);
}

pub fn delete(self: *Self, comptime data_field: Data, chunk_x: usize, chunk_y: usize) void {
    assert(chunk_x < SIZE and chunk_y < SIZE);

    var data = comptime &@field(self, @tagName(data_field));

    data[chunk_x][chunk_y] = 0;
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
