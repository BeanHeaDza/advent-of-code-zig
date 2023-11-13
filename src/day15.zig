const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;
const print = std.debug.print;

const DEBUG = false;

pub fn part1(input: []const u8, allocator: Allocator) !u32 {
    return solve1(input, allocator, 2000000);
}

fn solve1(input: []const u8, allocator: Allocator, row: i32) !u32 {
    var sensors = try parseInput(input, allocator);
    defer allocator.free(sensors);

    var ranges = ArrayList(@Vector(2, i32)).init(allocator);
    defer ranges.deinit();

    for (sensors) |sensor| {
        const diff = std.math.cast(i32, @abs(sensor.sensor[1] - row)) orelse return error.BadInput;
        const x: i32 = sensor.radius - diff;
        if (x < 0) {} else if (x == 0 and sensor.closestBeacon[1] == row) {} else {
            var left = sensor.sensor[0] - x;
            var right = sensor.sensor[0] + x;
            if (sensor.closestBeacon[1] == row) {
                if (left == sensor.closestBeacon[0]) {
                    left += 1;
                } else {
                    right -= 1;
                }
            }

            try ranges.append([2]i32{ left, right });
        }
    }

    std.mem.sort(@Vector(2, i32), ranges.items, {}, lessThan);

    var answer: u32 = 0;
    var i: usize = 0;
    while (i + 1 < ranges.items.len) : (i += 1) {
        var current = ranges.items[i];
        var next = ranges.items[i + 1];
        while (true) {
            if (current[1] >= next[0]) {
                current[1] = @max(current[1], next[1]);
                _ = ranges.orderedRemove(i + 1);
                if (i + 1 < ranges.items.len) {
                    next = ranges.items[i + 1];
                } else break;
            } else break;
        }
        const count = std.math.cast(u32, current[1] - current[0] + 1) orelse unreachable;
        answer += count;
        if (DEBUG) print("Inclusive untouchable range {any}\n", .{current});
    }

    return answer;
}

fn lessThan(_: void, lhs: @Vector(2, i32), rhs: @Vector(2, i32)) bool {
    return lhs[0] < rhs[0];
}

pub fn part2(input: []const u8, allocator: Allocator) !i64 {
    return solve2(input, allocator, 4000000);
}

fn solve2(input: []const u8, allocator: Allocator, clamp: i32) !i64 {
    if (DEBUG) print("\n", .{});
    var sensors = try parseInput(input, allocator);
    defer allocator.free(sensors);

    var positiveLineCs = std.AutoHashMap(i32, void).init(allocator);
    defer positiveLineCs.deinit();
    var negativeLineCs = std.AutoHashMap(i32, void).init(allocator);
    defer negativeLineCs.deinit();

    var i: usize = 0;
    while (i < sensors.len) : (i += 1) {
        const sensor = sensors[i];
        const left: @Vector(2, i32) = sensor.sensor + [2]i32{ -sensor.radius - 1, 0 };
        const right: @Vector(2, i32) = sensor.sensor + [2]i32{ sensor.radius + 1, 0 };

        // y = mx + c
        // For m=1:  c = y - x
        // For m=-1:  c = y + x
        try positiveLineCs.put(left[1] - left[0], {});
        try negativeLineCs.put(left[1] + left[0], {});
        try positiveLineCs.put(right[1] - right[0], {});
        try negativeLineCs.put(right[1] + right[0], {});
    }

    var positiveC = positiveLineCs.keyIterator();
    while (positiveC.next()) |c1| {
        var negativeC = negativeLineCs.keyIterator();
        search: while (negativeC.next()) |c2| {
            // y1 = x1 + c1
            // y2 = -x2 + c2
            // x + c1 = -x + c2
            // 2x = c2 - c1
            const xTimes2 = c2.* - c1.*;
            if (@mod(xTimes2, 2) != 0) {
                continue;
            }

            const x = @divExact(xTimes2, 2);
            const y = x + c1.*;
            if (x < 0 or x > clamp or y < 0 or y > clamp) {
                continue;
            }
            const possibleBeacon = @Vector(2, i32){ x, y };
            for (sensors) |sensor| {
                const distance = manhattanDistance(i32, sensor.sensor, possibleBeacon) orelse return error.BadManhanttan;
                if (distance <= sensor.radius) {
                    continue :search;
                }
            }
            return @as(i64, x) * 4000000 + y;
        }
    }

    return error.AnswerNotFound;
}

const Input = struct {
    sensor: @Vector(2, i32),
    closestBeacon: @Vector(2, i32),
    radius: i32,
};
fn parseInput(input: []const u8, allocator: Allocator) ![]const Input {
    var result = ArrayList(Input).init(allocator);
    errdefer result.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var pos = [4]i32{ undefined, undefined, undefined, undefined };
        var index: usize = 0;
        for (0..pos.len) |i| {
            index = std.mem.indexOfScalarPos(u8, line, index, '=') orelse return error.InvalidInput;
            const start = index + 1;
            index = std.mem.indexOfNonePos(u8, line, index + 1, "-1234567890") orelse line.len;

            pos[i] = try std.fmt.parseInt(i32, line[start..index], 10);
        }

        const sensor: @Vector(2, i32) = pos[0..2].*;
        const closestBeacon: @Vector(2, i32) = pos[2..4].*;
        const radius: i32 = manhattanDistance(i32, sensor, closestBeacon) orelse return error.BadInput;

        try result.append(Input{ .sensor = sensor, .closestBeacon = closestBeacon, .radius = radius });
    }

    return result.toOwnedSlice();
}

fn manhattanDistance(comptime T: type, a: @Vector(2, T), b: @Vector(2, T)) ?T {
    return std.math.cast(T, @reduce(.Add, @abs(a - b)));
}

test "parseInput" {
    var input = try parseInput(testInput, testing.allocator);
    defer testing.allocator.free(input);

    try testing.expectEqual(@as(usize, 14), input.len);

    const expected = Input{ .sensor = [2]i32{ 2, 18 }, .closestBeacon = [2]i32{ -2, 15 }, .radius = 7 };
    try testing.expectEqual(expected, input[0]);
}

test "Part 1 example" {
    var result = try solve1(testInput, testing.allocator, 10);

    try std.testing.expectEqual(@as(u32, 26), result);
}

test "Part 2 example" {
    var result = try solve2(testInput, testing.allocator, 20);

    try std.testing.expectEqual(@as(i64, 56000011), result);
}

const testInput =
    \\Sensor at x=2, y=18: closest beacon is at x=-2, y=15
    \\Sensor at x=9, y=16: closest beacon is at x=10, y=16
    \\Sensor at x=13, y=2: closest beacon is at x=15, y=3
    \\Sensor at x=12, y=14: closest beacon is at x=10, y=16
    \\Sensor at x=10, y=20: closest beacon is at x=10, y=16
    \\Sensor at x=14, y=17: closest beacon is at x=10, y=16
    \\Sensor at x=8, y=7: closest beacon is at x=2, y=10
    \\Sensor at x=2, y=0: closest beacon is at x=2, y=10
    \\Sensor at x=0, y=11: closest beacon is at x=2, y=10
    \\Sensor at x=20, y=14: closest beacon is at x=25, y=17
    \\Sensor at x=17, y=20: closest beacon is at x=21, y=22
    \\Sensor at x=16, y=7: closest beacon is at x=15, y=3
    \\Sensor at x=14, y=3: closest beacon is at x=15, y=3
    \\Sensor at x=20, y=1: closest beacon is at x=15, y=3
;
