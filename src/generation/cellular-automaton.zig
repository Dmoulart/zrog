const std = @import("std");

pub const CellularAutomaton = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    cells: []Cells,
    next_cells: []Cells,

    height: usize,
    width: usize,

    pub const Cells = enum(u8) {
        dead = 0,
        alive = 1,
    };

    pub fn init(allocator: std.mem.Allocator, width: usize, height: usize) !Self {
        var cells = try allocator.alloc(Cells, width * height);
        var next_cells = try allocator.alloc(Cells, width * height);

        var automaton = Self{
            .allocator = allocator,
            .cells = cells,
            .next_cells = next_cells,
            .width = width,
            .height = height,
        };

        var y: usize = 0;

        while (y < height) : (y += 1) {
            var x: usize = 0;

            while (x < width) : (x += 1) {
                automaton.set(x, y, .dead);
            }
        }

        return automaton;
    }

    pub fn set(self: *Self, x: usize, y: usize, state: Cells) void {
        self.cells[y * self.width + x] = state;
    }

    pub fn get(self: *Self, x: usize, y: usize) *Cells {
        return &self.cells[y * self.width + x];
    }

    pub fn map(self: *Self, function: *const fn (x: usize, y: usize, state: *Cells) Cells) void {
        var y: usize = 0;
        while (y < self.height - 1) : (y += 1) {
            var x: usize = 0;

            while (x < self.width - 1) : (x += 1) {
                var cell = self.get(x, y);
                cell.* = function(x, y, self.get(x, y));
            }
        }
    }

    pub fn each(self: *Self, param: anytype, function: *const fn (param: anytype, x: usize, y: usize, state: *Cells) void) void {
        var y: usize = 0;
        while (y < self.height - 1) : (y += 1) {
            var x: usize = 0;

            while (x < self.width - 1) : (x += 1) {
                function(param, x, y, self.get(x, y));
            }
        }
    }

    pub fn update(self: *Self, n: u32) void {
        var i: u32 = 0;
        while (i < n) : (i += 1) {
            self.step();
        }
    }

    pub fn step(self: *Self) void {
        var y: usize = 1;

        var neighbors: [8]Cells = undefined;

        var next_cells = self.allocator.alloc(Cells, self.width * self.height) catch unreachable;

        while (y < self.height - 1) : (y += 1) {
            var x: usize = 1;

            while (x < self.width - 1) : (x += 1) {
                const left = self.get(x - 1, y).*;
                const right = self.get(x + 1, y).*;

                const top = self.get(x, y - 1).*;
                const top_left = self.get(x - 1, y - 1).*;
                const top_right = self.get(x + 1, y - 1).*;

                const bottom = self.get(x, y + 1).*;
                const bottom_left = self.get(x - 1, y + 1).*;
                const bottom_right = self.get(x + 1, y + 1).*;

                neighbors = [_]Cells{
                    left,
                    right,
                    top,
                    top_left,
                    top_right,
                    bottom,
                    bottom_left,
                    bottom_right,
                };

                var alive_neighbors: u8 = 0;

                for (neighbors) |neighbor| {
                    alive_neighbors = if (neighbor == .alive) alive_neighbors + 1 else alive_neighbors;
                }

                var current_cell = self.get(x, y).*;

                if (current_cell == .alive) {
                    // If the cell is alive, then it stays alive if it has either 2 or 3 live neighbors.
                    if (alive_neighbors < 2 or alive_neighbors > 3) {
                        self.set(x, y, .dead);
                    } else {
                        self.set(x, y, .alive);
                    }
                } else {
                    // If the cell is dead, then it springs to life only in the case that it has 3 live neighbors.
                    if (alive_neighbors == 3) {
                        self.set(x, y, .dead);
                    } else {
                        self.set(x, y, .alive);
                    }
                }
            }
        }

        self.cells = next_cells;
    }
};
