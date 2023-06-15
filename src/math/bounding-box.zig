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

    pub fn endX(self: *Self) i32 {
        return self.x + @intCast(i32, self.width);
    }

    pub fn endY(self: *Self) i32 {
        return self.y + @intCast(i32, self.height);
    }
};
