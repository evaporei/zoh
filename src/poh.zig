const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;
const nanoTimestamp = std.time.nanoTimestamp;

pub const Poh = struct {
    currHash: [Sha256.digest_length]u8,
    hashesPerTick: u64,
    numHashes: u64,
    remainingHashes: u64,
    tickNumber: u64,
    slotStartTime: u64,

    pub fn init(initialBuf: []const u8, hashesPerTick: u64) Poh {
        var hasher = Sha256.init(.{});
        hasher.update(initialBuf);
        const initialHash = hasher.finalResult();

        return Poh{
            .currHash = initialHash,
            .hashesPerTick = hashesPerTick,
            .numHashes = 0,
            .remainingHashes = hashesPerTick,
            .tickNumber = 0,
            .slotStartTime = @intCast(nanoTimestamp()),
        };
    }

    fn nextHash(self: *Poh, mixin: []const u8) void {
        var hasher = Sha256.init(.{});
        hasher.update(&self.currHash);
        hasher.update(mixin);
        self.currHash = hasher.finalResult();

        self.numHashes += 1;
        self.remainingHashes -= 1;
    }

    pub fn tick(self: *Poh, mixin: []const u8) [Sha256.digest_length]u8 {
        while (self.remainingHashes > 0) {
            self.nextHash(mixin);
        }

        self.tickNumber += 1;
        self.reset();

        return self.currHash;
    }

    pub fn newSlot(self: *Poh) void {
        self.tickNumber = 0;
        self.slotStartTime = @intCast(nanoTimestamp());
    }

    fn reset(self: *Poh) void {
        self.numHashes = 0;
        self.remainingHashes = self.hashesPerTick;
    }

    pub fn targetTime(self: *Poh, targetNsPerTick: u64) u64 {
        // std.debug.print("startTime {d}\n", .{self.slotStartTime});
        const offsetTickNs = targetNsPerTick * self.tickNumber;
        // std.debug.print("offsetTickNs {d}\n", .{offsetTickNs});
        const offsetNs = targetNsPerTick * self.numHashes / self.hashesPerTick;
        // std.debug.print("offsetNs {d}\n", .{offsetNs});
        return offsetTickNs + offsetNs;
    }
};

const testing = std.testing;

test "target time" {
    const zero = "";
    for (10..12) |targetNsPerTick| {
        var poh = Poh.init(zero, std.math.maxInt(u64));
        try testing.expect(poh.targetTime(targetNsPerTick) == poh.slotStartTime);
        poh.tickNumber = 2;
        try testing.expect(poh.targetTime(targetNsPerTick) ==
            poh.slotStartTime + (targetNsPerTick * 2));
        poh = Poh.init(zero, 5);
        try testing.expect(poh.targetTime(targetNsPerTick) == poh.slotStartTime);
        poh.tickNumber = 2;
        try testing.expect(poh.targetTime(targetNsPerTick) ==
            poh.slotStartTime + (targetNsPerTick * 2));
        poh.numHashes = 3;
        try testing.expect(poh.targetTime(targetNsPerTick) ==
            poh.slotStartTime + (targetNsPerTick * 2 + targetNsPerTick * 3 / 5));
    }
}
