const std = @import("std");
const root = @import("./root.zig");

const load_input = root.load_input;
const parse_input = root.parse_input;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    const buffer = try load_input(allocator, "input.txt");

    const parts: std.ArrayList(root.Part), const gears: std.ArrayList(root.Gear) = (try parse_input(buffer, allocator));

    var sum: usize = 0;
    for (parts.items) |part| {
        if (part.neighbors_conut > 0) sum += try part.get_value();
    }
    try std.io.getStdOut().writer().print("First part: {d}\n", .{sum});

    sum = 0;
    for (gears.items) |gear| sum += gear.ratio();
    try std.io.getStdOut().writer().print("Second part: {d}\n", .{sum});

    allocator.free(buffer);
}
