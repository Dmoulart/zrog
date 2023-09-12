const std = @import("std");
const fmt = std.fmt;
const rl = @import("raylib");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const UI = @import("./element.zig");

const createCamera = @import("../graphics/camera.zig").createCamera;

var camera: rl.Camera2D = undefined;

var panel: UI.Element = undefined;
var position_indicator: UI.Element = undefined;
var health_indicator: UI.Element = undefined;

var is_ready = false;

fn setup(world: *Ecs) void {
    const camera_entity = createCamera(world);
    camera = world.clone(camera_entity, .Camera);

    const screen_width = world.getResource(.screen_width);
    const screen_height = world.getResource(.screen_height);

    const panel_height = screen_height;
    const panel_width = 250;

    panel = UI.Element{
        .rect = .{
            .size = .{
                .width = panel_width,
                .height = panel_height,
            },
            .pos = .{
                .x = screen_width - panel_width,
                .y = 0,
            },
            .color = rl.BLACK,
        },
    };

    position_indicator = UI.Element{
        .text = .{
            .font_size = 20,
            .pos = .{
                .x = screen_width,
                .y = 0,
            },
            .color = rl.WHITE,
            .content = " ",
        },
    };

    health_indicator = UI.Element{
        .text = .{
            .font_size = 20,
            .pos = .{
                .x = screen_width - 50,
                .y = 250,
            },
            .color = rl.WHITE,
            .content = "HEALTH",
        },
    };

    is_ready = true;
}

// Should we use the ecs for the UI ?
pub fn renderUI(world: *Ecs) void {
    if (!is_ready) {
        setup(world);
    }

    rl.BeginMode2D(camera);

    rl.DrawFPS(
        @as(c_int, @intCast(0)),
        @as(c_int, @intCast(0)),
    );

    panel.draw();

    position_indicator.text.content = blk: {
        const player = world.getResource(.player);
        const player_transform = world.pack(player, .Transform);

        const x = player_transform.x.*;
        const y = player_transform.y.*;

        var text_buffer: [20]u8 = undefined;

        break :blk fmt.bufPrintZ(
            &text_buffer,
            "x: {d} y: {d}",
            .{ x, y },
        ) catch "Error";
    };

    position_indicator.draw();

    health_indicator.text.content = blk: {
        const player = world.getResource(.player);
        const player_health = world.pack(player, .Health);

        var text_buffer: [20]u8 = undefined;

        break :blk fmt.bufPrintZ(
            &text_buffer,
            "HEALTH: {d}",
            .{player_health.points.*},
        ) catch "Error";
    };

    health_indicator.draw();
}

// fn draw(world: *Ecs, entity: Zecs.Entity) void {
//     const pos = world.pack(entity, .ScreenPosition);

//     if (world.has(entity, .Rect)) {
//         const rect = world.pack(entity, .Rect);

//         rl.DrawRectangle(
//             @intCast(c_int, pos.x.*),
//             @intCast(c_int, pos.y.*),
//             rect.width.*,
//             rect.height.*,
//             rect.background_color.*,
//         );
//     }

//     if (world.has(entity, .Text)) {
//         const text = world.pack(entity, .Text);
//         var content: []const u8 = undefined;

//         if (std.mem.eql(u8, text.content.*, "[PLAYER_POS]")) {
//             const player = world.getResource(.player);
//             const player_transform = world.pack(player, .Transform);

//             const x = player_transform.x.*;
//             const y = player_transform.y.*;

//             var text_buffer: [20]u8 = undefined;

//             content = fmt.bufPrintZ(
//                 &text_buffer,
//                 "x: {d} y: {d}",
//                 .{ x, y },
//             ) catch "Error";
//         } else {
//             content = text.content.*;
//         }

//         // take text width into account
//         const x = pos.x.* - rl.MeasureText(@ptrCast([*c]const u8, content), text.size.*);

//         rl.DrawText(
//             @ptrCast([*c]const u8, content[0..]),
//             @intCast(c_int, x),
//             @intCast(c_int, pos.y.*),
//             text.size.*,
//             text.color.*,
//         );
//     }
// }
