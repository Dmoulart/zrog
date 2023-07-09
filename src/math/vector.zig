pub fn Vector(comptime NumberType: type) type {
    return struct {
        const Self = @This();

        x: NumberType,
        y: NumberType,

        pub fn equals(self: *Self, other: *Self) bool {
            return self.x == other.x and self.y == other.y;
        }

        pub fn add(self: *Self, other: Self) Self {
            return Self{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }
    };
}
