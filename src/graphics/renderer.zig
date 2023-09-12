const std = @import("std");
const assert = @import("std").debug.assert;
const rl = @import("raylib");
const Zecs = @import("zecs");

const Ecs = @import("../context.zig").Ecs;

const pointIsInFieldOfView = @import("./camera.zig").pointIsInFieldOfView;
const getCameraBoundingBox = @import("./camera.zig").getCameraBoundingBox;
const getTerrainBoundingBox = @import("../map/moon.zig").getTerrainBoundingBox;

const Chunk = @import("../map/chunk.zig");

pub const CELL_SIZE = 24;

pub fn prerender(world: *Ecs) void {
    var camera = world.getResource(.camera);
    // clone ?
    var camera_object = world.clone(camera, .Camera);

    rl.BeginDrawing();

    rl.ClearBackground(rl.BLACK);

    rl.BeginMode2D(camera_object);
}

pub fn render(world: *Ecs) void {
    const camera = world.getResource(.camera);

    var chunks = world.getResource(.chunks);

    var visible_chunks = chunks.filterVisible(world, camera);
    var camera_bbox = getCameraBoundingBox(world, camera);

    var fields_of_views = world.getResource(.fields_of_views);
    var player = world.getResource(.player);
    var player_fov = fields_of_views.get(player).?;

    for (visible_chunks) |visible_chunk| {
        var intersection = camera_bbox.intersection(&visible_chunk.bbox);

        var start_x: usize = @intCast(intersection.x - visible_chunk.bbox.x);
        var start_y: usize = @intCast(intersection.y - visible_chunk.bbox.y);

        var end_x: usize = @intCast(start_x + @as(usize, @intCast(intersection.width)));
        var end_y: usize = @intCast(start_y + @as(usize, @intCast(intersection.height)));

        var x = start_x;
        var y = start_y;

        while (y < end_y) : (y += 1) {
            while (x < end_x) : (x += 1) {
                var global_x = visible_chunk.toGlobalX(@as(i32, @intCast(x)));
                var global_y = visible_chunk.toGlobalY(@as(i32, @intCast(y)));

                if (!player_fov.contains(.{ .x = global_x, .y = global_y })) {
                    continue;
                }

                draw(world, visible_chunk.get(.terrain, x, y).?);

                if (visible_chunk.get(.props, x, y)) |prop| {
                    draw(world, prop);
                }

                if (visible_chunk.get(.beings, x, y)) |being| {
                    draw(world, being);
                }
            }

            x = start_x;
        }
    }
}

fn draw(world: *Ecs, entity: Zecs.Entity) void {
    const glyph = world.pack(entity, .Glyph);
    const transform = world.pack(entity, .Transform);

    var x = @as(c_int, @intCast(transform.x.*)) * CELL_SIZE;
    var y = @as(c_int, @intCast(transform.y.*)) * CELL_SIZE;

    rl.DrawText(glyph.char.*, x, y, CELL_SIZE, glyph.color.*);
}

pub fn postrender(_: *Ecs) void {
    rl.EndMode2D();

    rl.EndDrawing();
}
