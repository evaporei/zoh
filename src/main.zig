const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;

const MockBank = struct {
    tickHeight: u32,

    fn init() MockBank {
        return MockBank{ .tickHeight = 0 };
    }

    fn record_tick(self: *MockBank, _: []const u8) void {
        self.tickHeight += 1;
        // do something with tick hash
    }
};

const Poh = struct {
    currHash: []u8,
    hashesPerTick: u32,
    numHashes: u32,
    remainingHashes: u32,

    fn init(initialHash: []const u8, hashesPerTick: u32) !Poh {
        const copiedHash = try std.heap.page_allocator.dupe(u8, initialHash);
        return Poh{
            .currHash = copiedHash,
            .hashesPerTick = hashesPerTick,
            .numHashes = 0,
            .remainingHashes = hashesPerTick,
        };
    }

    fn nextHash(self: *Poh, mixin: []const u8) !void {
        var hasher = Sha256.init(.{});
        hasher.update(self.currHash);
        hasher.update(mixin);
        std.heap.page_allocator.free(self.currHash);
        self.currHash = try std.heap.page_allocator.dupe(u8, &hasher.finalResult());
        self.numHashes += 1;
        self.remainingHashes -= 1;
    }

    fn tick(self: *Poh, mixin: []const u8) ![]const u8 {
        while (self.remainingHashes > 0) {
            std.debug.print("new hash\n", .{});
            try self.nextHash(mixin);
        }
        std.debug.print("reset\n", .{});
        const final = try std.heap.page_allocator.dupe(u8, self.currHash);
        try self.reset();
        return final;
    }

    fn reset(self: *Poh) !void {
        self.numHashes = 0;
        self.remainingHashes = self.hashesPerTick;
    }

    fn deinit(self: *Poh) void {
        std.heap.page_allocator.free(self.currHash);
    }
};

const Recorder = struct {
    poh: Poh,
    transactions: std.ArrayList([]const u8),
    bank: MockBank,

    fn init(bank: MockBank) !Recorder {
        return Recorder{
            .poh = try Poh.init("initial hash", 5),
            .transactions = std.ArrayList([]const u8).init(std.heap.page_allocator),
            .bank = bank,
        };
    }

    fn tick(self: *Recorder) !void {
        std.debug.print("tick\n", .{});
        var hasher = Sha256.init(.{});
        for (self.transactions.items) |trx| {
            hasher.update(trx);
        }
        self.transactions.clearRetainingCapacity();
        const mixin = try std.heap.page_allocator.dupe(u8, &hasher.finalResult());
        const tick_hash = try self.poh.tick(mixin);
        self.bank.record_tick(tick_hash);
        std.time.sleep(2 * 1e9);
    }

    fn record_transactions(self: *Recorder, trxs: std.ArrayList([]const u8)) !void {
        for (trxs.items) |trx| {
            const copied = try std.heap.page_allocator.dupe(u8, trx);
            try self.transactions.append(copied);
        }
    }

    fn deinit(self: *Recorder) void {
        self.poh.deinit();
        self.transactions.deinit();
    }
};

const Service = struct {
    recorder: Recorder,

    fn init(bank: MockBank) !Service {
        return Service{ .recorder = try Recorder.init(bank) };
    }

    fn run(self: *Service) !void {
        std.debug.print("start\n", .{});
        while (true) {
            var mock_trxs = std.ArrayList([]const u8).init(std.heap.page_allocator);
            for (0..20) |i| {
                var buf: [5]u8 = undefined;
                const mock_trx = try std.fmt.bufPrint(&buf, "trx{d}", .{i});
                try mock_trxs.append(mock_trx);
            }
            defer mock_trxs.deinit();
            try self.recorder.record_transactions(mock_trxs);
            try self.recorder.tick();
        }
    }

    fn deinit(self: *Service) void {
        self.recorder.deinit();
    }
};

pub fn main() !void {
    const bank = MockBank.init();
    var service = try Service.init(bank);
    defer service.deinit();
    try service.run();
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
