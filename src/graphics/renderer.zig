const std = @import("std");
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
    var fov_bbox = getCameraBoundingBox(world, camera);

    for (visible_chunks) |visible_chunk| {
        var intersection = fov_bbox.intersection(&visible_chunk.bbox);

        var start_x = @intCast(usize, intersection.x - visible_chunk.bbox.x);
        var start_y = @intCast(usize, intersection.y - visible_chunk.bbox.y);

        var end_x = @intCast(usize, start_x + @intCast(usize, intersection.width));
        var end_y = @intCast(usize, start_y + @intCast(usize, intersection.height));

        var x = start_x;
        var y = start_y;

        while (y < end_y) : (y += 1) {
            while (x < end_x) : (x += 1) {
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
    const sprite = world.pack(entity, .Sprite);
    const transform = world.pack(entity, .Transform);

    var x = @intCast(c_int, transform.x.*) * CELL_SIZE;
    var y = @intCast(c_int, transform.y.*) * CELL_SIZE;

    rl.DrawText(sprite.char.*, x, y, CELL_SIZE, sprite.color.*);
}

pub fn postrender(_: *Ecs) void {
    rl.EndMode2D();

    rl.EndDrawing();
}
