const std = @import("std");
const assert = std.debug.assert;

const Zecs = @import("zecs");

const Chunk = @import("./chunk.zig");
const Ecs = @import("../context.zig").Ecs;
const BoundingBox = @import("../math/bounding-box.zig");
const getCameraBoundingBox = @import("../graphics/camera.zig").getCameraBoundingBox;

const GlobalCollisionGrid = [Chunk.SIZE * 9][Chunk.SIZE * 9]u8;

const Point = struct { x: usize, y: usize };
const COORDS: [9]Point = [9]Point{ .{
    .x = 0,
    .y = 0,
}, .{
    .x = 1,
    .y = 0,
}, .{
    .x = 2,
    .y = 0,
}, .{
    .x = 0,
    .y = 1,
}, .{
    .x = 1,
    .y = 1,
}, .{
    .x = 2,
    .y = 1,
}, .{
    .x = 0,
    .y = 2,
}, .{
    .x = 1,
    .y = 2,
}, .{
    .x = 2,
    .y = 2,
} };

const Self = @This();
const ChunkGroup = [3][3]?Chunk;

allocator: std.mem.Allocator,

chunks: *ChunkGroup = undefined,

visible_chunks_memory: [9]*Chunk = undefined,

pub fn create(allocator: std.mem.Allocator) *Self {
    var chunks = allocator.create(Self) catch unreachable;
    chunks.allocator = allocator;

    var chunk_group = allocator.create(ChunkGroup) catch unreachable;

    for (COORDS) |point| {
        chunk_group[point.x][point.y] = Chunk.init(
            @intCast(i32, point.x),
            @intCast(i32, point.y),
        );
    }

    chunks.chunks = chunk_group;
    return chunks;
}

pub fn destroy(self: *Self) void {
    self.allocator.destroy(self);
}

pub fn getChunkAtPosition(self: *Self, x: i32, y: i32) ?*Chunk {
    for (self.chunks) |*row| {
        for (row) |*maybe_chunk| {
            if (maybe_chunk.*) |*chunk| {
                if (chunk.bbox.contains(x, y)) return chunk;
            }
        }
    }

    return null;
}

pub fn get(self: *Self, comptime data_field: Chunk.Data, world_x: i32, world_y: i32) ?Zecs.Entity {
    var chunk = self.getChunkAtPosition(world_x, world_y);

    assert(chunk != null);

    return chunk.?.getFromWorldPosition(data_field, world_x, world_y);
}

pub fn maybeGet(self: *Self, comptime data_field: Chunk.Data, world_x: i32, world_y: i32) ?Zecs.Entity {
    var chunk = self.getChunkAtPosition(world_x, world_y);

    if (chunk == null) return null;

    return chunk.?.getFromWorldPosition(data_field, world_x, world_y);
}

pub fn set(self: *Self, comptime data_field: Chunk.Data, entity: Zecs.Entity, world_x: i32, world_y: i32) void {
    var chunk = self.getChunkAtPosition(world_x, world_y);

    assert(chunk != null);

    chunk.?.setFromWorldPosition(data_field, entity, world_x, world_y);
}

pub fn delete(self: *Self, comptime data_field: Chunk.Data, world_x: i32, world_y: i32) void {
    var chunk = self.getChunkAtPosition(world_x, world_y);

    assert(chunk != null);

    chunk.?.deleteFromWorldPosition(data_field, world_x, world_y);
}

pub fn filterVisible(
    self: *Self,
    world: *Ecs,
    camera: Zecs.Entity,
) []*Chunk {
    // reinit memory
    self.visible_chunks_memory = undefined;

    var camera_bbox = getCameraBoundingBox(world, camera);

    var buffer: []*Chunk = &self.visible_chunks_memory;
    var chunks: []*Chunk = buffer[0..];

    var count: usize = 0;

    for (self.chunks) |*row| {
        for (row) |*maybe_chunk| {
            if (maybe_chunk.*) |*chunk| {
                if (chunk.bbox.intersects(&camera_bbox)) {
                    chunks[count] = chunk;
                    count += 1;
                }
            }
        }
    }

    return chunks[0..count];
}

pub fn generateCollisionGrid(self: *Self) GlobalCollisionGrid {
    var grid: GlobalCollisionGrid = undefined;

    for (self.chunks) |*row| {
        for (row) |*maybe_chunk| {
            if (maybe_chunk.*) |*chunk| {
                var chunk_grid = chunk.generateCollisionGrid(.{
                    .x = 0,
                    .y = 0,
                });

                for (chunk_grid) |*grid_row, x| {
                    for (grid_row) |_, y| {
                        var global_x = @intCast(usize, (@intCast(usize, chunk.x) * Chunk.SIZE) + x);
                        var global_y = @intCast(usize, (@intCast(usize, chunk.y) * Chunk.SIZE) + y);
                        // std.debug.print("\n x{} y{} \n", .{ global_x, global_y });
                        // std.debug.print("\n chunk grid {} \n", .{chunk_grid[x][y]});
                        grid[global_x][global_y] = chunk_grid[x][y];
                    }
                }
            }
        }
    }
    // std.debug.print("grid {any}", .{grid});
    return grid;

    // var len = Chunk.SIZE * Chunk.SIZE;

    // var i: u32 = 0;

    // while(len <= i){
    //     for(self.chunks) |chunk|{
    //         chunk.props[i]
    //     }
    // }

    // for (self.chunks) |chunk| {
    //     var col: [Chunk.SIZE * 9]u8 = undefined;
    //     _ = col;
    //     var chunk_grid = chunk.generateCollisionGrid(.{
    //         .x = chunk.x,
    //         .x = chunk.y,
    //     });
    //     _ = chunk_grid;

    //     for(chunk.grid){

    //     }
    // }

    // var grid: [SIZE][SIZE]u8 = undefined;

    // for (grid) |_, x| {
    //     var col: [SIZE]u8 = undefined;

    //     for (col) |_, y| {
    //         const obstacle = self.has(.props, x + offset.x, offset.y); // or self.has(.beings, x, y);
    //         col[y] = if (obstacle) 1 else 0;
    //     }

    //     grid[x] = col;
    // }

    // return grid;
}

pub fn getBoundingBox(self: *Self) BoundingBox {
    var chunks_bbox: ?BoundingBox = null;

    for (self.chunks) |*row| {
        for (row) |*maybe_chunk| {
            if (maybe_chunk.*) |*chunk| {
                if (chunks_bbox) |*bbox| {
                    chunks_bbox = chunk.bbox.merge(bbox);
                } else {
                    // init bbox
                    chunks_bbox = BoundingBox{
                        .x = chunk.bbox.x,
                        .y = chunk.bbox.y,
                        .width = chunk.bbox.width,
                        .height = chunk.bbox.height,
                    };
                }
            }
        }
    }

    // We always should have at least one chunk loaded so the bbox should always be defined
    return chunks_bbox.?;
}

// pub fn getByID(self: *Self, id: Zecs.Entity) ?*Chunk {
//     for (self.chunks) |*row| {
//         for (row) |*maybe_chunk| {
//             if (maybe_chunk.*) |*chunk| {
//                 if (chunk.id == id) return chunk;
//             }
//         }
//     }
//     return null;
// }
