const std = @import("std");
const util = @import("../util.zig");

const Node = struct {
    name: []const u8,
    left: *Node,
    right: *Node,
};

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !u32 {
    var nodes = std.StringArrayHashMap(Node).init(allocator);
    defer nodes.deinit();
    const nodeCount = std.mem.count(u8, input, "\n") - 1;
    try nodes.ensureTotalCapacity(nodeCount);

    var lines = std.mem.splitScalar(u8, input, '\n');
    const steps = lines.first();
    _ = lines.next();
    while (lines.next()) |line| {
        const name = line[0..3];
        try nodes.put(name, Node{ .name = name, .left = undefined, .right = undefined });
    }
    nodes.lockPointers();
    defer nodes.unlockPointers();
    lines.reset();
    _ = lines.first();
    _ = lines.next();
    while (lines.next()) |line| {
        var iter = std.mem.tokenizeAny(u8, line, " =(,)");
        const node = nodes.getPtr(iter.next().?).?;
        node.left = nodes.getPtr(iter.next().?).?;
        node.right = nodes.getPtr(iter.next().?).?;
    }

    var answer: u32 = 0;
    var currentNode = &nodes.get("AAA").?;
    const targetName = nodes.get("ZZZ").?.name.ptr;
    while (true) {
        for (steps) |side| {
            answer += 1;
            currentNode = if (side == 'L') currentNode.left else currentNode.right;
            if (currentNode.name.ptr == targetName) {
                return answer;
            }
        }
    }
}

pub fn part2(input: []const u8, allocator: std.mem.Allocator) !u64 {
    var nodes = std.StringArrayHashMap(Node).init(allocator);
    defer nodes.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    const steps = lines.first();
    _ = lines.next();
    while (lines.next()) |line| {
        const name = line[0..3];
        try nodes.put(name, Node{ .name = name, .left = undefined, .right = undefined });
    }
    nodes.lockPointers();
    defer nodes.unlockPointers();
    lines.reset();
    _ = lines.first();
    _ = lines.next();
    while (lines.next()) |line| {
        var iter = std.mem.tokenizeAny(u8, line, " =(,)");
        const node = nodes.getPtr(iter.next().?).?;
        node.left = nodes.getPtr(iter.next().?).?;
        node.right = nodes.getPtr(iter.next().?).?;
    }

    var currentNodes = std.ArrayList(*Node).init(allocator);
    defer currentNodes.deinit();
    var nodesIter = nodes.iterator();
    while (nodesIter.next()) |node| {
        if (node.key_ptr.*[2] == 'A') {
            try currentNodes.append(node.value_ptr);
        }
    }

    var ghostSteps = try allocator.alloc(u64, currentNodes.items.len);
    defer allocator.free(ghostSteps);
    @memset(ghostSteps, 0);
    var done = try allocator.alloc(bool, currentNodes.items.len);
    defer allocator.free(done);
    @memset(done, false);

    outerWhile: while (true) {
        for (steps) |side| {
            nodeLoop: for (currentNodes.items, 0..) |currentNode, i| {
                if (done[i]) continue;
                ghostSteps[i] += 1;

                const next = if (side == 'L') currentNode.left else currentNode.right;
                currentNodes.items[i] = next;
                if (next.name[2] == 'Z') {
                    done[i] = true;
                    for (done) |isDone| if (!isDone) continue :nodeLoop;
                    break :outerWhile;
                }
            }
        }
    }

    var answer: u64 = 1;
    for (ghostSteps) |step| {
        answer = util.lcm(answer, step);
    }

    return answer;
}

test "Part 1 example" {
    const result = try part1(testInput1, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 6), result);
}

test "Part 2 example" {
    const result = try part2(testInput2, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 6), result);
}

const testInput1 =
    \\LLR
    \\
    \\AAA = (BBB, BBB)
    \\BBB = (AAA, ZZZ)
    \\ZZZ = (ZZZ, ZZZ)
;

const testInput2 =
    \\LR
    \\
    \\11A = (11B, XXX)
    \\11B = (XXX, 11Z)
    \\11Z = (11B, XXX)
    \\22A = (22B, XXX)
    \\22B = (22C, 22C)
    \\22C = (22Z, 22Z)
    \\22Z = (22B, 22B)
    \\XXX = (XXX, XXX)
;
