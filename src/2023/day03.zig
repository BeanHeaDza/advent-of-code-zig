const std = @import("std");

const NUMBERS = "0123456789";

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    _ = allocator;
    var lines = std.mem.splitScalar(u8, input, '\n');
    var answer: u32 = 0;
    var previous: ?[]const u8 = null;
    while (lines.next()) |line| {
        var start: usize = 0;
        var i = std.mem.indexOfAnyPos(u8, line, start, NUMBERS);
        while (i != null) {
            const end = std.mem.indexOfNonePos(u8, line, i.?, NUMBERS) orelse line.len;
            if (isPart(previous, line, lines.peek(), i.?, end - i.?)) {
                answer += try std.fmt.parseInt(u32, line[i.?..end], 10);
            }
            start = end;
            i = std.mem.indexOfAnyPos(u8, line, start, NUMBERS);
        }

        previous = line;
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    _ = allocator;
    var lines = std.mem.splitScalar(u8, input, '\n');
    var answer: u32 = 0;
    var previous: ?[]const u8 = null;
    while (lines.next()) |line| {
        var i = std.mem.indexOfScalar(u8, line, '*');
        while (i != null) {
            answer += gearValue(previous, line, lines.peek(), i.?);
            i = std.mem.indexOfScalarPos(u8, line, i.? + 1, '*');
        }

        previous = line;
    }

    return answer;
}

const NumberIterator = struct {
    source: []const u8,
    offset: ?usize,
    pub fn next(self: NumberIterator) ?u32 {
        if (self.offset == null) {
            return null;
        }
        const start = std.mem.indexOfAnyPos(u8, self.source, self.offset.?, NUMBERS) orelse {
            self.offset = null;
            return null;
        };
        const end = std.mem.indexOfNonePos(u8, self.source, start, NUMBERS) orelse self.source.len;
        return std.fmt.parseInt(u8, self.source[start..end], 10) catch unreachable;
    }
    pub fn init(source: []const u8) NumberIterator {
        return .{ .source = source, .offset = 0 };
    }
};

fn isPart(previousLine: ?[]const u8, line: []const u8, nextLine: ?[]const u8, offset: usize, length: usize) bool {
    const checkLeft = offset != 0;
    const leftSearchIndex = if (checkLeft) offset - 1 else offset;
    const checkRight = offset + length < line.len;
    const rightSearchIndex = if (checkRight) offset + length + 1 else offset + length;

    if (previousLine != null and hasSymbol(previousLine.?[leftSearchIndex..rightSearchIndex])) {
        return true;
    }
    if (checkLeft and hasSymbol(line[offset - 1 .. offset])) {
        return true;
    }
    if (checkRight and hasSymbol(line[offset + length .. offset + length + 1])) {
        return true;
    }
    return nextLine != null and hasSymbol(nextLine.?[leftSearchIndex..rightSearchIndex]);
}

fn getAdjacentNumbers(optionalLine: ?[]const u8, index: usize) [2]?u32 {
    if (optionalLine == null) {
        return [2]?u32{ null, null };
    }
    const line = optionalLine.?;
    if (line[index] >= '0' and line[index] <= '9') {
        var left = index;
        var right = index + 1;
        while (left > 0 and line[left - 1] >= '0' and line[left - 1] <= '9') {
            left -= 1;
        }
        while (right < line.len and line[right] >= '0' and line[right] <= '9') {
            right += 1;
        }
        const val = std.fmt.parseInt(u32, line[left..right], 10) catch unreachable;
        return [2]?u32{ val, null };
    }
    var leftResult: ?u32 = null;

    if (index > 0 and line[index - 1] >= '0' and line[index - 1] <= '9') {
        var left = index - 1;
        while (left > 0 and line[left - 1] >= '0' and line[left - 1] <= '9') {
            left -= 1;
        }
        leftResult = std.fmt.parseInt(u32, line[left..index], 10) catch unreachable;
    }

    var rightResult: ?u32 = null;
    if (index + 1 < line.len and line[index + 1] >= '0' and line[index + 1] <= '9') {
        var right = index + 2;
        while (right < line.len and line[right] >= '0' and line[right] <= '9') {
            right += 1;
        }
        rightResult = std.fmt.parseInt(u32, line[index + 1 .. right], 10) catch unreachable;
    }
    return if (leftResult == null) [2]?u32{ rightResult, null } else [2]?u32{ leftResult, rightResult };
}

fn gearValue(previousLine: ?[]const u8, line: []const u8, nextLine: ?[]const u8, offset: usize) u32 {
    const numbers = getAdjacentNumbers(previousLine, offset) ++ getAdjacentNumbers(line, offset) ++ getAdjacentNumbers(nextLine, offset);
    var first: ?u32 = null;
    var second: ?u32 = null;
    for (numbers) |number| {
        if (number != null) {
            if (first == null) {
                first = number;
            } else if (second == null) {
                second = number;
            } else {
                return 0;
            }
        }
    }
    if (first != null and second != null) {
        return first.? * second.?;
    }
    return 0;
}

fn hasSymbol(slice: []const u8) bool {
    return null != std.mem.indexOfNone(u8, slice, "0123456789.");
}

test "getAdjacentNumbers" {
    var answer = getAdjacentNumbers(null, 10);
    try std.testing.expectEqual([2]?u32{ null, null }, answer);

    answer = getAdjacentNumbers("123", 1);
    try std.testing.expectEqual([2]?u32{ 123, null }, answer);

    answer = getAdjacentNumbers(".123.", 2);
    try std.testing.expectEqual([2]?u32{ 123, null }, answer);

    answer = getAdjacentNumbers("12.34", 2);
    try std.testing.expectEqual([2]?u32{ 12, 34 }, answer);

    answer = getAdjacentNumbers(".123.", 0);
    try std.testing.expectEqual([2]?u32{ 123, null }, answer);

    answer = getAdjacentNumbers(".123.", 4);
    try std.testing.expectEqual([2]?u32{ 123, null }, answer);
}

test "hasSymbol" {
    const answer = hasSymbol("...*");
    try std.testing.expectEqual(true, answer);
}

test "isPart" {
    const answer = isPart(null, "467.", "...*", 0, 3);
    try std.testing.expectEqual(true, answer);
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 4361), result);
}

test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 467835), result);
}

const testInput =
    \\467..114..
    \\...*......
    \\..35..633.
    \\......#...
    \\617*......
    \\.....+.58.
    \\..592.....
    \\......755.
    \\...$.*....
    \\.664.598..
;
