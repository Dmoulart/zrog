const std = @import("std");
const assert = std.debug.assert;
const Int = i32;

const Point = struct { x: Int, y: Int };

// Implement something more specific ?
pub const GeoSet = std.AutoHashMap(
    Point,
    void,
);

test "can use geo set" {
    var set = GeoSet.init(std.testing.allocator);
    defer set.deinit();

    try set.put(.{ .x = 10, .y = 10 }, {});

    assert(set.contains(.{ .x = 10, .y = 10 }));
    assert(!set.contains(.{ .x = 10, .y = 11 }));

    try set.put(.{ .x = -10, .y = -10 }, {});

    assert(set.contains(.{ .x = -10, .y = -10 }));
    assert(!set.contains(.{ .x = -10, .y = -11 }));
}

// Todo: implement more specific/efficient method for geo hashing ?
// const Context = struct {
//     pub fn eql(self: Context, a: Point, b: Point) bool {
//         _ = self;

//         return a.x == b.x and a.y == b.y;
//     }

//     pub fn hash(self: Context, value: Point) u64 {
//         _ = self;
//should allow negative value
//         return @intCast(u64, hashPoint(value.x, value.y));
//     }
// };

// pub const GeoSet = std.HashMap(
//     Point,
//     void,
//     Context,
//     std.hash_map.default_max_load_percentage,
// );

// fn hashPoint(x: i32, y: i32) i32 {
//     return (x << 16) ^ y;
// }
