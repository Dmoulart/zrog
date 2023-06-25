const std = @import("std");
const print = std.debug.print;
const Ecs = @import("../context.zig").Ecs;
const IsBlockingFn = *const fn (*Ecs, i32, i32) bool;
const MarkVisibleFn = *const fn (*Ecs, i32, i32) void;

pub fn FieldOfView(comptime is_blocking: IsBlockingFn, comptime mark_visible: MarkVisibleFn) type {
    return struct {
        const Self = @This();

        origin_x: i32,
        origin_y: i32,

        world: *Ecs,

        pub fn compute(self: *Self) void {
            mark_visible(self.world, self.origin_x, self.origin_y);

            for (range(4)) |_, i| {
                var direction = @intToEnum(Quadrant.Direction, i);

                var quadrant = Quadrant{
                    .cardinal = direction,
                    .origin_x = self.origin_x,
                    .origin_y = self.origin_y,
                };

                var first_row = Row{
                    .depth = 1,
                    .start_slope = -1,
                    .end_slope = 1,
                };

                self.scan(&first_row, &quadrant);
            }
        }

        pub fn scan(self: *Self, row: *Row, quadrant: *Quadrant) void {
            var prev_tile: ?Tile = null;

            var tiles = row.tiles();

            // print("\ntiles max ! {any}\n", .{tiles.max});

            while (tiles.next()) |tile| {
                // std.debug.print("\ntiles curr ! {any}\n", .{tiles.curr});
                // std.debug.print("next tile {}", .{i});
                if (self.isWall(tile, quadrant) or isSymmetric(row, tile)) {
                    // print("tile is wall or is symmetric \n", .{});
                    self.reveal(tile, quadrant);
                }

                if (self.isWall(prev_tile, quadrant) and self.isFloor(tile, quadrant)) {
                    // print("prev tile is wall and tile is floor \n", .{});
                    row.start_slope = slope(tile);
                }

                if (self.isFloor(prev_tile, quadrant) and self.isWall(tile, quadrant)) {
                    print("prev tile is floor and tile is wall \n", .{});
                    var next_row = row.next();
                    next_row.end_slope = slope(tile);
                    self.scan(&next_row, quadrant);
                }

                prev_tile = tile;
            }

            // print("\n prev_tile {any}\n", .{prev_tile});

            if (self.isFloor(prev_tile, quadrant)) {
                // print("\n prev tile is floor {}\n", .{self.isFloor(prev_tile, quadrant)});
                var next_row = row.next();
                if (next_row.depth > 100) return;
                self.scan(&next_row, quadrant);
            }
        }

        pub fn reveal(self: *Self, tile: Tile, quadrant: *Quadrant) void {
            var pos = quadrant.transform(tile);
            mark_visible(self.world, pos.x, pos.y);
        }

        pub fn isWall(self: *Self, tile: ?Tile, quadrant: *Quadrant) bool {
            if (tile) |existing_tile| {
                var pos = quadrant.transform(existing_tile);
                return is_blocking(self.world, pos.x, pos.y);
            }

            return false;
        }

        pub fn isFloor(self: *Self, tile: ?Tile, quadrant: *Quadrant) bool {
            if (tile) |existing_tile| {
                var pos = quadrant.transform(existing_tile);

                // std.debug.print("\n is blocking {}\n", .{is_blocking(self.world, pos.x, pos.y)});
                return !is_blocking(self.world, pos.x, pos.y);
            }

            return false;
        }
    };
}

const Quadrant = struct {
    const Self = @This();

    pub const Direction = enum {
        north,
        east,
        south,
        west,
    };

    cardinal: Direction,

    origin_x: i32,
    origin_y: i32,

    // Convert a (row, col) tuple representing a position relative to the current quadrant
    // into an (x, y) tuple representing an absolute position in the grid.
    pub fn transform(self: *Self, tile: Tile) Coordinates {
        var col = tile.col;
        var row = tile.depth;

        return switch (self.cardinal) {
            .north => .{
                .x = self.origin_x + col,
                .y = self.origin_y - row,
            },
            .south => .{
                .x = self.origin_x + col,
                .y = self.origin_y + row,
            },
            .east => .{
                .x = self.origin_x + row,
                .y = self.origin_y + col,
            },
            .west => .{
                .x = self.origin_x - row,
                .y = self.origin_y + col,
            },
        };
    }
};

pub const Tile = struct {
    depth: i32,
    col: i32,

    pub const Iterator = struct {
        min: i32,
        max: i32,

        curr: i32 = 0,
        depth: i32,

        pub fn next(self: *@This()) ?Tile {
            if (self.curr >= self.max) {
                return null;
            }

            self.curr += 1;

            return Tile{
                .col = self.curr,
                .depth = self.depth,
            };
        }
    };
};

const Row = struct {
    const Self = @This();

    depth: i32,

    start_slope: f32,
    end_slope: f32,

    pub fn tiles(self: Self) Tile.Iterator {
        const depth = @intToFloat(f32, self.depth);

        const min_col = roundTiesUp(depth * self.start_slope);
        const max_col = roundTiesDown(depth * self.end_slope); // +1 ?

        // std.debug.print("\nmin col {} \n max col {}", .{ min_col, max_col });

        return Tile.Iterator{
            .depth = self.depth,
            .min = min_col,
            .max = max_col,
            .curr = min_col,
        };
    }

    pub fn next(self: *Self) Self {
        return Self{
            .depth = self.depth + 1,
            .start_slope = self.start_slope,
            .end_slope = self.end_slope,
        };
    }
};

fn slope(tile: Tile) f32 {
    return (2 * @intToFloat(f32, tile.col) - 1) / (2 * @intToFloat(f32, tile.depth));
}

fn roundTiesUp(n: f32) i32 {
    return @floatToInt(i32, @floor(n + 0.5));
}

fn roundTiesDown(n: f32) i32 {
    return @floatToInt(i32, @ceil(n - 0.5));
}

fn isSymmetric(row: *Row, tile: Tile) bool {
    var depth = @intToFloat(f32, row.depth);
    var col = @intToFloat(f32, tile.col);

    var is_symetric = (col >= depth * row.start_slope and col <= depth * row.end_slope);

    // print("\nis symetric {} \n", .{is_symetric});

    return is_symetric;
}

// todo: make generic vec class ?
const Coordinates = struct {
    x: i32,
    y: i32,
};

fn range(len: usize) []const void {
    return @as([*]void, undefined)[0..len];
}
