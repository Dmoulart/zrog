const std = @import("std");

pub const Cells = enum(u8) {
    dead = 0,
    alive = 1,
};

pub const CellularAutomaton = struct {
    const Self = @This();

    cells: []Cells = undefined,

    height: usize,
    width: usize,

    pub fn init(width: usize, height: usize) Self {
        var cells: []Cells = undefined;

        var y: usize = 0;

        while (y < height) : (y += 1) {
            var x: usize = 0;

            var row: []Cells = undefined;

            cells[y] = row;

            while (x < width) : (x += 1) {
                cells[y][x] = Cells.Dead;
            }
        }

        return Self{
            .cells = cells,
            .width = width,
            .height = height,
        };
    }

    pub fn populate(self: *Self, x: usize, y: usize) void {
        self.cells[x][y] = Cells.Alive;
    }

    pub fn update(self: *Self) void {
        var y: usize = 1;
        var neighbors: [8]Cells = undefined;

        var next_cells: []Cells = undefined;

        while (y < self.height - 1) : (y += 1) {
            var x: usize = 1;

            while (x < self.width - 1) : (x += 1) {
                const left = self.cells[y][x - 1];
                const right = self.cells[y][x + 1];

                const top = self.cells[y - 1][x];
                const top_left = self.cells[y - 1][x - 1];
                const top_right = self.cells[y - 1][x + 1];

                const bottom = self.cells[y + 1][x];
                const bottom_left = self.cells[y + 1][x - 1];
                const bottom_right = self.cells[y + 1][x + 1];

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
                    alive_neighbors = if (neighbor == .Alive) alive_neighbors + 1 else alive_neighbors;
                }

                if (self.cells[y][x] == .Alive) {
                    // If the cell is alive, then it stays alive if it has either 2 or 3 live neighbors.
                    if (alive_neighbors < 2 or alive_neighbors > 3) {
                        next_cells[y][x] = .Dead;
                    } else {
                        next_cells[y][x] = .Alive;
                    }
                } else {
                    // If the cell is dead, then it springs to life only in the case that it has 3 live neighbors.
                    if (alive_neighbors == 3) {
                        next_cells[y][x] = Cells.Alive;
                    } else {
                        next_cells[y][x] = Cells.Dead;
                    }
                }
            }
        }

        self.cells = next_cells;
    }
};
