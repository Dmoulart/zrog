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
    _ = world;
    // var drawables = world.query()
    //     .all(.{ .Transform, .Sprite })
    //     .not(.{.Terrain})
    //     .execute();

    // drawables.each(draw);
}

pub fn renderTerrain(world: *Ecs) void {
    var chunk = world.getResource(.chunk).?;
    const camera = world.getResource(.camera);

    var fov_bbox = getCameraBoundingBox(world, camera);

    var end_x = @min(fov_bbox.endX(), chunk.bbox.endX());
    var end_y = @min(fov_bbox.endY(), chunk.bbox.endY());

    var x: usize = if (fov_bbox.x >= 0) @intCast(usize, fov_bbox.x) else 0;
    var y: usize = if (fov_bbox.y >= 0) @intCast(usize, fov_bbox.y) else 0;

    var start_x = x;

    while (y < end_y) : (y += 1) {
        while (x < end_x) : (x += 1) {
            draw(world, chunk.terrain[x][y]);
        }

        x = start_x;
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
