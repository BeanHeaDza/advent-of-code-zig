const std = @import("std");

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    const parsed = try parseInput(input, allocator);
    defer parsed.deinit();

    var answer: u32 = 0;

    for (parsed.manuals) |manual| {
        answer += try tryGetMiddleOfCorrectManual(parsed.pageOrderRules, manual) orelse 0;
    }

    return answer;
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u32 {
    const parsed = try parseInput(input, allocator);
    defer parsed.deinit();

    var answer: u32 = 0;

    for (parsed.manuals) |manual| {
        if (try tryGetMiddleOfCorrectManual(parsed.pageOrderRules, manual) != null) {
            continue;
        }
        answer += try getMiddleAfterSortingManual(parsed.pageOrderRules, manual);
    }

    return answer;
}

const Input = struct {
    allocator: std.mem.Allocator,
    pageOrderRules: [][2]u32,
    manuals: [][]u32,
    pub fn deinit(self: Input) void {
        self.allocator.free(self.pageOrderRules);
        for (self.manuals) |page| {
            self.allocator.free(page);
        }
        self.allocator.free(self.manuals);
    }
};

fn parseInput(input: []const u8, allocator: std.mem.Allocator) !Input {
    var pageRules = std.ArrayList([2]u32).init(allocator);
    errdefer pageRules.deinit();
    var pages = std.ArrayList([]u32).init(allocator);
    errdefer {
        for (pages.items) |page| {
            allocator.free(page);
        }
        pages.deinit();
    }

    var lines = std.mem.splitScalar(u8, input, '\n');
    var readingRules = true;
    while (lines.next()) |lineRaw| {
        if (lineRaw.len == 0 or (lineRaw.len == 1 and lineRaw[0] == '\r')) {
            readingRules = false;
            continue;
        }

        const line = if (lineRaw[lineRaw.len - 1] == '\r') lineRaw[0 .. lineRaw.len - 1] else lineRaw;

        if (readingRules) {
            var parts = std.mem.splitScalar(u8, line, '|');
            const left = try std.fmt.parseInt(u32, parts.first(), 10);
            const right = try std.fmt.parseInt(u32, parts.next() orelse return error.BadInput, 10);
            try pageRules.append([2]u32{ left, right });
        } else {
            var parts = std.mem.splitScalar(u8, line, ',');
            var manuals = std.ArrayList(u32).init(allocator);
            errdefer manuals.deinit();
            while (parts.next()) |part| {
                try manuals.append(try std.fmt.parseInt(u32, part, 10));
            }
            try pages.append(try manuals.toOwnedSlice());
        }
    }

    return Input{
        .allocator = allocator,
        .pageOrderRules = try pageRules.toOwnedSlice(),
        .manuals = try pages.toOwnedSlice(),
    };
}

fn tryGetMiddleOfCorrectManual(pageOrderRules: [][2]u32, manual: []u32) !?u32 {
    for (pageOrderRules) |rule| {
        const leftIndex = std.mem.indexOfScalar(u32, manual, rule[0]);
        const rightIndex = std.mem.indexOfScalar(u32, manual, rule[1]);
        if (leftIndex != null and rightIndex != null and leftIndex.? >= rightIndex.?) {
            return null;
        }
    }

    return manual[@divFloor(manual.len, 2)];
}

fn getMiddleAfterSortingManual(pageOrderRules: [][2]u32, manual: []u32) !u32 {
    var targetIndex: usize = 0;
    target: while (targetIndex < manual.len) : (targetIndex += 1) {
        var leftMostIndex = targetIndex;
        leftMostSearch: while (leftMostIndex < manual.len) : (leftMostIndex += 1) {
            const workingNumber = manual[leftMostIndex];
            for (pageOrderRules) |rule| {
                // Check if the workingNumber is on the right of the rule and that
                if (rule[1] == workingNumber and std.mem.indexOfScalarPos(u32, manual, targetIndex, rule[0]) != null) {
                    continue :leftMostSearch;
                }
            }

            // Not on the right for any applicable rule, so we can put it on the left
            const temp = manual[targetIndex];
            manual[targetIndex] = manual[leftMostIndex];
            manual[leftMostIndex] = temp;
            continue :target;
        }

        return error.CouldNotSortManual;
    }
    return manual[@divFloor(manual.len, 2)];
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 143), result);
}

test "Part 2 example" {
    const result = try part2(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 123), result);
}

const testInput =
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;
