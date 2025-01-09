const std = @import("std");

const DIGITS = "0123456789";

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var answer: u32 = 0;
    var leftList = std.ArrayList(u32).init(allocator);
    defer leftList.deinit();
    var rightList = std.ArrayList(u32).init(allocator);
    defer rightList.deinit();
    while (lines.next()) |line| {
        var index = std.mem.indexOfNone(u8, line, DIGITS) orelse return error.NoSpaceInInput;
        const left = try std.fmt.parseInt(u32, line[0..index], 10);
        try leftList.append(left);
        index = std.mem.indexOfAnyPos(u8, line, index, DIGITS) orelse return error.NoSecondInt;
        const end = std.mem.lastIndexOfAny(u8, line, DIGITS) orelse return error.BadInputNoDigits;
        const right = try std.fmt.parseInt(u32, line[index .. end + 1], 10);
        try rightList.append(right);
    }
    std.mem.sort(u32, leftList.items, {}, lessThan);
    std.mem.sort(u32, rightList.items, {}, lessThan);
    for (leftList.items, 0..) |left, i| {
        const right = rightList.items[i];
        answer += if (right > left) right - left else left - right;
    }
    return answer;
}
pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var answer: u32 = 0;
    var leftList = std.ArrayList(u32).init(allocator);
    defer leftList.deinit();
    var rightList = std.ArrayList(u32).init(allocator);
    defer rightList.deinit();
    while (lines.next()) |line| {
        var index = std.mem.indexOfNone(u8, line, DIGITS) orelse return error.NoSpaceInInput;
        const left = try std.fmt.parseInt(u32, line[0..index], 10);
        try leftList.append(left);
        index = std.mem.indexOfAnyPos(u8, line, index, DIGITS) orelse return error.NoSecondInt;
        const end = std.mem.lastIndexOfAny(u8, line, DIGITS) orelse return error.BadInputNoDigits;
        const right = try std.fmt.parseInt(u32, line[index .. end + 1], 10);
        try rightList.append(right);
    }
    std.mem.sort(u32, rightList.items, {}, lessThan);
    for (leftList.items) |left| {
        const startIndex = std.mem.indexOfScalar(u32, rightList.items, left);
        const start: ?u32 = if (startIndex != null) @intCast(startIndex.?) else null;
        const endIndex = std.mem.lastIndexOfScalar(u32, rightList.items, left);
        const end: ?u32 = if (endIndex != null) @intCast(endIndex.?) else null;
        if (start != null) {
            answer += left * (end.? - start.? + 1);
        }
    }
    return answer;
}

fn lessThan(_: void, lhs: u32, rhs: u32) bool {
    return lhs < rhs;
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 11), result);
}
test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 31), result);
}

const testInput =
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
;
