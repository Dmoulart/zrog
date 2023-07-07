pub fn Vector(comptime NumberType: type) type {
    return struct {
        x: NumberType,
        y: NumberType,
    };
}
