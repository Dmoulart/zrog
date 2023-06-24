const std = @import("std");
const assert = @import("std").debug.assert;

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const FieldOfView = @import("./fov.zig").FieldOfView(isBlocking, markVisible);

pub fn fieldsOfview(world: *Ecs) void {
    var fieldsOfView = world.query().all(.{
        .Transform,
        .Vision,
    }).execute();

    fieldsOfView.each(compute);
}

fn compute(world: *Ecs, entity: Zecs.Entity) void {
    var pos = world.pack(entity, .Transform);
    var fov = FieldOfView{
        .origin_x = pos.x.*,
        .origin_y = pos.y.*,
    };
    fov.compute();
}

fn markVisible(x: i32, y: i32) void {
    _ = y;
    _ = x;
}
fn isBlocking(x: i32, y: i32) bool {
    _ = y;
    _ = x;
    return false;
}
