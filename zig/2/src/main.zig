const std = @import("std");
const root = @import("./root.zig");

const load_input = root.load_input;
const Subset = root.Subset;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    const buffer: []u8, const size: usize = (try load_input(allocator, "input.txt"));
    const games = try root.parse_input(buffer, size, allocator);

    const test_subset = Subset.init(12, 13, 14);

    var sum: usize = 0;
    for (games.items) |game| {
        if (game.is_possible(test_subset)) sum += game.id;
    }

    try std.io.getStdOut().writer().print("First part: {d}\n", .{sum});

    sum = 0;
    for (games.items) |game| {
        sum += game.create_maximum_subset().get_power();
    }

    try std.io.getStdOut().writer().print("Second part: {d}", .{sum});

    allocator.free(buffer);
}
