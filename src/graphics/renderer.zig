const std = @import("std");
const rl = @import("raylib");
const Zecs = @import("zecs");

const Ecs = @import("../context.zig").Ecs;

const pointIsInFieldOfView = @import("./camera.zig").pointIsInFieldOfView;
const getCameraBoundingBox = @import("./camera.zig").getCameraBoundingBox;
const getTerrainBoundingBox = @import("../map/forest.zig").getTerrainBoundingBox;

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
    var camera = world.getResource(.camera);

    var chunks = world.getResource(.chunks).?;
    var visible_chunks = chunks.filterVisible(world, camera);

    var drawables = world.query()
        .all(.{ .Transform, .Sprite, .InChunk })
        .not(.{.Terrain})
        .execute()
        .iterator();

    var camera_bbox = getCameraBoundingBox(world, camera);

    // how to make this faster ?
    // 1) faster iterator
    // 2) filter by chunk in the query (relationships ?)
    // 3) some data structure that keep track of these drawables entities (kdtree ? quadtree ? )
    while (drawables.next()) |drawable| {
        var transform = world.pack(drawable, .Transform);

        var entity_chunk_id = world.get(drawable, .InChunk, .chunk).*;
        var is_in_visible_chunk = false;
        // visible chunks should be a set ?
        for (visible_chunks) |visible_chunk| {
            if (visible_chunk.id == entity_chunk_id) {
                is_in_visible_chunk = true;
                break;
            }
        }

        if (!is_in_visible_chunk) continue;

        // if (owning_chunk != current_chunk.?.id) continue;
        if (!camera_bbox.contains(transform.x.*, transform.y.*)) continue;

        draw(world, drawable);
    }
}

pub fn renderTerrain(world: *Ecs) void {
    const camera = world.getResource(.camera);

    var chunks = world.getResource(.chunks).?;

    var visible_chunks = chunks.filterVisible(world, camera);
    var fov_bbox = getCameraBoundingBox(world, camera);

    for (visible_chunks) |visible_chunk| {
        var intersection = fov_bbox.intersection(&visible_chunk.bbox);

        var start_x = intersection.x - visible_chunk.bbox.x;
        var start_y = intersection.y - visible_chunk.bbox.y;

        var end_x = start_x + @intCast(i32, intersection.width);
        var end_y = start_y + @intCast(i32, intersection.height);

        var x = start_x;
        var y = start_y;

        while (y < end_y) : (y += 1) {
            while (x < end_x) : (x += 1) {
                draw(
                    world,
                    visible_chunk.terrain[@intCast(usize, x)][@intCast(usize, y)],
                );
            }

            x = intersection.x - visible_chunk.bbox.x;
        }
    }
}

// pub fn renderTerrain(world: *Ecs) void {
//     const camera = world.getResource(.camera);

//     var chunk = world.getResource(.player_chunk).?;
//     var chunks = world.getResource(.chunks).?;

//     var visible_chunks = chunks.filterVisible(world, camera);
//     std.debug.print("chunks len {}\n", .{visible_chunks.len});

//     var fov_bbox = getCameraBoundingBox(world, camera);

//     var end_x = @min(fov_bbox.endX(), chunk.bbox.endX());
//     var end_y = @min(fov_bbox.endY(), chunk.bbox.endY());

//     var x: usize = if (fov_bbox.x >= 0) @intCast(usize, fov_bbox.x) else 0;
//     var y: usize = if (fov_bbox.y >= 0) @intCast(usize, fov_bbox.y) else 0;

//     var start_x = x;

//     while (y < end_y) : (y += 1) {
//         while (x < end_x) : (x += 1) {
//             draw(world, chunk.terrain[x][y]);
//         }

//         x = start_x;
//     }
// }

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
