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

    drawables.each(draw);
}

fn draw(world: *Ecs, entity: Zecs.Entity) void {
    const sprite = world.pack(entity, .Sprite);
    const transform = world.pack(entity, .Transform);

    var x = @floatToInt(c_int, transform.x.*) * CELL_SIZE;
    var y = @floatToInt(c_int, transform.y.*) * CELL_SIZE;

    rl.DrawText(sprite.char.*, x, y, 24, sprite.color.*);
}
