const Zecs = @import("zecs");
const BoundingBox = @import("../math/bounding-box.zig").BoundingBox;

const Self = @This();

// The size of a map chunk in cells.
pub const SIZE = 120;
pub const MAX_ENTITY_PER_CELL = 10;

// in chunk size
x: i32,
y: i32,

bbox: BoundingBox,

id: Zecs.Entity,

terrain: [SIZE][SIZE]Zecs.Entity = undefined,
// entities: [SIZE][SIZE][MAX_ENTITY_PER_CELL]Zecs.Entity = undefined,

pub fn init(x: i32, y: i32, id: Zecs.Entity) Self {
    return Self{
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
}

pub fn getChunkX(self: *Self) i32 {
    return self.x * SIZE;
}

pub fn getChunkY(self: *Self) i32 {
    return self.y * SIZE;
}
