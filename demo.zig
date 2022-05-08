const std = @import("std");

pub const NSObject = struct {
    pub inline fn hash(self: *NSObject) u32 {
        return 420;
    }
};

pub const NSString = struct {
    pub const InheritsFrom = .{NSObject};

    export var objc_selector_NSString_string: *const [6:0]u8 linksection("__TEXT,__objc_methname,cstring_literals") = "string";
    export var objc_selector_NSString_string_ref: struct {
        ptr: *const [6:0]u8,
    } linksection("__DATA,__objc_selrefs,literal_pointers,no_dead_strip") = .{
        .ptr = objc_selector_NSString_string,
    };

    pub inline fn string() *NSString {}

    pub inline fn hash(self: *NSString) u32 {
        return self.as(NSObject).hash();
    }

    pub inline fn as(self: *NSString, comptime OtherType: type) OtherType {
        if (std.builtin.Mode == .debug) {
            inline for (InheritsFrom) |superType| {
                if (superType == OtherType)
                    return @ptrCast(self, *OtherType);
            }
            @compileError("Cannot cast " ++ @typeName(NSString) ++ " into " ++ @typeName(OtherType));
        } else {
            return @ptrCast(self, *OtherType);
        }
    }
};
