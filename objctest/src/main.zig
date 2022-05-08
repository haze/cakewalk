const std = @import("std");
const objc = @cImport({
    @cInclude("objc/message.h");
});

pub fn main() !void {
    const mutable_array = NSMutableArray.alloc();
    defer mutable_array.release();

    mutable_array.addObject(420);
    mutable_array.addObject(69);
    mutable_array.addObject(666);

    std.log.info("My array has {} items", .{mutable_array.count()});
}

pub const NSObject = struct {
    fn alloc() objc.id {
    }
};

pub const NSMutableArray = struct {
    pub usingnamespace Inherets(NSObject);
};
