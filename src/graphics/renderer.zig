const std = @import("std");
const rl = @import("raylib");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const CELL_SIZE = 24;

pub fn render(world: *Ecs) void {
    var drawables = world.query()
        .all(.{.Transform})
        .any(.{.Sprite})
        .execute();

    var camera = world.getResource(.camera);
    // clone ?
    var camera_object = world.clone(camera, .Camera);

    rl.BeginDrawing();

    rl.ClearBackground(rl.BLACK);

    rl.BeginMode2D(camera_object);

    drawables.each(draw);

    rl.EndMode2D();

    rl.EndDrawing();
}

fn draw(world: *Ecs, entity: Zecs.Entity) void {
    const sprite = world.pack(entity, .Sprite);
    const transform = world.pack(entity, .Transform);

    var x = @floatToInt(c_int, transform.x.*) * CELL_SIZE;
    var y = @floatToInt(c_int, transform.y.*) * CELL_SIZE;

    rl.DrawText(sprite.char.*, x, y, CELL_SIZE, sprite.color.*);
}
