const Zecs = @import("zecs");

const Chunk = @import("./chunk.zig");
const Ecs = @import("../context.zig").Ecs;
const getCameraBoundingBox = @import("../graphics/camera.zig").getCameraBoundingBox;

const Self = @This();
const ChunkGroup = [3][3]?Chunk;

chunks: ChunkGroup,

pub fn init(chunks: *[3][3]?Chunk) Self {
    return Self{
        .chunks = chunks.*,
    };
}

pub fn containsPoint(self: *Self, x: i32, y: i32) []*Chunk {
    var chunks: []*Chunk = undefined;
    var nb_chunks: usize = 0;

    for (self.chunks) |*row| {
        for (row) |*maybe_chunk| {
            if (maybe_chunk) |chunk| {
                if (chunk.bbox.contains(x, y)) {
                    chunks[nb_chunks] = chunk;
                    nb_chunks += 1;
                }
            }
        }
    }
    return chunks;
}

pub fn filterVisible(
    self: *Self,
    world: *Ecs,
    camera: Zecs.Entity,
) []*Chunk {
    var camera_bbox = getCameraBoundingBox(world, camera);
    var memory: [9]*Chunk = undefined;
    var buffer: []*Chunk = &memory;

    var chunks: []*Chunk = buffer[0..];
    var nb_chunks: usize = 0;

    for (self.chunks) |*row| {
        for (row) |*maybe_chunk| {
            if (maybe_chunk.*) |*chunk| {
                if (chunk.bbox.intersects(&camera_bbox)) {
                    chunks[nb_chunks] = chunk;
                    nb_chunks += 1;
                }
            }
        }
    }

    return chunks[0..nb_chunks];
}
