const std = @import("std");

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    const grid = try inputToGrid(input, allocator);
    defer allocator.free(grid);

    var answer: u32 = 0;

    for (0..grid.len) |i| {
        for (0..grid[i].len) |j| {
            if (grid[i][j] != 'X') continue;
            const pos = [2]usize{ i, j };
            const remainingChars = "MAS";
            const adjustments = [_][2]i8{
                [2]i8{ 1, 0 },
                [2]i8{ 0, 1 },
                [2]i8{ -1, 0 },
                [2]i8{ 0, -1 },
                [2]i8{ 1, 1 },
                [2]i8{ 1, -1 },
                [2]i8{ -1, 1 },
                [2]i8{ -1, -1 },
            };
            for (adjustments) |adjustment| {
                if (searchWord(grid, pos, remainingChars, adjustment)) {
                    answer += 1;
                }
            }
        }
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    const grid = try inputToGrid(input, allocator);
    defer allocator.free(grid);

    var answer: u32 = 0;

    for (1..grid.len - 1) |i| {
        for (1..grid[i].len - 1) |j| {
            if (grid[i][j] != 'A') continue;
            const NW = grid[i - 1][j - 1];
            if (NW != 'M' and NW != 'S') continue;
            const SE = grid[i + 1][j + 1];
            if (SE != 'M' and SE != 'S') continue;
            const NE = grid[i - 1][j + 1];
            if (NE != 'M' and NE != 'S') continue;
            const SW = grid[i + 1][j - 1];
            if (SW != 'M' and SW != 'S') continue;

            if (NW == SE or NE == SW) continue;

            answer += 1;
        }
    }

    return answer;
}

fn inputToGrid(input: []const u8, allocator: std.mem.Allocator) ![][]const u8 {
    var list = std.ArrayList([]const u8).init(allocator);
    errdefer list.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        try list.append(line);
    }

    return list.toOwnedSlice();
}

fn searchWord(grid: [][]const u8, pos: [2]usize, remainingChars: []const u8, adjustment: [2]i8) bool {
    if (remainingChars.len == 0) {
        return true;
    }

    var intPos: @Vector(2, i64) = undefined;
    intPos[0] = std.math.cast(i64, pos[0]) orelse @panic("grid too big.");
    intPos[1] = std.math.cast(i64, pos[1]) orelse @panic("grid too big.");

    const ov = @addWithOverflow(intPos, adjustment);
    if (@reduce(.Or, ov[1]) > 0) {
        return false;
    }
    intPos = ov[0];

    var newPos: [2]usize = undefined;
    newPos[0] = std.math.cast(usize, intPos[0]) orelse return false;
    newPos[1] = std.math.cast(usize, intPos[1]) orelse return false;

    if (newPos[0] >= grid.len or newPos[1] >= grid[newPos[0]].len or remainingChars[0] != grid[newPos[0]][newPos[1]]) {
        return false;
    }

    return searchWord(grid, newPos, remainingChars[1..], adjustment);
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 18), result);
}

test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 9), result);
}

const testInput =
    \\MMMSXXMASM
    \\MSAMXMSMSA
    \\AMXSXMAAMM
    \\MSAMASMSMX
    \\XMASAMXAMM
    \\XXAMMXXAMA
    \\SMSMSASXSS
    \\SAXAMASAAA
    \\MAMMMXMMMM
    \\MXMXAXMASX
;
