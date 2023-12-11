const std = @import("std");

const Patterns = [][]const u8;
const PatternsPtr = *const [][]const u8;

const Match = struct { full: bool, matched: []const u8 };

pub fn load_input(allocator: std.mem.Allocator, name: []const u8) !std.meta.Tuple(&.{ []u8, usize }) {
    const input = try std.fs.cwd().openFile(name, .{});
    const stats = try input.stat();
    const buffer = try allocator.alloc(u8, stats.size);

    const size = try input.reader().read(buffer);

    return .{ buffer, size };
}

pub fn parse_simple(buffer: []u8, size: usize) usize {
    var iter: usize = 0;
    var digits = [_]u8{ 0, 0 };
    var sum: usize = 0;

    while (iter < size) : (iter += 1) {
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
    }
    return sum;
}

const PatternBuffer = struct {
    buffer: []u8,
    length: u8,
    patterns: PatternsPtr,

    pub fn init(size: u8, allocator: std.mem.Allocator, patterns: PatternsPtr) !*PatternBuffer {
        var allocatedBuffer = try allocator.create(PatternBuffer);
        const allocatedInnerBuffer = try allocator.alloc(u8, size);

        allocatedBuffer.buffer = allocatedInnerBuffer;
        allocatedBuffer.length = 0;
        allocatedBuffer.patterns = patterns;

        return allocatedBuffer;
    }

    pub fn put(self: *PatternBuffer, symbol: u8) void {
        self.buffer[self.length] = symbol;
        self.length += 1;
    }

    pub fn reset(self: *PatternBuffer) void {
        self.length = 0;
    }

    pub fn is_empty(self: *PatternBuffer) bool {
        return self.length == 0;
    }

    pub fn match(self: *PatternBuffer) ?Match {
        if (!self.is_empty()) {
            for (self.patterns.*) |pattern| {
                if (pattern.len >= self.length and std.mem.eql(u8, self.buffer[0..self.length], pattern[0..self.length])) {
                    return Match{ .matched = pattern, .full = self.length == pattern.len };
                }
            }
        }
        return null;
    }
};

const PatternBuffers = struct {
    buffers: std.ArrayList(*PatternBuffer),
    allocator: std.mem.Allocator,
    buffer_size: u8,
    patterns: PatternsPtr,
    recently_emptied: usize,

    pub fn init(size: u8, buffer_size: u8, allocator: std.mem.Allocator, patterns: PatternsPtr) !*PatternBuffers {
        const allocated_buffers = try allocator.create(PatternBuffers);
        allocated_buffers.allocator = allocator;
        allocated_buffers.buffer_size = buffer_size;
        allocated_buffers.patterns = patterns;
        allocated_buffers.buffers = std.ArrayList(*PatternBuffer).init(allocator);
        allocated_buffers.recently_emptied = 0;

        var addr = try allocated_buffers.buffers.addManyAsSlice(size);

        var iter: u8 = 0;
        while (iter < size) : (iter += 1) {
            addr[iter] = try PatternBuffer.init(allocated_buffers.buffer_size, allocated_buffers.allocator, allocated_buffers.patterns);
        }
        return allocated_buffers;
    }

    pub fn reset(self: *PatternBuffers) void {
        for (self.buffers.items) |buffer| buffer.reset();
    }

    pub fn match(self: *PatternBuffers) ?Match {
        var to_return: ?Match = null;
        for (self.buffers.items, 0..) |buffer, i| {
            const match_result = buffer.match();
            if (match_result) |result| {
                if (result.full) {
                    to_return = result;
                    buffer.reset();
                    self.recently_emptied = @as(u8, @truncate(i));
                }
            } else if (match_result == null) {
                buffer.reset();
                self.recently_emptied = @as(u8, @truncate(i));
            }
        }
        return to_return;
    }

    fn find_or_create_empty(self: *PatternBuffers) !usize {
        var items = self.buffers.items;
        const size = items.len;
        var iter: usize = 0;
        while (iter < size) : (iter += 1) {
            if (items[iter].is_empty()) return iter;
        }
        _ = try self.buffers.addOne();
        const new_buffer = try PatternBuffer.init(self.buffer_size, self.allocator, self.patterns);
        self.buffers.items[size] = new_buffer;
        return size;
    }

    fn put_symbol(self: *PatternBuffers, symbol: u8) !void {
        for (self.buffers.items) |buffer| {
            if (!buffer.is_empty()) buffer.put(symbol);
        }
        const empty = if (self.recently_emptied != std.math.maxInt(usize)) self.recently_emptied else try self.find_or_create_empty();
        self.recently_emptied = std.math.maxInt(usize);
        self.buffers.items[empty].put(symbol);
    }

    fn free(self: *PatternBuffers) void {
        for (self.buffers.items) |buffer| {
            self.allocator.free(buffer.buffer);
            self.allocator.destroy(buffer);
        }
    }
};

pub fn parse_adanced(buffer: []u8, size: usize, patterns: Patterns, values: std.array_hash_map.StringArrayHashMap(u8), allocator: std.mem.Allocator) !usize {
    const pattern_buffers = try PatternBuffers.init(2, 8, allocator, &patterns);

    var line: usize = 0;
    var iter: usize = 0;
    var digits = [_]u8{ 0, 0 };
    var sum: usize = 0;

    while (iter < size) : (iter += 1) {
        const symbol = buffer[iter];

        if (symbol == '\n') {
            const line_sum = if (std.fmt.parseInt(u8, &digits, 10)) |result| result else |_| 0;
            sum += line_sum;
            line += 1;
            digits[0] = 0;
            digits[1] = 0;
            pattern_buffers.reset();
        }

        if (std.ascii.isDigit(symbol)) {
            if (digits[0] == 0) digits[0] = symbol;
            digits[1] = symbol;
        }

        try pattern_buffers.put_symbol(symbol);
        const optional_match = pattern_buffers.match();

        if (optional_match) |match| {
            if (match.full) {
                const value = std.fmt.digitToChar(values.get(match.matched).?, std.fmt.Case.lower);
                if (digits[0] == 0) digits[0] = value;
                digits[1] = value;
            }
        }
    }

    pattern_buffers.free();
    allocator.destroy(pattern_buffers);
    return sum;
}
