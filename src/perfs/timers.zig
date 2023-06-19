const std = @import("std");
const Self = @This();

name: []const u8,

before: i64 = 0,
after: i64 = 0,

var instances: *std.StringHashMap(Self) = undefined;
var is_ready = false;

// this leaks memory
// no deinit and no timer destroy for now

pub fn setup() void {
    const allocator = std.heap.page_allocator;

    var hashmap = allocator.create(std.StringHashMap(Self)) catch unreachable;
    hashmap.* = std.StringHashMap(Self).init(allocator);
    instances = hashmap;

    is_ready = true;
}

pub fn startTimer(self: *Self) void {
    self.before = std.time.milliTimestamp();
}

pub fn start(timer_name: []const u8) void {
    if (!is_ready) {
        setup();
    }

    var timer = Self{
        .name = timer_name,
    };

    timer.startTimer();
    instances.put(timer_name, timer) catch unreachable;
}

pub fn end(timer_name: []const u8) void {
    if (!is_ready) {
        setup();
    }

    if (instances.getPtr(timer_name)) |timer| {
        timer.endTimer();
    } else {
        std.log.warn("Trying to end a timer which doesn't exist. Timer name : {s}", .{timer_name});
    }
}

pub fn endTimer(self: *Self) void {
    self.after = std.time.milliTimestamp();

    std.debug.print("\n", .{});
    std.debug.print("\n{s} Results : {} ms", .{ self.name, self.after - self.before });
    std.debug.print("\n", .{});
    std.debug.print("\n", .{});

    self.before = 0;
    self.after = 0;
}
