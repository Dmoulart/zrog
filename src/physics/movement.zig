const std = @import("std");
const assert = @import("std").debug.assert;

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const Timer = @import("../perfs/timer.zig");

pub fn movement(world: *Ecs) void {
    var movables = world.query().all(.{
        .Transform,
        .Velocity,
        .Speed,
    }).execute();

    movables.each(move);
}

pub fn move(world: *Ecs, entity: Zecs.Entity) void {
    // Check movement speed
    var turn = world.getResource(.turn);
    var speed = world.pack(entity, .Speed);

    // between 0 and 1 for now
    assert(speed.value.* >= 0 and speed.value.* <= 1);

    var turn_nb_since_last_move: f32 = @intToFloat(f32, turn - speed.last_move.*);
    var move_frequency_in_turn: f32 = speed.value.* * 10;

    if (turn_nb_since_last_move <= move_frequency_in_turn) return;

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

    var prop = new_chunk.?.getFromWorldPosition(.props, movement_x, movement_y);
    // get out if there is a prop on our way
    if (prop != null) return;

    // update chunk position
    old_chunk.?.deleteFromWorldPosition(.beings, transform.x.*, transform.y.*);

    transform.x.* = movement_x;
    transform.y.* = movement_y;

    new_chunk.?.setFromWorldPosition(.beings, entity, movement_x, movement_y);
}
