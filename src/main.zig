const std = @import("std");
const day1 = @import("day1.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Day 1 timing - Part 1
    var timer = try std.time.Timer.start();
    try day1.runFromFile(allocator, "input/day1.txt", 1);
    var ns: u64 = timer.read();

    var ms_f: f64 = @as(f64, @floatFromInt(ns)) / 1_000_000.0;
    std.debug.print("Day 1 Part 1 took {d:.3} ms\n", .{ms_f});

    // Day 1 timing - Part 2
    timer.reset(); // <-- FIXED
    try day1.runFromFile(allocator, "input/day1.txt", 2);
    ns = timer.read();

    ms_f = @as(f64, @floatFromInt(ns)) / 1_000_000.0;
    std.debug.print("Day 1 Part 2 took {d:.3} ms\n", .{ms_f});
}
