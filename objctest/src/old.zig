const objc = @cImport({
    @cInclude("objc/objc-runtime.h");
    @cInclude("objc/objc.h");
});

export const objc_info_flags: u32 linksection("__DATA,__objc_imageinfo,regular,no_dead_strip") = 64;
export const objc_info_version: u32 linksection("__DATA,__objc_imageinfo,regular,no_dead_strip") = 64;

export const OBJC_METH_VAR_NAME_: *const [49:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "initWithBytesNoCopy:length:encoding:freeWhenDone:";

const Foo = struct {
    ptr: *const [49:0]u8,
};

export var OBJC_SELECTOR_REFERENCES_: Foo linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = Foo{
    .ptr = OBJC_METH_VAR_NAME_,
};

const std = @import("std");

// extern fn objc_getClass(class_name: [*:0]const u8) *objc.Class;
// extern fn sel_getUid(selector_name: [*:0]const u8) *SEL;

// const static_hash: usize = blk: {
//     break :blk @intToPtr(fn (*Object, SEL) usize, @ptrToInt(objc.objc_msgSend))(ns_object_instance, @ptrCast(SEL, OBJC_SELECTOR_REFERENCES_.ptr));
// };

// pub fn main() void {
//     var ns_string_class = objc.objc_getClass("NSString");
//     var alloc_sel = objc.sel_getUid("new");
//     var func = @ptrCast(fn (objc.Class, SEL) callconv(.C) *objc.id, objc.objc.objc_msgSend);
//     var ns_string_instance =
//         @call(.{}, func, .{ ns_string_class, alloc_sel });
//
//     std.log.info("string = {*}", .{ns_string_instance});

// const content = "hello";

// @intToPtr(fn (*Object, SEL, *const anyopaque, u64, u64, bool) callconv(.C) void, @ptrToInt(objc.objc_msgSend))(ns_string_instance, @ptrCast(SEL, OBJC_SELECTOR_REFERENCES_.ptr), content, content.len, 4, false);
// @intToPtr(fn (*Object, SEL, *const anyopaque, u64, u64, bool) callconv(.C) void, @ptrToInt(objc.objc_msgSend))(ns_string_instance, sel_getUid("initWithBytesNoCopy:length:encoding:freeWhenDone:"), content, content.len, 4, false);

// var length_sel = objc.sel_getUid("length");
// const length = @intToPtr(fn (objc.id, SEL) callconv(.C) u64, @ptrToInt(objc.objc.objc_msgSend))(ns_string_instance, length_sel);
//
// std.log.info("NSString legnth = {} ({*})", .{ length, ns_string_instance });
// }

const SEL = *const objc.objc_selector;

pub fn main() void {
    var string = NSString.alloc();
    const contents = "hello, zig";
    const encoding = 4;
    string.initWithBytesNoCopy(contents, contents.len, encoding, false);
    const reported_length = string.lengthOfBytesUsingEncoding(encoding);
    std.log.info("Got {}, expected {}", .{ reported_length, contents.len });
}

pub const NSObject = opaque {
    export const objc_selector_NSObject_hash: *const [4:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "hash";
    export var objc_selector_NSObject_hash_ref: struct {
        ptr: *const [4:0]u8,
    } linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = .{
        .ptr = objc_selector_NSObject_hash,
    };
    pub inline fn hash(self: *NSObject) u32 {
        return @intToPtr(fn (*NSObject, SEL) u32, @ptrToInt(objc.objc_msgSend))(self, @ptrCast(SEL, objc_selector_NSObject_hash_ref.ptr));
    }
    export const objc_selector_NSObject_new: *const [3:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "new";
    export var objc_selector_NSObject_new_ref: struct {
        ptr: *const [3:0]u8,
    } linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = .{
        .ptr = objc_selector_NSObject_new,
    };
    pub inline fn new() *NSObject {
        const class = objc.objc_getClass("NSObject");
        return @intToPtr(fn (objc.Class, SEL) *NSObject, @ptrToInt(objc.objc_msgSend))(class, @ptrCast(SEL, objc_selector_NSObject_new_ref.ptr));
    }
};

pub const NSString = opaque {
    pub const InheritsFrom = .{NSObject};

    export const objc_selector_NSString_new: *const [3:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "new";
    export var objc_selector_NSString_new_ref: struct {
        ptr: *const [3:0]u8,
    } linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = .{
        .ptr = objc_selector_NSString_new,
    };

    pub inline fn new() *NSString {
        const class = objc.objc_getClass("NSString");
        return @intToPtr(fn (objc.Class, SEL) *NSString, @ptrToInt(objc.objc_msgSend))(class, @ptrCast(SEL, objc_selector_NSString_new_ref.ptr));
    }

    export const objc_selector_NSString_alloc: *const [5:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "alloc";
    export var objc_selector_NSString_alloc_ref: struct {
        ptr: *const [5:0]u8,
    } linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = .{
        .ptr = objc_selector_NSString_alloc,
    };

    pub inline fn alloc() *NSString {
        const class = objc.objc_getClass("NSString");
        return @intToPtr(fn (objc.Class, SEL) *NSString, @ptrToInt(objc.objc_msgSend))(class, @ptrCast(SEL, objc_selector_NSString_alloc_ref.ptr));
    }

    export const objc_selector_NSString_init: *const [4:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "init";
    export var objc_selector_NSString_init_ref: struct {
        ptr: *const [4:0]u8,
    } linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = .{
        .ptr = objc_selector_NSString_init,
    };

    pub inline fn init(self: *NSString) void {
        @intToPtr(fn (*NSString, SEL) void, @ptrToInt(objc.objc_msgSend))(self, @ptrCast(SEL, objc_selector_NSString_init_ref.ptr));
    }

    export const objc_selector_NSString_release: *const [7:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "release";
    export var objc_selector_NSString_release_ref: struct {
        ptr: *const [7:0]u8,
    } linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = .{
        .ptr = objc_selector_NSString_release,
    };

    pub inline fn release(self: *NSString) void {
        @intToPtr(fn (*NSString, SEL) callconv(.C) void, @ptrToInt(objc.objc_msgSend))(self, @ptrCast(SEL, objc_selector_NSString_release_ref.ptr));
    }

    export const objc_selector_NSString_string: *const [6:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "string";
    export var objc_selector_NSString_string_ref: struct {
        ptr: *const [6:0]u8,
    } linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = .{
        .ptr = objc_selector_NSString_string,
    };

    pub inline fn string() *NSString {
        const class = objc.objc_getClass("NSString");
        return @intToPtr(fn (objc.Class, SEL) *NSString, @ptrToInt(objc.objc_msgSend))(class, @ptrCast(SEL, objc_selector_NSString_string_ref.ptr));
    }

    export const objc_selector_NSString_lengthOfBytesUsingEncoding: *const [27:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "lengthOfBytesUsingEncoding:";
    export var objc_selector_NSString_lengthOfBytesUsingEncoding_ref: struct {
        ptr: *const [27:0]u8,
    } linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = .{
        .ptr = objc_selector_NSString_lengthOfBytesUsingEncoding,
    };

    pub inline fn lengthOfBytesUsingEncoding(self: *NSString, encoding: u32) u32 {
        return @intToPtr(fn (*NSString, SEL, u32) u32, @ptrToInt(objc.objc_msgSend))(self, @ptrCast(SEL, objc_selector_NSString_lengthOfBytesUsingEncoding_ref.ptr), encoding);
    }

    export const objc_selector_NSString_length: *const [6:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "length";
    export var objc_selector_NSString_length_ref: struct {
        ptr: *const [6:0]u8,
    } linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = .{
        .ptr = objc_selector_NSString_length,
    };

    pub inline fn length(self: *NSString) u32 {
        return @intToPtr(fn (*NSString, SEL) u32, @ptrToInt(objc.objc_msgSend))(self, @ptrCast(SEL, objc_selector_NSString_length_ref.ptr));
    }

    export const objc_selector_NSString_initWithBytesNoCopy: *const [49:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "initWithBytesNoCopy:length:encoding:freeWhenDone:";
    export var objc_selector_NSString_initWithBytesNoCopy_ref: struct {
        ptr: *const [49:0]u8,
    } linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = .{
        .ptr = objc_selector_NSString_initWithBytesNoCopy,
    };
    pub inline fn initWithBytesNoCopy(self: *NSString, bytes: *const anyopaque, inputLength: u64, encoding: u64, freeWhenDone: bool) void {
        @intToPtr(
            fn (*NSString, SEL, *const anyopaque, u64, u64, bool) callconv(.C) void,
            @ptrToInt(objc.objc_msgSend),
        )(
            self,
            @ptrCast(SEL, objc_selector_NSString_initWithBytesNoCopy_ref.ptr),
            bytes,
            inputLength,
            encoding,
            freeWhenDone,
        );
    }

    pub inline fn hash(self: *NSString) ?u32 {
        return (self.as(NSObject) orelse return null).hash();
    }

    pub inline fn as(self: *NSString, comptime OtherType: type) ?*OtherType {
        if (@import("builtin").mode == .Debug) {
            inline for (InheritsFrom) |superType| {
                if (superType == OtherType)
                    return @ptrCast(?*OtherType, self);
            }
            @compileError("Cannot cast " ++ @typeName(NSString) ++ " into " ++ @typeName(OtherType));
        } else {
            return @ptrCast(?*OtherType, self);
        }
    }
};
