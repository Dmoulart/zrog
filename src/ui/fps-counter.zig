const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const rl = @import("raylib");

pub fn createFPSCounter(world: *Ecs) Zecs.Entity {
    var counter = world.createEmpty();

    world.attach(counter, .ScreenPosition);
    world.attach(counter, .Panel);
    world.attach(counter, .FPSCounter);

    var width: c_int = 250;
    var height: c_int = 100;

    var screen_width = world.getResource(.screen_width);
    var screen_height = world.getResource(.screen_height);

    world.write(counter, .ScreenPosition, .{
        .x = screen_width - width,
        .y = screen_height - height,
    });

    world.write(counter, .Panel, .{
        .width = width,
        .height = height,
        .background_color = rl.WHITE,
        .text = "Hello",
    });

    return counter;
}
