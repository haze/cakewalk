pub const clang = @cImport({
    @cInclude("clang-c/Index.h");
});

const std = @import("std");
const out = std.log.scoped(.cakewalk);
const ast = @import("ast.zig");
const ClassMethod = @import("Method.zig");

// NOTE(haze): @properties => setters & getters

const WrappedType = struct {
    clang_type: clang.CXType,

    fn init(maybe_clang_type: ?clang.CXType) ?WrappedType {
        if (maybe_clang_type == null or maybe_clang_type.?.kind == 0) return null;
        return WrappedType{
            .clang_type = maybe_clang_type.?,
        };
    }

    pub fn format(
        self: WrappedType,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        // const type_kind = clang.clang_getTypeKind()
        const type_spelling = clang.clang_getTypeSpelling(self.clang_type);
        defer clang.clang_disposeString(type_spelling);

        const type_kind = self.clang_type.kind;
        //clang.clang_getTypeKind(self.clang_type);
        const type_kind_spelling = clang.clang_getTypeKindSpelling(type_kind);
        defer clang.clang_disposeString(type_kind_spelling);

        return writer.print("Type{{ kind='{s}' ({}), spelling='{s}' }}", .{
            clang.clang_getCString(type_kind_spelling),
            type_kind,
            clang.clang_getCString(type_spelling),
        });
    }
};

const WrappedCursor = struct {
    clang_cursor: clang.CXCursor,
    cursor_spelling: clang.CXString,
    cursor_spelling_slice: []const u8,

    fn init(maybe_clang_cursor: ?clang.CXCursor) ?WrappedCursor {
        if (maybe_clang_cursor == null) return null;
        const cursor_spelling = clang.clang_getCursorSpelling(maybe_clang_cursor.?);
        return WrappedCursor{
            .cursor_spelling = cursor_spelling,
            .cursor_spelling_slice = std.mem.span(clang.clang_getCString(cursor_spelling)),
            .clang_cursor = maybe_clang_cursor.?,
        };
    }

    fn deinit(self: *WrappedCursor) void {
        clang.clang_disposeString(self.cursor_spelling);
        self.* = undefined;
    }

    pub fn format(
        self: WrappedCursor,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        const cursor_spelling = clang.clang_getCursorSpelling(self.clang_cursor);
        defer clang.clang_disposeString(cursor_spelling);

        const cursor_kind = clang.clang_getCursorKind(self.clang_cursor);
        const cursor_kind_spelling = clang.clang_getCursorKindSpelling(cursor_kind);
        defer clang.clang_disposeString(cursor_kind_spelling);

        return writer.print("Cursor{{ kind='{s}' ({}), spelling='{s}' }}", .{
            clang.clang_getCString(cursor_kind_spelling),
            cursor_kind,
            clang.clang_getCString(cursor_spelling),
        });
    }
};

const ChildVisitorContext = struct {
    const Self = @This();
    const State = union(enum) {
        expecting_implementation_interface,
        found_interface: WrappedCursor,
    };
    const ObjCClassInformation = struct {
        methods: *std.ArrayList(ClassMethod),
        allocator: std.mem.Allocator,

        fn init(allocator: std.mem.Allocator) !ObjCClassInformation {
            var methods = try allocator.create(std.ArrayList(ClassMethod));
            methods.* = std.ArrayList(ClassMethod).init(allocator);
            return ObjCClassInformation{
                .methods = methods,
                .allocator = allocator,
            };
        }

        fn deinit(self: *ObjCClassInformation) void {
            self.methods.deinit();
            self.allocator.destroy(self.methods);
            self.* = undefined;
        }
    };

    classes: std.StringHashMap(ObjCClassInformation),
    allocator: std.mem.Allocator,
    state: State = .expecting_implementation_interface,

    fn init(allocator: std.mem.Allocator) Self {
        return .{
            .classes = std.StringHashMap(ObjCClassInformation).init(allocator),
            .allocator = allocator,
        };
    }

    fn addClassMethod(
        self: *Self,
        class_name: []const u8,
        method: ClassMethod,
    ) !void {
        if (!self.hasClass(class_name))
            return self.addClass(class_name);
        var class_info = self.classes.getEntry(class_name);
        var class_methods = class_info.?.value_ptr.methods;
        class_methods.append(method) catch |err| {
            out.err("failed to add class method ({s} to {s}): {}", .{ method.name, class_name, err });
            return err;
        };
    }

    fn hasClass(self: Self, class_name: []const u8) bool {
        return self.classes.contains(class_name);
    }

    fn addClass(self: *Self, class_name: []const u8) !void {
        out.debug("attempting to add class {s}", .{class_name});
        self.classes.put(self.allocator.dupe(u8, class_name) catch |err| {
            std.log.err("failed to copy class name for class map: {}", .{err});
            return err;
        }, try ChildVisitorContext.ObjCClassInformation.init(self.allocator)) catch |err| {
            std.log.err("failed to insert class & associated method context struct into map: {}", .{err});
            return err;
        };
    }

    fn deinit(self: *Self) void {
        var classes_iter = self.classes.iterator();
        while (classes_iter.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            for (entry.value_ptr.methods.items) |*method| {
                method.deinit();
            }
            entry.value_ptr.deinit();
        }
        self.classes.deinit();
        self.* = undefined;
    }
};

// const ObjCInterfaceDeclCursorKind = 11;
// const ObjCClassMethodDeclCursorKind = 17;
// const ObjCCategoryDeclCursorKind = 12;

fn nullableCursor(input_cursor: clang.CXCursor) ?clang.CXCursor {
    if (input_cursor.kind == clang.clang_getNullCursor().kind) return null;
    return input_cursor;
}

fn nullableType(input_type: clang.CXType) ?clang.CXType {
    if (input_type.kind == clang.CXType_Invalid) return null;
    return input_type;
}

fn printDirectChildren(
    cursor: clang.CXCursor,
    parent: clang.CXCursor,
    client_data: clang.CXClientData,
) callconv(.C) clang.CXChildVisitResult {
    _ = client_data;
    _ = parent;

    if (WrappedCursor.init(cursor)) |wrapped_cursor| {
        defer wrapped_cursor.deinit();

        std.log.info("child={}", .{wrapped_cursor});
        // if (WrappedCursor.init(clang.clang_getTypeDeclaration(cursor))) |decl_cursor| {
        //     std.log.info("decl={}", .{decl_cursor});
        // }

        // if (WrappedCursor.init(clang.clang_getCursorReferenced(cursor))) |wrapped_referenced_cursor| {
        //     std.log.info("ref_cursor={}", .{wrapped_referenced_cursor});
        //
        //     if (WrappedType.init(clang.clang_getCursorType(wrapped_referenced_cursor.clang_cursor))) |wrapped_type| {
        //         std.log.info("{}", .{wrapped_type});
        //     }
        // }
    }

    return clang.CXChildVisit_Continue;
}

fn visitCategoryChildrenAndAddMethodsAndProperties(
    cursor: clang.CXCursor,
    parent: clang.CXCursor,
    client_data: clang.CXClientData,
) callconv(.C) clang.CXChildVisitResult {
    _ = parent;

    const cursor_kind = clang.clang_getCursorKind(cursor);
    const cursor_spelling = clang.clang_getCursorSpelling(cursor);
    defer clang.clang_disposeString(cursor_spelling);

    // const cursor_kind_spelling = clang.clang_getCursorKindSpelling(cursor_kind);
    // defer clang.clang_disposeString(cursor_kind_spelling);
    // const parent_cursor_kind_spelling = clang.clang_getCursorKindSpelling(clang.clang_getCursorKind(parent));
    // defer clang.clang_disposeString(cursor_kind_spelling);

    var maybe_context = @intToPtr(?*ChildVisitorContext, @ptrToInt(client_data));
    if (maybe_context == null) {
        out.err("No ChildVisitorContext found during 'visitCategoryChildrenAndAddMethodsAndProperties', exiting early", .{});
        return clang.CXChildVisit_Break;
    }
    var context = maybe_context.?;

    var wrapped_cursor = WrappedCursor.init(cursor).?;
    defer wrapped_cursor.deinit();

    switch (context.state) {
        .expecting_implementation_interface => {
            switch (cursor_kind) {
                clang.CXCursor_ObjCClassRef => {
                    context.state = .{ .found_interface = WrappedCursor.init(cursor).? };
                    const cursor_spelling_slice = std.mem.span(clang.clang_getCString(cursor_spelling));
                    if (!context.hasClass(cursor_spelling_slice))
                        context.addClass(cursor_spelling_slice) catch return clang.CXChildVisit_Continue;
                },
                else => return clang.CXChildVisit_Continue,
            }
        },
        .found_interface => |impl_cursor| {
            _ = impl_cursor;
            const cursor_spelling_slice = std.mem.span(clang.clang_getCString(cursor_spelling));
            switch (cursor_kind) {
                clang.CXCursor_ObjCPropertyDecl => {
                    // out.info("{} visited property {}", .{ impl_cursor, wrapped_cursor });
                },
                clang.CXCursor_ObjCInstanceMethodDecl => {
                    // out.info("{} visited instance method {}", .{ impl_cursor, wrapped_cursor });
                },
                clang.CXCursor_ObjCClassMethodDecl => {
                    // out.info("{} visited static (class) method {}", .{ impl_cursor, wrapped_cursor });
                    if (ClassMethod.createFromClangCursor(
                        context.allocator,
                        cursor,
                    )) |method| {
                        context.addClassMethod(impl_cursor.cursor_spelling_slice, method) catch |err| {
                            out.err("failed to add class method ({s}): {}", .{ cursor_spelling_slice, err });
                            return clang.CXChildVisit_Break;
                        };
                        out.debug("added class method {s}", .{cursor_spelling_slice});
                    }
                },
                else => return clang.CXChildVisit_Continue,
            }
        },
    }

    return clang.CXChildVisit_Continue;
}

fn visitChildren(
    cursor: clang.CXCursor,
    parent: clang.CXCursor,
    client_data: clang.CXClientData,
) callconv(.C) clang.CXChildVisitResult {
    _ = parent;
    _ = client_data;

    var maybe_context = @intToPtr(?*ChildVisitorContext, @ptrToInt(client_data));
    if (maybe_context == null) {
        out.err("No ChildVisitorContext found during 'visitCategoryChildrenAndAddMethodsAndProperties', exiting early", .{});
        return clang.CXChildVisit_Break;
    }
    var context = maybe_context.?;

    // var maybe_context = @intToPtr(?*ChildVisitorContext, @ptrToInt(client_data));
    const cursor_spelling = clang.clang_getCursorSpelling(cursor);
    defer clang.clang_disposeString(cursor_spelling);
    const cursor_kind = clang.clang_getCursorKind(cursor);

    if (cursor_kind == clang.CXCursor_ObjCCategoryDecl) {
        out.debug("Parsing implementation methods and properties for category: {s}", .{
            clang.clang_getCString(cursor_spelling),
        });

        const terminated_prematurely = clang.clang_visitChildren(
            cursor,
            visitCategoryChildrenAndAddMethodsAndProperties,
            client_data,
        ) != 0;
        if (terminated_prematurely)
            return clang.CXChildVisit_Break;

        switch (context.state) {
            .found_interface => |*wrapped_cursor| wrapped_cursor.deinit(),
            else => {},
        }
        context.state = .expecting_implementation_interface;
    }

    return clang.CXChildVisit_Recurse;
}

pub fn objcMain() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());

    // var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    // defer arena.deinit();

    // TODO(haze): turn into arguments
    const header = "/Library/Developer/CommandLineTools/SDKs/MacOSX12.1.sdk/System/Library/Frameworks/Foundation.framework/Versions/C/Headers/Foundation.h";
    // const header = "/Library/Developer/CommandLineTools/SDKs/MacOSX12.1.sdk/System/Library/Frameworks/AVFAudio.framework/Versions/Current/Headers/AVFAudio.h";
    const sdk_root = "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX12.1.sdk";

    var index: clang.CXIndex = clang.clang_createIndex(0, 0);
    defer clang.clang_disposeIndex(index);

    var translation_unit: clang.CXTranslationUnit = undefined;
    defer clang.clang_disposeTranslationUnit(translation_unit);

    const parse_args = [_][*:0]const u8{
        "-x",
        "objective-c",
        "-isysroot",
        sdk_root,
    };

    const error_code: clang.CXErrorCode = clang.clang_parseTranslationUnit2(
        index,
        header,
        &parse_args,
        parse_args.len,
        null,
        0,
        0,
        &translation_unit,
    );

    if (error_code != clang.CXError_Success) {
        return error.FailedToCreateTranslationUnit;
    }

    var translation_unit_cursor = clang.clang_getTranslationUnitCursor(translation_unit);

    var context = ChildVisitorContext.init(gpa.allocator());
    defer context.deinit();

    const terminated_prematurely = clang.clang_visitChildren(
        translation_unit_cursor,
        visitChildren,
        @ptrCast(clang.CXClientData, &context),
    ) != 0;

    out.info("(term_pre={}), unit={}", .{ terminated_prematurely, translation_unit });

    var classes_iter = context.classes.iterator();
    while (classes_iter.next()) |entry| {
        out.info("=== Class {s}", .{entry.key_ptr.*});
        for (entry.value_ptr.methods.items) |method| {
            out.info("\t{s}{s}: {} params", .{
                switch (method.kind) {
                    .static => "+",
                    .instance => "-",
                },
                method.name,
                method.parameters.items.len,
            });
        }
    }
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .stack_trace_frames = 32,
    }){};
    defer std.debug.assert(!gpa.deinit());
    const allocator = gpa.allocator();

    var writer = std.io.getStdOut().writer();
    var tree = try createAst(allocator);
    defer {
        allocator.free(tree.source);
        tree.deinit(allocator);
    }

    const renderedAst = try tree.render(allocator);
    defer allocator.free(renderedAst);
    try writer.writeAll(renderedAst);
}

// pub const VarDecl = struct {
//     base: Payload,
//     data: struct {
//         is_pub: bool,
//         is_const: bool,
//         is_extern: bool,
//         is_export: bool,
//         is_threadlocal: bool,
//         alignment: ?c_uint,
//         linksection_string: ?[]const u8,
//         name: []const u8,
//         type: Node,
//         init: ?Node,
//     },
// };

fn createAst(allocator: std.mem.Allocator) !std.zig.Ast {
    const nodes = [_]ast.Node{
        ast.Node.initPayload(&(ast.Payload.VarDecl{
            .base = .{ .tag = .var_decl },
            .data = .{
                .is_pub = true,
                .is_const = true,
                .is_extern = false,
                .is_export = false,
                .is_threadlocal = false,
                .alignment = null,
                .linksection_string = null,
                .name = "frediEatsAss",
                .type = ast.Node.Tag.void_type.init(),
                .init = null,
            },
        }).base),
    };
    return ast.render(allocator, &nodes);
}

