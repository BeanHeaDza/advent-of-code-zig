const std = @import("std");

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    _ = allocator;
    var index: ?usize = 0;
    var answer: u32 = 0;

    while (std.mem.indexOfPos(u8, input, index.?, "mul(")) |i| {
        index = i + 4;
        const end = std.mem.indexOfScalarPos(u8, input, index.?, ')');
        if (end == null) break;

        if (execMul(input[index.?..end.?])) |product| {
            answer += product;
        }
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var index: ?usize = 0;
    var answer: u32 = 0;

    const disabledRanges = try getDisabledRanges(input, allocator);
    defer allocator.free(disabledRanges);
    var disableIndex: usize = 0;

    while (std.mem.indexOfPos(u8, input, index.?, "mul(")) |i| {
        index = i + 4;

        while (disableIndex < disabledRanges.len and index.? > disabledRanges[disableIndex][1]) {
            disableIndex += 1;
        }

        if (disableIndex < disabledRanges.len) {
            if (index.? >= disabledRanges[disableIndex][0] and index.? <= disabledRanges[disableIndex][1]) {
                continue;
            }
        }

        const end = std.mem.indexOfScalarPos(u8, input, index.?, ')');
        if (end == null) break;

        if (execMul(input[index.?..end.?])) |product| {
            answer += product;
        }
    }

    return answer;
}

fn getDisabledRanges(input: []const u8, allocator: std.mem.Allocator) ![][2]usize {
    var list = std.ArrayList([2]usize).init(allocator);
    errdefer list.deinit();

    var i: ?usize = 0;
    while (true) {
        const start = std.mem.indexOfPos(u8, input, i.?, "don't()") orelse break;
        const end = std.mem.indexOfPos(u8, input, i.? + 7, "do()") orelse input.len;

        try list.append([2]usize{ start, end });

        i = end + 4;
    }

    return list.toOwnedSlice();
}

fn execMul(insideMul: []const u8) ?u32 {
    var nums = std.mem.splitScalar(u8, insideMul, ',');
    var product: u32 = 1;
    while (nums.next()) |numStr| {
        product *= std.fmt.parseInt(u32, numStr, 10) catch return null;
    }
    return product;
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 161), result);
}

test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 48), result);
}

const testInput =
    \\xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))
;
