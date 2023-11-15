const std = @import("std");

const DEBUG = false;

pub fn AutoDijkstra(comptime NodeType: type, comptime DistanceType: type, comptime Context: type) type {
    return struct {
        const Self = @This();
        pub const Edge = struct { node: NodeType, distance: DistanceType };
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

                var edges = try getConnected(self.context, edge.node);
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
