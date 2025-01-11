const std = @import("std");

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    _ = allocator;

    var lines = std.mem.splitScalar(u8, input, '\n');
    var timeIter = std.mem.tokenizeScalar(u8, lines.first(), ' ');
    _ = timeIter.next();
    var distanceIter = std.mem.tokenizeScalar(u8, lines.next().?, ' ');
    _ = distanceIter.next();

    var answer: u32 = 1;
    while (timeIter.next()) |timeText| {
        const time = try std.fmt.parseFloat(f64, timeText);
        const distance = try std.fmt.parseFloat(f64, distanceIter.next().?);
        // x * (7-x) > 9
        // -x^2 + 7x - 9 > 0
        // a = -1
        // b = time
        // c = -distance
        const x = try quadraticFormula(-1, time, -distance);
        const from = std.math.floor(x[0]) + 1;
        const to = std.math.ceil(x[1]) - 1;

        const winConditions: u32 = @intFromFloat(to - from + 1);
        answer *= winConditions;
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !i64 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var timeIter = std.mem.tokenizeScalar(u8, lines.first(), ' ');
    _ = timeIter.next();
    var timeText = std.ArrayList(u8).init(allocator);
    defer timeText.deinit();
    while (timeIter.next()) |t| try timeText.appendSlice(t);
    const time = try std.fmt.parseFloat(f64, timeText.items);

    var distanceIter = std.mem.tokenizeScalar(u8, lines.next().?, ' ');
    _ = distanceIter.next();
    var distanceText = std.ArrayList(u8).init(allocator);
    defer distanceText.deinit();
    while (distanceIter.next()) |t| try distanceText.appendSlice(t);
    const distance = try std.fmt.parseFloat(f64, distanceText.items);

    // x * (7-x) > 9
    // -x^2 + 7x - 9 > 0
    // a = -1
    // b = time
    // c = -distance
    const x = try quadraticFormula(-1, time, -distance);
    const from = std.math.floor(x[0]) + 1;
    const to = std.math.ceil(x[1]) - 1;

    const answer: i64 = @intFromFloat(to - from + 1);

    return answer;
}

fn quadraticFormula(a: f64, b: f64, c: f64) ![2]f64 {
    const discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
        return error.ComplexNumber;
    }

    const x1 = (-b + std.math.sqrt(discriminant)) / (2 * a);
    const x2 = (-b - std.math.sqrt(discriminant)) / (2 * a);
    return [2]f64{ x1, x2 };
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 288), result);
}

test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(i64, 71503), result);
}

const testInput =
    \\Time:      7  15   30
    \\Distance:  9  40  200
;
