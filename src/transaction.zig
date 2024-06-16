const std = @import("std");

// In the real impl, it should be signatures + message (instructions)
pub const Transaction = []const u8;

pub const mockTransactions = generateMockTrxs();

fn generateMockTrxs() [20]Transaction {
    var trxs: [20]Transaction = undefined;
    for (0..20) |i| {
        const trx = std.fmt.comptimePrint("trx{d}", .{i});
        trxs[i] = trx;
    }
    return trxs;
}
