const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const rl = @import("raylib");

pub fn createPlayer(world: *Ecs) Zecs.Entity {
    const Player = Ecs.Type(.{
        .Transform,
        .Velocity,
        .Sprite,
        .Input,
        .InChunk,
    });

    world.registerType(Player);

    var player = world.create(Player);

    world.setResource(.player, player);

    world.write(player, .Transform, .{
        .x = 10,
        .y = 10,
        .z = 1,
    });

    world.write(player, .Velocity, .{
        .x = 0,
        .y = 0,
    });

    world.write(player, .Sprite, .{
        .char = "@",
        .color = rl.WHITE,
    });

    return player;
}
