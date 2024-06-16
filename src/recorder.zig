const std = @import("std");
const Allocator = std.mem.Allocator;
const Sha256 = std.crypto.hash.sha2.Sha256;

const Poh = @import("root.zig").Poh;
const MockBank = @import("root.zig").MockBank;
const Transaction = @import("root.zig").Transaction;

const hashes_per_tick = 5;

pub const Recorder = struct {
    allocator: Allocator,
    poh: Poh,
    transactions: std.ArrayList(Transaction),
    bank: MockBank,

    pub fn init(allocator: Allocator, bank: MockBank) !Recorder {
        return Recorder{
            .allocator = allocator,
            .poh = try Poh.init("initial buf", hashes_per_tick),
            .transactions = std.ArrayList(Transaction).init(allocator),
            .bank = bank,
        };
    }

    pub fn tick(self: *Recorder) void {
        std.debug.print("tick\n", .{});

        const mixin = self.hashTransactions();
        self.transactions.clearRetainingCapacity();
        const tick_hash = self.poh.tick(&mixin);

        self.bank.recordTick(tick_hash);
        std.time.sleep(2 * std.time.ns_per_s);
    }

    fn hashTransactions(self: *Recorder) [Sha256.digest_length]u8 {
        var hasher = Sha256.init(.{});
        for (self.transactions.items) |trx| {
            hasher.update(trx);
        }
        return hasher.finalResult();
    }

    pub fn recordTransactions(self: *Recorder, trxs: []const Transaction) !void {
        for (trxs) |trx| {
            const copied = try self.allocator.dupe(u8, trx);
            try self.transactions.append(copied);
        }
    }

    pub fn deinit(self: *Recorder) void {
        self.transactions.deinit();
    }
};
