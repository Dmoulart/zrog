const std = @import("std");
const assert = @import("std").debug.assert;

const rl = @import("raylib");
const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const GeoSet = @import("../geo/geo-set.zig").GeoSet;
pub const FieldsOfViews = std.AutoHashMap(Zecs.Entity, GeoSet);

const FieldOfView = @import("./symetric-shadowcasting.zig").FieldOfView(isBlocking, markVisible);

var is_ready = false;
var fields_of_views: FieldsOfViews = undefined;

fn setup(world: *Ecs) void {
    fields_of_views = FieldsOfViews.init(world.allocator);

    world.setResource(.fields_of_views, &fields_of_views);

    world.onDeinit(cleanup);

    is_ready = true;
}

fn cleanup(world: *Ecs) void {
    _ = world;

    var iterator = fields_of_views.iterator();

    while (iterator.next()) |field_of_view| {
        field_of_view.value_ptr.deinit();
    }

    fields_of_views.deinit();
}

pub fn fieldsOfview(world: *Ecs) void {
    if (!is_ready) {
        setup(world);
    }

    var fieldsOfView = world.query().all(.{ .Transform, .Vision })
        .onEnter(createEntityVisibleTiles)
        .onExit(destroyEntityVisibleTiles)
        .execute();

    fieldsOfView.each(compute);
}

fn compute(world: *Ecs, entity: Zecs.Entity) void {
    var pos = world.pack(entity, .Transform);
    var range = world.get(entity, .Vision, .range);

    var entity_fov = fields_of_views.get(entity).?;

    entity_fov.clearRetainingCapacity();

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

    entity_fov.value_ptr.put(.{ .x = x, .y = y }, {}) catch unreachable;
}

fn isBlocking(world: *Ecs, x: i32, y: i32) bool {
    var chunks = world.getResource(.chunks);

    var chunk = chunks.getChunkAtPosition(x, y);
    if (chunk == null) return true;

    var prop = chunk.?.getFromWorldPosition(.props, x, y);

    return prop != null;
}

fn createEntityVisibleTiles(world: *Ecs, entity: Zecs.Entity) void {
    fields_of_views.put(entity, GeoSet.init(world.allocator)) catch unreachable;
}

fn destroyEntityVisibleTiles(_: *Ecs, entity: Zecs.Entity) void {
    std.debug.print("destroy !", .{});
    var visible_tiles = fields_of_views.get(entity).?;
    visible_tiles.deinit();
    _ = fields_of_views.remove(entity);
}
