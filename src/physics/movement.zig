const std = @import("std");
const assert = @import("std").debug.assert;

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const Timer = @import("../perfs/timer.zig");

pub fn movement(world: *Ecs) void {
    var movables = world.query().all(.{
        .Transform,
        .Velocity,
        .Mover,
    }).execute();

    movables.each(move);
}

pub fn move(world: *Ecs, entity: Zecs.Entity) void {
    // Check movement speed
    var turn = world.getResource(.turn);
    var speed = world.pack(entity, .Mover);

    var move_freq = speed.move_freq.*;

    var turn_nb_since_last_move: f32 = @intToFloat(f32, turn - speed.last_move.*);

    if (turn_nb_since_last_move <= move_freq) return;

    speed.last_move.* = turn;

    // Calculate movement
    var vel = world.pack(entity, .Velocity);
    if (vel.x.* == 0 and vel.y.* == 0) return;

    var transform = world.pack(entity, .Transform);

    var movement_x = transform.x.* + vel.x.*;
    var movement_y = transform.y.* + vel.y.*;

    var chunks = world.getResource(.chunks);

    var old_chunk = chunks.getChunkAtPosition(transform.x.*, transform.y.*);
    var new_chunk = chunks.getChunkAtPosition(movement_x, movement_y);
    // get out if we have reach the map edge
    if (new_chunk == null) return;

    var prop = new_chunk.?.getFromGlobalPosition(.props, movement_x, movement_y);
    var being = new_chunk.?.getFromGlobalPosition(.beings, movement_x, movement_y);
    // get out if there is a prop on our way
    if (prop != null or being != null) return;

    // update chunk position
    old_chunk.?.deleteFromGlobalPosition(.beings, transform.x.*, transform.y.*);

    transform.x.* = movement_x;
    transform.y.* = movement_y;

    new_chunk.?.setFromGlobalPosition(.beings, entity, movement_x, movement_y);
}
