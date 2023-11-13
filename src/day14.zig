const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;
const print = std.debug.print;
fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

const DEBUG = false;

const Vector = @Vector(2, i32);
const Set = std.AutoHashMap(Vector, void);

pub fn part1(input: []const u8, allocator: Allocator) !u32 {
    if (DEBUG) print("\n", .{});
    var rocks = try getRocks(input, allocator);
    defer rocks.deinit();
    const rockCount = rocks.count();

    var depth: i32 = 0;
    var keys = rocks.keyIterator();
    while (keys.next()) |rock| {
        depth = @max(depth, rock[1]);
    }

    if (DEBUG) print("Depth: {}\n", .{depth});

    const down = Vector{ 0, 1 };
    const left = Vector{ -1, 1 };
    const right = Vector{ 1, 1 };
    outer: while (true) {
        var sand = Vector{ 500, 0 };
        while (true) {
            if (!rocks.contains(sand + down)) {
                sand += down;
            } else if (!rocks.contains(sand + left)) {
                sand += left;
            } else if (!rocks.contains(sand + right)) {
                sand += right;
            } else {
                break;
            }
            if (DEBUG) print("Sand is at {}\n", .{sand});
            if (sand[1] > depth) break :outer;
        }
        if (DEBUG) print("Sand settled at {}\n", .{sand});
        try rocks.put(sand, {});
    }

    return rocks.count() - rockCount;
}

pub fn part2(input: []const u8, allocator: Allocator) !u32 {
    if (DEBUG) print("\n", .{});
    var rocks = try getRocks(input, allocator);
    defer rocks.deinit();
    const rockCount = rocks.count();

    var depth: i32 = 0;
    var keys = rocks.keyIterator();
    while (keys.next()) |rock| {
        depth = @max(depth, rock[1]);
    }

    if (DEBUG) print("Depth: {}\n", .{depth});

    const down = Vector{ 0, 1 };
    const left = Vector{ -1, 1 };
    const right = Vector{ 1, 1 };
    var sand = Vector{ 0, 0 };
    while (!std.meta.eql(sand, Vector{ 500, 0 })) {
        sand = Vector{ 500, 0 };
        while (true) {
            if (!rocks.contains(sand + down)) {
                sand += down;
            } else if (!rocks.contains(sand + left)) {
                sand += left;
            } else if (!rocks.contains(sand + right)) {
                sand += right;
            } else {
                break;
            }
            if (sand[1] == depth + 1) break;
            if (DEBUG) print("Sand is at {}\n", .{sand});
        }
        if (DEBUG) print("Sand settled at {}\n", .{sand});
        try rocks.put(sand, {});
    }

    return rocks.count() - rockCount;
}

fn getRocks(input: []const u8, allocator: Allocator) !Set {
    var result = Set.init(allocator);
    errdefer result.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        var points = std.mem.splitSequence(u8, line, " -> ");
        var previous = try toPoint(points.first());
        try result.put(previous, {});
        while (points.next()) |pointText| {
            const point = try toPoint(pointText);
            var diff = @min(@max(Vector{ -1, -1 }, point - previous), Vector{ 1, 1 });
            while (!std.meta.eql(previous, point)) {
                previous += diff;
                try result.put(previous, {});
            }
        }
    }

    return result;
}

fn toPoint(pair: []const u8) !Vector {
    var coords = std.mem.splitScalar(u8, pair, ',');
    const left = try std.fmt.parseInt(i32, coords.first(), 10);
    const right = try std.fmt.parseInt(i32, coords.next() orelse return error.PointNeedsAComma, 10);
    return Vector{ left, right };
}

test "Get rocks" {
    var rocks = try getRocks(testInput, testing.allocator);
    defer rocks.deinit();
    try testing.expectEqual(@as(usize, 20), rocks.count());
}

test "Part 1 example" {
    var result = try part1(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u32, 24), result);
}

test "Part 2 example" {
    var result = try part2(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u32, 93), result);
}

const testInput =
    \\498,4 -> 498,6 -> 496,6
    \\503,4 -> 502,4 -> 502,9 -> 494,9
;
