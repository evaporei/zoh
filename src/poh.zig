const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;

pub const Poh = struct {
    currHash: [Sha256.digest_length]u8,
    hashesPerTick: u32,
    numHashes: u32,
    remainingHashes: u32,

    pub fn init(initialBuf: []const u8, hashesPerTick: u32) !Poh {
        var hasher = Sha256.init(.{});
        hasher.update(initialBuf);
        const initialHash = hasher.finalResult();

        return Poh{
            .currHash = initialHash,
            .hashesPerTick = hashesPerTick,
            .numHashes = 0,
            .remainingHashes = hashesPerTick,
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
            std.debug.print("new hash\n", .{});
            self.nextHash(mixin);
        }

        std.debug.print("reset\n", .{});
        self.reset();
        return self.currHash;
    }

    fn reset(self: *Poh) void {
        self.numHashes = 0;
        self.remainingHashes = self.hashesPerTick;
    }
};
