const std = @import("std");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

pub fn movement(world: *Ecs) void {
    var movables = world.query().all(.{ .Transform, .Velocity }).execute();

    movables.each(move);
}

fn move(world: *Ecs, entity: Zecs.Entity) void {
    var transform = world.pack(entity, .Transform);
    var vel = world.pack(entity, .Velocity);

    transform.x.* += vel.x.*;
    transform.y.* += vel.y.*;
}
