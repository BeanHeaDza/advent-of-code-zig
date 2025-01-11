const std = @import("std");

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var answer: i64 = 0;
    while (lines.next()) |line| {
        var next: i64 = 0;
        var parsed = std.ArrayList(i64).init(allocator);
        defer parsed.deinit();
        var numbers = std.mem.splitScalar(u8, line, ' ');
        while (numbers.next()) |num| {
            const number = try std.fmt.parseInt(i64, num, 10);
            try parsed.append(number);
        }

        next += parsed.items[parsed.items.len - 1];
        const diffLength = parsed.items.len - 1;
        var diff = try allocator.alloc(i64, diffLength);
        defer {
            diff.len = diffLength;
            allocator.free(diff);
        }

        var top = &parsed.items;
        var bottom = &diff;

        while (true) {
            bottom.len = top.len - 1;
            @memset(bottom.*, 0);
            for (bottom.*, 0..) |*x, i| {
                x.* = top.*[i + 1] - top.*[i];
            }
            next += bottom.*[bottom.len - 1];
            if (std.mem.indexOfNone(i64, bottom.*, &[1]i64{0}) == null) {
                break;
            } else {
                const temp = top;
                top = bottom;
                bottom = temp;
            }
        }
        answer += next;
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var lines = std.mem.splitScalar(u8, input, '\n');

    var answer: i64 = 0;
    while (lines.next()) |line| {
        var next: i64 = 0;
        var multiplier: i64 = 1;
        var parsed = std.ArrayList(i64).init(allocator);
        defer parsed.deinit();
        var numbers = std.mem.splitScalar(u8, line, ' ');
        while (numbers.next()) |num| {
            const number = try std.fmt.parseInt(i64, num, 10);
            try parsed.append(number);
        }

        next += parsed.items[0] * multiplier;
        multiplier *= -1;
        const diffLength = parsed.items.len - 1;
        var diff = try allocator.alloc(i64, diffLength);
        defer {
            diff.len = diffLength;
            allocator.free(diff);
        }

        var top = &parsed.items;
        var bottom = &diff;

        while (true) {
            bottom.len = top.len - 1;
            @memset(bottom.*, 0);
            for (bottom.*, 0..) |*x, i| {
                x.* = top.*[i + 1] - top.*[i];
            }
            next += bottom.*[0] * multiplier;
            multiplier *= -1;
            if (std.mem.indexOfNone(i64, bottom.*, &[1]i64{0}) == null) {
                break;
            } else {
                const temp = top;
                top = bottom;
                bottom = temp;
            }
        }
        answer += next;
    }

    return answer;
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(i64, 114), result);
}

test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(i64, 2), result);
}

const testInput =
    \\0 3 6 9 12 15
    \\1 3 6 10 15 21
    \\10 13 16 21 30 45
;
