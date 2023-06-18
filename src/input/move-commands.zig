const std = @import("std");
const Timer = @import("../perfs/timer.zig");

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const rl = @import("raylib");

pub fn moveCommands(world: *Ecs) void {
    var movables = world.query().all(.{ .Transform, .Input }).execute();
    movables.each(processMoveCommands);
}

fn processMoveCommands(world: *Ecs, entity: Zecs.Entity) void {
    Timer.start("Move commands");

    var x: i32 = 0;
    var y: i32 = 0;

    if (rl.IsKeyDown(.KEY_LEFT)) {
        x = -1; // * dt * TIME_FACTOR;
        y = 0;
    } else if (rl.IsKeyDown(.KEY_RIGHT)) {
        x = 1; // * dt * TIME_FACTOR;
        y = 0;
    } else if (rl.IsKeyDown(.KEY_UP)) {
        x = 0;
        y = -1; // * dt * TIME_FACTOR;
    } else if (rl.IsKeyDown(.KEY_DOWN)) {
        x = 0;
        y = 1; // * dt * TIME_FACTOR;
    } else {
        x = 0;
        y = 0;
    }

    var vel = world.pack(entity, .Velocity);

    vel.x.* = x;
    vel.y.* = y;

    Timer.end();
}
