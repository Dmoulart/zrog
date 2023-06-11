const std = @import("std");
const rl = @import("raylib");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const pointIsInFieldOfView = @import("./camera.zig").pointIsInFieldOfView;
const getCameraBoundingBox = @import("./camera.zig").getCameraBoundingBox;

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
    var drawables = world.query()
        .all(.{ .Transform, .Sprite })
        .not(.{.Terrain})
        .execute();

    drawables.each(draw);
}

fn draw(world: *Ecs, entity: Zecs.Entity) void {
    const sprite = world.pack(entity, .Sprite);
    const transform = world.pack(entity, .Transform);

    var x = @intCast(c_int, transform.x.*) * CELL_SIZE;
    var y = @intCast(c_int, transform.y.*) * CELL_SIZE;

    rl.DrawText(sprite.char.*, x, y, CELL_SIZE, sprite.color.*);
}

pub fn renderTerrain(world: *Ecs) void {
    var terrains = world.query()
        .all(.{ .Transform, .Sprite, .Terrain })
        .execute();

    terrains.each(drawTerrain);
}

fn drawTerrain(world: *Ecs, entity: Zecs.Entity) void {
    const camera = world.getResource(.camera);

    const sprite = world.pack(entity, .Sprite);
    const transform = world.pack(entity, .Transform);
    const terrain = world.pack(entity, .Terrain);

    var start_x = @intCast(c_int, transform.x.*) * CELL_SIZE;
    var start_y = @intCast(c_int, transform.y.*) * CELL_SIZE;

    var x = start_x;
    var y = start_y;

    var height = terrain.height.* * CELL_SIZE;
    var width = terrain.width.* * CELL_SIZE;

    var camera_bbox = getCameraBoundingBox(world, camera);

    var cell_x = @divTrunc(x, CELL_SIZE);
    var cell_y = @divTrunc(y, CELL_SIZE);

    while (y < height) : (y += CELL_SIZE) {
        cell_y = @divTrunc(y, CELL_SIZE);

        while (x < width) : (x += CELL_SIZE) {
            cell_x = @divTrunc(x, CELL_SIZE);

            if (!camera_bbox.contains(cell_x, cell_y)) continue;

            rl.DrawText(sprite.char.*, x, y, CELL_SIZE, sprite.color.*);
        }

        x = start_x;
    }
}

pub fn postrender(_: *Ecs) void {
    rl.EndMode2D();

    rl.EndDrawing();
}
