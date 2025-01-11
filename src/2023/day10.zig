const std = @import("std");
const assert = std.debug.assert;

const GridContext = struct {
    grid: [][]const u8,
    allocator: std.mem.Allocator,
    pointersToFree: *std.ArrayList([]Djikstra.Edge),
};
const Djikstra = AutoDijkstra(@Vector(2, usize), usize, GridContext);

fn any(c: u8, values: []const u8) bool {
    return std.mem.indexOfAny(u8, &[1]u8{c}, values) != null;
}

fn getConnectedPipes(context: *GridContext, n: @Vector(2, usize)) ![]Djikstra.Edge {
    const x = n[0];
    const y = n[1];
    // var edges = try context.allocator.alloc(Djikstra.Edge, 4);
    // try context.pointersToFree.append(edges);
    // edges.len = 0;

    const height = context.grid.len;
    const width = context.grid[0].len;

    const grid = context.grid;
    var i: usize = 0;
    var edges = [1]Djikstra.Edge{undefined} ** 4;

    // Up
    if (y > 0 and any(grid[y][x], "|LJS") and any(grid[y - 1][x], "|7FS")) {
        edges[i] = Djikstra.Edge{ .node = [2]usize{ x, y - 1 }, .distance = 1 };
        i += 1;
    }
    // Down
    if (y < height - 1 and any(grid[y][x], "|7FS") and any(grid[y + 1][x], "|LJS")) {
        edges[i] = Djikstra.Edge{ .node = [2]usize{ x, y + 1 }, .distance = 1 };
        i += 1;
    }
    // Left
    if (x > 0 and any(grid[y][x], "-J7S") and any(grid[y][x - 1], "-LFS")) {
        edges[i] = Djikstra.Edge{ .node = [2]usize{ x - 1, y }, .distance = 1 };
        i += 1;
    }

    // Right
    if (x < width - 1 and any(grid[y][x], "-LFS") and any(grid[y][x + 1], "-J7S")) {
        edges[i] = Djikstra.Edge{ .node = [2]usize{ x + 1, y }, .distance = 1 };
        i += 1;
    }

    const slice = try context.allocator.alloc(Djikstra.Edge, i);
    @memcpy(slice, edges[0..i]);
    try context.pointersToFree.append(slice);
    return slice;
}

pub fn part1(input: []const u8, allocator: std.mem.Allocator) !usize {
    var grid = std.ArrayList([]const u8).init(allocator);
    defer grid.deinit();
    var lines = std.mem.splitScalar(u8, input, '\n');
    try grid.append(lines.first());
    const width = grid.items[0].len;
    var start: ?@Vector(2, usize) = if (std.mem.indexOfScalar(u8, grid.items[0], 'S')) |i| [2]usize{ i, 0 } else null;
    while (lines.next()) |line| {
        assert(width == line.len);
        try grid.append(line);
        if (start == null) {
            start = if (std.mem.indexOfScalar(u8, line, 'S')) |i| [2]usize{ i, grid.items.len - 1 } else null;
        }
    }
    assert(start != null);
    var pointersToFree = std.ArrayList([]Djikstra.Edge).init(allocator);
    defer {
        for (pointersToFree.items) |ptr| {
            allocator.free(ptr);
        }
        pointersToFree.deinit();
    }
    var context = GridContext{ .grid = grid.items, .allocator = allocator, .pointersToFree = &pointersToFree };
    var djikstra = Djikstra.init(allocator, &context);
    defer djikstra.deinit();
    const solution = try djikstra.solveAll(start.?, getConnectedPipes);
    defer allocator.free(solution);
    return solution[solution.len - 1].distance;
}

test "Part 1 example" {
    const result = try part1(testInput, std.testing.allocator);

    try std.testing.expectEqual(@as(u32, 8), result);
}

const testInput =
    \\..F7.
    \\.FJ|.
    \\SJ.L7
    \\|F--J
    \\LJ...
;

const DEBUG = false;

pub fn AutoDijkstra(comptime NodeType: type, comptime DistanceType: type, comptime Context: type) type {
    return struct {
        const Self = @This();
        pub const Edge = struct { node: NodeType, distance: DistanceType };
        pub const NodeDistance = struct { node: NodeType, distance: DistanceType };
        pub const EndNode = union(enum) { single: NodeType, multiple: []const NodeType };
        fn lessThan(context: void, a: Edge, b: Edge) std.math.Order {
            _ = context;
            return std.math.order(a.distance, b.distance);
        }
        const Queue = std.PriorityQueue(Edge, void, lessThan);

        queue: Queue,
        doneNodes: std.AutoHashMap(NodeType, void),
        allocator: std.mem.Allocator,
        context: *Context,

        pub fn init(allocator: std.mem.Allocator, context: *Context) Self {
            return Self{
                .queue = Queue.init(allocator, {}),
                .doneNodes = std.AutoHashMap(NodeType, void).init(allocator),
                .allocator = allocator,
                .context = context,
            };
        }

        pub fn deinit(self: *Self) void {
            self.queue.deinit();
            self.doneNodes.deinit();
        }

        fn containsNode(distances: []const NodeDistance, node: NodeType) bool {
            for (distances) |distance| {
                if (std.meta.eql(distance.node, node)) {
                    return true;
                }
            }
            return false;
        }

        pub fn solveAll(self: *Self, start: NodeType, comptime getConnected: fn (context: *Context, n: NodeType) anyerror![]Edge) ![]NodeDistance {
            if (DEBUG) std.debug.print("\n", .{});
            var result = std.ArrayList(NodeDistance).init(self.allocator);
            errdefer result.deinit();

            self.queue.shrinkAndFree(self.queue.capacity());

            const first = Edge{ .node = start, .distance = 0 };
            try self.queue.add(first);
            while (self.queue.removeOrNull()) |edge| {
                if (containsNode(result.items, edge.node)) {
                    continue;
                }
                if (DEBUG) std.debug.print("Checking node {}\n", .{edge.node});
                try result.append(NodeDistance{ .node = edge.node, .distance = edge.distance });

                const edges = try getConnected(self.context, edge.node);
                if (DEBUG) std.debug.print("Edges: {any}\n", .{edges});
                for (edges) |next| {
                    if (containsNode(result.items, next.node)) {
                        continue;
                    }
                    const newPriority = edge.distance + next.distance;
                    // std.mem.indexOfScalar(NodeType, slice: []const T, value: T)
                    const nextEdge = Edge{ .node = next.node, .distance = newPriority };
                    try self.queue.add(nextEdge);
                }
            }

            return try result.toOwnedSlice();
        }

        pub fn solve(self: *Self, start: NodeType, end: EndNode, comptime getConnected: fn (context: *Context, n: NodeType) anyerror![]Edge) !DistanceType {
            self.doneNodes.clearRetainingCapacity();
            self.queue.shrinkAndFree(self.queue.capacity());

            const first = Edge{ .node = start, .distance = 0 };
            try self.queue.add(first);
            var answer: DistanceType = std.math.maxInt(DistanceType);
            while (self.queue.removeOrNull()) |edge| {
                if (self.doneNodes.contains(edge.node)) {
                    continue;
                }
                if (edge.distance > answer) {
                    break;
                }
                if (DEBUG) std.debug.print("Checking node {}\n", .{edge.node});
                try self.doneNodes.put(edge.node, {});

                const edges = try getConnected(self.context, edge.node);
                for (edges) |next| {
                    if (self.doneNodes.contains(next.node)) {
                        continue;
                    }
                    const newPriority = edge.distance + next.distance;
                    // std.mem.indexOfScalar(NodeType, slice: []const T, value: T)
                    const isEndNode = switch (end) {
                        .single => |n| std.meta.eql(next.node, n),
                        .multiple => |nodes| std.mem.indexOfScalar(NodeType, nodes, next.node) != null,
                    };
                    if (DEBUG) std.debug.print("Is end node {}: {}\n", .{ next.node, isEndNode });
                    if (isEndNode) {
                        answer = if (answer > newPriority) newPriority else answer;
                        continue;
                    }
                    const nextEdge = Edge{ .node = next.node, .distance = newPriority };
                    try self.queue.add(nextEdge);
                }
            }

            return answer;
        }
    };
}

const MyContext = struct { edges: [][]PathFinder.Edge };
const PathFinder = AutoDijkstra(usize, u32, MyContext);

fn getConnectedNodes(context: *MyContext, n: usize) ![]PathFinder.Edge {
    return context.edges.ptr[n - 1];
}

test "dijkstra" {
    const allocator = std.testing.allocator;

    const node1edges = try allocator.alloc(PathFinder.Edge, 3);
    defer allocator.free(node1edges);
    node1edges[0] = PathFinder.Edge{ .node = 2, .distance = 7 };
    node1edges[1] = PathFinder.Edge{ .node = 3, .distance = 9 };
    node1edges[2] = PathFinder.Edge{ .node = 6, .distance = 14 };

    const node2edges = try allocator.alloc(PathFinder.Edge, 3);
    defer allocator.free(node2edges);
    node2edges[0] = PathFinder.Edge{ .node = 1, .distance = 7 };
    node2edges[1] = PathFinder.Edge{ .node = 3, .distance = 10 };
    node2edges[2] = PathFinder.Edge{ .node = 4, .distance = 15 };

    const node3edges = try allocator.alloc(PathFinder.Edge, 4);
    defer allocator.free(node3edges);
    node3edges[0] = PathFinder.Edge{ .node = 1, .distance = 9 };
    node3edges[1] = PathFinder.Edge{ .node = 2, .distance = 10 };
    node3edges[2] = PathFinder.Edge{ .node = 4, .distance = 11 };
    node3edges[3] = PathFinder.Edge{ .node = 6, .distance = 2 };

    const node4edges = try allocator.alloc(PathFinder.Edge, 3);
    defer allocator.free(node4edges);
    node4edges[0] = PathFinder.Edge{ .node = 2, .distance = 15 };
    node4edges[1] = PathFinder.Edge{ .node = 3, .distance = 11 };
    node4edges[2] = PathFinder.Edge{ .node = 5, .distance = 6 };

    const node5edges = try allocator.alloc(PathFinder.Edge, 2);
    defer allocator.free(node5edges);
    node5edges[0] = PathFinder.Edge{ .node = 4, .distance = 6 };
    node5edges[1] = PathFinder.Edge{ .node = 6, .distance = 9 };

    const node6edges = try allocator.alloc(PathFinder.Edge, 3);
    defer allocator.free(node6edges);
    node6edges[0] = PathFinder.Edge{ .node = 1, .distance = 14 };
    node6edges[1] = PathFinder.Edge{ .node = 3, .distance = 2 };
    node6edges[2] = PathFinder.Edge{ .node = 5, .distance = 9 };

    const edges = try allocator.alloc(@TypeOf(node1edges), 6);
    edges[0] = node1edges;
    edges[1] = node2edges;
    edges[2] = node3edges;
    edges[3] = node4edges;
    edges[4] = node5edges;
    edges[5] = node6edges;
    defer allocator.free(edges);

    var context = MyContext{ .edges = edges };
    var pathFinder = PathFinder.init(std.testing.allocator, &context);
    defer pathFinder.deinit();

    const answer = try pathFinder.solve(1, PathFinder.EndNode{ .single = 5 }, getConnectedNodes);
    try std.testing.expectEqual(@as(u32, 20), answer);

    var endNodes = try std.testing.allocator.alloc(usize, 2);

    defer std.testing.allocator.free(endNodes);
    endNodes[0] = 4;
    endNodes[0] = 5;

    const answer2 = try pathFinder.solve(1, PathFinder.EndNode{ .multiple = endNodes }, getConnectedNodes);
    try std.testing.expectEqual(@as(u32, 20), answer2);
}

test "dijkstra all" {
    const allocator = std.testing.allocator;

    const node1edges = try allocator.alloc(PathFinder.Edge, 3);
    defer allocator.free(node1edges);
    node1edges[0] = PathFinder.Edge{ .node = 2, .distance = 7 };
    node1edges[1] = PathFinder.Edge{ .node = 3, .distance = 9 };
    node1edges[2] = PathFinder.Edge{ .node = 6, .distance = 14 };

    const node2edges = try allocator.alloc(PathFinder.Edge, 3);
    defer allocator.free(node2edges);
    node2edges[0] = PathFinder.Edge{ .node = 1, .distance = 7 };
    node2edges[1] = PathFinder.Edge{ .node = 3, .distance = 10 };
    node2edges[2] = PathFinder.Edge{ .node = 4, .distance = 15 };

    const node3edges = try allocator.alloc(PathFinder.Edge, 4);
    defer allocator.free(node3edges);
    node3edges[0] = PathFinder.Edge{ .node = 1, .distance = 9 };
    node3edges[1] = PathFinder.Edge{ .node = 2, .distance = 10 };
    node3edges[2] = PathFinder.Edge{ .node = 4, .distance = 11 };
    node3edges[3] = PathFinder.Edge{ .node = 6, .distance = 2 };

    const node4edges = try allocator.alloc(PathFinder.Edge, 3);
    defer allocator.free(node4edges);
    node4edges[0] = PathFinder.Edge{ .node = 2, .distance = 15 };
    node4edges[1] = PathFinder.Edge{ .node = 3, .distance = 11 };
    node4edges[2] = PathFinder.Edge{ .node = 5, .distance = 6 };

    const node5edges = try allocator.alloc(PathFinder.Edge, 2);
    defer allocator.free(node5edges);
    node5edges[0] = PathFinder.Edge{ .node = 4, .distance = 6 };
    node5edges[1] = PathFinder.Edge{ .node = 6, .distance = 9 };

    const node6edges = try allocator.alloc(PathFinder.Edge, 3);
    defer allocator.free(node6edges);
    node6edges[0] = PathFinder.Edge{ .node = 1, .distance = 14 };
    node6edges[1] = PathFinder.Edge{ .node = 3, .distance = 2 };
    node6edges[2] = PathFinder.Edge{ .node = 5, .distance = 9 };

    const edges = try allocator.alloc(@TypeOf(node1edges), 6);
    edges[0] = node1edges;
    edges[1] = node2edges;
    edges[2] = node3edges;
    edges[3] = node4edges;
    edges[4] = node5edges;
    edges[5] = node6edges;
    defer allocator.free(edges);

    var context = MyContext{ .edges = edges };
    var pathFinder = PathFinder.init(std.testing.allocator, &context);
    defer pathFinder.deinit();

    const answer = try pathFinder.solveAll(1, getConnectedNodes);
    defer std.testing.allocator.free(answer);
    const expected = [_]PathFinder.NodeDistance{
        .{ .node = 1, .distance = 0 },
        .{ .node = 2, .distance = 7 },
        .{ .node = 3, .distance = 9 },
        .{ .node = 6, .distance = 11 },
        .{ .node = 4, .distance = 20 },
        .{ .node = 5, .distance = 20 },
    };
    try std.testing.expectEqualSlices(PathFinder.NodeDistance, &expected, answer);
}
