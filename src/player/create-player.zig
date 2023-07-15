const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const rl = @import("raylib");

const Player = Ecs.Type(.{
    .Transform,
    .Velocity,
    .Mover,
    .Glyph,
    .Input,
    .Vision,
    .Health,
});

pub fn createPlayer(world: *Ecs) Zecs.Entity {
    world.registerType(Player);

    var player = world.create(Player);

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
    world.write(player, .Mover, .{
        .move_freq = 2,
        .last_move = 0,
    });

    world.write(player, .Glyph, .{
        .char = "@",
        .color = rl.WHITE,
    });

    world.set(player, .Vision, .range, 30);
    world.set(player, .Health, .points, 10);

    return player;
}
