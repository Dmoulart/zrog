const rl = @import("raylib");

const Size = struct {
    width: i32,
    height: i32,
};

const Position = struct {
    x: i32,
    y: i32,
};

pub const Text = struct {
    const Self = @This();

    content: []const u8,

    pos: Position,

    font_size: c_int,

    color: rl.Color,

    pub fn draw(self: Self) void {
        const content: [*c]const u8 = @ptrCast(self.content);
        const x = self.pos.x - rl.MeasureText(content, self.font_size);

        rl.DrawText(
            content,
            @as(c_int, @intCast(x)),
            @as(c_int, @intCast(self.pos.y)),
            self.font_size,
            self.color,
        );
    }
};

pub const Rect = struct {
    const Self = @This();

    size: Size,

    pos: Position,

    color: rl.Color,

    pub fn draw(self: Self) void {
        rl.DrawRectangle(
            @as(c_int, @intCast(self.pos.x)),
            @as(c_int, @intCast(self.pos.y)),
            self.size.width,
            self.size.height,
            self.color,
        );
    }
};

pub const Element = union(enum) {
    rect: Rect,
    text: Text,

    pub fn draw(self: Element) void {
        return switch (self) {
            inline else => |el| el.draw(),
        };
    }
};
