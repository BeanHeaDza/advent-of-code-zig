const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;

pub fn part1(input: []const u8, allocator: Allocator) !usize {
    _ = allocator;
    var window = std.mem.window(u8, input, 4, 1);

    while (window.next()) |w| {
        if (w[0] != w[1] and w[0] != w[2] and w[0] != w[3] and w[1] != w[2] and w[1] != w[3] and w[2] != w[3]) {
            const index = window.index orelse return error.NotFound;
            return index + 3;
        }
    }
    return error.NotFound;
}

pub fn part2(input: []const u8, allocator: Allocator) !usize {
    _ = allocator;
    var window = std.mem.window(u8, input, 14, 1);

    label: while (window.next()) |w| {
        const size = std.math.maxInt(u8);
        var tracking: [size]bool = [1]bool{false} ** size;
        for (w) |c| {
            if (tracking[c]) continue :label;
            tracking[c] = true;
        }
        const index = window.index orelse return error.NotFound;
        return index + 13;
    }
    return error.NotFound;
}

const testInput =
    \\mjqjpqmgbljsphdztnvjfqwrcgsmlb
;

test "Part 1 example" {
    const result = try part1(testInput, testing.allocator);

    try std.testing.expectEqual(@as(usize, 7), result);
}

test "Part 2 example" {
    const result = try part2(testInput, testing.allocator);

    try std.testing.expectEqual(@as(usize, 19), result);
}
