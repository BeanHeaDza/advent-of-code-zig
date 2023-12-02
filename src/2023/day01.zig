const std = @import("std");

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var answer: u32 = 0;
    var numbers = std.ArrayList(u8).init(allocator);
    defer numbers.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        numbers.clearRetainingCapacity();
        // This can be faster, instead of doing all the numbers just do the first from the left and first from the right
        for (line) |c| {
            if (c >= '1' and c <= '9') {
                try numbers.append(c - '0');
            }
        }

        answer += numbers.items[0] * 10 + numbers.items[numbers.items.len - 1];
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    _ = allocator;
    var answer: u32 = 0;

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var left: ?u8 = null;
        var right: ?u8 = null;
        var index: usize = 0;
        while (left == null) : (index += 1) {
            left = getFakeDigitAtIndex(line, index);
        }
        index = line.len;
        while (right == null) {
            index -= 1;
            right = getFakeDigitAtIndex(line, index);
        }
        answer += left.? * 10 + right.?;
    }

    return answer;
}

fn getFakeDigitAtIndex(line: []const u8, index: usize) ?u8 {
    const c = line[index];
    // I should check if doing a inline for (comptime) would still execute in the same time as this code
    if (c >= '1' and c <= '9') {
        return c - '0';
    } else if (eql(line, index, "one")) {
        return 1;
    } else if (eql(line, index, "two")) {
        return 2;
    } else if (eql(line, index, "three")) {
        return 3;
    } else if (eql(line, index, "four")) {
        return 4;
    } else if (eql(line, index, "five")) {
        return 5;
    } else if (eql(line, index, "six")) {
        return 6;
    } else if (eql(line, index, "seven")) {
        return 7;
    } else if (eql(line, index, "eight")) {
        return 8;
    } else if (eql(line, index, "nine")) {
        return 9;
    }
    return null;
}

inline fn eql(line: []const u8, offset: usize, comptime value: []const u8) bool {
    if (line.len < offset + value.len or line[offset] != value[0]) {
        return false;
    }
    return std.mem.eql(u8, line[offset .. offset + value.len], value);
}

test "Part 1 example" {
    var result = try part1(testInput1, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 142), result);
}

const testInput1 =
    \\1abc2
    \\pqr3stu8vwx
    \\a1b2c3d4e5f
    \\treb7uchet
;

test "Part 2 example" {
    var result = try part2(testInput2, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 281), result);
}

const testInput2 =
    \\two1nine
    \\eightwothree
    \\abcone2threexyz
    \\xtwone3four
    \\4nineeightseven2
    \\zoneight234
    \\7pqrstsixteen
;

test "reverse while loop" {
    const input = "abc";
    var index: usize = input.len - 1;

    var aIndex: ?usize = null;
    while (aIndex == null) : (index -= 1) {
        if (input[index] == 'a') {}
    }
}
