const std = @import("std");
const ArrayList = std.ArrayList;
const NodeList = std.ArrayList(*Node);
const print = std.debug.print;

const Position = struct {
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

    pub fn create(parent: ?*Self, position: Position, allocator: std.mem.Allocator) *Self {
        var node = allocator.create(Node) catch unreachable;
        node.position = position;
        node.parent = parent;
        node.g = 0;
        node.f = 0;
        node.h = 0;

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

const GRID_SIZE = 10;
pub const Grid = [GRID_SIZE][GRID_SIZE]u8;

pub fn astar(
    grid: *Grid,
    start: Position,
    end: Position,
    allocator: std.mem.Allocator,
) !ArrayList(Position) {
    const start_node = Node.create(null, start, allocator);
    const end_node = Node.create(null, end, allocator);

    var open_list = NodeList.init(allocator);
    var closed_list = NodeList.init(allocator);

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
            var path = ArrayList(Position).init(allocator);
            var current: ?*Node = current_node;

            while (current) |node| {
                try path.append(node.position);
                current = node.parent;
            }

            return path;
        }

        var children = NodeList.init(allocator);

        for (neighbors) |new_position| {
            var node_position = current_node.position.add(new_position);

            // make sure within range
            if (node_position.x >= GRID_SIZE or node_position.x < 0 or node_position.y >= GRID_SIZE or node_position.y < 0) {
                continue;
            }

            if (grid[@intCast(usize, node_position.x)][@intCast(usize, node_position.y)] != 0) {
                continue;
            }

            var new_node = Node.create(current_node, node_position, allocator);

            try children.append(new_node);
        }

        childloop: for (children.items) |child| {
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

    return ArrayList(Position).init(allocator);
}
