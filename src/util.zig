const std = @import("std");

pub fn lcm(a: anytype, b: anytype) @TypeOf(a, b) {
    // only unsigned integers are allowed and both must be positive
    comptime switch (@typeInfo(@TypeOf(a, b))) {
        .Int => |int| std.debug.assert(int.signedness == .unsigned),
        .ComptimeInt => {
            std.debug.assert(a > 0);
            std.debug.assert(b > 0);
        },
        else => unreachable,
    };
    std.debug.assert(a != 0 and b != 0);

    const gcd: @TypeOf(a, b) = std.math.gcd(a, b);
    return a / gcd * b;
}

pub fn inputGrid(input: []const u8, allocator: std.mem.Allocator) ![]const []const u8 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var grid = std.ArrayList([]const u8).init(allocator);
    errdefer grid.deinit();

    while (lines.next()) |line| {
        try grid.append(line);
    }

    return grid.toOwnedSlice();
}

pub fn mutableInputGrid(input: []u8, allocator: std.mem.Allocator) ![][]u8 {
    var grid = std.ArrayList([]u8).init(allocator);
    errdefer grid.deinit();

    var start: usize = 0;
    while (std.mem.indexOfScalarPos(u8, input, start, '\n')) |newlinePos| {
        const end = if (input[newlinePos - 1] == '\r') newlinePos - 1 else newlinePos;
        try grid.append(input[start..end]);

        start = newlinePos + 1;
    }
    try grid.append(input[start..]);

    return grid.toOwnedSlice();
}

pub fn getNextPos(grid: []const []const u8, pos: [2]usize, direction: [2]i8) ?[2]usize {
    var result = pos;
    const add0 = direction[0] >= 0;
    const add1 = direction[1] >= 0;
    const value0: u8 = @intCast(@abs(direction[0]));
    const value1: u8 = @intCast(@abs(direction[1]));

    if (add0) {
        result[0] += value0;
        if (result[0] >= grid.len) return null;
    } else {
        const ov = @subWithOverflow(result[0], value0);
        if (ov[1] > 0) return null;
        result[0] = ov[0];
    }

    if (add1) {
        result[1] += value1;
        if (result[1] >= grid[result[0]].len) return null;
    } else {
        const ov = @subWithOverflow(result[1], value1);
        if (ov[1] > 0) return null;
        result[1] = ov[0];
    }

    return result;
}

test "LCM" {
    const a: u32 = 10;
    const b: u32 = 35;
    try std.testing.expectEqual(@as(u32, 70), lcm(a, b));
}
