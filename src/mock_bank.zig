const std = @import("std");
const Sha256 = std.crypto.hash.sha2.Sha256;

const TICKS_PER_SLOT = 64;

pub const MockBank = struct {
    tickHeight: u64,
    slot: u64,

    pub fn init() MockBank {
        return MockBank{
            .tickHeight = 0,
            .slot = 0,
        };
    }

    pub fn recordTick(self: *MockBank, _: [Sha256.digest_length]u8) bool {
        self.tickHeight += 1;

        if (self.tickHeight == TICKS_PER_SLOT) {
            self.tickHeight = 0;
            self.slot += 1;
            return true;
        }

        // do something with tick hash
        return false;
    }
};
