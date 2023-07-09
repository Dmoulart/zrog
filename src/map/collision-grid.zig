pub fn CollisionGrid(comptime width: comptime_int, comptime height: comptime_int) type {
    return [width][height]u8;
}
