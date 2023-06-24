const IsBlockingFn = *const fn (i32, i32) bool;
const MarkVisibleFn = *const fn (i32, i32) void;

pub fn FieldOfView(comptime is_blocking: IsBlockingFn, comptime mark_visible: MarkVisibleFn) type {
    return struct {
        const Self = @This();
        origin_x: i32,
        origin_y: i32,

        pub fn compute(self: *Self) void {
            mark_visible(self.origin_x, self.origin_y);

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

                scan(&first_row, &quadrant);
            }
        }

        pub fn scan(row: *Row, quadrant: *Quadrant) void {
            var prev_tile: ?Tile = null;

            var tiles = row.tiles();

            while (tiles.next()) |tile| {
                if (isWall(tile, quadrant) or isSymmetric(row, tile)) {
                    reveal(tile, quadrant);
                }

                if (isWall(prev_tile, quadrant) and isFloor(tile, quadrant)) {
                    row.start_slope = slope(tile);
                }

                if (isFloor(prev_tile, quadrant) and isWall(tile, quadrant)) {
                    var next_row = row.next();
                    next_row.end_slope = slope(tile);
                    scan(&next_row, quadrant);
                }

                prev_tile = tile;
            }

            if (isFloor(prev_tile, quadrant)) {
                var next_row = row.next();
                scan(&next_row, quadrant);
            }
        }

        pub fn reveal(tile: Tile, quadrant: *Quadrant) void {
            var pos = quadrant.transform(tile);
            mark_visible(pos.x, pos.y);
        }

        pub fn isWall(tile: ?Tile, quadrant: *Quadrant) bool {
            return if (tile == null) false else |existing_tile| blk: {
                var pos = quadrant.transform(existing_tile);
                break :blk is_blocking(pos.x, pos.y);
            };
        }

        pub fn isFloor(tile: ?Tile, quadrant: *Quadrant) bool {
            return if (tile == null) false else |existing_tile| blk: {
                var pos = quadrant.transform(existing_tile);
                break :blk !is_blocking(pos.x, pos.y);
            };
        }
    };
}
// pub fn computeFieldOfView(
//     origin_x: i32,
//     origin_y: i32,
//     is_blocking: IsBlockingFn,
//     mark_visible: MarkVisibleFn,
// ) void {
//     _ = is_blocking;
//     mark_visible(origin_x, origin_y);

//     for (range(4)) |_, i| {
//         var direction = @intToEnum(Quadrant.Direction, i);

//         var quadrant = Quadrant{
//             .cardinal = direction,
//             .origin_x = origin_x,
//             .origin_y = origin_y,
//         };
//         _ = quadrant;
//     }
//     // _ = is_blocking;
// }

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
            return if (self.curr >= self.max) null else blk: {
                self.curr += 1;

                break :blk Tile{
                    .col = self.curr,
                    .depth = self.depth,
                };
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
        const max_col = roundTiesDown(depth * self.end_slope) + 1;

        return Tile.Iterator{
            .depth = self.depth,
            .min = @floatToInt(i32, min_col),
            .max = @floatToInt(i32, max_col),
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
    return 2 * @intToFloat(f32, tile.col) - 1 / 2 * @intToFloat(f32, tile.depth);
}

fn roundTiesUp(n: f32) f32 {
    return @floor(n + 0.5);
}

fn roundTiesDown(n: f32) f32 {
    return @ceil(n - 0.5);
}

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
