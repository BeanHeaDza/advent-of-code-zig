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
    if (c >= '1' and c <= '9') {
        return c - '0';
    }

    inline for ([_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" }, 1..) |digitText, digitValue| {
        const value = comptime std.math.cast(u8, digitValue) orelse @compileError("Failed to cast value to u8");
        if (line.len >= index + digitText.len and line[index] == digitText[0] and std.mem.eql(u8, line[index .. index + digitText.len], digitText)) {
            return value;
        }
    }
    return null;
}

test "Part 1 example" {
    const result = try part1(testInput1, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 142), result);
}

const testInput1 =
    \\1abc2
    \\pqr3stu8vwx
    \\a1b2c3d4e5f
    \\treb7uchet
;

test "Part 2 example" {
    const result = try part2(testInput2, std.testing.allocator);

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
