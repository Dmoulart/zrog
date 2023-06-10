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

    // bind camera offset to transform
    var camera_transform_x = world.get(camera, .Transform, .x);
    var camera_transform_y = world.get(camera, .Transform, .y);

    var camera_offset = world.get(camera, .Camera, .offset);
    var camera_offset_x = &camera_offset.x;
    var camera_offset_y = &camera_offset.y;

    camera_offset_x = camera_transform_x;
    camera_offset_y = camera_transform_y;

    world.setResource(.camera, camera);

    return camera;
}

pub fn updateCameraMovement(world: *Ecs) void {
    var camera_ent = world.getResource(.camera_entity);
    syncCameraMovements(world, camera_ent);
}

fn syncCameraMovements(world: *Ecs, camera_ent: Zecs.Entity) void {
    var camera_object = world.get(camera_ent, .Camera, .object);
    var position = world.pack(camera_ent, .Position);

    camera_object.offset.x = position.x.*;
    camera_object.offset.y = position.y.*;
}
