const std = @import("std");
const readInt = @import("./util.zig").readInt;

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    _ = allocator;
    var answer: u32 = 0;
    var elves = std.mem.splitSequence(u8, input, "\n\n");
    while (elves.next()) |elf| {
        var items = std.mem.splitScalar(u8, elf, '\n');
        var sum: u32 = 0;
        while (items.next()) |item| {
            sum += try std.fmt.parseInt(u32, item, 10);
        }
        answer = @max(answer, sum);
    }
    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var elves = std.mem.splitSequence(u8, input, "\n\n");
    var values = std.ArrayList(u32).init(allocator);
    defer values.deinit();

    while (elves.next()) |elf| {
        var items = std.mem.splitScalar(u8, elf, '\n');
        var sum: u32 = 0;
        while (items.next()) |item| {
            sum += try std.fmt.parseInt(u32, item, 10);
        }
        try values.append(sum);
    }

    std.mem.sort(u32, values.items, {}, greaterThan);
    return values.items[0] + values.items[1] + values.items[2];
}

fn greaterThan(_: void, a: u32, b: u32) bool {
    return a > b;
}

const testInput =
    \\1000
    \\2000
    \\3000
    \\
    \\4000
    \\
    \\5000
    \\6000
    \\
    \\7000
    \\8000
    \\9000
    \\
    \\10000
;
test "Part 1 passes example" {
    const result = try part1(testInput, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 24000), result);
}
test "Part 2 passes example" {
    const result = try part2(testInput, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 45000), result);
}
