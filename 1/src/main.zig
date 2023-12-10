const std = @import("std");
const root = @import("./root.zig");

const load_input = root.load_input;
const parse_adanced = root.parse_adanced;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var patterns = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };
    var values = std.array_hash_map.StringArrayHashMap(u8).init(allocator);

    for (patterns, 0..) |pattern, index| {
        try values.put(pattern, @truncate(index + 1));
    }

    const buffer: []u8, const size: usize = (try load_input(allocator, "input.txt"));

    const sum = try parse_adanced(buffer, size, &patterns, values, allocator);

    allocator.free(buffer);
    try std.io.getStdOut().writer().print("{d}", .{sum});
}
