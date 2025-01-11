const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;
const print = std.debug.print;

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn part1(input: []const u8, allocator: Allocator) !u32 {
    var parsed = try parseInput(input, allocator);
    defer parsed.map.deinit();
    defer parsed.keys.deinit();

    var map = parsed.map;

    var dirSums = std.StringArrayHashMap(u32).init(allocator);
    defer dirSums.deinit();

    var mapIter = map.iterator();
    while (mapIter.next()) |path| {
        var index: ?usize = 0;

        while (index != null) {
            const key = path.key_ptr.*[0..index.?];
            const getOrPut = try dirSums.getOrPut(key);
            if (getOrPut.found_existing) {
                getOrPut.value_ptr.* += path.value_ptr.*;
            } else {
                getOrPut.value_ptr.* = path.value_ptr.*;
            }
            const hasMore = index.? < path.key_ptr.len - 1;
            index = std.mem.indexOfScalarPos(u8, path.key_ptr.*, index.? + 1, '/');
            if (index == null and hasMore) {
                index = path.key_ptr.len;
            }
        }
    }

    var result: u32 = 0;
    var dirIter = dirSums.iterator();
    while (dirIter.next()) |dir| {
        if (dir.value_ptr.* <= 100000) {
            result += dir.value_ptr.*;
        }
    }
    return result;
}

pub fn part2(input: []const u8, allocator: Allocator) !u32 {
    var parsed = try parseInput(input, allocator);
    defer parsed.map.deinit();
    defer parsed.keys.deinit();

    var map = parsed.map;

    var dirSums = std.StringArrayHashMap(u32).init(allocator);
    defer dirSums.deinit();

    var mapIter = map.iterator();
    var totalUsed: u32 = 0;
    while (mapIter.next()) |path| {
        var index: ?usize = 0;
        totalUsed += path.value_ptr.*;

        while (index != null) {
            const key = path.key_ptr.*[0..index.?];
            const getOrPut = try dirSums.getOrPut(key);
            if (getOrPut.found_existing) {
                getOrPut.value_ptr.* += path.value_ptr.*;
            } else {
                getOrPut.value_ptr.* = path.value_ptr.*;
            }
            const hasMore = index.? < path.key_ptr.len - 1;
            index = std.mem.indexOfScalarPos(u8, path.key_ptr.*, index.? + 1, '/');
            if (index == null and hasMore) {
                index = path.key_ptr.len;
            }
        }
    }

    const needToFree = totalUsed + 30000000 - 70000000;

    var result: u32 = std.math.maxInt(u32);
    var dirIter = dirSums.iterator();
    while (dirIter.next()) |dir| {
        if (dir.value_ptr.* >= needToFree and dir.value_ptr.* < result) {
            result = dir.value_ptr.*;
        }
    }
    return result;
}

const Input = struct {
    map: std.StringHashMap(u32),
    keys: std.heap.ArenaAllocator,
};

fn parseInput(input: []const u8, allocator: Allocator) !Input {
    var pathSelfSize: std.StringHashMap(u32) = std.StringHashMap(u32).init(allocator);
    var keysHeap = std.heap.ArenaAllocator.init(allocator);
    var keyAllocator = keysHeap.allocator();

    var lines = std.mem.splitScalar(u8, input, '\n');

    var path = ArrayList(u8).init(allocator);
    defer path.deinit();

    while (lines.next()) |line| {
        if (eql(line, "$ cd ..")) {
            const lastChar = while (path.popOrNull()) |c| switch (c) {
                '/' => break c,
                else => continue,
            } else null;
            if (lastChar == null) {
                return error.AlreadyInRoot;
            }
        } else if (eql(line[0..4], "$ cd")) {
            if (path.getLastOrNull() != '/' and line[5] != '/') {
                try path.append('/');
            }
            try path.appendSlice(line[5..]);
        } else {
            var words = std.mem.splitScalar(u8, line, ' ');
            const first = words.next() orelse continue;
            const fileSize = std.fmt.parseInt(u32, first, 10) catch continue;
            if (!pathSelfSize.contains(path.items)) {
                const key = try keyAllocator.alloc(u8, path.items.len);
                @memcpy(key, path.items);
                try pathSelfSize.put(key, 0);
            }
            const pathSize: *u32 = pathSelfSize.getPtr(path.items) orelse return error.ItemNotFound;
            pathSize.* += fileSize;
        }
    }

    return Input{ .map = pathSelfSize, .keys = keysHeap };
}

const testInput =
    \\$ cd /
    \\$ ls
    \\dir a
    \\14848514 b.txt
    \\8504156 c.dat
    \\dir d
    \\$ cd a
    \\$ ls
    \\dir e
    \\29116 f
    \\2557 g
    \\62596 h.lst
    \\$ cd e
    \\$ ls
    \\584 i
    \\$ cd ..
    \\$ cd ..
    \\$ cd d
    \\$ ls
    \\4060174 j
    \\8033020 d.log
    \\5626152 d.ext
    \\7214296 k
;

test "Should parse correctly" {
    var sizes: Input = try parseInput(testInput, testing.allocator);
    defer sizes.map.deinit();
    defer sizes.keys.deinit();
    const map = sizes.map;

    try testing.expectEqual(@as(u32, 4), map.count());
    try testing.expectEqual(@as(u32, 14848514 + 8504156), map.get("/").?);
    try testing.expectEqual(@as(u32, 29116 + 2557 + 62596), map.get("/a").?);
    try testing.expectEqual(@as(u32, 584), map.get("/a/e").?);
    try testing.expectEqual(@as(u32, 4060174 + 8033020 + 5626152 + 7214296), map.get("/d").?);
}

test "Part 1 example" {
    const result = try part1(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u32, 95437), result);
}

test "Part 2 example" {
    const result = try part2(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u32, 24933642), result);
}
