const std = @import("std");
const Ecs = @import("../context.zig").Ecs;
const Zecs = @import("zecs");
const BoundingBox = @import("../math/bounding-box.zig");
const CELL_SIZE = @import("./renderer.zig").CELL_SIZE;

pub fn createCamera(world: *Ecs) Zecs.Entity {
    var camera = world.createEmpty();

    world.attach(camera, .Camera);
    world.attach(camera, .Transform);
    world.attach(camera, .Velocity);

    world.write(
        camera,
        .Transform,
        .{
            .x = 0,
            .y = 0,
        },
    );

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

    return camera;
}

pub fn updateCamera(world: *Ecs) void {
    var camera = world.getResource(.camera);

    followPlayer(world, camera);

    syncCameraMovements(world, camera);
}

fn followPlayer(world: *Ecs, camera: Zecs.Entity) void {
    var player = world.getResource(.player);

    var player_transform = world.pack(player, .Transform);
    var camera_transform = world.pack(camera, .Transform);

    var chunks = world.getResource(.chunks);

    // Increment position first
    camera_transform.x.* = player_transform.x.*;
    camera_transform.y.* = player_transform.y.*;

    var camera_bbox = getCameraBoundingBox(world, camera);
    var chunks_bbox = chunks.getBoundingBox();

    // Check world bounds, correct position if needed
    if (camera_bbox.x <= chunks_bbox.x) {
        camera_transform.x.* = chunks_bbox.x + camera_bbox.halfWidth();
    } else if (camera_bbox.endX() >= chunks_bbox.endX()) {
        camera_transform.x.* = chunks_bbox.endX() - camera_bbox.halfWidth();
    }

    if (camera_bbox.y <= chunks_bbox.y) {
        camera_transform.y.* = chunks_bbox.y + camera_bbox.halfHeight();
    } else if (camera_bbox.endY() >= chunks_bbox.endY()) {
        camera_transform.y.* = chunks_bbox.endY() - camera_bbox.halfHeight() - 1; // should we - 1 this  ? there is a gap i'm not sure why
    }
}

fn syncCameraMovements(world: *Ecs, camera: Zecs.Entity) void {
    var offset = world.get(camera, .Camera, .offset);

    var transform = world.pack(camera, .Transform);

    var screen_width = @intToFloat(f32, world.getResource(.screen_width));
    var screen_height = @intToFloat(f32, world.getResource(.screen_height));

    var position_x = @intToFloat(f32, transform.x.*) * CELL_SIZE;
    var position_y = @intToFloat(f32, transform.y.*) * CELL_SIZE;

    offset.x = -position_x + screen_width / 2;
    offset.y = -position_y + screen_height / 2;
}

pub fn getCameraBoundingBox(world: *Ecs, camera: Zecs.Entity) BoundingBox {
    var transform = world.pack(camera, .Transform);

    var screen_width = @intCast(i32, world.getResource(.screen_width));
    var screen_height = @intCast(i32, world.getResource(.screen_height));

    var screen_cells_width = @divTrunc(screen_width, CELL_SIZE);
    var screen_cells_height = @divTrunc(screen_height, CELL_SIZE);

    var half_width = @divTrunc(screen_cells_width, 2);
    var half_height = @divTrunc(screen_cells_height, 2);

    return BoundingBox{
        .x = transform.x.* - half_width,
        .y = transform.y.* - half_height,
        .width = screen_cells_width,
        .height = screen_cells_height,
    };
}
