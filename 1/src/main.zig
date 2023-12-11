const std = @import("std");
const root = @import("./root.zig");

const load_input = root.load_input;
const parse_adanced = root.parse_adanced;
const parse_simple = root.parse_simple;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var patterns = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    var values = std.array_hash_map.StringArrayHashMap(u8).init(allocator);

    for (patterns, 0..) |pattern, index| try values.put(pattern, @truncate(index + 1));

    const buffer: []u8, const size: usize = (try load_input(allocator, "input.txt"));

    const sum1 = parse_simple(buffer, size);
    const sum2 = try parse_adanced(buffer, size, &patterns, values, allocator);

    allocator.free(buffer);
    values.clearAndFree();
    try std.io.getStdOut().writer().print("First part: \t{d}\nSecond part: \t{d}\n", .{ sum1, sum2 });
}
