const std = @import("std");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

pub fn movement(world: *Ecs) void {
    var movables = world.query().all(.{ .Transform, .Velocity, .InChunk }).execute();

    movables.each(move);
}

fn move(world: *Ecs, entity: Zecs.Entity) void {
    var transform = world.pack(entity, .Transform);
    var vel = world.pack(entity, .Velocity);

    if (vel.x.* == 0 and vel.y.* == 0) return;

    transform.x.* += vel.x.*;
    transform.y.* += vel.y.*;

    var chunks = world.getResource(.chunks).?;

    if (chunks.getChunkAtPosition(transform.x.*, transform.y.*)) |chunk| {
        var current_chunk_id = world.get(entity, .InChunk, .chunk);

        if (current_chunk_id.* != chunk.id) {
            current_chunk_id.* = chunk.id;
        }
    }
}
