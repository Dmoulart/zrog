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

    var grid = chunk.generateCollisionGrid();
    std.debug.print("\n astar grid {any}\n", .{grid});

    var start_pos = world.pack(entity, .Transform);

    var player = world.getResource(.player);
    var end_pos = world.pack(player, .Transform);

    var path_positions: [200]Position = undefined;

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
        path_positions[0..],
        10_000,
        world.allocator,
    ) catch unreachable;

    if (result) |path| {
        var first_move_x = path[0].x - start_pos.x.*;
        var first_move_y = path[0].y - start_pos.y.*;

        world.set(entity, .Velocity, .x, first_move_x);
        world.set(entity, .Velocity, .y, first_move_y);
    }

    // std.debug.print("\npath {any}\n", .{path});
}
