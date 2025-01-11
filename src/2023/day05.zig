const std = @import("std");

const Input = struct {
    seeds: []i64,
    maps: []Map,
    allocator: std.mem.Allocator,

    pub fn deinit(input: Input) void {
        input.allocator.free(input.seeds);
        for (input.maps) |m| {
            m.deinit();
        }
        input.allocator.free(input.maps);
    }
};
const Map = struct {
    from: []const u8,
    to: []const u8,
    mappings: [][3]i64,
    allocator: std.mem.Allocator,

    pub fn deinit(map: Map) void {
        map.allocator.free(map.mappings);
    }
};

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !i64 {
    const inp = try parseInput(input, allocator);
    defer inp.deinit();
    var answer: i64 = std.math.maxInt(i64);
    for (inp.seeds) |seed| {
        var result: i64 = seed;
        for (inp.maps) |map| {
            for (map.mappings) |mapping| {
                if (result >= mapping[1] and result < mapping[1] + mapping[2]) {
                    result += mapping[0] - mapping[1];
                    break;
                }
            }
        }
        if (result < answer) {
            answer = result;
        }
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !i64 {
    const inp = try parseInput(input, allocator);
    defer inp.deinit();
    var a = std.ArrayList([2]i64).init(allocator);
    defer a.deinit();
    var b = std.ArrayList([2]i64).init(allocator);
    defer b.deinit();
    var currentList = &a;
    var nextList = &b;

    var iter = std.mem.window(i64, inp.seeds, 2, 2);
    while (iter.next()) |x| {
        try currentList.append([2]i64{ x[0], x[1] });
    }

    for (inp.maps) |map| {
        var i: usize = 0;
        outer: while (i < currentList.items.len) : (i += 1) {
            const seeds = currentList.items[i];
            for (map.mappings) |mapping| {
                // no overlap
                if (seeds[0] + seeds[1] <= mapping[1] or mapping[1] + mapping[2] <= seeds[0]) {
                    continue;
                }

                // Add left dangling seeds back onto current list
                if (seeds[0] < mapping[1]) {
                    try currentList.append([2]i64{ seeds[0], mapping[1] - seeds[0] });
                }

                // Add right dangling seeds back onto current list
                if (seeds[0] + seeds[1] > mapping[1] + mapping[2]) {
                    try currentList.append([2]i64{ mapping[1] + mapping[2], seeds[0] + seeds[1] - mapping[1] - mapping[2] });
                }

                // Map overlap onto next list
                // [left, right)
                const left = @max(seeds[0], mapping[1]);
                const right = @min(seeds[0] + seeds[1], mapping[1] + mapping[2]);
                const length = right - left;

                try nextList.append([2]i64{ left + mapping[0] - mapping[1], length });

                continue :outer;
            }
            // No mapping for seed range, add to next list

            try nextList.append(seeds);
        }
        currentList.clearRetainingCapacity();
        const temp = currentList;
        currentList = nextList;
        nextList = temp;
    }

    var answer: i64 = std.math.maxInt(i64);
    for (currentList.items) |seeds| {
        if (seeds[0] < answer) {
            answer = seeds[0];
        }
    }

    return answer;
}

pub fn parseInput(input: []const u8, allocator: std.mem.Allocator) !Input {
    var lines = std.mem.splitScalar(u8, input, '\n');

    const seedsLine = lines.first();
    var seeds = std.ArrayList(i64).init(allocator);
    errdefer seeds.deinit();
    var seedsIter = std.mem.splitScalar(u8, seedsLine, ' ');
    _ = seedsIter.first();
    while (seedsIter.next()) |seed| {
        try seeds.append(try std.fmt.parseInt(i64, seed, 10));
    }

    var maps = std.ArrayList(Map).init(allocator);
    errdefer {
        for (maps.items) |map| map.deinit();
        maps.deinit();
    }

    var currentMap: ?Map = null;
    var mappings: ?std.ArrayList([3]i64) = null;
    errdefer if (mappings != null) mappings.?.deinit();
    while (lines.next()) |line| {
        if (line.len == 0) {
            continue;
        }

        if (line[0] < '0' or line[0] > '9') {
            if (currentMap != null) {
                currentMap.?.mappings = try mappings.?.toOwnedSlice();
                try maps.append(currentMap.?);
            }
            var iter = std.mem.splitAny(u8, line, "- ");
            const from = iter.first();
            _ = iter.next();
            const to = iter.next() orelse return error.BadFromToInput;
            currentMap = Map{ .allocator = allocator, .from = from, .to = to, .mappings = undefined };
            mappings = std.ArrayList([3]i64).init(allocator);
        } else {
            var iter = std.mem.splitScalar(u8, line, ' ');
            const destination = try std.fmt.parseInt(i64, iter.first(), 10);
            const source = try std.fmt.parseInt(i64, iter.next() orelse return error.MappingMissedSource, 10);
            const length = try std.fmt.parseInt(i64, iter.next() orelse return error.MappingMissedLength, 10);
            try mappings.?.append([3]i64{ destination, source, length });
        }
    }

    currentMap.?.mappings = try mappings.?.toOwnedSlice();
    try maps.append(currentMap.?);

    return Input{ .allocator = allocator, .maps = try maps.toOwnedSlice(), .seeds = try seeds.toOwnedSlice() };
}

test "Parse Input" {
    const input = try parseInput(testInput, std.testing.allocator);
    defer input.deinit();
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(i64, 35), result);
}

test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(i64, 46), result);
}

const testInput =
    \\seeds: 79 14 55 13
    \\
    \\seed-to-soil map:
    \\50 98 2
    \\52 50 48
    \\
    \\soil-to-fertilizer map:
    \\0 15 37
    \\37 52 2
    \\39 0 15
    \\
    \\fertilizer-to-water map:
    \\49 53 8
    \\0 11 42
    \\42 0 7
    \\57 7 4
    \\
    \\water-to-light map:
    \\88 18 7
    \\18 25 70
    \\
    \\light-to-temperature map:
    \\45 77 23
    \\81 45 19
    \\68 64 13
    \\
    \\temperature-to-humidity map:
    \\0 69 1
    \\1 0 69
    \\
    \\humidity-to-location map:
    \\60 56 37
    \\56 93 4
;
