const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;

const ArrayList = std.ArrayList;
const BoundedArray = std.BoundedArray;
const NodeList = std.ArrayList(*Node);

pub const Position = struct {
    const Self = @This();

    x: i32,
    y: i32,

    pub fn equals(self: *Self, other: *Self) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn add(self: *Self, other: Self) Self {
        return Self{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }
};

const neighbors = [_]Position{
    Position{
        .x = 0,
        .y = -1,
    },
    Position{
        .x = 0,
        .y = 1,
    },
    Position{
        .x = -1,
        .y = 0,
    },
    Position{
        .x = 1,
        .y = 0,
    },
    Position{
        .x = -1,
        .y = -1,
    },
    Position{
        .x = -1,
        .y = 1,
    },
    Position{
        .x = 1,
        .y = -1,
    },
    Position{
        .x = 1,
        .y = 1,
    },
};

pub const Node = struct {
    const Self = @This();

    parent: ?*Node,

    position: Position,

    g: i32,
    h: i32,
    f: i32,

    pub fn init(parent: ?*Self, position: Position) Self {
        return Self{
            .position = position,
            .parent = parent,
            .g = 0,
            .h = 0,
            .f = 0,
        };
    }

    pub fn create(parent: ?*Self, position: Position, allocator: std.mem.Allocator) !*Self {
        var node = try allocator.create(Self);
        node.position = position;
        node.parent = parent;
        node.g = 0;
        node.h = 0;
        node.f = 0;
        return node;
    }

    pub fn equals(self: *Self, other: *Self) bool {
        return self.position.equals(&other.position);
    }

    pub fn clone(self: *Self) Self {
        return Self{
            .position = Position{
                .x = self.position.x,
                .y = self.position.y,
            },
            .parent = self.parent,
            .g = self.g,
            .h = self.h,
            .f = self.f,
        };
    }
};

pub fn astar(
    grid: anytype, // can be an 2D array or slice
    start: Position,
    end: Position,
    limit: u32,
    allocator: std.mem.Allocator,
) !?ArrayList(Position) {
    const GRID_WIDTH = grid.len;
    const GRID_HEIGHT = grid[0].len;

    // Keep a reference to all node pointers so
    // we can clean it at the end of the function.
    // it feels wrong, but leaks feels wronger
    var nodes = ArrayList(*Node).init(allocator);
    defer {
        for (nodes.items) |node| {
            allocator.destroy(node);
        }
        nodes.deinit();
    }
    // estimate the total capacity to gain a little perf boost.
    try nodes.ensureTotalCapacity((GRID_WIDTH * GRID_HEIGHT));

    var start_node = try Node.create(null, start, allocator);
    var end_node = try Node.create(null, end, allocator);

    nodes.appendAssumeCapacity(start_node);
    nodes.appendAssumeCapacity(end_node);

    assert(start_node.position.x >= 0 and start_node.position.x <= GRID_WIDTH);
    assert(start_node.position.y >= 0 and start_node.position.y <= GRID_HEIGHT);

    var open_list = NodeList.init(allocator);
    var closed_list = NodeList.init(allocator);
    defer {
        open_list.deinit();
        closed_list.deinit();
    }

    try open_list.append(start_node);

    var tries: u32 = 0;

    while (open_list.items.len > 0) : (tries += 1) {
        if (tries >= limit) return null;

        var current_index: usize = 0;

        var current_node = open_list.items[0];

        var i: usize = 0;

        for (open_list.items) |node| {
            if (node.f < current_node.f) {
                current_node = node;
                current_index = i;
            }
            i += 1;
        }

        // Add to close list
        _ = open_list.orderedRemove(current_index);
        try closed_list.append(current_node);

        // Found goal
        if (current_node.equals(end_node)) {
            var path_list = ArrayList(Position).init(allocator);
            defer path_list.deinit();

            var reversed_path_list = ArrayList(Position).init(allocator);
            var current: ?*Node = current_node;

            while (current) |node| {
                try path_list.append(node.position);
                current = node.parent;
            }

            // reverse path
            try reversed_path_list.ensureTotalCapacity(path_list.capacity);
            while (path_list.popOrNull()) |item| {
                reversed_path_list.appendAssumeCapacity(item);
            }

            return reversed_path_list;
        }

        var children = try BoundedArray(*Node, neighbors.len).init(0);

        for (neighbors) |new_position| {
            var node_position = current_node.position.add(new_position);

            // make sure within range
            if (node_position.x >= GRID_WIDTH or node_position.x < 0 or node_position.y >= GRID_HEIGHT or node_position.y < 0) {
                continue;
            }

            if (grid[@intCast(usize, node_position.x)][@intCast(usize, node_position.y)] != 0) {
                continue;
            }

            var new_node = try Node.create(current_node, node_position, allocator);

            try nodes.append(new_node);
            try children.append(new_node);
        }

        childloop: for (children.slice()) |child| {
            // Child is in the closed list
            for (closed_list.items) |closed_child| {
                if (child.equals(closed_child)) continue :childloop;
            }

            child.g = current_node.g + 1;
            child.h = ((child.position.x - end_node.position.x) * (child.position.x - end_node.position.x)) + ((child.position.y - end_node.position.y) * (child.position.y - end_node.position.y));
            child.f = child.g + child.h;

            // Child is already in the open list
            for (open_list.items) |open_node| {
                if (child.equals(open_node) and child.g > open_node.g) continue :childloop;
            }

            try open_list.append(child);
        }
    }

    return null;
}

pub fn bench() !void {
    var grid = [10][10]u8{
        [_]u8{ 0, 0, 1, 0, 1, 0, 0, 1, 1, 0 },
        [_]u8{ 0, 0, 1, 0, 1, 0, 1, 0, 0, 0 },
        [_]u8{ 1, 0, 1, 0, 1, 0, 1, 0, 0, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 1, 0, 1, 0, 0 },
        [_]u8{ 0, 0, 1, 1, 1, 0, 0, 0, 0, 0 },
        [_]u8{ 0, 0, 1, 0, 1, 0, 1, 0, 1, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 0, 0, 0, 1, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 1, 0, 0, 1, 0 },
        [_]u8{ 0, 0, 0, 1, 0, 0, 0, 0, 1, 0 },
    };

    var start_x: u8 = 0;
    var start_y: u8 = 0;

    var end_x: u8 = 4;
    var end_y: u8 = 4;

    var path_positions: [200]Position = undefined;

    var buffer: [10_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // Timers.start("path");
    var path = try astar(
        &grid,
        .{ .x = start_x, .y = start_y },
        .{ .x = end_x, .y = end_y },
        path_positions[0..],
        10_000,
        allocator,
    );
    // Timers.end("path");

    var y: usize = 0;
    while (y < 10) : (y += 1) {
        std.debug.print("\n", .{});
        var x: usize = 0;
        while (x < 10) : (x += 1) {
            var is_path = false;
            for (path) |node| {
                if (node.x == x and node.y == y) {
                    is_path = true;
                    break;
                }
            }
            if (grid[@intCast(usize, x)][@intCast(usize, y)] == 1) {
                std.debug.print("x ", .{});
            } else if (x == start_x and y == start_y) {
                std.debug.print("S ", .{});
            } else if (x == end_x and y == end_y) {
                std.debug.print("E ", .{});
            } else if (is_path) {
                std.debug.print("o ", .{});
            } else {
                std.debug.print(". ", .{});
            }
        }
    }
}

test "Astar" {
    var grid = [10][10]u8{
        [_]u8{ 0, 0, 1, 0, 1, 0, 0, 1, 1, 0 },
        [_]u8{ 0, 0, 1, 0, 1, 0, 1, 0, 0, 0 },
        [_]u8{ 1, 0, 1, 0, 1, 0, 1, 0, 0, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 0, 0, 0, 0, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 1, 0, 1, 0, 0 },
        [_]u8{ 0, 0, 1, 1, 1, 0, 0, 0, 0, 0 },
        [_]u8{ 0, 0, 1, 0, 1, 0, 1, 0, 1, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 0, 0, 0, 1, 0 },
        [_]u8{ 0, 0, 1, 0, 0, 1, 0, 0, 1, 0 },
        [_]u8{ 0, 0, 0, 1, 0, 0, 0, 0, 1, 0 },
    };

    var start_x: u8 = 0;
    var start_y: u8 = 0;

    var end_x: u8 = 4;
    var end_y: u8 = 4;

    const allocator = std.testing.allocator;
    var path = try astar(
        &grid,
        .{ .x = start_x, .y = start_y },
        .{ .x = end_x, .y = end_y },
        10_000,
        allocator,
    );
    defer path.?.deinit();

    try std.testing.expect(path.?.items.len > 0);
}
