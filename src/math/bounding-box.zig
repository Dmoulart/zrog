const std = @import("std");
const assert = std.debug.assert;

const Self = @This();

x: i32,
y: i32,

width: i32,
height: i32,

pub fn contains(self: *Self, x: i32, y: i32) bool {
    return x >= self.left() and x < self.right() and y >= self.top() and y < self.bottom();
}

pub fn intersects(self: *Self, other: *Self) bool {
    const self_right = self.right();
    const self_bottom = self.bottom();

    const other_right = other.right();
    const other_bottom = other.bottom();

    return self.x < other_right and self_right > other.x and self.y < other_bottom and self_bottom > other.y;
}

pub fn intersection(self: *Self, other: *Self) Self {
    assert(self.intersects(other));

    const self_right = self.right();
    const self_bottom = self.bottom();

    const other_right = other.right();
    const other_bottom = other.bottom();

    // Calculate intersection coordinates
    const intersection_start_x = @max(self.x, other.x);
    const intersection_start_y = @max(self.y, other.y);

    const intersection_right = @min(self_right, other_right);
    const intersection_bottom = @min(self_bottom, other_bottom);

    // Calculate intersection dimensions
    const intersection_width = intersection_right - intersection_start_x;
    const intersection_height = intersection_bottom - intersection_start_y;

    return Self{
        .x = intersection_start_x,
        .y = intersection_start_y,
        .width = intersection_width,
        .height = intersection_height,
    };
}

pub fn merge(self: *Self, other: *Self) Self {
    const self_right = self.right();
    const self_bottom = self.bottom();

    const other_right = other.right();
    const other_bottom = other.bottom();

    const union_x = @min(self.x, other.x);
    const union_y = @min(self.y, other.y);

    const union_right = @max(self_right, other_right);
    const union_bottom = @max(self_bottom, other_bottom);

    const union_width = union_right - union_x;
    const union_height = union_bottom - union_y;

    return Self{
        .x = union_x,
        .y = union_y,
        .width = union_width,
        .height = union_height,
    };
}

// Must we make the bounding box immutable and precaculate all these props ?
pub fn left(self: *Self) i32 {
    return self.x;
}

pub fn right(self: *Self) i32 {
    return self.x + self.width;
}

pub fn top(self: *Self) i32 {
    return self.y;
}

pub fn bottom(self: *Self) i32 {
    return self.y + self.height;
}

pub fn halfWidth(self: *Self) i32 {
    return @divTrunc(self.width, 2);
}

pub fn halfHeight(self: *Self) i32 {
    return @divTrunc(self.height, 2);
}

pub fn debugPrint(self: *Self, name: []const u8) void {
    std.debug.print("\n\nBbox {s} :\n-x {}\n-y {}\n-width {}\n-height {}\n-endX {}\n-endY {}\n", .{ name, self.x, self.y, self.width, self.height, self.right(), self.bottom() });
}
