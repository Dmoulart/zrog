const Zecs = @import("zecs");

const Chunk = @import("./chunk.zig");
const Ecs = @import("../context.zig").Ecs;
const getCameraBoundingBox = @import("../graphics/camera.zig").getCameraBoundingBox;

const Self = @This();
const ChunkGroup = [3][3]?Chunk;

chunks: ChunkGroup,

// alloc ?
visible_chunks_memory: [9]*Chunk = undefined,

pub fn init(chunks: *ChunkGroup) Self {
    return Self{
        .chunks = chunks.*,
    };
}

// pub fn containsPoint(self: *Self, x: i32, y: i32) []*Chunk {
//     var chunks: []*Chunk = undefined;
//     var nb_chunks: usize = 0;

//     for (self.chunks) |*row| {
//         for (row) |*maybe_chunk| {
//             if (maybe_chunk) |chunk| {
//                 if (chunk.bbox.contains(x, y)) {
//                     chunks[nb_chunks] = chunk;
//                     nb_chunks += 1;
//                 }
//             }
//         }
//     }
//     return chunks;
// }

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
