const std = @import("std");

const Game = struct {
    number: u32,
    subsets: []const @Vector(3, u32),
};

const Games = struct {
    games: []const Game,
    allocator: std.mem.Allocator,
    pub fn deinit(self: Games) void {
        for (self.games) |game| {
            self.allocator.free(game.subsets);
        }
        self.allocator.free(self.games);
    }
};

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var games = try parse(input, allocator);
    defer games.deinit();
    var answer: u32 = 0;

    for (games.games) |game| {
        var valid = true;
        for (game.subsets) |subset| {
            if (subset[0] > 12 or subset[1] > 13 or subset[2] > 14) {
                valid = false;
                break;
            }
        }
        if (valid) {
            answer += game.number;
        }
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var games = try parse(input, allocator);
    defer games.deinit();
    var answer: u32 = 0;

    for (games.games) |game| {
        var minCubes: @Vector(3, u32) = [3]u32{ 0, 0, 0 };
        for (game.subsets) |subset| {
            minCubes = @max(minCubes, subset);
        }
        answer += @reduce(.Mul, minCubes);
    }

    return answer;
}

fn parse(input: []const u8, allocator: std.mem.Allocator) !Games {
    var games = std.ArrayList(Game).init(allocator);
    errdefer {
        for (games.items) |game| {
            allocator.free(game.subsets);
        }
        games.deinit();
    }

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const colonIndex = std.mem.indexOfScalar(u8, line, ':') orelse return error.BadInput;
        const gameNumber = try std.fmt.parseInt(u32, line[5..colonIndex], 10);
        var gameSubSets = std.ArrayList(@Vector(3, u32)).init(allocator);
        errdefer gameSubSets.deinit();

        var subsetIter = std.mem.splitSequence(u8, line[colonIndex + 2 ..], "; ");
        while (subsetIter.next()) |subset| {
            var cubes: @Vector(3, u32) = [3]u32{ 0, 0, 0 };
            var colorIter = std.mem.splitSequence(u8, subset, ", ");
            while (colorIter.next()) |cube| {
                var parts = std.mem.splitScalar(u8, cube, ' ');
                const count = try std.fmt.parseInt(u32, parts.first(), 10);
                const color = parts.next() orelse return error.BadInput;
                switch (color[0]) {
                    'r' => cubes[0] = count,
                    'g' => cubes[1] = count,
                    'b' => cubes[2] = count,
                    else => return error.BadInput,
                }
            }
            try gameSubSets.append(cubes);
        }
        var game = Game{ .number = gameNumber, .subsets = try gameSubSets.toOwnedSlice() };
        try games.append(game);
    }
    return Games{ .games = try games.toOwnedSlice(), .allocator = allocator };
}

test "Parse" {
    var result = try parse(testInput, std.testing.allocator);
    defer result.deinit();

    try std.testing.expectEqual(@as(usize, 5), result.games.len);
    try std.testing.expectEqual(@as(u32, 1), result.games[0].number);

    const expected = Game{
        .number = 1,
        .subsets = &[_]@Vector(3, u32){
            [3]u32{ 4, 0, 3 },
            [3]u32{ 1, 2, 6 },
            [3]u32{ 0, 2, 0 },
        },
    };
    try std.testing.expectEqualDeep(expected, result.games[0]);
}

test "Error Parse" {
    const badInput =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 x, 13 green; 5 green, 1 red
    ;
    const result = parse(badInput, std.testing.allocator);
    try std.testing.expectError(error.BadInput, result);
}

test "Part 1 example" {
    var result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 8), result);
}

test "Part 2 example" {
    var result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 2286), result);
}

const testInput =
    \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
    \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
    \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
    \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
    \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
;
