const std = @import("std");

pub fn contains(comptime T: type, list: std.ArrayList(T), item: T, comp: fn (first: T, second: T) bool) bool {
    for (list.items) |element| {
        if (comp(item, element)) return true;
    }

    return false;
}

pub fn intersection(comptime T: type, first: std.ArrayList(T), second: std.ArrayList(T), comptime comp: fn (first: T, second: T) bool) usize {
    var count: usize = 0;
    for (first.items) |element| {
        if (contains(T, second, element, comp)) count += 1;
    }
    return count;
}

pub const Card = struct {
    id: usize,
    count: usize,
    winning: std.ArrayList(usize),
    current: std.ArrayList(usize),

    pub fn init(id: usize, allocator: std.mem.Allocator) Card {
        return Card{ .id = id, .winning = std.ArrayList(usize).init(allocator), .current = std.ArrayList(usize).init(allocator), .count = 1 };
    }

    pub fn compare_usizes(first: usize, second: usize) bool {
        return first == second;
    }

    pub fn get_value(self: Card) usize {
        return intersection(usize, self.winning, self.current, Card.compare_usizes);
    }
};

pub fn load_input(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const input = try std.fs.cwd().openFile(name, .{});
    const stats = try input.stat();
    const buffer = try allocator.alloc(u8, stats.size);

    _ = try input.reader().read(buffer);

    return buffer;
}

pub fn parse_file(buffer: []u8, allocator: std.mem.Allocator) !std.ArrayList(Card) {
    var cards = std.ArrayList(Card).init(allocator);

    var iter = std.mem.splitScalar(u8, buffer, '\n');
    while (iter.next()) |entry| {
        var parts = std.mem.splitAny(u8, entry, ":|");

        var part_iter = std.mem.splitScalar(u8, parts.next().?, ' ');

        _ = part_iter.next().?;
        var id = part_iter.next().?;
        while (id.len == 0) {
            id = part_iter.next().?;
        }

        var card = Card.init((try std.fmt.parseInt(usize, id, 10)), allocator);

        part_iter = std.mem.splitScalar(u8, parts.next().?, ' ');
        while (part_iter.next()) |sub_part| {
            if (sub_part.len != 0) {
                try card.winning.append(try std.fmt.parseInt(usize, sub_part, 10));
            }
        }

        part_iter = std.mem.splitScalar(u8, parts.next().?, ' ');
        while (part_iter.next()) |sub_part| {
            if (sub_part.len != 0) {
                try card.current.append(try std.fmt.parseInt(usize, sub_part, 10));
            }
        }

        try cards.append(card);
    }
    return cards;
}
