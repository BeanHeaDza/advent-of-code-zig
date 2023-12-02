const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const tokenizeAny = std.mem.tokenizeAny;
const testing = std.testing;

pub fn part1(input: []const u8, allocator: Allocator) !u32 {
    var nums = ArrayList(u32).init(allocator);
    defer nums.deinit();

    try parseInput(input, &nums);
    var window: std.mem.WindowIterator(u32) = std.mem.window(u32, nums.items, 4, 4);

    var count: u32 = 0;
    while (window.next()) |pair| {
        if (pair[0] == pair[2] or pair[1] == pair[3] or (pair[2] > pair[0] and pair[3] < pair[1]) or (pair[0] > pair[2] and pair[1] < pair[3])) {
            count += 1;
        }
    }

    return count;
}

pub fn part2(input: []const u8, allocator: Allocator) !u32 {
    var nums = ArrayList(u32).init(allocator);
    defer nums.deinit();

    try parseInput(input, &nums);
    var window: std.mem.WindowIterator(u32) = std.mem.window(u32, nums.items, 4, 4);

    var count: u32 = 0;
    while (window.next()) |pair| {
        if ((pair[0] <= pair[2] and pair[1] >= pair[2]) or (pair[2] <= pair[0] and pair[3] >= pair[0])) {
            count += 1;
        }
    }

    return count;
}

fn parseInput(input: []const u8, list: *ArrayList(u32)) !void {
    var tokenizer = tokenizeAny(u8, input, "-,\n");
    while (tokenizer.next()) |num| try list.append(try std.fmt.parseInt(u32, num, 10));
}

const testInput =
    \\2-4,6-8
    \\2-3,4-5
    \\5-7,7-9
    \\2-8,3-7
    \\6-6,4-6
    \\2-6,4-8
;

test "Parses correctly" {
    var nums = ArrayList(u32).init(testing.allocator);
    defer nums.deinit();
    try parseInput("20-4,6-8\n2-3,4-5", &nums);

    try testing.expectEqualSlices(u32, &[_]u32{ 20, 4, 6, 8, 2, 3, 4, 5 }, nums.items);
}

test "Part 1 example" {
    const result = try part1(testInput, testing.allocator);
    try std.testing.expectEqual(@as(u32, 2), result);
}
test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 4), result);
}
