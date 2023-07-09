const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const rl = @import("raylib");

pub fn createTestUI(world: *Ecs) Zecs.Entity {
    var counter = world.createEmpty();

    world.attach(counter, .ScreenPosition);
    world.attach(counter, .Rect);

    var width: c_int = 250;
    var height: c_int = 100;

    var screen_width = world.getResource(.screen_width);
    var screen_height = world.getResource(.screen_height);

    world.write(counter, .ScreenPosition, .{
        .x = screen_width - width,
        .y = screen_height - height,
    });

    world.write(counter, .Rect, .{
        .width = width,
        .height = height,
        .background_color = rl.DARKBLUE,
        .text = "Hello",
    });

    return counter;
}

pub fn createPositionIndicator(world: *Ecs) Zecs.Entity {
    const indicator = world.createEmpty();

    world.attach(indicator, .ScreenPosition);
    world.attach(indicator, .Text);

    const screen_width = world.getResource(.screen_width);

    const content = "[PLAYER_POS]";
    world.write(indicator, .ScreenPosition, .{
        .x = screen_width,
        .y = 0,
    });

    world.write(indicator, .Text, .{
        .content = content,
        .size = 20,
        .color = rl.WHITE,
    });

    return indicator;
}
