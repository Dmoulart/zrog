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

    var grid = chunks.generateCollisionGrid();

    var start_pos = world.pack(entity, .Transform);

    var player = world.getResource(.player);
    var end_pos = world.pack(player, .Transform);

    std.debug.print("\n start \n", .{});

    if (start_pos.x.* == end_pos.x.* and start_pos.y.* == end_pos.y.*) {
        world.set(entity, .Velocity, .x, 0);
        world.set(entity, .Velocity, .y, 0);
        std.debug.print("\n start and pos EQUALS \n", .{});
        return;
    }

    std.debug.print("\nstart and pos not EQUALS\n", .{});

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
        // Remove start_pos from path
        _ = path.orderedRemove(0);
        var path_slice = path.toOwnedSlice();

        if (path_slice.len == 0) return;
        // std.debug.print("\n path_slice {any} \n", .{path_slice});

        // if (path_slice.len < 2) return;

        var first = path_slice[0];
        // if (first == null) return;

        var first_move_x = first.x - start_pos.x.*;
        var first_move_y = first.y - start_pos.y.*;

        world.set(entity, .Velocity, .x, first_move_x);
        world.set(entity, .Velocity, .y, first_move_y);
    }
}

// fn isAdjacent(x_a: i32, y_a: i32, x_b: i32, y_b: i32) bool {
//     var x_diff = x_b - x_a;
//     var y_diff = y_b - y_a;

//     return x_diff >= -1 and x_diff <= 1 and y_diff >= -1 and y_diff <= 1;
// }
