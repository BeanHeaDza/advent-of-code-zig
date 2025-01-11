const std = @import("std");
const util = @import("../util.zig");
const AutoDijkstra = @import("../dijkstra.zig").AutoDijkstra;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;
const print = std.debug.print;
fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

const DEBUG = false;

const Context = struct {
    input: []const u8,
    cleanUp: ArrayList([]Dijkstra.Edge),
    width: usize,
    height: usize,
    allocator: Allocator,
};

const Dijkstra = AutoDijkstra(usize, u32, Context);

pub fn part1(input: []const u8, allocator: Allocator) !u32 {
    const width = std.mem.indexOfScalar(u8, input, '\n') orelse return error.InvalidInput1;
    if (@rem(input.len, width + 1) != width) {
        return error.InvalidInput2;
    }
    const height = input.len / (width + 1);
    var context = Context{ .input = input, .cleanUp = ArrayList([]Dijkstra.Edge).init(allocator), .width = width, .height = height, .allocator = allocator };
    defer {
        for (context.cleanUp.items) |ptr| {
            allocator.free(ptr);
        }
        context.cleanUp.deinit();
    }

    var dijkstra = Dijkstra.init(allocator, &context);
    defer dijkstra.deinit();

    const startIndex = std.mem.indexOfScalar(u8, input, 'S') orelse return error.StartNotFound;
    const endIndex = std.mem.indexOfScalar(u8, input, 'E') orelse return error.EndNotFound;

    return dijkstra.solve(startIndex, Dijkstra.EndNode{ .single = endIndex }, getConnected);
}

pub fn part2(input: []const u8, allocator: Allocator) !u32 {
    if (DEBUG) print("\n", .{});
    const width = std.mem.indexOfScalar(u8, input, '\n') orelse return error.InvalidInput1;
    if (@rem(input.len, width + 1) != width) {
        return error.InvalidInput2;
    }
    const height = input.len / (width + 1);
    var context = Context{ .input = input, .cleanUp = ArrayList([]Dijkstra.Edge).init(allocator), .width = width, .height = height, .allocator = allocator };
    defer {
        for (context.cleanUp.items) |ptr| {
            allocator.free(ptr);
        }
        context.cleanUp.deinit();
    }

    var dijkstra = Dijkstra.init(allocator, &context);
    defer dijkstra.deinit();

    const startIndex = std.mem.indexOfScalar(u8, input, 'E') orelse return error.EndNotFound;

    var endIndices = ArrayList(usize).init(allocator);
    defer endIndices.deinit();

    for (input, 0..) |c, i| {
        if (c == 'S' or c == 'a') {
            try endIndices.append(i);
        }
    }
    if (DEBUG) print("{} a height nodes {any}\n", .{ endIndices.items.len, endIndices.items });
    return dijkstra.solve(startIndex, Dijkstra.EndNode{ .multiple = endIndices.items }, getConnectedDown);
}

inline fn calcHeight(char: u8) u8 {
    return switch (char) {
        'S' => 'a',
        'E' => 'z',
        else => char,
    };
}

fn getConnected(context: *Context, node: usize) anyerror![]Dijkstra.Edge {
    const char = context.input[node];
    const height: u8 = calcHeight(char);
    var edges = [_]Dijkstra.Edge{undefined} ** 4;
    var len: usize = 0;

    // Up
    if (node > context.width) {
        const upIndex = node - context.width - 1;
        const upChar = context.input[upIndex];
        if (calcHeight(upChar) <= height + 1) {
            edges[len] = Dijkstra.Edge{ .node = upIndex, .distance = 1 };
            len += 1;
        }
    }

    // Down
    if (node + context.width + 1 < context.input.len) {
        const downIndex = node + context.width + 1;
        const downChar = context.input[downIndex];
        if (calcHeight(downChar) <= height + 1) {
            edges[len] = Dijkstra.Edge{ .node = downIndex, .distance = 1 };
            len += 1;
        }
    }

    // Left
    if (@mod(node, context.width + 1) > 0) {
        const leftIndex = node - 1;
        const leftChar = context.input[leftIndex];
        if (calcHeight(leftChar) <= height + 1) {
            edges[len] = Dijkstra.Edge{ .node = leftIndex, .distance = 1 };
            len += 1;
        }
    }

    // Right
    if (@mod(node, context.width + 1) < context.width - 1) {
        const rightIndex = node + 1;
        const rightChar = context.input[rightIndex];
        if (calcHeight(rightChar) <= height + 1) {
            edges[len] = Dijkstra.Edge{ .node = rightIndex, .distance = 1 };
            len += 1;
        }
    }

    var result = try context.allocator.alloc(Dijkstra.Edge, len);
    for (0..len) |i| {
        result[i] = edges[i];
    }
    try context.cleanUp.append(result);
    return result;
}

fn getConnectedDown(context: *Context, node: usize) anyerror![]Dijkstra.Edge {
    const char = context.input[node];
    const height: u8 = calcHeight(char);
    var edges = [_]Dijkstra.Edge{undefined} ** 4;
    var len: usize = 0;
    if (DEBUG) print("Checking for edges for char {c}, index {}, height, {}\n", .{ char, node, height });

    // Up
    if (node > context.width) {
        const upIndex = node - context.width - 1;
        const upChar = context.input[upIndex];
        if (calcHeight(upChar) + 1 >= height) {
            edges[len] = Dijkstra.Edge{ .node = upIndex, .distance = 1 };
            len += 1;
        }
    }

    // Down
    if (node + context.width + 1 < context.input.len) {
        const downIndex = node + context.width + 1;
        const downChar = context.input[downIndex];
        if (calcHeight(downChar) + 1 >= height) {
            edges[len] = Dijkstra.Edge{ .node = downIndex, .distance = 1 };
            len += 1;
        }
    }

    // Left
    if (@mod(node, context.width + 1) > 0) {
        const leftIndex = node - 1;
        const leftChar = context.input[leftIndex];
        if (calcHeight(leftChar) + 1 >= height) {
            edges[len] = Dijkstra.Edge{ .node = leftIndex, .distance = 1 };
            len += 1;
        }
    }

    // Right
    if (@mod(node, context.width + 1) < context.width - 1) {
        const rightIndex = node + 1;
        const rightChar = context.input[rightIndex];
        if (calcHeight(rightChar) + 1 >= height) {
            edges[len] = Dijkstra.Edge{ .node = rightIndex, .distance = 1 };
            len += 1;
        }
    }

    var result = try context.allocator.alloc(Dijkstra.Edge, len);
    for (0..len) |i| {
        result[i] = edges[i];
    }
    try context.cleanUp.append(result);
    return result;
}

test "Part 1 example" {
    const result = try part1(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u32, 31), result);
}

test "Part 2 example" {
    const result = try part2(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u32, 29), result);
}

const testInput =
    \\Sabqponm
    \\abcryxxl
    \\accszExk
    \\acctuvwj
    \\abdefghi
;
