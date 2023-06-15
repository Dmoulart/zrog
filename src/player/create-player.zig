const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const rl = @import("raylib");

const Player = Ecs.Type(.{
    .Transform,
    .Velocity,
    .Sprite,
    .Input,
    .InChunk,
});

pub fn createPlayer(world: *Ecs) Zecs.Entity {
    world.registerType(Player);

    var player = world.create(Player);

    world.setResource(.player, player);

    // Place it on the current chunk
    var chunk = world.getResource(.player_chunk);
    world.set(player, .InChunk, .chunk, chunk.?.id);

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
