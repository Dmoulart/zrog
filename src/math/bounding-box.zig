pub const BoundingBox = struct {
    const Self = @This();

    x: i32,
    y: i32,

    width: u32,
    height: u32,

    pub fn contains(self: *Self, x: i32, y: i32) bool {
        const x_end = self.x + @intCast(i32, self.width);
        const y_end = self.y + @intCast(i32, self.height);

        return x >= self.x and x < x_end and y >= self.y and y < y_end;
    }
};
