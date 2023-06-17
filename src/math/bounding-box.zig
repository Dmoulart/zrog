const std = @import("std");
const assert = std.debug.assert;

const Self = @This();

x: i32,
y: i32,

width: i32,
height: i32,

pub fn contains(self: *Self, x: i32, y: i32) bool {
    const x_end = self.endX();
    const y_end = self.endY();

    return x >= self.x and x < x_end and y >= self.y and y < y_end;
}

pub fn intersects(self: *Self, other: *Self) bool {
    const self_end_x = self.endX();
    const self_end_y = self.endY();

    const other_end_x = other.endX();
    const other_end_y = other.endY();

    return self.x < other_end_x and self_end_x > other.x and self.y < other_end_y and self_end_y > other.y;
}

pub fn intersection(self: *Self, other: *Self) Self {
    assert(self.intersects(other));

    var self_end_x = self.endX();
    var self_end_y = self.endY();

    var other_end_x = other.endX();
    var other_end_y = other.endY();

    // Calculate intersection coordinates
    const intersection_start_x = @max(self.x, other.x);
    const intersection_start_y = @max(self.y, other.y);

    const intersection_end_x = @min(self_end_x, other_end_x);
    const intersection_end_y = @min(self_end_y, other_end_y);

    // Calculate intersection dimensions
    const intersection_width = intersection_end_x - intersection_start_x;
    const intersection_height = intersection_end_y - intersection_start_y;

    return Self{
        .x = intersection_start_x,
        .y = intersection_start_y,
        .width = intersection_width,
        .height = intersection_height,
    };
}

pub fn merge(self: *Self, other: *Self) Self {
    const union_start_x = @min(self.x, other.x);
    const union_start_y = @min(self.y, other.y);

    const self_end_x = self.endX();
    const self_end_y = self.endY();
    const other_end_x = other.endX();
    const other_end_y = other.endY();

    const union_end_x = @max(self_end_x, other_end_x);
    const union_end_y = @max(self_end_y, other_end_y);

    const union_width = union_end_x - union_start_x;
    const union_height = union_end_y - union_start_y;

    return Self{
        .x = union_start_x,
        .y = union_start_y,
        .width = union_width,
        .height = union_height,
    };
}

pub fn halfWidth(self: *Self) i32 {
    return @divTrunc(self.width, 2);
}

pub fn halfHeight(self: *Self) i32 {
    return @divTrunc(self.height, 2);
}

pub fn endX(self: *Self) i32 {
    return self.x + self.width;
}

pub fn endY(self: *Self) i32 {
    return self.y + self.height;
}

pub fn debugPrint(self: *Self, name: []const u8) void {
    std.debug.print("\n\nBbox {s} :\n-x {}\n-y {}\n-width {}\n-height {}\n-endX {}\n-endY {}\n", .{ name, self.x, self.y, self.width, self.height, self.endX(), self.endY() });
}
