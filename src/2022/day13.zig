const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;
const print = std.debug.print;
fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

const DEBUG = false;
const Pair = struct {
    index: usize,
    left: []const u8,
    right: []const u8,
};

pub fn part1(input: []const u8, allocator: Allocator) !u32 {
    _ = allocator;
    var lines = std.mem.splitScalar(u8, input, '\n');
    var index: u32 = 1;
    var answer: u32 = 0;
    while (lines.next()) |left| : (index += 1) {
        const right = lines.next() orelse return error.InvalidInput;

        if (try rightOrder(left, right) orelse return error.UndefinedOrder) {
            answer += index;
        }

        _ = lines.next();
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: Allocator) !usize {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var packets = ArrayList([]const u8).init(allocator);
    defer packets.deinit();
    const divider1 = "[[2]]";
    const divider2 = "[[6]]";
    try packets.append(divider1);
    try packets.append(divider2);

    while (lines.next()) |line| {
        if (line.len > 0) try packets.append(line);
    }

    std.mem.sort([]const u8, packets.items, {}, lessThanFn);

    var answer: usize = 1;
    for (packets.items, 1..) |packet, i| {
        if (packet.ptr == divider1) {
            answer *= i;
        } else if (packet.ptr == divider2) {
            answer *= i;
        }
    }

    return answer;
}

fn lessThanFn(_: void, lhs: []const u8, rhs: []const u8) bool {
    return rightOrder(lhs, rhs) catch true orelse true;
}

fn rightOrder(leftSlice: []const u8, rightSlice: []const u8) !?bool {
    if (leftSlice.len == 0 or rightSlice.len == 0) {
        return error.EmptyLeftOrRight;
    }

    // Integers
    if (leftSlice[0] != '[' and rightSlice[0] != '[') {
        const left = try std.fmt.parseInt(u32, leftSlice, 10);
        const right = try std.fmt.parseInt(u32, rightSlice, 10);
        return if (left == right) null else left < right;
    }

    var leftIter = getListItems(leftSlice);
    var rightIter = getListItems(rightSlice);

    while (leftIter.next()) |left| {
        const right = rightIter.next();
        if (right == null) return false;

        const order = try rightOrder(left, right.?);
        if (order != null) return order;
    }
    if (rightIter.next() != null) {
        return true;
    }

    return null;
}

const ListIterator = struct {
    buffer: []const u8,
    index: ?usize,

    /// Returns a slice of the next field, or null if iteration is complete.
    pub fn next(self: *ListIterator) ?[]const u8 {
        if (self.index == null) return null;

        // If the first char isn't a [ then just return the entire buffer
        if (self.index == 0 and (self.buffer.len == 0 or self.buffer[0] != '[')) {
            self.index = null;
            return self.buffer;
        }
        if (self.index == 0) {
            self.index.? += 1;
        }

        const start = self.index.?;

        var depth: usize = 1;
        while (self.index.? < self.buffer.len) : (self.index.? += 1) {
            if (self.buffer[self.index.?] == '[') {
                depth += 1;
            } else if (self.buffer[self.index.?] == ']') {
                depth -= 1;
            } else if (self.buffer[self.index.?] == ',' and depth == 1) {
                defer self.index.? += 1;
                return self.buffer[start..self.index.?];
            }
        }
        defer self.index = null;
        return if (self.index.? - 1 > start) self.buffer[start .. self.index.? - 1] else null;
    }
};

fn getListItems(list: []const u8) ListIterator {
    return ListIterator{ .buffer = list, .index = 0 };
}

test "getListItems" {
    var iter = getListItems("[1,2,[0,0],3]");
    try std.testing.expectEqualSlices(u8, "1", iter.next() orelse return error.IsNull);
    try std.testing.expectEqualSlices(u8, "2", iter.next() orelse return error.IsNull);
    try std.testing.expectEqualSlices(u8, "[0,0]", iter.next() orelse return error.IsNull);
    try std.testing.expectEqualSlices(u8, "3", iter.next() orelse return error.IsNull);
    try std.testing.expectEqual(@as(?[]const u8, null), iter.next());

    iter = getListItems("[]");
    try std.testing.expectEqual(@as(?[]const u8, null), iter.next());
}

test "Part 1 example" {
    const result = try part1(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u32, 13), result);
}

test "Part 2 example" {
    const result = try part2(testInput, testing.allocator);

    try std.testing.expectEqual(@as(usize, 140), result);
}

const testInput =
    \\[1,1,3,1,1]
    \\[1,1,5,1,1]
    \\
    \\[[1],[2,3,4]]
    \\[[1],4]
    \\
    \\[9]
    \\[[8,7,6]]
    \\
    \\[[4,4],4,4]
    \\[[4,4],4,4,4]
    \\
    \\[7,7,7,7]
    \\[7,7,7]
    \\
    \\[]
    \\[3]
    \\
    \\[[[]]]
    \\[[]]
    \\
    \\[1,[2,[3,[4,[5,6,7]]]],8,9]
    \\[1,[2,[3,[4,[5,6,0]]]],8,9]
;
