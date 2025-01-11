const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;
const print = std.debug.print;

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn part1(input: []const u8, allocator: Allocator) !i32 {
    _ = allocator;
    var lines = std.mem.splitScalar(u8, input, '\n');
    var x: i32 = 1;
    var cycle: i32 = 0;
    var signalStrength: i32 = 0;

    while (lines.next()) |line| {
        var words = std.mem.splitScalar(u8, line, ' ');
        const command = words.first();
        const param = words.next() orelse "";

        if (eql(command, "addx")) {
            step1(&cycle, &signalStrength, x);
            step1(&cycle, &signalStrength, x);
            x += try std.fmt.parseInt(i32, param, 10);
        } else if (eql(command, "noop")) {
            step1(&cycle, &signalStrength, x);
        } else {
            return error.UnknownCommand;
        }
    }

    return signalStrength;
}
pub fn part2(input: []const u8, allocator: Allocator) ![]const u8 {
    var output = try ArrayList(u8).initCapacity(allocator, 41 * 6);
    defer output.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    var x: i32 = 1;
    var cycle: i32 = 0;

    while (lines.next()) |line| {
        var words = std.mem.splitScalar(u8, line, ' ');
        const command = words.first();
        const param = words.next() orelse "";

        if (eql(command, "addx")) {
            try step2(&cycle, x, &output);
            try step2(&cycle, x, &output);
            x += try std.fmt.parseInt(i32, param, 10);
        } else if (eql(command, "noop")) {
            try step2(&cycle, x, &output);
        } else {
            return error.UnknownCommand;
        }
    }

    return allocator.dupe(u8, output.items);
}

fn step1(cycle: *i32, signalStrength: *i32, x: i32) void {
    cycle.* += 1;
    if (@mod(cycle.*, 40) == 20) {
        signalStrength.* += cycle.* * x;
    }
}

fn step2(cycle: *i32, x: i32, output: *ArrayList(u8)) !void {
    if (@rem(cycle.*, 40) == 0) {
        try output.append('\n');
    }
    const rowPos = @mod(cycle.*, 40);
    if (rowPos >= x - 1 and rowPos <= x + 1) {
        try output.append('#');
    } else {
        try output.append('.');
    }
    cycle.* += 1;
}

test "Part 1 example" {
    const result = try part1(testInput, testing.allocator);

    try std.testing.expectEqual(@as(i32, 13140), result);
}

test "Part 2 example" {
    const result = try part2(testInput, testing.allocator);
    defer testing.allocator.free(result);
    const output =
        \\
        \\##..##..##..##..##..##..##..##..##..##..
        \\###...###...###...###...###...###...###.
        \\####....####....####....####....####....
        \\#####.....#####.....#####.....#####.....
        \\######......######......######......####
        \\#######.......#######.......#######.....
    ;
    try std.testing.expectEqualSlices(u8, result, output);
}

const testInput =
    \\addx 15
    \\addx -11
    \\addx 6
    \\addx -3
    \\addx 5
    \\addx -1
    \\addx -8
    \\addx 13
    \\addx 4
    \\noop
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx 5
    \\addx -1
    \\addx -35
    \\addx 1
    \\addx 24
    \\addx -19
    \\addx 1
    \\addx 16
    \\addx -11
    \\noop
    \\noop
    \\addx 21
    \\addx -15
    \\noop
    \\noop
    \\addx -3
    \\addx 9
    \\addx 1
    \\addx -3
    \\addx 8
    \\addx 1
    \\addx 5
    \\noop
    \\noop
    \\noop
    \\noop
    \\noop
    \\addx -36
    \\noop
    \\addx 1
    \\addx 7
    \\noop
    \\noop
    \\noop
    \\addx 2
    \\addx 6
    \\noop
    \\noop
    \\noop
    \\noop
    \\noop
    \\addx 1
    \\noop
    \\noop
    \\addx 7
    \\addx 1
    \\noop
    \\addx -13
    \\addx 13
    \\addx 7
    \\noop
    \\addx 1
    \\addx -33
    \\noop
    \\noop
    \\noop
    \\addx 2
    \\noop
    \\noop
    \\noop
    \\addx 8
    \\noop
    \\addx -1
    \\addx 2
    \\addx 1
    \\noop
    \\addx 17
    \\addx -9
    \\addx 1
    \\addx 1
    \\addx -3
    \\addx 11
    \\noop
    \\noop
    \\addx 1
    \\noop
    \\addx 1
    \\noop
    \\noop
    \\addx -13
    \\addx -19
    \\addx 1
    \\addx 3
    \\addx 26
    \\addx -30
    \\addx 12
    \\addx -1
    \\addx 3
    \\addx 1
    \\noop
    \\noop
    \\noop
    \\addx -9
    \\addx 18
    \\addx 1
    \\addx 2
    \\noop
    \\noop
    \\addx 9
    \\noop
    \\noop
    \\noop
    \\addx -1
    \\addx 2
    \\addx -37
    \\addx 1
    \\addx 3
    \\noop
    \\addx 15
    \\addx -21
    \\addx 22
    \\addx -6
    \\addx 1
    \\noop
    \\addx 2
    \\addx 1
    \\noop
    \\addx -10
    \\noop
    \\noop
    \\addx 20
    \\addx 1
    \\addx 2
    \\addx 2
    \\addx -6
    \\addx -11
    \\noop
    \\noop
    \\noop
;
