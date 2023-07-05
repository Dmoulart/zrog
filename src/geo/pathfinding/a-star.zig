const std = @import("std");
const print = std.debug.print;
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
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
    path: []Position, // The slice we'll write the end path to
    allocator: std.mem.Allocator,
) ![]Position {
    const GRID_WIDTH = grid.len;
    const GRID_HEIGHT = grid[0].len;

    var nodes = ArrayList(Node).init(allocator);
    // Ths should never resize to avoid pointer invalidation !
    // what is the maximum number of node we need to create ?
    try nodes.ensureTotalCapacity((GRID_WIDTH * GRID_HEIGHT) * 4);
    defer nodes.deinit();

    var start_node = nodes.addOneAssumeCapacity();
    var end_node = nodes.addOneAssumeCapacity();

    start_node.* = Node.init(null, start);
    end_node.* = Node.init(null, end);

    assert(start_node.position.x >= 0 and start_node.position.x <= GRID_WIDTH);
    assert(start_node.position.y >= 0 and start_node.position.y <= GRID_HEIGHT);

    var open_list = NodeList.init(allocator);
    var closed_list = NodeList.init(allocator);

    defer open_list.deinit();
    defer closed_list.deinit();

    try open_list.append(start_node);

    while (open_list.items.len > 0) {
        var current_index: usize = 0;

        // Get the current node
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
            var current: ?*Node = current_node;
            var path_index: usize = 0;

            while (current) |node| {
                path[path_index] = node.position;
                current = node.parent;
                path_index += 1;
            }

            return path;
        }

        var children = try std.BoundedArray(*Node, neighbors.len).init(0);

        for (neighbors) |new_position| {
            var node_position = current_node.position.add(new_position);

            // make sure within range
            if (node_position.x >= GRID_WIDTH or node_position.x < 0 or node_position.y >= GRID_HEIGHT or node_position.y < 0) {
                continue;
            }

            if (grid[@intCast(usize, node_position.x)][@intCast(usize, node_position.y)] != 0) {
                continue;
            }

            var new_node = try nodes.addOne();
            new_node.* = Node.init(current_node, node_position);
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

    return path;
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

    var path_positions: [15]Position = undefined;

    var buffer: [10_000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    // Timers.start("path");
    var path = try astar(
        &grid,
        .{ .x = start_x, .y = start_y },
        .{ .x = end_x, .y = end_y },
        path_positions[0..],
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

    var path_positions: [200]Position = undefined;

    const allocator = std.testing.allocator;
    var path = try astar(
        &grid,
        .{ .x = start_x, .y = start_y },
        .{ .x = end_x, .y = end_y },
        path_positions[0..],
        allocator,
    );

    try std.testing.expect(path.len > 0);
}
