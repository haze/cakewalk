const std = @import("std");
const clang = @import("main.zig").clang;
const WrappedCursor = @import("main.zig").WrappedCursor;
const out = std.log.scoped(.cakewalk_method);

const Self = @This();

const Kind = enum {
    instance,
    static,
};

kind: Kind,
name: []const u8,
parameters: std.ArrayList([]u8),
allocator: std.mem.Allocator,

const CollectParametersContext = struct {
    method_name: []const u8,
    param_list: *std.ArrayList([]u8),
    allocator: std.mem.Allocator,
};

fn collectParameters(
    cursor: clang.CXCursor,
    parent: clang.CXCursor,
    client_data: clang.CXClientData,
) callconv(.C) clang.CXChildVisitResult {
    _ = parent;

    const maybe_context = @ptrCast(?*CollectParametersContext, @alignCast(@alignOf(?*CollectParametersContext), client_data));
    if (maybe_context == null) {
        out.err("failed to find context when collecting parameters for method", .{});
        return clang.CXChildVisit_Break;
    }
    var context = maybe_context.?;

    const cursor_spelling = clang.clang_getCursorSpelling(cursor);
    defer clang.clang_disposeString(cursor_spelling);

    context.param_list.append(
        context.allocator.dupe(u8, std.mem.span(clang.clang_getCString(cursor_spelling))) catch {
            out.err("({s}) failed to duplicate param name to method storage", .{context.method_name});
            return clang.CXChildVisit_Break;
        },
    ) catch {
        out.err("({s}) failed to add parameter to method param list", .{context.method_name});
        return clang.CXChildVisit_Break;
    };

    return clang.CXChildVisit_Continue;
}

pub fn deinit(self: *Self) void {
    for (self.parameters.items) |param| {
        self.allocator.free(param);
    }
    self.parameters.deinit();
    self.allocator.free(self.name);
    self.* = undefined;
}

pub fn createFromClangCursor(allocator: std.mem.Allocator, cursor: clang.CXCursor) ?Self {
    const cursor_spelling = clang.clang_getCursorSpelling(cursor);
    defer clang.clang_disposeString(cursor_spelling);
    const method_name = std.mem.span(clang.clang_getCString(cursor_spelling));

    const cursor_kind = clang.clang_getCursorKind(cursor);
    const method_kind = switch (cursor_kind) {
        clang.CXCursor_ObjCClassMethodDecl => Kind.static,
        clang.CXCursor_ObjCInstanceMethodDecl => Kind.instance,
        else => {
            out.err("({s}) given invalid cursor kind ({})", .{ method_name, cursor_kind });
            return null;
        },
    };

    var param_list = std.ArrayList([]u8).init(allocator);

    var context = CollectParametersContext{
        .method_name = method_name,
        .allocator = allocator,
        .param_list = &param_list,
    };

    const terminated_prematurely = clang.clang_visitChildren(cursor, collectParameters, &context) != 0;
    if (terminated_prematurely) return null;

    return Self{
        .allocator = allocator,
        .kind = method_kind,
        .name = allocator.dupe(u8, method_name) catch |err| {
            out.err("failed to copy method name into struct ({s}): {}", .{ method_name, err });
            return null;
        },
        .parameters = param_list,
    };
}
