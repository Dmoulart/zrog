const std = @import("std");
const assert = @import("std").debug.assert;

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const Timer = @import("../perfs/timer.zig");

const findPath = @import("../geo/pathfinding/a-star.zig").astar;
const Position = @import("../geo/pathfinding/a-star.zig").Position;

pub fn followPlayer(world: *Ecs) void {
    var enemies = world.query().all(.{
        .Transform,
        .Velocity,
        .Mover,
        .Enemy,
    }).execute();

    enemies.each(follow);
}

pub fn follow(world: *Ecs, entity: Zecs.Entity) void {
    var chunks = world.getResource(.chunks);
    var chunk = chunks.getChunkAtPosition(0, 0).?;
    _ = chunk;

    // var grid = chunk.generateCollisionGrid(.{ .x = 0, .y = 0 });
    var grid = chunks.generateCollisionGrid();

    var start_pos = world.pack(entity, .Transform);

    var player = world.getResource(.player);
    var end_pos = world.pack(player, .Transform);

    if (isAdjacent(start_pos.x.*, start_pos.y.*, end_pos.x.*, end_pos.y.*)) {
        return;
    }

    var result = findPath(
        &grid,
        .{
            .x = start_pos.x.*,
            .y = start_pos.y.*,
        },
        .{
            .x = end_pos.x.*,
            .y = end_pos.y.*,
        },
        500,
        world.allocator,
    ) catch unreachable;

    if (result) |*path| {
        var path_slice = path.toOwnedSlice();
        if (path_slice.len <= 1) return;
        var last = path_slice[path_slice.len - 2];
        var first_move_x = last.x - start_pos.x.*;
        var first_move_y = last.y - start_pos.y.*;
        std.debug.print("\nfirst move {} {} \n", .{ first_move_x, first_move_y });
        world.set(entity, .Velocity, .x, first_move_x);
        world.set(entity, .Velocity, .y, first_move_y);
    }

    // std.debug.print("\npath {any}\n", .{path});
}

fn isAdjacent(x_a: i32, y_a: i32, x_b: i32, y_b: i32) bool {
    var x_diff = x_b - x_a;
    var y_diff = y_b - y_a;

    return x_diff >= -1 and x_diff <= 1 and y_diff >= -1 and y_diff <= 1;
}
