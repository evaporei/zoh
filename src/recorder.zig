const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;
const Poh = @import("root.zig").Poh;
const MockBank = @import("root.zig").MockBank;
const Transaction = @import("root.zig").Transaction;

pub const Recorder = struct {
    poh: Poh,
    transactions: std.ArrayList(Transaction),
    bank: MockBank,

    pub fn init(bank: MockBank) !Recorder {
        return Recorder{
            .poh = try Poh.init("initial hash", 5),
            .transactions = std.ArrayList(Transaction).init(std.heap.page_allocator),
            .bank = bank,
        };
    }

    pub fn tick(self: *Recorder) !void {
        std.debug.print("tick\n", .{});
        var hasher = Sha256.init(.{});
        for (self.transactions.items) |trx| {
            hasher.update(trx);
        }
        self.transactions.clearRetainingCapacity();
        const mixin = try std.heap.page_allocator.dupe(u8, &hasher.finalResult());
        const tick_hash = try self.poh.tick(mixin);
        self.bank.recordTick(tick_hash);
        std.time.sleep(2 * 1e9);
    }

    pub fn recordTransactions(self: *Recorder, trxs: []Transaction) !void {
        for (trxs) |trx| {
            const copied = try std.heap.page_allocator.dupe(u8, trx);
            try self.transactions.append(copied);
        }
    }

    pub fn deinit(self: *Recorder) void {
        self.poh.deinit();
        self.transactions.deinit();
    }
};
