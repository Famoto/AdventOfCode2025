const std = @import("std");
const testing = std.testing;

fn numDigits(n: u64) u8 {
    var x = n;
    var d: u8 = 1;
    while (x >= 10) {
        x /= 10;
        d += 1;
    }
    return d;
}

fn initPow10() [20]u64 {
    var pow10: [20]u64 = undefined;
    pow10[0] = 1;
    var i: usize = 1;
    while (i < pow10.len) : (i += 1) {
        pow10[i] = pow10[i - 1] * 10;
    }
    return pow10;
}

/// Sums all "double" IDs in [L, R], where the decimal representation of N
/// is some string of digits repeated twice, e.g. 11, 6464, 123123.
fn sumDoubleInRange(L_in: u64, R_in: u64, pow10: []const u64) u64 {
    var L = L_in;
    var R = R_in;
    if (L > R) {
        const tmp = L;
        L = R;
        R = tmp;
    }

    var total: u64 = 0;

    const max_digits = numDigits(R);

    // Consider all even lengths of decimal representation.
    var len: u8 = 2;
    while (len <= max_digits) : (len += 2) {
        const k: usize = len / 2;

        // Guard against pow10 out-of-bounds; u64 never needs more than 20 digits.
        if (k == 0 or k >= pow10.len) break;

        const ten_pow_k = pow10[k];
        const base = ten_pow_k + 1; // N = H * 10^k + H = H * (10^k + 1)

        const half_min = pow10[k - 1]; // smallest k-digit half (no leading zero)
        const half_max = ten_pow_k - 1; // largest  k-digit half

        // Find H such that L <= H*base <= R  (i.e. ceil(L/base) <= H <= floor(R/base))
        var h_low_by_L: u64 = 0;
        if (L > 0) {
            // ceil(L / base) = (L - 1) / base + 1
            h_low_by_L = (L - 1) / base + 1;
        }
        const h_high_by_R: u64 = R / base;

        var H_low = h_low_by_L;
        if (H_low < half_min) H_low = half_min;

        var H_high = h_high_by_R;
        if (H_high > half_max) H_high = half_max;

        if (H_low > H_high) continue;

        var H = H_low;
        while (H <= H_high) : (H += 1) {
            const N = H * ten_pow_k + H;
            if (N >= L and N <= R) {
                total += N;
            }
        }
    }

    return total;
}

/// Part 1 solver: parses all ranges from the input and returns the sum
/// of all invalid "double" IDs.
pub fn solvePart1(input: []const u8) !u64 {
    var pow10 = initPow10();

    var total: u64 = 0;

    // Ranges are separated by commas (and possibly whitespace/newlines).
    var it = std.mem.tokenizeAny(u8, input, ", \n\r\t");
    while (it.next()) |tok| {
        if (tok.len == 0) continue;

        const dash_idx_opt = std.mem.indexOfScalar(u8, tok, '-');
        if (dash_idx_opt) |dash_idx| {
            const a_str = tok[0..dash_idx];
            const b_str = tok[dash_idx + 1 ..];

            const L = try std.fmt.parseInt(u64, a_str, 10);
            const R = try std.fmt.parseInt(u64, b_str, 10);

            total += sumDoubleInRange(L, R, &pow10);
        } else {
            // Malformed piece without '-', ignore or handle as needed.
        }
    }

    return total;
}

fn isPrimitiveBlock(H: u64, t: u8, buf: []u8) bool {
    // fill buf[0..t] with the t-digit decimal representation of H
    var x = H;
    var i: usize = t;
    while (i > 0) : (i -= 1) {
        const digit = @as(u8, @intCast(x % 10));
        buf[i - 1] = '0' + digit;
        x /= 10;
    }

    // Check all proper divisors d of t to see if buf is (buf[0..d]) repeated
    var d: u8 = 1;
    while (d < t) : (d += 1) {
        if (t % d != 0) continue;

        const reps: u8 = t / d;
        var ok = true;

        var r: u8 = 1;
        while (r < reps and ok) : (r += 1) {
            var j: u8 = 0;
            while (j < d) : (j += 1) {
                const idx = @as(usize, r) * d + j;
                if (buf[idx] != buf[j]) {
                    ok = false;
                    break;
                }
            }
        }

        if (ok) {
            // H itself is something like "22" -> "2" repeated
            // => non-primitive block
            return false;
        }
    }

    return true; // no smaller repeating pattern found
}

fn sumRepeatedInRange(L_in: u64, R_in: u64, pow10: []const u64) u64 {
    var L = L_in;
    var R = R_in;
    if (L > R) {
        const tmp = L;
        L = R;
        R = tmp;
    }

    var total: u64 = 0;

    const max_digits = numDigits(R);

    // temp buffer for decimal digits of H, max 20 digits for u64
    var tmp_digits: [20]u8 = undefined;

    var total_len: u8 = 2;
    while (total_len <= max_digits) : (total_len += 1) {
        var t: u8 = 1;
        while (t < total_len) : (t += 1) {
            if (total_len % t != 0) continue;

            const reps = total_len / t;
            if (reps < 2) continue;

            if (t >= pow10.len) break;

            const minH = pow10[t - 1];
            const maxH = pow10[t] - 1;

            // Build multiplier
            var mult: u64 = 0;
            var r: u8 = 0;
            while (r < reps) : (r += 1) {
                mult += pow10[t * (reps - 1 - r)];
            }

            const h_low_by_L: u64 = if (L == 0) 0 else (L - 1) / mult + 1;
            const h_high_by_R: u64 = R / mult;

            var H_low = h_low_by_L;
            if (H_low < minH) H_low = minH;

            var H_high = h_high_by_R;
            if (H_high > maxH) H_high = maxH;

            if (H_low > H_high) continue;

            var H = H_low;
            while (H <= H_high) : (H += 1) {
                // skip non-primitive blocks to avoid duplicates
                if (!isPrimitiveBlock(H, t, tmp_digits[0..t])) continue;

                const N = H * mult;
                if (N >= L and N <= R and numDigits(N) == total_len) {
                    total += N;
                }
            }
        }
    }

    return total;
}

pub fn solvePart2(input: []const u8) !u64 {
    var pow10 = initPow10();

    var total: u64 = 0;

    var it = std.mem.tokenizeAny(u8, input, ", \n\r\t");
    while (it.next()) |tok| {
        if (tok.len == 0) continue;

        const dash_idx_opt = std.mem.indexOfScalar(u8, tok, '-');
        if (dash_idx_opt) |dash_idx| {
            const a_str = tok[0..dash_idx];
            const b_str = tok[dash_idx + 1 ..];

            const L = try std.fmt.parseInt(u64, a_str, 10);
            const R = try std.fmt.parseInt(u64, b_str, 10);

            total += sumRepeatedInRange(L, R, &pow10);
        }
    }

    return total;
}

pub fn runFromFile(
    allocator: std.mem.Allocator,
    path: []const u8,
    part: u8,
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

    std.debug.print("Day 2, part {d}: {d}\n", .{ part, result });
}

// --------------- Tests ----------------

test "sumDoubleInRange simple 11-22" {
    var pow10 = initPow10();
    const got = sumDoubleInRange(11, 22, &pow10);
    // 11 and 22 are the only invalid IDs here: 11 + 22 = 33
    try testing.expectEqual(@as(u64, 33), got);
}

test "solvePart1 example from problem statement" {
    const input =
        "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";

    const got = try solvePart1(input);
    // the sum of all invalid IDs is 1227775554.
    try testing.expectEqual(@as(u64, 1227775554), got);
}

test "solvePart2 example from problem statement" {
    const input =
        "11-22,95-115,998-1012,1188511880-1188511890,222220-222224,1698522-1698528,446443-446449,38593856-38593862,565653-565659,824824821-824824827,2121212118-2121212124";

    const got = try solvePart2(input);
    try testing.expectEqual(@as(u64, 4174379265), got);
}
