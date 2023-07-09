const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const rl = @import("raylib");

pub fn createPanel(world: *Ecs) Zecs.Entity {
    var panel = world.createEmpty();

    world.attach(panel, .ScreenPosition);
    world.attach(panel, .Rect);

    var screen_width = world.getResource(.screen_width);
    var screen_height = world.getResource(.screen_height);

    var width: c_int = 300;
    var height: c_int = screen_height;

    world.write(panel, .ScreenPosition, .{
        .x = screen_width - width,
        .y = 0,
    });

    world.write(panel, .Rect, .{
        .width = width,
        .height = height,
        .background_color = rl.BLACK,
    });

    return panel;
}
