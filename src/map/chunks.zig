const Zecs = @import("zecs");
const BoundingBox = @import("../math/bounding-box.zig").BoundingBox;

const Self = @This();

// The size of a map chunk in cells.
pub const SIZE = 200;
pub const MAX_ENTITY_PER_CELL = 10;

x: i32,
y: i32,

bbox: BoundingBox,

terrain: [SIZE][SIZE]Zecs.Entity = undefined,
entities: [SIZE][SIZE][MAX_ENTITY_PER_CELL]Zecs.Entity = undefined,

pub fn init(x: i32, y: i32) Self {
    return Self{
        .x = x,
        .y = y,
        .bbox = BoundingBox{
            .x = x,
            .y = y,
            .width = SIZE,
            .height = SIZE,
        },
    };
}
