const std = @import("std");

pub fn load_input(allocator: std.mem.Allocator, name: []const u8) !std.meta.Tuple(&.{ []u8, usize }) {
    const input = try std.fs.cwd().openFile(name, .{});
    const stats = try input.stat();
    const buffer = try allocator.alloc(u8, stats.size);

    const size = try input.reader().read(buffer);

    return .{ buffer, size };
}

pub const Game = struct {
    id: usize,
    subsets: std.ArrayList(Subset),

    pub fn init(id: usize, allocator: std.mem.Allocator) Game {
        return Game{ .id = id, .subsets = std.ArrayList(Subset).init(allocator) };
    }

    pub fn is_possible(self: Game, test_subset: Subset) bool {
        for (self.subsets.items) |subset| if (!subset.fits_in(test_subset)) return false;
        return true;
    }

    pub fn create_maximum_subset(self: Game) Subset {
        var maximum_subset = Subset.init(0, 0, 0);
        for (self.subsets.items) |subset| {
            if (subset.red > maximum_subset.red) maximum_subset.red = subset.red;
            if (subset.green > maximum_subset.green) maximum_subset.green = subset.green;
            if (subset.blue > maximum_subset.blue) maximum_subset.blue = subset.blue;
        }

        return maximum_subset;
    }
};

pub const Subset = struct {
    red: usize,
    green: usize,
    blue: usize,

    pub fn init(red: usize, green: usize, blue: usize) Subset {
        return Subset{
            .red = red,
            .green = green,
            .blue = blue,
        };
    }

    pub fn fits_in(self: Subset, test_subset: Subset) bool {
        return self.blue <= test_subset.blue and self.red <= test_subset.red and self.green <= test_subset.green;
    }

    pub fn get_power(self: Subset) usize {
        return self.blue * self.green * self.red;
    }
};

pub fn parse_subset(buffer: []u8, allocator: std.mem.Allocator) !Subset {
    _ = allocator;

    var red: usize = 0;
    var green: usize = 0;
    var blue: usize = 0;

    var item_start: usize = 0;
    const length = buffer.len - 1;
    for (buffer, 0..) |symbol, i| {
        if (symbol == ',' or i == length) {
            const item = buffer[item_start..i];
            const item_length = item.len;

            if (std.mem.eql(u8, item[item_length - 3 ..], "red"))
                red = try std.fmt.parseInt(u8, item[0 .. item_length - 4], 10)
            else if (std.mem.eql(u8, item[item_length - 5 ..], "green"))
                green = try std.fmt.parseInt(u8, item[0 .. item_length - 6], 10)
            else if (std.mem.eql(u8, item[item_length - 4 ..], "blue"))
                blue = try std.fmt.parseInt(u8, item[0 .. item_length - 5], 10);

            item_start = i + 2;
        }
    }
    return Subset.init(red, green, blue);
}

pub fn parse_line(buffer: []u8, size: usize, allocator: std.mem.Allocator) !Game {
    var iterator: usize = 0;
    while (iterator < size) : (iterator += 1) {
        if (buffer[iterator] == ':') break;
    }
    var game = Game.init(try std.fmt.parseInt(usize, buffer[5..iterator], 10), allocator);

    iterator += 2;
    var subset_start: usize = iterator;
    while (iterator < size) : (iterator += 1) {
        const symbol: u8 = buffer[iterator];
        if (symbol == ';' or symbol == '\n') {
            if (symbol == '\n') iterator -= 1;
            try game.subsets.append(try parse_subset(buffer[subset_start .. iterator + 1], allocator));
            if (symbol == '\n') break;
            subset_start = iterator + 2;
        }
    }
    return game;
}

pub fn parse_input(buffer: []u8, size: usize, allocator: std.mem.Allocator) !std.ArrayList(Game) {
    var games = std.ArrayList(Game).init(allocator);

    var line_buffer = try allocator.alloc(u8, 255);
    var line_size: usize = 0;

    var iterator: usize = 0;
    while (iterator < size) : (iterator += 1) {
        const symbol: u8 = buffer[iterator];

        line_buffer[line_size] = symbol;
        line_size += 1;

        if (symbol == '\n') {
            line_buffer[line_size] = symbol;
            try games.append(try parse_line(line_buffer, line_size, allocator));
            line_size = 0;
        }
    }

    return games;
}
