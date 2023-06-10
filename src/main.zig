const std = @import("std");
const rl = @import("raylib");
const rlM = @import("raylib-math");

const Zecs = @import("zecs");
const Ecs = @import("./context.zig").Ecs;

pub fn main() !void {
    try Ecs.setup(std.heap.page_allocator);
    defer Ecs.unsetup();

    var world = try Ecs.init(.{
        .allocator = std.heap.page_allocator,
    });
    defer world.deinit();
}
