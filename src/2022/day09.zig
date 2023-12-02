const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;
const print = std.debug.print;

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn part1(input: []const u8, allocator: Allocator) !u32 {
    return solve(input, allocator, 2);
}

pub fn part2(input: []const u8, allocator: Allocator) !u32 {
    return solve(input, allocator, 10);
}

fn solve(input: []const u8, allocator: Allocator, knotsCount: usize) !u32 {
    var locations = std.AutoHashMap(@Vector(2, i32), void).init(allocator);
    defer locations.deinit();

    var knots = try allocator.alloc(@Vector(2, i32), knotsCount);
    defer allocator.free(knots);
    for (0..knotsCount) |i| {
        knots[i] = [_]i32{ 0, 0 };
    }
    try locations.put(knots[knotsCount - 1], {});

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const move = switch (line[0]) {
            'R' => @Vector(2, i32){ 1, 0 },
            'L' => @Vector(2, i32){ -1, 0 },
            'U' => @Vector(2, i32){ 0, 1 },
            'D' => @Vector(2, i32){ 0, -1 },
            else => return error.InvalidMoveCommand,
        };

        const times = try std.fmt.parseInt(usize, line[2..], 10);
        for (0..times) |_| {
            knots[0] += move;
            for (1..knotsCount) |i| {
                var diff = knots[i] - knots[i - 1];
                if (@reduce(.Or, @abs(diff)) > 1) {
                    if (diff[0] > 1) diff[0] = 1;
                    if (diff[1] > 1) diff[1] = 1;
                    if (diff[0] < -1) diff[0] = -1;
                    if (diff[1] < -1) diff[1] = -1;
                    knots[i] -= diff;
                    if (i == knotsCount - 1) {
                        try locations.put(knots[i], {});
                    }
                } else {
                    break;
                }
            }
        }
    }

    return locations.count();
}

const testInput =
    \\R 4
    \\U 4
    \\L 3
    \\D 1
    \\R 4
    \\D 1
    \\L 5
    \\R 2
;
const testInput2 =
    \\R 5
    \\U 8
    \\L 8
    \\D 3
    \\R 17
    \\D 10
    \\L 25
    \\U 20
;

test "Part 1 example" {
    var result = try part1(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u32, 13), result);
}

test "Part 2 example" {
    var result = try part2(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u32, 1), result);
}

test "Part 2-2 example" {
    var result = try part2(testInput2, testing.allocator);

    try std.testing.expectEqual(@as(u32, 36), result);
}
