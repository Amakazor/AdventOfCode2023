const std = @import("std");

pub const Location = struct {
    x: usize,

    pub fn init(x: usize) Location {
        return Location{
            .x = x,
        };
    }

    pub fn equals(self: Location, other: Location) bool {
        return self.x == other.x;
    }
};

pub const Gear = struct {
    neighbors: std.ArrayList(usize),
    location: Location,

    pub fn init(allocator: std.mem.Allocator, location: Location, neighbor: usize) !Gear {
        var gear = Gear{
            .neighbors = std.ArrayList(usize).init(allocator),
            .location = location,
        };

        try gear.neighbors.append(neighbor);
        return gear;
    }

    pub fn is_located(self: Gear, other: Location) bool {
        return self.location.equals(other);
    }

    pub fn ratio(self: Gear) usize {
        if (self.neighbors.items.len == 2) {
            return self.neighbors.items[0] * self.neighbors.items[1];
        }
        return 0;
    }
};

pub const Part = struct {
    slice: []u8,
    neighbors_conut: usize = 0,

    pub fn init(slice: []u8, neighbors_conut: usize) Part {
        return Part{
            .slice = slice,
            .neighbors_conut = neighbors_conut,
        };
    }

    pub fn get_value(self: Part) !usize {
        return std.fmt.parseInt(usize, self.slice, 10);
    }
};

pub fn load_input(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const input = try std.fs.cwd().openFile(name, .{});
    const stats = try input.stat();
    const buffer = try allocator.alloc(u8, stats.size);

    _ = try input.reader().read(buffer);

    return buffer;
}

pub fn parse_input(buffer: []u8, allocator: std.mem.Allocator) !std.meta.Tuple(&.{ std.ArrayList(Part), std.ArrayList(Gear) }) {
    var parts = std.ArrayList(Part).init(allocator);
    var gears = std.ArrayList(Gear).init(allocator);

    var line_length: usize = 0;

    var iter: usize = 0;
    while (iter < buffer.len and line_length == 0) : (iter += 1) {
        if (buffer[iter] == '\n') line_length = iter + 1;
    }

    iter = 0;
    var start_index: usize = std.math.maxInt(usize);
    var end_index: usize = std.math.maxInt(usize);
    while (iter < buffer.len) : (iter += 1) {
        const symbol = buffer[iter];
        if (std.ascii.isDigit(symbol) and start_index == std.math.maxInt(usize)) {
            start_index = iter;
        }
        if (!std.ascii.isDigit(symbol) and start_index != std.math.maxInt(usize)) {
            end_index = iter - 1;
            const line = @divFloor(iter, line_length);

            const start_in_line = start_index - line * line_length;
            const end_in_line = end_index - line * line_length;

            const value = try get_neighbors_value(buffer, start_in_line, end_in_line, line_length, line, &gears, try std.fmt.parseInt(usize, buffer[start_index .. end_index + 1], 10), allocator);

            try parts.append(Part.init(buffer[start_index .. end_index + 1], value));

            start_index = std.math.maxInt(usize);
            end_index = std.math.maxInt(usize);
        }
    }
    return .{ parts, gears };
}

fn is_valid_neighbor(line_offset: isize, current_line: usize, start: usize, end: usize, val: usize, line_length: usize, buffer_length: usize) bool {
    const first_line_clause = line_offset == -1 and current_line > 0;
    const second_line_clause = (line_offset == 0 and ((start > 0 and val == start - 1) or val == end + 1));
    const third_line_clause = line_offset == 1 and ((current_line + 1) * line_length + val) < buffer_length;

    return first_line_clause or second_line_clause or third_line_clause;
}

fn find_and_append_neighbor(gears: *std.ArrayList(Gear), new_location: Location, value: usize) !bool {
    var found: bool = false;
    for (gears.*.items) |*gear| {
        if (gear.is_located(new_location)) {
            found = true;
            try gear.neighbors.append(value);
            break;
        }
    }

    return found;
}

pub fn get_neighbors_value(buffer: []u8, start: usize, end: usize, line_length: usize, current_line: usize, gears: *std.ArrayList(Gear), value: usize, allocator: std.mem.Allocator) !usize {
    var sum: usize = 0;

    for (0..3) |line_offset_raw| {
        const line_offset: isize = @as(isize, @intCast(line_offset_raw)) - 1;

        for ((if (start > 0) start - 1 else start)..(end + 2)) |val| {
            if (is_valid_neighbor(line_offset, current_line, start, end, val, line_length, buffer.len)) {
                const offset_line = @as(usize, @intCast(@as(isize, @intCast(current_line)) + line_offset));
                const symbol = buffer[offset_line * line_length + val];
                if (symbol != '.' and symbol != '\n') sum += 1;
                if (symbol == '*') {
                    const new_location: Location = Location.init(offset_line * line_length + val);

                    if (!(try find_and_append_neighbor(gears, new_location, value))) {
                        try gears.append(try Gear.init(allocator, new_location, value));
                    }
                }
            }
        }
    }
    return sum;
}
