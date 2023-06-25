const std = @import("std");
const assert = @import("std").debug.assert;

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const FieldOfView = @import("./symetric-shadowcasting.zig").FieldOfView(isBlocking, markVisible);

const rl = @import("raylib");

pub fn fieldsOfview(world: *Ecs) void {
    var fieldsOfView = world.query().all(
        .{
            .Transform,
            .Vision,
        },
    ).execute();

    fieldsOfView.each(compute);
}

fn compute(world: *Ecs, entity: Zecs.Entity) void {
    var pos = world.pack(entity, .Transform);
    var range = world.get(entity, .Vision, .range);

    // reuse struct ?
    var fov = FieldOfView{
        .origin_x = pos.x.*,
        .origin_y = pos.y.*,
        .range = range.*,
        .world = world,
    };

    fov.compute();
}

fn markVisible(world: *Ecs, x: i32, y: i32) void {
    _ = world;

    rl.DrawText(".", x * 24, y * 24, 24, rl.RED);
}
fn isBlocking(world: *Ecs, x: i32, y: i32) bool {
    var chunks = world.getResource(.chunks);

    var chunk = chunks.getChunkAtPosition(x, y);
    if (chunk == null) return true;

    var prop = chunk.?.getFromWorldPosition(.props, x, y);

    return prop != null;
}
