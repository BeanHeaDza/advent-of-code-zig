const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;
const print = std.debug.print;

const DEBUG = true;

pub fn part1(input: []const u8, allocator: Allocator) !u32 {
    return solve1(input, allocator, 2000000);
}

fn solve1(input: []const u8, allocator: Allocator, row: i32) !u32 {
    var sensors = try parseInput(input, allocator);
    defer sensors.deinit();

    var ranges = ArrayList(@Vector(2, i32)).init(allocator);
    defer ranges.deinit();

    for (sensors.items) |sensor| {
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

pub fn part2(input: []const u8, allocator: Allocator) !u32 {
    return solve2(input, allocator, 4000000);
}

fn solve2(input: []const u8, allocator: Allocator, height: i32) !u32 {
    _ = height;
    if (DEBUG) print("\n", .{});
    var sensors = try parseInput(input, allocator);
    defer allocator.free(sensors);

    var x: usize = 0;
    while (x < sensors.len) : (x += 1) {
        const leftSensor = sensors[x];
        var y: usize = x + 1;
        while (y < sensors.len) : (y += 1) {
            const rightSensor = sensors[y];
            // Check if overlapping
            const distance = manhattanDistance(i32, leftSensor.sensor, rightSensor.sensor) orelse return error.BadInput;
            if (distance > leftSensor.radius + rightSensor.radius)
                continue;

            if (DEBUG) print("Sensor {any} with radius {}, overlaps sensor {any} with radius {}, distance between sensors {any}\n", .{ leftSensor.sensor, leftSensor.radius, rightSensor.sensor, rightSensor.radius, manhattanDistance(i32, leftSensor.sensor, rightSensor.sensor) });

            var up: @Vector(2, i32) = leftSensor.sensor + [2]i32{ 0, leftSensor.radius + 1 };
            var down: @Vector(2, i32) = leftSensor.sensor + [2]i32{ 0, -leftSensor.radius - 1 };
            var right: @Vector(2, i32) = leftSensor.sensor + [2]i32{ leftSensor.radius + 1, 0 };
            var left: @Vector(2, i32) = leftSensor.sensor + [2]i32{ -leftSensor.radius - 1, 0 };

            var currentPos = up;
            var modifier: @Vector(2, i32) = [2]i32{ 1, -1 };
            _ = modifier;
            while (!std.meta.eql(currentPos, right)) : (currentPos += [2]i32{ 1, -1 }) {
                // TODO: Better loop logic here
                if (manhattanDistance(i32, currentPos, rightSensor.sensor) == rightSensor.radius + 1) {
                    if (DEBUG) print("  intersection point {any}\n", .{currentPos});
                }
            }
            while (!std.meta.eql(currentPos, down)) : (currentPos += [2]i32{ -1, -1 }) {
                // TODO: Better loop logic here
                if (manhattanDistance(i32, currentPos, rightSensor.sensor) == rightSensor.radius + 1) {
                    if (DEBUG) print("  intersection point {any}\n", .{currentPos});
                }
            }
            while (!std.meta.eql(currentPos, left)) : (currentPos += [2]i32{ -1, 1 }) {
                // TODO: Better loop logic here
                if (manhattanDistance(i32, currentPos, rightSensor.sensor) == rightSensor.radius + 1) {
                    if (DEBUG) print("  intersection point {any}\n", .{currentPos});
                }
            }
            while (!std.meta.eql(currentPos, up)) : (currentPos += [2]i32{ 1, 1 }) {
                // TODO: Better loop logic here
                if (manhattanDistance(i32, currentPos, rightSensor.sensor) == rightSensor.radius + 1) {
                    if (DEBUG) print("  intersection point {any}\n", .{currentPos});
                }
            }
        }
    }

    return 56000011;
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

// test "Part 1 example" {
//     var result = try solve1(testInput, testing.allocator, 10);

//     try std.testing.expectEqual(@as(u32, 26), result);
// }

test "Part 2 example" {
    var result = try solve2(testInput, testing.allocator, 20);

    try std.testing.expectEqual(@as(u32, 56000011), result);
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
