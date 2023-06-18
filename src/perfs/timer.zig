const std = @import("std");

pub var before: i64 = 0;
pub var after: i64 = 0;

pub var nano_before: i128 = 0;
pub var nano_after: i128 = 0;

pub var name: []const u8 = "";

pub fn start(timer_name: []const u8) void {
    name = timer_name;
    before = std.time.milliTimestamp();
}

pub fn nanoStart() void {
    nano_before = std.time.nanoTimestamp();
}

pub fn end() void {
    after = std.time.milliTimestamp();

    std.debug.print("\n", .{});
    std.debug.print("\n{s} Results : {} ms", .{ name, after - before });
    std.debug.print("\n", .{});
    std.debug.print("\n", .{});
}

pub fn nanoEnd() void {
    nano_after = std.time.nanoTimestamp();

    std.debug.print("\n", .{});
    std.debug.print("\n{} Results : {} ms", .{ name, after - before });
    std.debug.print("\n", .{});
    std.debug.print("\n", .{});
}
