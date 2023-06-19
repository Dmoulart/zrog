const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const rl = @import("raylib");

const Player = Ecs.Type(.{
    .Transform,
    .Velocity,
    .Sprite,
    .Input,
});

pub fn createPlayer(world: *Ecs) Zecs.Entity {
    world.registerType(Player);

    var player = world.create(Player);

    world.setResource(.player, player);

    var start_position = .{
        .x = 10,
        .y = 10,
        .z = 1,
    };

    var chunks = world.getResource(.chunks);

    chunks.set(.beings, player, start_position.x, start_position.y);

    world.write(player, .Transform, start_position);

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
