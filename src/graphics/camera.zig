const Ecs = @import("../context.zig").Ecs;
const Zecs = @import("zecs");
const Rl = @import("raylib");
const CELL_SIZE = @import("./renderer.zig").CELL_SIZE;

pub fn createCamera(world: *Ecs) Zecs.Entity {
    var camera = world.createEmpty();

    world.attach(camera, .Camera);
    world.attach(camera, .Transform);
    world.attach(camera, .Velocity);

    world.write(
        camera,
        .Velocity,
        .{
            .x = 0,
            .y = 0,
        },
    );

    world.write(
        camera,
        .Camera,
        .{
            .offset = .{
                .x = 0,
                .y = 0,
            },
            .target = .{
                .x = 0,
                .y = 0,
            },
            .rotation = 0,
            .zoom = 1,
        },
    );

    world.setResource(.camera, camera);

    world.addSystem(updateCameraMovement);

    return camera;
}

pub fn updateCameraMovement(world: *Ecs) void {
    var camera = world.getResource(.camera);

    followPlayer(world, camera);

    syncCameraMovements(world, camera);
}

fn followPlayer(world: *Ecs, camera: Zecs.Entity) void {
    var player = world.getResource(.player);

    var player_transform = world.pack(player, .Transform);
    var camera_transform = world.pack(camera, .Transform);

    camera_transform.x.* = player_transform.x.*;
    camera_transform.y.* = player_transform.y.*;
}

fn syncCameraMovements(world: *Ecs, camera: Zecs.Entity) void {
    var offset = world.get(camera, .Camera, .offset);

    var position = world.pack(camera, .Transform);

    var screen_width = @intToFloat(f32, world.getResource(.screen_width));
    var screen_height = @intToFloat(f32, world.getResource(.screen_height));

    var position_x = @intToFloat(f32, position.x.*) * CELL_SIZE;
    var position_y = @intToFloat(f32, position.y.*) * CELL_SIZE;

    offset.x = -position_x + screen_width / 2;
    offset.y = -position_y + screen_height / 2;
}
