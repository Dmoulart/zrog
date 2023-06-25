const std = @import("std");
const print = std.debug.print;

const Zecs = @import("zecs");
const Ecs = @import("../context.zig").Ecs;

const IsBlockingFn = *const fn (*Ecs, i32, i32) bool;
const MarkVisibleFn = *const fn (*Ecs, Zecs.Entity, i32, i32) void;

// Symetric shadowcasting
// Field of view implementation based on : https://www.albertford.com/shadowcasting
//
pub fn FieldOfView(comptime is_blocking: IsBlockingFn, comptime mark_visible: MarkVisibleFn) type {
    return struct {
        const Self = @This();

        origin_x: i32,
        origin_y: i32,

        entity: Zecs.Entity,

        range: i32,

        world: *Ecs,

        pub fn compute(self: *Self) void {
            mark_visible(self.world, self.entity, self.origin_x, self.origin_y);

            for (Quadrant.directions) |direction| {
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

        // Scan a row and recursively scan all of its children.
        // If you think of each quadrant as a tree of rows, this essentially is a depth-first tree traversal.
        pub fn scan(self: *Self, row: *Row, quadrant: *Quadrant) void {
            var prev_tile: ?Tile = null;

            var tiles = row.tiles();

            while (tiles.next()) |tile| {
                if (self.isWall(tile, quadrant) or isSymmetric(row, tile)) {
                    self.reveal(tile, quadrant);
                }

                if (self.isWall(prev_tile, quadrant) and self.isFloor(tile, quadrant)) {
                    row.start_slope = slope(tile);
                }

                if (self.isFloor(prev_tile, quadrant) and self.isWall(tile, quadrant)) {
                    var next_row = row.next();
                    next_row.end_slope = slope(tile);
                    self.scan(&next_row, quadrant);
                }

                prev_tile = tile;
            }

            if (self.isFloor(prev_tile, quadrant)) {
                if (row.depth + 1 >= self.range) return;

                var next_row = row.next();

                self.scan(&next_row, quadrant);
            }
        }

        pub fn reveal(self: *Self, tile: Tile, quadrant: *Quadrant) void {
            var pos = quadrant.transform(tile);

            mark_visible(self.world, self.entity, pos.x, pos.y);
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

                return !is_blocking(self.world, pos.x, pos.y);
            }

            return false;
        }
    };
}

// A Quadrant represents a 90 degree sector pointing north, south, east, or west.
// Quadrants are traversed row by row.
// For the east and west quadrants, these “rows” are vertical, not horizontal.
const Quadrant = struct {
    const Self = @This();

    pub const Direction = enum {
        north,
        east,
        south,
        west,
    };

    pub const directions = [_]Direction{
        .north,
        .east,
        .south,
        .west,
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

// A Row represents a segment of tiles bound between a start and end slope.
// Depth represents the distance between the row and the quadrant’s origin.
const Row = struct {
    const Self = @This();

    depth: i32,

    start_slope: f32,
    end_slope: f32,

    pub fn tiles(self: Self) Tile.Iterator {
        const depth = @intToFloat(f32, self.depth);

        const min_col = roundTiesUp(depth * self.start_slope) - 1; // need this to avoid a hole between west and north, but why ?
        const max_col = roundTiesDown(depth * self.end_slope);

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

// Checks if a given floor tile can be seen symmetrically from the origin.
// It returns true if the central point of the tile is in the sector swept out by the row’s start and end slopes.
// Otherwise, it returns false.
fn slope(tile: Tile) f32 {
    return (2 * @intToFloat(f32, tile.col) - 1) / (2 * @intToFloat(f32, tile.depth));
}

// Round n to the nearest integer. If n ends in .5, rounds up.
// there might be a problem with this one (see function utilisation above)
fn roundTiesUp(n: f32) i32 {
    return @floatToInt(i32, @floor(n + 0.5));
}

// Round n to the nearest integer. If n ends in .5, rounds down
fn roundTiesDown(n: f32) i32 {
    return @floatToInt(i32, @ceil(n - 0.5));
}

// Checks if a given floor tile can be seen symmetrically from the origin.
// It returns true if the central point of the tile is in the sector swept out by the row’s start and end slopes.
// Otherwise, it returns false.
fn isSymmetric(row: *Row, tile: Tile) bool {
    var depth = @intToFloat(f32, row.depth);
    var col = @intToFloat(f32, tile.col);

    return (col >= depth * row.start_slope and col <= depth * row.end_slope);
}

// todo: make generic vec class ?
const Coordinates = struct {
    x: i32,
    y: i32,
};

fn range(len: usize) []const void {
    return @as([*]void, undefined)[0..len];
}
