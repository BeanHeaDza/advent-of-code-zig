const std = @import("std");

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var answer: u32 = 0;

    var lines = std.mem.splitAny(u8, input, "\r\n");
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        const numbers = try parseLine(line, allocator);
        defer allocator.free(numbers);

        if (try isValid(numbers, false, null)) {
            answer += 1;
        }
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var answer: u32 = 0;

    var lines = std.mem.splitAny(u8, input, "\r\n");
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }
        const numbers = try parseLine(line, allocator);
        defer allocator.free(numbers);

        if (try isValid(numbers, true, null)) {
            answer += 1;
        }
    }

    return answer;
}

fn parseLine(line: []const u8, allocator: std.mem.Allocator) ![]i32 {
    var nums = std.mem.splitScalar(u8, line, ' ');
    var buffer = std.ArrayList(i32).init(allocator);
    errdefer buffer.deinit();
    while (nums.next()) |numStr| {
        const num = try std.fmt.parseInt(i32, numStr, 10);
        try buffer.append(num);
    }
    return buffer.toOwnedSlice();
}

fn isValid(levels: []i32, useDampener: bool, ignoreIndex: ?usize) !bool {
    if (useDampener and ignoreIndex != null) {
        const i = ignoreIndex.?;
        const temp = levels[i];
        std.mem.copyForwards(i32, levels[i .. levels.len - 1], levels[i + 1 .. levels.len]);
        const result = try isValid(levels[0 .. levels.len - 1], false, null);
        std.mem.copyBackwards(i32, levels[i + 1 .. levels.len], levels[i .. levels.len - 1]);
        levels[i] = temp;
        return result;
    }

    if (levels.len < 2) {
        return true;
    }
    const isIncreasing = levels[0] < levels[1];
    var i: usize = 1;
    while (i < levels.len) : (i += 1) {
        const previous = levels[i - 1];
        const next = levels[i];

        if ((isIncreasing and (next <= previous or next > previous + 3)) or (!isIncreasing and (next >= previous or next < previous - 3))) {
            if (useDampener) {
                for (0..levels.len) |x| {
                    if (try isValid(levels, true, x)) {
                        return true;
                    }
                }
                return false;
            }
            return false;
        }
    }
    return true;
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 2), result);
}

test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 4), result);
}

const testInput =
    \\7 6 4 2 1
    \\1 2 7 8 9
    \\9 7 6 2 1
    \\1 3 2 4 5
    \\8 6 4 4 1
    \\1 3 6 7 9
;
