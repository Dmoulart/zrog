const std = @import("std");
const assert = std.debug.assert;

pub const BoundingBox = struct {
    const Self = @This();

    x: i32,
    y: i32,

    width: u32,
    height: u32,

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
        const intersection_width = @intCast(u32, intersection_end_x - intersection_start_x);
        const intersection_height = @intCast(u32, intersection_end_y - intersection_start_y);

        return BoundingBox{
            .x = intersection_start_x,
            .y = intersection_start_y,
            .width = intersection_width,
            .height = intersection_height,
        };
    }

    pub fn endX(self: *Self) i32 {
        return self.x + @intCast(i32, self.width);
    }

    pub fn endY(self: *Self) i32 {
        return self.y + @intCast(i32, self.height);
    }

    pub fn debugPrint(self: *Self, name: []const u8) void {
        std.debug.print("\n\nBbox {s} :\n-x {}\n-y {}\n-width {}\n-height {}\n-endX {}\n-endY {}\n", .{ name, self.x, self.y, self.width, self.height, self.endX(), self.endY() });
    }
};
