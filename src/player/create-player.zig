const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const rl = @import("raylib");

pub fn createPlayer(world: *Ecs) Zecs.Entity {
    const Player = Ecs.Type(.{
        .Transform,
        .Velocity,
        .Sprite,
    });

    world.registerType(Player);

    var player = world.create(Player);

    world.setResource(.player, player);

    world.write(player, .Transform, .{
        .x = 10,
        .y = 10,
    });
    world.write(player, .Sprite, .{
        .char = "@",
        .color = rl.WHITE,
    });

    return player;
}
