const std = @import("std");

pub fn solvePart1(input: []const u8) !u32 {
    var count_zero: u32 = 0;
    var pos: i32 = 50; // dial starts at 50
    const N = 100;

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \r\t");
        if (line.len == 0) continue;

        const dir = line[0];
        if (line.len < 2) return error.InvalidInstruction;

        const num_slice = std.mem.trim(u8, line[1..], " \t\r");
        const dist_u = try std.fmt.parseInt(u32, num_slice, 10);
        const dist_mod: i32 = @intCast(dist_u % 100);

        switch (dir) {
            'L' => pos = @mod(pos - dist_mod, N),
            'R' => pos = @mod(pos + dist_mod, N),
            else => return error.InvalidDirection,
        }

        if (pos == 0) count_zero += 1;
    }

    return count_zero;
}

pub fn solvePart2(input: []const u8) !u32 {
    var count_zero: u32 = 0;
    var pos: u32 = 50; // always 0..99
    const N: u32 = 100;

    var it = std.mem.tokenizeScalar(u8, input, '\n');
    while (it.next()) |line_raw| {
        const line = std.mem.trim(u8, line_raw, " \r\t");
        if (line.len == 0) continue;

        const dir = line[0];
        if (line.len < 2) return error.InvalidInstruction;

        const num_slice = std.mem.trim(u8, line[1..], " \t\r");
        const dist_u = try std.fmt.parseInt(u32, num_slice, 10);

        // Count ALL clicks hitting 0
        count_zero += countZeroClicks(pos, dist_u, dir);

        // Now move the dial (only mod 100 matters)
        const dist_mod = dist_u % N;
        switch (dir) {
            'L' => pos = (pos + N - dist_mod) % N,
            'R' => pos = (pos + dist_mod) % N,
            else => return error.InvalidDirection,
        }
    }

    return count_zero;
}

fn countZeroClicks(start_pos: u32, dist: u32, dir: u8) u32 {
    const N: u32 = 100;

    if (dist == 0) return 0;

    return switch (dir) {
        'R' => (start_pos + dist) / N,
        'L' => (((N - (start_pos % N)) % N) + dist) / N,
        else => unreachable,
    };
}

pub fn runFromFile(
    allocator: std.mem.Allocator,
    path: []const u8,
    part: u8, // 1 or 2
) !void {
    const cwd = std.fs.cwd();
    const limit: std.Io.Limit = @enumFromInt(std.math.maxInt(usize));

    const data = try cwd.readFileAlloc(path, allocator, limit);
    defer allocator.free(data);

    const result = switch (part) {
        1 => try solvePart1(data),
        2 => try solvePart2(data),
        else => return error.InvalidPart,
    };

    std.debug.print("Day 1, part {d}: {d}\n", .{ part, result });
}

test "day1 example part1" {
    const example =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;

    const got = try solvePart1(example);
    try std.testing.expectEqual(@as(u32, 3), got);
}

test "day1 example part2" {
    const example =
        \\L68
        \\L30
        \\R48
        \\L5
        \\R60
        \\L55
        \\L1
        \\L99
        \\R14
        \\L82
    ;

    const got = try solvePart2(example);
    try std.testing.expectEqual(@as(u32, 6), got);
}
