const std = @import("std");
const assert = @import("std").debug.assert;

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const FieldOfView = @import("./symetric-shadowcasting.zig").FieldOfView(isBlocking, markVisible);

const rl = @import("raylib");

pub const VisibleTiles = std.AutoHashMap(i32, void);
pub const FieldsOfViews = std.AutoHashMap(Zecs.Entity, VisibleTiles);

var is_ready = false;

var fields_of_views: FieldsOfViews = undefined;

fn setup(world: *Ecs) void {
    // memory leak
    fields_of_views = FieldsOfViews.init(world.allocator);

    world.setResource(.fields_of_views, &fields_of_views);

    is_ready = true;
}

pub fn fieldsOfview(world: *Ecs) void {
    if (!is_ready) {
        setup(world);
    }

    var fieldsOfView = world.query().all(
        .{
            .Transform,
            .Vision,
        },
    ).execute();

    fieldsOfView.each(compute);
}

fn compute(world: *Ecs, entity: Zecs.Entity) void {
    var pos = world.pack(entity, .Transform);
    var range = world.get(entity, .Vision, .range);

    var entity_fov = fields_of_views.getOrPut(entity) catch unreachable;

    if (!entity_fov.found_existing) {
        entity_fov.value_ptr.* = VisibleTiles.init(world.allocator);
    } else {
        entity_fov.value_ptr.clearRetainingCapacity();
    }

    // reuse struct ?
    var fov = FieldOfView{
        .origin_x = pos.x.*,
        .origin_y = pos.y.*,
        .entity = entity,
        .range = range.*,
        .world = world,
    };

    fov.compute();
}

fn markVisible(world: *Ecs, entity: Zecs.Entity, x: i32, y: i32) void {
    _ = world;
    var entity_fov = fields_of_views.getOrPut(entity) catch unreachable;
    entity_fov.value_ptr.put(hash(x, y), {}) catch unreachable;

    // rl.DrawText(".", x * 24, y * 24, 24, rl.RED);
}

fn hash(x: i32, y: i32) i32 {
    return (x << 16) ^ y;
}

fn isBlocking(world: *Ecs, x: i32, y: i32) bool {
    var chunks = world.getResource(.chunks);

    var chunk = chunks.getChunkAtPosition(x, y);
    if (chunk == null) return true;

    var prop = chunk.?.getFromWorldPosition(.props, x, y);

    return prop != null;
}
