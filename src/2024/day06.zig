const std = @import("std");
const util = @import("../util.zig");

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    const mutableInput = try allocator.alloc(u8, input.len);
    defer allocator.free(mutableInput);
    @memcpy(mutableInput, input);
    const grid = try util.mutableInputGrid(mutableInput, allocator);
    defer allocator.free(grid);

    const result = try solve(grid, allocator);
    defer allocator.free(result);

    return @intCast(result.len);
}

const GuardPathWithHeading = struct {
    pos: [2]usize,
    heading: [2]i8,
};

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    const mutableInput = try allocator.alloc(u8, input.len);
    defer allocator.free(mutableInput);
    @memcpy(mutableInput, input);
    const grid = try util.mutableInputGrid(mutableInput, allocator);
    defer allocator.free(grid);

    const relevantBlocks = try solve(grid, allocator);
    defer allocator.free(relevantBlocks);

    var answer: u32 = 0;

    for (relevantBlocks) |pos| {
        const char = grid[pos[0]][pos[1]];
        if (char != '.') continue;

        grid[pos[0]][pos[1]] = '#';
        const result = solve(grid, allocator);
        if (result == error.Unsolvable) {
            answer += 1;
        } else {
            allocator.free(try result);
        }
        grid[pos[0]][pos[1]] = '.';
    }

    return answer;
}

fn solve(grid: []const []const u8, allocator: std.mem.Allocator) ![][2]usize {
    var currentPos = try getStartingPos(grid);

    const headings = [4][2]i8{
        [2]i8{ -1, 0 },
        [2]i8{ 0, 1 },
        [2]i8{ 1, 0 },
        [2]i8{ 0, -1 },
    };
    var headingIndex: usize = 0;

    var guardPaths = std.AutoArrayHashMap(GuardPathWithHeading, void).init(allocator);
    defer guardPaths.deinit();

    try guardPaths.put(GuardPathWithHeading{ .pos = currentPos, .heading = headings[headingIndex] }, {});

    while (util.getNextPos(grid, currentPos, headings[headingIndex])) |nextPos| {
        const peekVal = grid[nextPos[0]][nextPos[1]];

        if (peekVal == '#') {
            headingIndex += 1;
            if (headingIndex >= headings.len) headingIndex = 0;
            continue;
        }

        const put = try guardPaths.getOrPut(GuardPathWithHeading{ .pos = nextPos, .heading = headings[headingIndex] });
        if (put.found_existing) {
            return error.Unsolvable;
        }
        currentPos = nextPos;
    }

    var uniqueCount = std.AutoArrayHashMap([2]usize, void).init(allocator);
    defer uniqueCount.deinit();

    for (guardPaths.keys()) |key| {
        try uniqueCount.put(key.pos, {});
    }

    var result = try allocator.alloc([2]usize, uniqueCount.count());

    for (uniqueCount.keys(), 0..) |key, i| {
        result[i] = key;
    }

    return result;
}

fn getStartingPos(grid: []const []const u8) ![2]usize {
    var currentPos = [2]usize{ 0, 0 };
    for (grid) |row| {
        const column = std.mem.indexOfScalar(u8, row, '^');
        if (column) |col| {
            currentPos[1] = col;
            return currentPos;
        }
        currentPos[0] += 1;
    }

    return error.StartPosNotFoundInGrid;
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 41), result);
}

test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 6), result);
}

const testInput =
    \\....#.....
    \\.........#
    \\..........
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
;
