const zoh = @import("root.zig");
const MockBank = zoh.MockBank;
const Service = zoh.Service;

pub fn main() !void {
    const bank = MockBank.init();
    var service = try Service.init(bank);
    defer service.deinit();
    try service.run();
}
