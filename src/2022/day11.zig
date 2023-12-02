const std = @import("std");
const util = @import("../util.zig");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const testing = std.testing;
const print = std.debug.print;

const Monkey = struct {
    items: ArrayList(u64),
    operation: []const u8,
    testDenominator: u64,
    trueMoney: usize,
    falseMoney: usize,
    inspections: u64,
};

const Monkeys = struct {
    monkeys: ArrayList(Monkey),
    allocator: Allocator,

    fn deinit(self: Monkeys) void {
        for (self.monkeys.items) |m| {
            m.items.deinit();
            self.allocator.free(m.operation);
        }
        self.monkeys.deinit();
    }
};

fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn part1(input: []const u8, allocator: Allocator) !u64 {
    var monkeys = try parseInput(input, allocator);
    defer monkeys.deinit();

    for (0..20) |_| {
        for (monkeys.monkeys.items) |*monkey| {
            while (monkey.items.popOrNull()) |x| {
                var item: u64 = x;
                monkey.inspections += 1;
                var words = std.mem.splitScalar(u8, monkey.operation, ' ');
                var leftWord = words.first();
                var left = if (eql(leftWord, "old")) item else try std.fmt.parseInt(u64, leftWord, 10);
                var opWord = words.next() orelse return error.InvalidOperation;
                var op = opWord[0];
                var rightWord = words.next() orelse return error.InvalidOperation;
                var right = if (eql(rightWord, "old")) item else try std.fmt.parseInt(u64, rightWord, 10);
                item = switch (op) {
                    '+' => left + right,
                    '-' => left - right,
                    '/' => left / right,
                    '*' => left * right,
                    else => return error.InvalidOperationOp,
                };
                item /= 3;
                if (@mod(item, monkey.testDenominator) == 0) {
                    try monkeys.monkeys.items[monkey.trueMoney].items.append(item);
                } else {
                    try monkeys.monkeys.items[monkey.falseMoney].items.append(item);
                }
            }
        }
    }

    var inspections = try allocator.alloc(u64, monkeys.monkeys.items.len);
    defer allocator.free(inspections);
    for (monkeys.monkeys.items, 0..) |m, i| {
        inspections[i] = m.inspections;
    }

    std.mem.sort(u64, inspections, {}, greaterThan);

    return inspections[0] * inspections[1];
}

pub fn part2(input: []const u8, allocator: Allocator) !u64 {
    var monkeys = try parseInput(input, allocator);
    defer monkeys.deinit();

    var denominator: u64 = 1;
    for (monkeys.monkeys.items) |monkey| {
        denominator = util.lcm(denominator, monkey.testDenominator);
    }

    for (0..10000) |_| {
        for (monkeys.monkeys.items) |*monkey| {
            while (monkey.items.popOrNull()) |x| {
                var item: u64 = x;
                monkey.inspections += 1;
                var words = std.mem.splitScalar(u8, monkey.operation, ' ');
                var leftWord = words.first();
                var left = if (eql(leftWord, "old")) item else try std.fmt.parseInt(u64, leftWord, 10);
                var opWord = words.next() orelse return error.InvalidOperation;
                var op = opWord[0];
                var rightWord = words.next() orelse return error.InvalidOperation;
                var right = if (eql(rightWord, "old")) item else try std.fmt.parseInt(u64, rightWord, 10);
                item = switch (op) {
                    '+' => left + right,
                    '-' => left - right,
                    '/' => left / right,
                    '*' => left * right,
                    else => return error.InvalidOperationOp,
                };
                item = @mod(item, denominator);
                if (@mod(item, monkey.testDenominator) == 0) {
                    try monkeys.monkeys.items[monkey.trueMoney].items.append(item);
                } else {
                    try monkeys.monkeys.items[monkey.falseMoney].items.append(item);
                }
            }
        }
    }

    var inspections = try allocator.alloc(u64, monkeys.monkeys.items.len);
    defer allocator.free(inspections);
    for (monkeys.monkeys.items, 0..) |m, i| {
        inspections[i] = m.inspections;
    }

    std.mem.sort(u64, inspections, {}, greaterThan);

    return inspections[0] * inspections[1];
}

fn greaterThan(_: void, lhs: u64, rhs: u64) bool {
    return std.math.compare(lhs, .gt, rhs);
}

fn parseInput(input: []const u8, allocator: Allocator) !Monkeys {
    var result = Monkeys{
        .allocator = allocator,
        .monkeys = ArrayList(Monkey).init(allocator),
    };
    errdefer result.deinit();

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |_| {
        // Items
        const itemsLine = lines.next() orelse return error.InvalidInput;
        const itemStart = comptime "  Starting items: ".len;
        var itemIter = std.mem.split(u8, itemsLine[itemStart..], ", ");
        var items = ArrayList(u64).init(allocator);
        errdefer items.deinit();
        while (itemIter.next()) |item| {
            try items.append(try std.fmt.parseInt(u64, item, 10));
        }

        // Operation
        const operationLine = lines.next() orelse return error.InvalidInput;
        const operationStart = comptime "  Operation: new = ".len;
        var operation = try allocator.dupe(u8, operationLine[operationStart..]);
        errdefer allocator.free(operation);

        // Divisor
        const divisorLine = lines.next() orelse return error.InvalidInput;
        const divisorStart = comptime "  Test: divisible by ".len;
        const testDenominator = try std.fmt.parseInt(u64, divisorLine[divisorStart..], 10);

        // true monkey
        const trueLine = lines.next() orelse return error.InvalidInput;
        const trueLineOffset = comptime "    If true: throw to monkey ".len;
        const trueMonkey = try std.fmt.parseInt(usize, trueLine[trueLineOffset..], 10);

        // false monkey
        const falseLine = lines.next() orelse return error.InvalidInput;
        const falseLineOffset = comptime "    If false: throw to monkey ".len;
        const falseMonkey = try std.fmt.parseInt(usize, falseLine[falseLineOffset..], 10);

        // empty line
        _ = lines.next();

        var monkey = Monkey{
            .items = items,
            .operation = operation,
            .testDenominator = testDenominator,
            .trueMoney = trueMonkey,
            .falseMoney = falseMonkey,
            .inspections = 0,
        };
        try result.monkeys.append(monkey);
    }

    return result;
}

test "Parse input" {
    var result = try parseInput(testInput, testing.allocator);
    defer result.deinit();

    try testing.expectEqual(@as(usize, 4), result.monkeys.items.len);

    var monkey1Items = ArrayList(u64).init(testing.allocator);
    defer monkey1Items.deinit();
    try monkey1Items.appendSlice(&[_]u64{ 54, 65, 75, 74 });
    const monkey1 = Monkey{ .items = monkey1Items, .operation = "old + 6", .testDenominator = 19, .trueMoney = 2, .falseMoney = 0, .inspections = 0 };
    try testing.expectEqualDeep(monkey1, result.monkeys.items[1]);
}

test "Should clean up memory when parsing fails" {
    var result = parseInput(brokenInput, testing.allocator);
    try testing.expectError(error.InvalidInput, result);
}

test "Part 1 example" {
    var result = try part1(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u64, 10605), result);
}

test "Part 2 example" {
    var result = try part2(testInput, testing.allocator);

    try std.testing.expectEqual(@as(u64, 2713310158), result);
}

const testInput =
    \\Monkey 0:
    \\  Starting items: 79, 98
    \\  Operation: new = old * 19
    \\  Test: divisible by 23
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 3
    \\
    \\Monkey 1:
    \\  Starting items: 54, 65, 75, 74
    \\  Operation: new = old + 6
    \\  Test: divisible by 19
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 0
    \\
    \\Monkey 2:
    \\  Starting items: 79, 60, 97
    \\  Operation: new = old * old
    \\  Test: divisible by 13
    \\    If true: throw to monkey 1
    \\    If false: throw to monkey 3
    \\
    \\Monkey 3:
    \\  Starting items: 74
    \\  Operation: new = old + 3
    \\  Test: divisible by 17
    \\    If true: throw to monkey 0
    \\    If false: throw to monkey 1
;
const brokenInput =
    \\Monkey 0:
    \\  Starting items: 79, 98
    \\  Operation: new = old * 19
    \\  Test: divisible by 23
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 3
    \\
    \\Monkey 1:
    \\  Starting items: 54, 65, 75, 74
    \\  Operation: new = old + 6
    \\  Test: divisible by 19
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 0
    \\
    \\Monkey 2:
    \\  Starting items: 79, 60, 97
    \\  Operation: new = old * old
    \\  Test: divisible by 13
;
