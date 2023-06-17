const Zecs = @import("zecs");

const Chunk = @import("./chunk.zig");
const Ecs = @import("../context.zig").Ecs;
const BoundingBox = @import("../math/bounding-box.zig");
const getCameraBoundingBox = @import("../graphics/camera.zig").getCameraBoundingBox;

const Self = @This();
const ChunkGroup = [3][3]?Chunk;

chunks: ChunkGroup,

visible_chunks_memory: [9]*Chunk = undefined,

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

pub fn getByID(self: *Self, id: Zecs.Entity) ?*Chunk {
    for (self.chunks) |*row| {
        for (row) |*maybe_chunk| {
            if (maybe_chunk.*) |*chunk| {
                if (chunk.id == id) return chunk;
            }
        }
    }
    return null;
}
