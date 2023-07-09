const std = @import("std");
const fmt = std.fmt;
const rl = @import("raylib");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const UI = @import("./debug.zig");
const createCamera = @import("../graphics/camera.zig").createCamera;

var is_ready = false;
var camera: rl.Camera2D = undefined;

fn setup(world: *Ecs) void {
    _ = UI.createTestUI(world);
    _ = UI.createPositionIndicator(world);
    const camera_entity = createCamera(world);
    camera = world.clone(camera_entity, .Camera);
    is_ready = true;
}

// Should we use the ecs for the UI ?
pub fn renderUI(world: *Ecs) void {
    if (!is_ready) {
        setup(world);
    }

    rl.BeginMode2D(camera);
    rl.DrawFPS(
        @intCast(c_int, 0),
        @intCast(c_int, 0),
    );

    world.query()
        .all(.{.ScreenPosition})
        .any(.{ .Rect, .Text })
        .execute()
        .each(draw);
}

fn draw(world: *Ecs, entity: Zecs.Entity) void {
    const pos = world.pack(entity, .ScreenPosition);

    if (world.has(entity, .Rect)) {
        const rect = world.pack(entity, .Rect);

        rl.DrawRectangle(
            @intCast(c_int, pos.x.*),
            @intCast(c_int, pos.y.*),
            rect.width.*,
            rect.height.*,
            rect.background_color.*,
        );
    }

    if (world.has(entity, .Text)) {
        const text = world.pack(entity, .Text);
        var content: []const u8 = undefined;

        if (std.mem.eql(u8, text.content.*, "[PLAYER_POS]")) {
            const player = world.getResource(.player);
            const player_transform = world.pack(player, .Transform);

            const x = player_transform.x.*;
            const y = player_transform.y.*;

            var text_buffer: [20]u8 = undefined;

            content = fmt.bufPrintZ(
                &text_buffer,
                "x: {d} y: {d}",
                .{ x, y },
            ) catch "Error";
        } else {
            content = text.content.*;
        }

        // take text width into account
        const x = pos.x.* - rl.MeasureText(@ptrCast([*c]const u8, content), text.size.*);

        rl.DrawText(
            @ptrCast([*c]const u8, content[0..]),
            @intCast(c_int, x),
            @intCast(c_int, pos.y.*),
            text.size.*,
            text.color.*,
        );
    }
}
