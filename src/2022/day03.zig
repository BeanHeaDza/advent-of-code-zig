const std = @import("std");

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    _ = allocator;
    var answer: u32 = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const half = line.len / 2;
        answer += calcCompartmentPriority(line[0..half], line[half..]);
    }
    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    _ = allocator;
    var answer: u32 = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line1| {
        const line2 = lines.next() orelse return error.BadInput;
        const line3 = lines.next() orelse return error.BadInput;
        const key = try findGroupKey([_][]const u8{ line1, line2, line3 });
        answer += priority(key);
    }
    return answer;
}

fn findGroupKey(lists: [3][]const u8) !u8 {
    var buffer: [664]u8 = [1]u8{undefined} ** 664;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var hash = std.AutoHashMap(u8, [3]bool).init(fba.allocator());
    try hash.ensureTotalCapacity(56);

    for (lists, 0..) |list, i| {
        for (list[0..]) |c| {
            var entry = try hash.getOrPutValue(c, [3]bool{ false, false, false });
            entry.value_ptr[i] = true;
        }
    }

    var iter = hash.iterator();
    const allTrue = [3]bool{ true, true, true };
    while (iter.next()) |entry| {
        if (std.mem.eql(bool, &allTrue, entry.value_ptr)) {
            return entry.key_ptr.*;
        }
    }
    return error.GroupKeyNotFound;
}

fn calcCompartmentPriority(left: []const u8, right: []const u8) u32 {
    var buffer: [408]u8 = [1]u8{undefined} ** 408;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var hash = std.AutoHashMap(u8, bool).init(fba.allocator());
    hash.ensureTotalCapacity(56) catch unreachable;

    var result: u32 = 0;
    for (left) |c| {
        hash.put(c, false) catch unreachable;
    }
    for (right) |c| {
        if (hash.get(c) == false) {
            hash.put(c, true) catch unreachable;
            result += priority(c);
        }
    }
    return result;
}
fn priority(c: u8) u8 {
    if (c >= 'a' and c <= 'z') {
        return c - 'a' + 1;
    } else {
        return c - 'A' + 27;
    }
}

const testInput =
    \\vJrwpWtwJgWrhcsFMMfFFhFp
    \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
    \\PmmdzqPrVvPwwTWBwg
    \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
    \\ttgJtRGJQctTZtZT
    \\CrZsJsPPZsGzwwsLwLmpwMDw
;
test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 157), result);
}
test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 70), result);
}
