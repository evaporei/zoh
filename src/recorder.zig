const std = @import("std");
const Allocator = std.mem.Allocator;
const Sha256 = std.crypto.hash.sha2.Sha256;

const Poh = @import("root.zig").Poh;
const MockBank = @import("root.zig").MockBank;
const Transaction = @import("root.zig").Transaction;

const HASHES_PER_SECOND = 2_000_000;
const TICKS_PER_SECOND = 160;

// 12.500
const HASHES_PER_TICK = HASHES_PER_SECOND / TICKS_PER_SECOND;

const SLOT_ADJUSTMENT_NS = 50_000_000;
const TARGET_TICK_DURATION = 1000 * 1000 * 1000 / TICKS_PER_SECOND;

// 400ms
const SLOT_IN_NS = 400_000_000;
// 20ms
const TICK_IN_NS = 20_000_000;
const TICKS_PER_SLOT = 20;

pub const Recorder = struct {
    allocator: Allocator,
    poh: Poh,
    transactions: std.ArrayList(Transaction),
    bank: MockBank,

    pub fn init(allocator: Allocator, bank: MockBank) !Recorder {
        return Recorder{
            .allocator = allocator,
            .poh = Poh.init("any random starting value", HASHES_PER_TICK),
            .transactions = std.ArrayList(Transaction).init(allocator),
            .bank = bank,
        };
    }

    pub fn tick(self: *Recorder) !void {
        const mixin = self.hashTransactions();
        self.transactions.clearRetainingCapacity();
        var timer = try std.time.Timer.start();
        const tickHash = self.poh.tick(&mixin);
        const elapsed = timer.read();
        std.debug.print("elapsed: {d}\n", .{elapsed});
        const newSlot = self.bank.recordTick(tickHash);

        const target = self.targetNsPerTick(TICKS_PER_SLOT);
        // std.debug.print("target {d}\n", .{target});
        const timeToSleep = self.poh.targetTime(target);
        // std.debug.print("time to sleep {d}\n", .{timeToSleep});
        std.time.sleep(timeToSleep);
        if (newSlot) {
            std.debug.print("new slot\n", .{});
            self.poh.newSlot();
        }
    }

    fn hashTransactions(self: *Recorder) [Sha256.digest_length]u8 {
        var hasher = Sha256.init(.{});
        for (self.transactions.items) |trx| {
            hasher.update(trx);
        }
        return hasher.finalResult();
    }

    fn targetNsPerTick(_: *Recorder, ticksPerSlot: u64) u64 {
        return TARGET_TICK_DURATION - SLOT_ADJUSTMENT_NS / ticksPerSlot;
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
