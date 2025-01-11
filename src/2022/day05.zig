const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;

pub fn part1(input: []const u8, allocator: Allocator) ![]const u8 {
    var parsed = try parseInput(input, allocator);
    defer parsed.deinit();

    for (parsed.instructions.items) |instruction| {
        var from: *ArrayList(u8) = parsed.crates.getPtr(instruction[1]) orelse return error.FromNotFound;
        var to: *ArrayList(u8) = parsed.crates.getPtr(instruction[2]) orelse return error.ToNotFound;
        for (0..instruction[0]) |i| {
            _ = i;

            try to.append(from.pop());
        }
        parsed.print();
    }
    var result = ArrayList(u8).init(allocator);
    const to = parsed.crates.count();
    for (0..to) |i| {
        const crateId: u8 = @intCast(i + 1);
        var crate: ArrayList(u8) = parsed.crates.get(crateId) orelse return error.CrateNotFound;
        try result.append(crate.pop());
    }
    return result.toOwnedSlice();
}

pub fn part2(input: []const u8, allocator: Allocator) ![]const u8 {
    var parsed = try parseInput(input, allocator);
    defer parsed.deinit();

    for (parsed.instructions.items) |instruction| {
        var from: *ArrayList(u8) = parsed.crates.getPtr(instruction[1]) orelse return error.FromNotFound;
        var to: *ArrayList(u8) = parsed.crates.getPtr(instruction[2]) orelse return error.ToNotFound;
        const targetIndex = to.items.len;
        for (0..instruction[0]) |i| {
            _ = i;

            try to.insert(targetIndex, from.pop());
        }
        parsed.print();
    }
    var result = ArrayList(u8).init(allocator);
    const to = parsed.crates.count();
    for (0..to) |i| {
        const crateId: u8 = @intCast(i + 1);
        var crate: ArrayList(u8) = parsed.crates.get(crateId) orelse return error.CrateNotFound;
        try result.append(crate.pop());
    }
    return result.toOwnedSlice();
}

const Input = struct {
    crates: std.AutoHashMap(u8, ArrayList(u8)),
    instructions: ArrayList([3]u8),
    allocator: Allocator,
    fn init(allocator: Allocator) Input {
        return Input{
            .crates = std.AutoHashMap(u8, ArrayList(u8)).init(allocator),
            .instructions = ArrayList([3]u8).init(allocator),
            .allocator = allocator,
        };
    }

    fn deinit(self: *Input) void {
        var iter = self.crates.valueIterator();
        while (iter.next()) |c| {
            c.*.deinit();
        }
        self.crates.deinit();
        self.instructions.deinit();
    }

    fn addCrate(self: *Input, c: u8, i: u8) !void {
        const x = try self.crates.getOrPut(i);
        if (!x.found_existing) {
            x.value_ptr.* = ArrayList(u8).init(self.allocator);
        }
        try x.value_ptr.*.insert(0, c);
    }

    fn print(self: Input) void {
        for (1..self.crates.count() + 1) |i| {
            const x: u8 = @intCast(i);
            const crate: ArrayList(u8) = self.crates.get(x) orelse unreachable;
            _ = crate;
        }
    }
};

fn parseInput(input: []const u8, allocator: Allocator) !Input {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var result = Input.init(allocator);

    var gettingBoxes = true;
    while (lines.next()) |line| {
        if (gettingBoxes) {
            if (line.len == 0) {
                gettingBoxes = false;
                continue;
            }
            for (line, 0..) |c, i| {
                if (c >= 'A' and c <= 'Z') {
                    const index: u8 = @intCast(i);
                    const z = (index + 3) / 4;
                    try result.addCrate(c, z);
                }
            }
        } else {
            var tokenizer = std.mem.tokenizeScalar(u8, line, ' ');
            var instruction = [_]u8{ 0, 0, 0 };
            for (0..6) |i| {
                const next: ?[]const u8 = tokenizer.next();
                if (next == null) {
                    break;
                }
                if (@rem(i, 2) == 1) {
                    instruction[(i - 1) / 2] = try std.fmt.parseInt(u8, next.?, 10);
                }
            }
            if (instruction[2] != 0) {
                try result.instructions.append(instruction);
            }
        }
    }

    return result;
}

const testInput =
    \\    [D]    
    \\[N] [C]    
    \\[Z] [M] [P]
    \\ 1   2   3 
    \\
    \\move 1 from 2 to 1
    \\move 3 from 1 to 3
    \\move 2 from 2 to 1
    \\move 1 from 1 to 2
;

test "Parses correctly" {
    var input = try parseInput(testInput, testing.allocator);
    defer input.deinit();
    try testing.expectEqual(input.crates.count(), 3);
    try testing.expectEqualSlices(u8, "ZN", input.crates.get(1).?.items);
    try testing.expectEqualSlices(u8, "MCD", input.crates.get(2).?.items);
    try testing.expectEqualSlices(u8, "P", input.crates.get(3).?.items);
    try testing.expectEqual(@as(usize, 4), input.instructions.items.len);
    try testing.expectEqualSlices(u8, &[3]u8{ 1, 2, 1 }, &input.instructions.items[0]);
    try testing.expectEqualSlices(u8, &[3]u8{ 3, 1, 3 }, &input.instructions.items[1]);
    try testing.expectEqualSlices(u8, &[3]u8{ 2, 2, 1 }, &input.instructions.items[2]);
    try testing.expectEqualSlices(u8, &[3]u8{ 1, 1, 2 }, &input.instructions.items[3]);
}

test "Part 1 example" {
    const result = try part1(testInput, testing.allocator);
    defer testing.allocator.free(result);

    try std.testing.expectEqualSlices(u8, "CMZ", result);
}

test "Part 2 example" {
    const result = try part2(testInput, testing.allocator);
    defer testing.allocator.free(result);

    try std.testing.expectEqualSlices(u8, "MCD", result);
}
