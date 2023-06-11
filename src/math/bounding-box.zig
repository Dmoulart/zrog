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

    pub fn endX(self: *Self) i32 {
        return self.x + @intCast(i32, self.width);
    }

    pub fn endY(self: *Self) i32 {
        return self.y + @intCast(i32, self.height);
    }
};
