const std = @import("std");

const NSString = opaque {};
const SEL = opaque {};
extern fn objc_msgSend() void;

pub fn main() anyerror!void {
    const string: *const NSString = @intToPtr(fn () callconv(.C) *const NSString, @ptrToInt(objc_msgSend))();
        std.log.info("string={}", .{string});
}
