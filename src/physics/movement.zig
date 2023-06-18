const std = @import("std");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

pub fn movement(world: *Ecs) void {
    var movables = world.query().all(
        .{
            .Transform,
            .Velocity,
            .InChunk,
        },
    ).execute();

    movables.each(move);
}

pub fn move(world: *Ecs, entity: Zecs.Entity) void {
    var vel = world.pack(entity, .Velocity);
    // get out if there is no movement to achieve
    if (vel.x.* == 0 and vel.y.* == 0) return;

    var transform = world.pack(entity, .Transform);

    var movement_x = transform.x.* + vel.x.*;
    var movement_y = transform.y.* + vel.y.*;

    // collisions
    var chunks = world.getResource(.chunks).?;
    var chunk = chunks.getChunkAtPosition(movement_x, movement_y);
    // get out if we have reach the map edge
    if (chunk == null) return;

    var prop = chunk.?.getProp(movement_x, movement_y);
    // get out if there is a prop on our way
    if (prop != null) return;

    // update position
    transform.x.* = movement_x;
    transform.y.* = movement_y;

    // update current chunk
    chunks.updateEntityChunk(world, entity, transform.x.*, transform.y.*);
}
