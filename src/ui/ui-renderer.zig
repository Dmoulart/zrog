const std = @import("std");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;
const rl = @import("raylib");

const CELL_SIZE = @import("../graphics/renderer.zig").CELL_SIZE;

const getCameraBoundingBox = @import("../graphics/camera.zig").getCameraBoundingBox;

pub fn renderUI(world: *Ecs) void {
    const camera = world.getResource(.camera);
    var fov_bbox = getCameraBoundingBox(world, camera);

    rl.DrawFPS(
        @intCast(c_int, fov_bbox.x * CELL_SIZE),
        @intCast(c_int, fov_bbox.y * CELL_SIZE),
    );
}
