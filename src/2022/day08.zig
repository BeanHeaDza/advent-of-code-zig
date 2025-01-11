const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;
const print = std.debug.print;

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn part1(input: []const u8, allocator: Allocator) !u32 {
    _ = allocator;
    const width = std.mem.indexOfScalar(u8, input, '\n') orelse return error.NoNewLineFound;
    if (input.len % (width + 1) != width) {
        return error.UnexpectedInputLength;
    }
    const height = input.len / width;
    var answer: usize = width * 2 + (height - 2) * 2;

    for (1..width - 1) |x| {
        for (1..height - 1) |y| {
            if (isVisible(input, width, height, x, y)) answer += 1;
        }
    }

    return std.math.cast(u32, answer) orelse error.FailedToCastToU32;
}

pub fn part2(input: []const u8, allocator: Allocator) !u32 {
    _ = allocator;
    const width = std.mem.indexOfScalar(u8, input, '\n') orelse return error.NoNewLineFound;
    if (input.len % (width + 1) != width) {
        return error.UnexpectedInputLength;
    }
    const height = input.len / width;
    var answer: usize = 0;

    for (1..width - 1) |x| {
        for (1..height - 1) |y| {
            const score = scenicScore(input, width, height, x, y);
            if (score > answer) answer = score;
        }
    }

    return std.math.cast(u32, answer) orelse error.FailedToCastToU32;
}

fn get(input: []const u8, width: usize, x: usize, y: usize) u8 {
    const i = x + y * (width + 1);
    return input[i];
}

fn isVisible(input: []const u8, width: usize, height: usize, selfX: usize, selfY: usize) bool {
    const this = get(input, width, selfX, selfY);
    var blocked = false;
    for (0..selfX) |x| {
        blocked = blocked or get(input, width, x, selfY) >= this;
    }
    if (!blocked) return true;

    blocked = false;
    for (selfX + 1..width) |x| {
        blocked = blocked or get(input, width, x, selfY) >= this;
    }
    if (!blocked) return true;

    blocked = false;
    for (0..selfY) |y| {
        blocked = blocked or get(input, width, selfX, y) >= this;
    }
    if (!blocked) return true;

    blocked = false;
    for (selfY + 1..height) |y| {
        blocked = blocked or get(input, width, selfX, y) >= this;
    }
    if (!blocked) return true;

    return false;
}

fn scenicScore(input: []const u8, width: usize, height: usize, selfX: usize, selfY: usize) usize {
    const this = get(input, width, selfX, selfY);
    var score: usize = 1;

    var temp: usize = 0;
    for (0..selfX) |x| {
        temp += 1;
        if (get(input, width, selfX - x - 1, selfY) >= this) {
            break;
        }
    }
    score *= temp;

    temp = 0;
    for (selfX + 1..width) |x| {
        temp += 1;
        if (get(input, width, x, selfY) >= this) {
            break;
        }
    }
    score *= temp;

    temp = 0;
    for (0..selfY) |y| {
        temp += 1;
        if (get(input, width, selfX, selfY - y - 1) >= this) {
            break;
        }
    }
    score *= temp;

    temp = 0;
    for (selfY + 1..height) |y| {
        temp += 1;
        if (get(input, width, selfX, y) >= this) {
            break;
        }
    }
    score *= temp;

    return score;
}

const testInput =
    \\30373
    \\25512
    \\65332
    \\33549
    \\35390
;

test "Part 1 example" {
    const result = try part1(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u32, 21), result);
}

test "Part 2 example" {
    const result = try part2(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u32, 8), result);
}
