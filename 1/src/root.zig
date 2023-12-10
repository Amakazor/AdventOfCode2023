const std = @import("std");

const Match = struct { partial: bool, full: bool, matched: []const u8 };

pub fn load_input(allocator: std.mem.Allocator, name: []const u8) !std.meta.Tuple(&.{ []u8, usize }) {
    const input = try std.fs.cwd().openFile(name, .{});
    const stats = try input.stat();
    const buffer = try allocator.alloc(u8, stats.size);

    const size = try input.reader().read(buffer);

    return .{ buffer, size };
}

pub fn matches_pattern(buffer: []u8, length: usize, patterns: [][]const u8) Match {
    for (patterns) |pattern| {
        if (pattern.len >= length and std.mem.eql(u8, buffer[0..length], pattern[0..length])) {
            return Match{ .partial = true, .matched = pattern, .full = length == pattern.len };
        }
    }
    return Match{ .partial = false, .full = false, .matched = "" };
}

pub fn parse_simple(buffer: []u8, size: usize) usize {
    var iter: usize = 0;
    var digits = [_]u8{ 0, 0 };
    var sum: usize = 0;

    while (iter < size) {
        const symbol = buffer[iter];
        if (symbol == '\n') {
            sum += if (std.fmt.parseInt(u8, &digits, 10)) |result| result else |_| 0;
            digits[0] = 0;
            digits[1] = 0;
        }
        if (std.ascii.isDigit(symbol)) {
            if (digits[0] == 0) digits[0] = symbol;
            digits[1] = symbol;
        }

        iter += 1;
    }

    return sum;
}

pub fn parse_adanced(buffer: []u8, size: usize, patterns: [][]const u8, values: std.array_hash_map.StringArrayHashMap(u8), allocator: std.mem.Allocator) !usize {
    var line: usize = 0;
    var iter: usize = 0;
    var cached_iter: usize = 0;
    var digits = [_]u8{ 0, 0 };
    var sum: usize = 0;
    var pattern_buffer = try allocator.alloc(u8, 256);
    var pattern_length: u8 = 0;
    while (iter < size) {
        const symbol = buffer[iter];

        if (symbol == '\n') {
            const line_sum = if (std.fmt.parseInt(u8, &digits, 10)) |result| result else |_| 0;
            sum += line_sum;
            line += 1;
            digits[0] = 0;
            digits[1] = 0;
            pattern_length = 0;
            cached_iter = 0;
        }

        if (std.ascii.isDigit(symbol)) {
            if (digits[0] == 0) digits[0] = symbol;
            digits[1] = symbol;
        }

        pattern_buffer[pattern_length] = symbol;
        pattern_length += 1;

        const match = matches_pattern(pattern_buffer, pattern_length, patterns);
        if (match.partial) {
            if (pattern_length == 1) {
                cached_iter = iter;
            }
            if (match.full) {
                const value = std.fmt.digitToChar(values.get(match.matched).?, std.fmt.Case.lower);
                if (digits[0] == 0) digits[0] = value;
                digits[1] = value;
                pattern_length = 0;
                iter = cached_iter;
                cached_iter = 0;
            }
        } else {
            if (pattern_length > 1 and cached_iter != 0) {
                iter = cached_iter;
                cached_iter = 0;
            }
            pattern_length = 0;
        }

        iter += 1;
    }
    return sum;
}
