export const objc_info_flags: u32 linksection("__DATA,__objc_imageinfo,regular,no_dead_strip") = 64;
export const objc_info_version: u32 linksection("__DATA,__objc_imageinfo,regular,no_dead_strip") = 64;
export const OBJC_METH_VAR_NAME_: *const [4:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "hash";

const Foo = struct {
    ptr: *const [4:0]u8,
};

export var OBJC_SELECTOR_REFERENCES_: Foo linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = Foo{
    .ptr = OBJC_METH_VAR_NAME_,
};

const std = @import("std");

pub const Sel = opaque {};
pub const Class = opaque {};
pub const Object = opaque {};

extern fn objc_msgSend() void;
extern fn objc_getClass(class_name: [*:0]const u8) *Class;
extern fn sel_getUid(selector_name: [*:0]const u8) *Sel;

pub fn main() void {
    const ns_object_class = objc_getClass("NSObject");
    const new_sel = sel_getUid("new:");
    const hash_sel = sel_getUid("hash:");
    const ns_object_instance = @intToPtr(fn (*Class, *Sel) *Object, @ptrToInt(objc_msgSend))(ns_object_class, new_sel);
    const runtime_hash: usize = @intToPtr(fn (*Object, *Sel) usize, @ptrToInt(objc_msgSend))(ns_object_instance, hash_sel);
    std.log.info("NSObject runtime hash: {}", .{runtime_hash});
    // const hash: usize = blk: {
    //     break :blk @intToPtr(fn () u32, @ptrToInt(objc_msgSend))();
    // };

}
