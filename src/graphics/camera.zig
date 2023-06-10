const Ecs = @import("../context.zig").Ecs;
const Zecs = @import("zecs");
const Rl = @import("raylib");

pub fn createCamera(world: *Ecs) Zecs.Entity {
    var camera = world.createEmpty();

    world.attach(camera, .Camera);
    world.attach(camera, .Transform);
    world.attach(camera, .Velocity);

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
    syncCameraMovements(world, camera);
}

fn syncCameraMovements(world: *Ecs, camera: Zecs.Entity) void {
    var offset = world.get(camera, .Camera, .offset);
    var position = world.pack(camera, .Transform);

    offset.x = -position.x.*;
    offset.y = -position.y.*;
}
