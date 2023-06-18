const std = @import("std");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

pub fn movement(world: *Ecs) void {
    var movables = world.query().all(.{
        .Transform,
        .Velocity,
    }).execute();

    movables.each(move);
}

pub fn move(world: *Ecs, entity: Zecs.Entity) void {
    var vel = world.pack(entity, .Velocity);
    // get out if there is no movement to achieve
    if (vel.x.* == 0 and vel.y.* == 0) return;

    var transform = world.pack(entity, .Transform);

    var movement_x = transform.x.* + vel.x.*;
    var movement_y = transform.y.* + vel.y.*;

    var chunks = world.getResource(.chunks);

    var old_chunk = chunks.getChunkAtPosition(transform.x.*, transform.y.*);
    var new_chunk = chunks.getChunkAtPosition(movement_x, movement_y);

    // get out if we have reach the map edge
    if (new_chunk == null) return;

    var prop = new_chunk.?.getFromWorldPosition(.props, movement_x, movement_y);
    // get out if there is a prop on our way
    if (prop != null) return;

    // update position
    old_chunk.?.deleteFromWorldPosition(.beings, transform.x.*, transform.y.*);

    transform.x.* = movement_x;
    transform.y.* = movement_y;

    new_chunk.?.setFromWorldPosition(.beings, entity, movement_x, movement_y);
}
