const std = @import("std");
const rl = @import("raylib");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const UI = @import("./test-ui.zig");
const createCamera = @import("../graphics/camera.zig").createCamera;

var is_ready = false;
var camera: rl.Camera2D = undefined;

fn setup(world: *Ecs) void {
    _ = UI.createTestUI(world);
    var camera_entity = createCamera(world);
    camera = world.clone(camera_entity, .Camera);
    is_ready = true;
}

pub fn renderUI(world: *Ecs) void {
    if (!is_ready) {
        setup(world);
    }

    rl.BeginMode2D(camera);
    rl.DrawFPS(
        @intCast(c_int, 0),
        @intCast(c_int, 0),
    );

    const ui = world.query().all(.{ .ScreenPosition, .Panel }).execute();
    ui.each(draw);
}

fn draw(world: *Ecs, entity: Zecs.Entity) void {
    var pos = world.pack(entity, .ScreenPosition);
    var panel = world.pack(entity, .Panel);

    rl.DrawRectangle(
        @intCast(c_int, pos.x.*),
        @intCast(c_int, pos.y.*),
        panel.width.*,
        panel.height.*,
        panel.background_color.*,
    );
}
