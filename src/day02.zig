const std = @import("std");
const readInt = @import("./util.zig").readInt;

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    _ = allocator;
    var score: u32 = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const opponent = line[0];
        const you = line[2];

        score += switch (you) {
            'X' => 1,
            'Y' => 2,
            'Z' => 3,
            else => return error.InvalidPlayerAction,
        };

        // AX = Rock
        // BY = Paper
        // CZ = Scissor
        // AX = 0 draw
        // AY = 1 win
        // AZ = 2 loss
        const diff: i32 = @as(i32, you) - opponent - 'X' + 'A';
        score += switch (diff) {
            0 => 3,
            1, -2 => 6,
            2, -1 => 0,
            else => {
                std.debug.print("\nUnknown outcome {s}{s} = {}\n", .{ [1]u8{opponent}, [1]u8{you}, diff });
                return error.NotImplemented;
            },
        };
    }

    return score;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !i32 {
    _ = allocator;
    var score: i32 = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const opponent = line[0];
        const outcome = line[2];

        score += switch (outcome) {
            'X' => 0,
            'Y' => 3,
            'Z' => 6,
            else => return error.InvalidPlayerAction,
        };

        var you: i32 = @as(i32, opponent) - 'A';
        you += switch (outcome) {
            'X' => 2,
            'Y' => 0,
            'Z' => 1,
            else => unreachable,
        };
        score += (@rem(you, 3)) + 1;
    }

    return score;
}

const testInput =
    \\A Y
    \\B X
    \\C Z
;
test "Part 1 passes example" {
    const result = try part1(testInput, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 15), result);
}
test "Part 2 passes example" {
    const result = try part2(testInput, std.testing.allocator);
    try std.testing.expectEqual(@as(i32, 12), result);
}
