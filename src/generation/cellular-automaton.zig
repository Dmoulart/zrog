const std = @import("std");
const Chunk = @import("../map/chunk.zig");
const assert = std.debug.assert;
const rl = @import("raylib");

const RndGen = std.rand.DefaultPrng;

pub const CellularAutomatonCells = enum(u8) {
    dead = 0,
    alive = 1,
};

pub fn CellularAutomaton(comptime width: comptime_int, comptime height: comptime_int) type {
    assert(width > 0);
    assert(height > 0);

    return struct {
        const Self = @This();

        pub const Cells = CellularAutomatonCells;

        cells: [width][height]Cells = undefined,

        height: usize = height,
        width: usize = width,

        pub fn init() Self {
            var automaton = Self{};

            automaton.clear();

            return automaton;
        }

        pub fn set(self: *Self, x: usize, y: usize, state: Cells) void {
            self.cells[x][y] = state;
        }

        pub fn get(self: *Self, x: usize, y: usize) Cells {
            return self.cells[x][y];
        }

        pub fn getPtr(self: *Self, x: usize, y: usize) *Cells {
            return &self.cells[x][y];
        }

        // Set all automaton cell's to dead
        pub fn clear(self: *Self) void {
            // is this a great idea ?
            @setEvalBranchQuota(10_000_000);

            var x: usize = 0;

            while (x < width) : (x += 1) {
                std.mem.set(Cells, &self.cells[x], .dead);
            }
        }

        pub fn map(self: *Self, function: *const fn (x: usize, y: usize, state: Cells) Cells) void {
            var y: usize = 0;
            while (y < height - 1) : (y += 1) {
                var x: usize = 0;

                while (x < width - 1) : (x += 1) {
                    var cell = self.get(x, y);
                    var state = function(x, y, cell);
                    self.set(x, y, state);
                }
            }
        }

        pub fn each(self: *Self, function: *const fn (x: usize, y: usize, state: *Cells) void) void {
            var y: usize = 0;
            while (y < height - 1) : (y += 1) {
                var x: usize = 0;

                while (x < width - 1) : (x += 1) {
                    function(x, y, self.getPtr(x, y));
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
            var y: usize = 0;

            var neighbors: [8]Cells = undefined;

            var next_cells: [width][height]Cells = undefined;

            var limit_y: usize = height - 1;
            var limit_x: usize = width - 1;

            while (y < height - 1) : (y += 1) {
                var x: usize = 0;

                var ym1 = if (y == 0) limit_y else y - 1;
                var yp1 = if (y == limit_y) limit_y else y + 1;

                while (x < width - 1) : (x += 1) {
                    var xm1 = if (x == 0) limit_x else x - 1;
                    var xp1 = if (x == limit_x) limit_x else x + 1;

                    const left = self.get(xm1, y);
                    const right = self.get(xp1, y);

                    const top = self.get(x, ym1);
                    const top_left = self.get(xm1, ym1);
                    const top_right = self.get(xp1, ym1);

                    const bottom = self.get(x, yp1);
                    const bottom_left = self.get(xm1, yp1);
                    const bottom_right = self.get(xp1, yp1);

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

                    var current_cell = self.get(x, y);

                    if (current_cell == .alive) {
                        // If the cell is alive, then it stays alive if it has either 2 or 3 live neighbors.
                        next_cells[x][y] = if (alive_neighbors < 2 or alive_neighbors > 3) .dead else .alive;
                    } else {
                        // If the cell is dead, then it springs to life only in the case that it has 3 live neighbors.
                        next_cells[x][y] = if (alive_neighbors == 3) .alive else .dead;
                    }
                }
            }

            self.cells = next_cells;
        }

        // Fill the grid  by specifying a individual cell living chance percentage.
        pub fn fillWithLivingChanceOf(self: *Self, chance: u8) void {
            assert(chance >= 0 and chance <= 100);

            var rnd = RndGen.init(@intCast(u64, std.time.milliTimestamp()));

            var y: usize = 0;

            while (y < self.height - 1) : (y += 1) {
                var x: usize = 0;

                while (x < self.width - 1) : (x += 1) {
                    var random_number = rnd.random().intRangeAtMost(u8, 0, 100);
                    var alive = random_number <= chance;

                    self.set(x, y, if (alive) .alive else .dead);
                }
            }
        }

        pub fn debugDraw(self: *Self, camera: rl.Camera2D, size: c_int) void {
            rl.BeginDrawing();

            rl.ClearBackground(rl.BLACK);

            rl.BeginMode2D(camera);

            var cells_x: usize = 0;
            var cells_y: usize = 0;

            while (cells_y < self.height - 1) : (cells_y += 1) {
                cells_x = 0;

                while (cells_x < self.width - 1) : (cells_x += 1) {
                    const state = self.get(cells_x, cells_y);

                    if (state == .alive) {
                        rl.DrawText("*", @intCast(c_int, cells_x) * size, @intCast(c_int, cells_y) * size, size, rl.WHITE);
                    }
                }
            }

            rl.EndMode2D();

            rl.EndDrawing();
        }
    };
}

// The default map chunk automaton
pub const MapAutomaton = CellularAutomaton(Chunk.SIZE, Chunk.SIZE);
pub const map_automaton = MapAutomaton.init();
