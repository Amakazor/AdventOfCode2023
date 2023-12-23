const std = @import("std");
const root = @import("./root.zig");

const load_input = root.load_input;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    const buffer = try load_input(allocator, "input.txt");
    var cards = try root.parse_file(buffer, allocator);

    var sum: usize = 0;
    for (cards.items) |card| {
        const points = if (card.get_value() > 0) @as(usize, 1) << @as(u5, @intCast(card.get_value() - 1)) else 0;
        sum += points;
    }

    var cards_map = std.AutoHashMap(usize, *root.Card).init(allocator);
    for ((&cards).items) |*card| {
        try cards_map.put(card.id, card);
    }

    try std.io.getStdOut().writer().print("First part: {d}\n", .{sum});

    for ((&cards).items) |*card| {
        const points = card.get_value();
        if (points == 0) continue;

        for (1..points + 1) |iter| {
            if (cards_map.get(card.id + iter)) |new_card| {
                new_card.*.count += card.count;
            }
        }
    }

    for (cards.items) |card| {
        sum += card.count;
    }

    try std.io.getStdOut().writer().print("Second part: {d}\n", .{sum});

    allocator.free(buffer);
}
