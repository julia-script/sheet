const std = @import("std");
const BoundedArray = std.BoundedArray;

fn writeVarUInt32(writer: std.io.AnyWriter, value: u32) !void {
    var val = value;
    while (true) {
        var byte: u8 = @intCast(val & 0x7F);
        val = val >> 7;
        if (val == 0) {
            try writer.writeByte(byte);
            break;
        } else {
            byte |= 0x80;
            try writer.writeByte(byte);
        }
    }
}
fn writeAllVarUInt32(writer: std.io.AnyWriter, values: anytype) !void {
    inline for (values) |value| {
        try writeVarUInt32(writer, @intCast(value));
    }
}
pub const Type = enum(u8) {
    function = 0x60,
    empty = 0x40,

    i32 = 0x7F,
    i64 = 0x7E,
    f32 = 0x7D,
    f64 = 0x7C,
    pub fn toBytes(self: Type, writer: std.io.AnyWriter) !void {
        try writeVarUInt32(writer, @intCast(@intFromEnum(self)));
    }
};

pub const Instruction = union(enum) {
    @"return": void,
    local_get: u32,
    local_set: u32,
    local_tee: u32,
    global_get: u32,
    global_set: u32,
    end: void,
    call: u32,
    drop: void,

    // Arithmetic Operations
    i32_add: void,
    i64_add: void,
    f32_add: void,
    f64_add: void,

    i32_sub: void,
    i64_sub: void,
    f32_sub: void,
    f64_sub: void,

    i32_mul: void,
    i64_mul: void,
    f32_mul: void,
    f64_mul: void,

    i32_div_s: void,
    i64_div_s: void,
    i32_div_u: void,
    i64_div_u: void,
    f32_div: void,
    f64_div: void,

    // Comparison Operations
    i32_eq: void,
    i32_ne: void,
    i32_lt_s: void,
    i32_lt_u: void,
    i32_gt_s: void,
    i32_gt_u: void,

    i64_eq: void,
    i64_ne: void,
    i64_lt_s: void,
    i64_lt_u: void,
    i64_gt_s: void,
    i64_gt_u: void,

    f32_eq: void,
    f32_ne: void,
    f32_lt: void,
    f32_gt: void,

    f64_eq: void,
    f64_ne: void,
    f64_lt: void,
    f64_gt: void,

    i32_const: i32,
    i64_const: i64,
    f32_const: f32,
    f64_const: f64,

    @"if": Type,
    @"else": void,
    br: u32,

    loop: Type,

    i32_store: MemOp,
    i64_store: MemOp,
    f32_store: MemOp,
    f64_store: MemOp,
    i32_store8: MemOp,
    i32_store16: MemOp,
    i64_store8: MemOp,
    i64_store16: MemOp,
    i64_store32: MemOp,

    i32_load: MemOp,
    i64_load: MemOp,
    f32_load: MemOp,
    f64_load: MemOp,
    i32_load8_s: MemOp,
    i32_load8_u: MemOp,
    i32_load16_s: MemOp,
    i32_load16_u: MemOp,
    i64_load8_s: MemOp,
    i64_load8_u: MemOp,
    i64_load16_s: MemOp,
    i64_load16_u: MemOp,
    i64_load32_s: MemOp,
    i64_load32_u: MemOp,

    // Memory instructions

    pub const BinOp = enum { add, sub, mul, div, mod };

    pub const MemOp = struct {
        offset: u8 = 0,
        alignment: ?u8 = null,
    };
    pub const END: Instruction = .{ .end = {} };
    pub fn writeInto(self: Instruction, section: *Section) !void {
        switch (self) {
            .@"return" => {
                try section.write(0x0f);
            },
            .local_get => |index| {
                try section.writeByte(0x20);
                try section.write(index);
            },
            .local_set => |index| {
                try section.writeByte(0x21);
                try section.write(index);
            },
            .local_tee => |index| {
                try section.writeByte(0x22);
                try section.write(index);
            },
            .global_get => |index| {
                try section.writeByte(0x23);
                try section.write(index);
            },
            .global_set => |index| {
                try section.writeByte(0x24);
                try section.write(index);
            },
            .call => |callee| {
                try section.writeByte(0x10);
                try section.write(callee);
            },
            .drop => try section.writeByte(0x1A),

            // Arithmetic Operations
            .i32_add => try section.writeByte(0x6A), // i32.add
            .i64_add => try section.writeByte(0x7C), // i64.add
            .f32_add => try section.writeByte(0x92), // f32.add
            .f64_add => try section.writeByte(0xA0), // f64.add

            .i32_sub => try section.writeByte(0x6B), // i32.sub
            .i64_sub => try section.writeByte(0x7D), // i64.sub
            .f32_sub => try section.writeByte(0x93), // f32.sub
            .f64_sub => try section.writeByte(0xA1), // f64.sub

            .i32_mul => try section.writeByte(0x6C), // i32.mul
            .i64_mul => try section.writeByte(0x7E), // i64.mul
            .f32_mul => try section.writeByte(0x94), // f32.mul
            .f64_mul => try section.writeByte(0xA2), // f64.mul

            .i32_div_s => try section.writeByte(0x6D), // i32.div_s
            .i64_div_s => try section.writeByte(0x7F), // i64.div_s
            .i32_div_u => try section.writeByte(0x6E), // i32.div_u
            .i64_div_u => try section.writeByte(0x80), // i64.div_u
            .f32_div => try section.writeByte(0x95), // f32.div
            .f64_div => try section.writeByte(0xA3), // f64.div

            // Comparison Operations
            .i32_eq => try section.writeByte(0x46), // i32.eq
            .i32_ne => try section.writeByte(0x47), // i32.ne
            .i32_lt_s => try section.writeByte(0x48), // i32.lt_s
            .i32_lt_u => try section.writeByte(0x49), // i32.lt_u
            .i32_gt_s => try section.writeByte(0x4A), // i32.gt_s
            .i32_gt_u => try section.writeByte(0x4B), // i32.gt_u

            .i64_eq => try section.writeByte(0x51), // i64.eq
            .i64_ne => try section.writeByte(0x52), // i64.ne
            .i64_lt_s => try section.writeByte(0x53), // i64.lt_s
            .i64_lt_u => try section.writeByte(0x54), // i64.lt_u
            .i64_gt_s => try section.writeByte(0x55), // i64.gt_s
            .i64_gt_u => try section.writeByte(0x56), // i64.gt_u

            .f32_eq => try section.writeByte(0x5B), // f32.eq
            .f32_ne => try section.writeByte(0x5C), // f32.ne
            .f32_lt => try section.writeByte(0x5D), // f32.lt
            .f32_gt => try section.writeByte(0x5E), // f32.gt

            .f64_eq => try section.writeByte(0x61), // f64.eq
            .f64_ne => try section.writeByte(0x62), // f64.ne
            .f64_lt => try section.writeByte(0x63), // f64.lt
            .f64_gt => try section.writeByte(0x64), // f64.gt

            .i32_const => |value| {
                try section.writeByte(0x41);
                try section.write(value);
            },
            .i64_const => |value| {
                try section.writeByte(0x42);
                try section.write(value);
            },

            .f32_const => |value| {
                try section.writeByte(0x43);
                try section.write(value);
            },
            .f64_const => |value| {
                try section.writeByte(0x44);
                try section.write(value);
            },
            .@"if" => |ty| {
                try section.writeByte(0x04);
                try section.write(ty);
            },
            .@"else" => try section.writeByte(0x05),
            .end => try section.writeByte(0x0b),
            .loop => |ty| {
                try section.writeByte(0x03);
                try section.write(ty);
            },
            .br => |index| {
                try section.writeByte(0x0c);
                try section.write(index);
            },

            .i32_store => |mem| {
                try section.writeByte(0x36);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 4);
            },
            .i64_store => |mem| {
                try section.writeByte(0x37);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 8);
            },
            .f32_store => |mem| {
                try section.writeByte(0x38);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 4);
            },
            .f64_store => |mem| {
                try section.writeByte(0x39);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 8);
            },
            .i32_store8 => |mem| {
                try section.writeByte(0x3a);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 1);
            },
            .i32_store16 => |mem| {
                try section.writeByte(0x3b);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 2);
            },
            .i64_store8 => |mem| {
                try section.writeByte(0x3c);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 1);
            },
            .i64_store16 => |mem| {
                try section.writeByte(0x3d);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 2);
            },
            .i64_store32 => |mem| {
                try section.writeByte(0x3e);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 4);
            },

            .i32_load => |mem| {
                try section.writeByte(0x28);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 4);
            },
            .i64_load => |mem| {
                try section.writeByte(0x29);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 8);
            },
            .f32_load => |mem| {
                try section.writeByte(0x2a);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 4);
            },
            .f64_load => |mem| {
                try section.writeByte(0x2b);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 8);
            },
            .i32_load8_s => |mem| {
                try section.writeByte(0x2c);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 1);
            },
            .i32_load8_u => |mem| {
                try section.writeByte(0x2d);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 1);
            },
            .i32_load16_s => |mem| {
                try section.writeByte(0x2e);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 2);
            },
            .i32_load16_u => |mem| {
                try section.writeByte(0x2f);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 2);
            },
            .i64_load8_s => |mem| {
                try section.writeByte(0x30);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 1);
            },
            .i64_load8_u => |mem| {
                try section.writeByte(0x31);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 1);
            },
            .i64_load16_s => |mem| {
                try section.writeByte(0x32);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 2);
            },
            .i64_load16_u => |mem| {
                try section.writeByte(0x33);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 2);
            },
            .i64_load32_s => |mem| {
                try section.writeByte(0x34);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 4);
            },
            .i64_load32_u => |mem| {
                try section.writeByte(0x35);
                try section.writeByte(mem.offset);
                try section.writeByte(mem.alignment orelse 4);
            },
        }
    }
    pub fn toWat(self: Instruction, writer: *WatWriter) !void {
        switch (self) {
            .local_get => |index| try writer.print("local.get {d}", .{index}),
            .local_set => |index| try writer.print("local.set {d}", .{index}),
            .global_get => |index| try writer.print("global.get {d}", .{index}),
            .i32_const => |value| try writer.print("i32.const {d}", .{value}),
            .i64_const => |value| try writer.print("i64.const {d}", .{value}),
            .f32_const => |value| try writer.print("f32.const {d}", .{value}),
            .f64_const => |value| try writer.print("f64.const {d}", .{value}),
            .@"if" => unreachable,
            .@"else" => unreachable,
            .end => unreachable,
            .loop => unreachable,
            .br => unreachable,
            .i32_add => try writer.write("i32.add"),
            .i64_add => try writer.write("i64.add"),
            .f32_add => try writer.write("f32.add"),
            .f64_add => try writer.write("f64.add"),
            .i32_sub => try writer.write("i32.sub"),
            .i64_sub => try writer.write("i64.sub"),
            .f32_sub => try writer.write("f32.sub"),
            .f64_sub => try writer.write("f64.sub"),
            .i32_mul => try writer.write("i32.mul"),
            .i64_mul => try writer.write("i64.mul"),
            .f32_mul => try writer.write("f32.mul"),
            .f64_mul => try writer.write("f64.mul"),
            .i32_div_s => try writer.write("i32.div_s"),
            .i64_div_s => try writer.write("i64.div_s"),
            .i32_div_u => try writer.write("i32.div_u"),
            .i64_div_u => try writer.write("i64.div_u"),
            .f32_div => try writer.write("f32.div"),
            .f64_div => try writer.write("f64.div"),
            .i32_eq => try writer.write("i32.eq"),
            .i32_ne => try writer.write("i32.ne"),
            .i32_lt_s => try writer.write("i32.lt_s"),
            .i32_lt_u => try writer.write("i32.lt_u"),
            .i32_gt_s => try writer.write("i32.gt_s"),
            .i32_gt_u => try writer.write("i32.gt_u"),
            .i64_eq => try writer.write("i64.eq"),
            .i64_ne => try writer.write("i64.ne"),
            .i64_lt_s => try writer.write("i64.lt_s"),
            .i64_lt_u => try writer.write("i64.lt_u"),
            .i64_gt_s => try writer.write("i64.gt_s"),
            .i64_gt_u => try writer.write("i64.gt_u"),

            .f32_eq => try writer.write("f32.eq"),
            .f32_ne => try writer.write("f32.ne"),
            .f32_lt => try writer.write("f32.lt"),
            .f32_gt => try writer.write("f32.gt"),

            .f64_eq => try writer.write("f64.eq"),

            .i32_store => try writer.write("i32.store"),
            .i64_store => try writer.write("i64.store"),
            .f32_store => try writer.write("f32.store"),
            .f64_store => try writer.write("f64.store"),
            .i32_store8 => try writer.write("i32.store8"),
            .i32_store16 => try writer.write("i32.store16"),
            .i64_store8 => try writer.write("i64.store8"),
            .i64_store16 => try writer.write("i64.store16"),
            .i64_store32 => try writer.write("i64.store32"),
            else => try writer.print("UNIMPLEMENTED: {s}", .{@tagName(self)}),
        }
    }
};
const Local = struct {
    count: u32,
    type: Type,
    pub fn toBytes(self: Local, writer: std.io.AnyWriter) !void {
        try writeVarUInt32(writer, self.count);
        try self.type.toBytes(writer);
    }
};
pub const Function = struct {
    index: usize,
    name: []const u8 = "",
    params: Array(Type),
    results: Array(Type),
    instructions: Array(Instruction),
    module: *Module,
    locals: Array(Local),
    @"export": bool = false,
    local_count: u32 = 0,

    pub fn init(module: *Module, index: usize) Function {
        return .{
            .index = index,
            .params = Array(Type).init(module.arena.allocator()),
            .results = Array(Type).init(module.arena.allocator()),
            .instructions = Array(Instruction).init(module.arena.allocator()),
            .locals = Array(Local).init(module.arena.allocator()),
            .module = module,
        };
    }
    pub fn pushParam(self: *Function, param: Type) !void {
        self.local_count += 1;
        try self.params.append(param);
    }
    pub fn pushInstruction(self: *Function, instruction: Instruction) !void {
        std.debug.print("pushInstruction: {}\n", .{(instruction)});
        try self.instructions.append(instruction);
        // self.hasher.update("instruction");
        // try instruction.toBytes(self.instructions.writer().any());
    }
    pub fn pushResult(self: *Function, result: Type) !void {
        try self.results.append(result);
    }
    pub fn pushLocal(self: *Function, value_type: Type) !u32 {
        const prev = self.locals.items.len;
        defer self.local_count += 1;
        if (self.locals.items.len > 0) {
            const last = self.locals.items[prev - 1];
            if (last.type == value_type) {
                self.locals.items[prev - 1].count += 1;
                return self.local_count;
            }
        }
        const local_count: u32 = 1;
        const local = Local{ .count = local_count, .type = value_type };
        try self.locals.append(local);
        return self.local_count;
    }
    pub fn getFunctionType(self: Function) FunctionType {
        return .{ .params = self.params.items, .results = self.results.items };
    }
};
const FunctionType = struct {
    params: []Type,
    results: []Type,
    pub fn toBytes(self: FunctionType, writer: std.io.AnyWriter) !void {
        try writeVarUInt32(writer, 0x60);
        try writeVarUInt32(writer, @intCast(self.params.len));
        for (self.params) |param| {
            try param.toBytes(writer);
        }
        try writeVarUInt32(writer, @intCast(self.results.len));
        for (self.results) |result| {
            try result.toBytes(writer);
        }
    }
    pub fn hash(self: FunctionType) u64 {
        var hasher = std.hash.Wyhash.init(0);
        hasher.update("function_type");
        hasher.update("params");
        for (self.params) |param| {
            hasher.update(std.mem.asBytes(&param));
        }
        hasher.update("results");
        for (self.results) |result| {
            hasher.update(std.mem.asBytes(&result));
        }
        return hasher.final();
    }
};

pub const Global = struct {
    index: usize,
    name: []const u8 = "",
    type: Type,
    mutable: bool = false,
    module: *Module,
    instructions: Array(Instruction),
    pub fn init(module: *Module, index: usize, name: []const u8, ty: Type) Global {
        return .{
            .index = index,
            .name = name,
            .type = ty,
            .instructions = Array(Instruction).init(module.arena.allocator()),
            .module = module,
        };
    }
    pub fn pushInstruction(self: *Global, instruction: Instruction) !void {
        std.debug.print("pushInstruction: {}\n", .{(instruction)});
        try self.instructions.append(instruction);
    }
    pub fn commit(self: *Global) !void {
        self.module.globals.items[self.index] = self.*;
    }
};
const Memory = struct {
    initial: u32,
    maximum: ?u32 = null,
};

const Array = std.ArrayList;
pub const Module = struct {
    const FunctionTypeEntry = struct {
        usize,
        FunctionType,
    };
    function_types: std.AutoArrayHashMapUnmanaged(u64, FunctionTypeEntry) = .{},
    functions: std.ArrayListUnmanaged(Function) = .{},
    globals: std.ArrayListUnmanaged(Global) = .{},
    memories: std.ArrayListUnmanaged(Memory) = .{},
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,
    scratch: std.ArrayListUnmanaged(u8) = .{},
    start: ?u32 = null,
    pub fn init(allocator: std.mem.Allocator) !Module {
        return Module{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .allocator = allocator,
        };
    }
    pub fn deinit(self: *Module) void {
        self.arena.deinit();
    }
    pub fn putFunction(self: *Module, function: *Function) !u32 {
        const func_type = function.getFunctionType();
        const hash = func_type.hash();
        if (self.function_types.get(hash) == null) {
            try self.function_types.put(self.arena.allocator(), hash, .{ self.function_types.count(), func_type });
        }
        self.functions.items[function.index] = function.*;
        return @intCast(self.functions.items.len - 1);
    }
    pub fn makeFunction(self: *Module) !Function {
        const index = self.functions.items.len;
        try self.functions.append(self.arena.allocator(), undefined);
        return Function.init(self, index);
    }
    pub fn makeGlobal(self: *Module, name: []const u8, ty: Type) !Global {
        const index = self.globals.items.len;
        try self.globals.append(self.arena.allocator(), undefined);
        return Global.init(self, index, name, ty);
    }
    pub fn pushMemory(self: *Module, memory: Memory) !u32 {
        const index = self.memories.items.len;
        try self.memories.append(self.arena.allocator(), memory);
        return @intCast(index);
    }
    pub fn toBytes(self: *Module, writer: std.io.AnyWriter) !void {
        // Magic number
        try writeAllVarUInt32(writer, &.{ 0x00, 0x61, 0x73, 0x6d });

        // Version
        try writeAllVarUInt32(writer, &.{ 0x01, 0x00, 0x00, 0x00 });

        // Write the Type Section
        // 01                 ; Section ID for Type Section
        // 07                 ; Section size (7 bytes)
        //
        // 01                 ; Type count (1 type)
        // for each type:
        // 60                 ; Function type indicator
        // 02                 ; Parameter count (2)
        // 7F 7F              ; Parameter types (i32, i32)
        // 01                 ; Result count (1)
        // 7F                 ; Result type (i32)

        const types_count = self.function_types.count();
        if (types_count > 0) {
            var types_section = Section.init(self.allocator, self, .type);
            defer types_section.deinit();

            try types_section.write(types_count);

            for (self.function_types.values()) |entry| {
                const func_type: FunctionType = entry[1];
                try types_section.write(Type.function);

                try types_section.write(func_type.params.len);
                try types_section.write(func_type.params);

                try types_section.write(func_type.results.len);
                try types_section.write(func_type.results);
            }

            try types_section.toBytes(writer);
        }

        // Write the Function Section
        // Example:
        // 03                 ; Section ID for Function Section
        // 02                 ; Section size (2 bytes)
        //
        // 01                 ; Function count (1 function)
        // 00                 ; Type index (0) for the function

        const functions_count = self.functions.items.len;
        if (functions_count > 0) {
            var functions_section = Section.init(self.allocator, self, .function);
            defer functions_section.deinit();

            try functions_section.write(functions_count);

            for (self.functions.items) |function| {
                const index = self.function_types.get(function.getFunctionType().hash()) orelse {
                    @panic("Function type not found");
                };
                try functions_section.write(index[0]);
            }

            try functions_section.toBytes(writer);
        }

        // Memory section
        // 05                 ; Section ID for Memory Section
        // 01                 ; Section size (1 bytes)
        // 01                 ; Memory count (1 memory)

        // 0x01               ; Flag (0x01 = has maximum, 0x00 = no maximum)
        // 0x00               ; Initial size (0)
        // 0x00               ; Maximum size (0) // only if if has maximum

        const memories_count = self.memories.items.len;
        if (memories_count > 0) {
            var memories_section = Section.init(self.allocator, self, .memory);
            defer memories_section.deinit();
            try memories_section.write(memories_count);

            for (self.memories.items) |memory| {
                if (memory.maximum) |max| {
                    try memories_section.writeByte(0x01);
                    try memories_section.write(memory.initial);
                    try memories_section.write(max);
                } else {
                    try memories_section.writeByte(0x00);
                    try memories_section.write(memory.initial);
                }
            }
            try memories_section.toBytes(writer);
        }

        // Global section
        // Global section
        // 06                 ; Section ID for Global Section
        // 01                 ; Section size (1 bytes)
        // 01                 ; Global count (1 global)

        // 0x7F               ; Global type (i32)
        // 01                 ; Mutable (true)
        // 0x41 0x2A          ; i32.const 42 (0x41 is the opcode for i32.const, 0x2A = 42 in LEB128)
        // 0x0B               ; end of init_expr

        const globals_count = self.globals.items.len;
        if (globals_count > 0) {
            var globals_section = Section.init(self.allocator, self, .global);
            defer globals_section.deinit();
            try globals_section.write(globals_count);

            for (self.globals.items) |global| {
                // try global.type.toBytes(globals_section.writer());
                try globals_section.write(global.type);

                try globals_section.write(global.mutable);
                // Instructions
                for (global.instructions.items) |instruction| {
                    try instruction.writeInto(&globals_section);
                }
                try Instruction.END.writeInto(&globals_section);
            }
            try globals_section.toBytes(writer);
        }

        // Export section
        // 07                 ; Section ID for Export Section
        // 01                 ; Section size (1 bytes)
        // 01                 ; Export count (1 export)
        // 00                 ; Function index (0)
        var export_count: usize = 0;
        for (self.functions.items) |function| {
            if (function.@"export") {
                export_count += 1;
            }
        }
        if (export_count > 0) {
            var export_section = Section.init(self.allocator, self, .@"export");
            defer export_section.deinit();
            try export_section.write(export_count);

            for (self.functions.items, 0..) |function, i| {
                if (function.@"export") {
                    try export_section.write(function.name.len);
                    try export_section.writeDirect(function.name);
                    try export_section.write(0);
                    try export_section.write(i);
                }
            }
            try export_section.toBytes(writer);
        }

        // Start section
        // 08                 ; Section ID for Start Section
        // 01                 ; Section size (1 bytes)
        // 00                 ; Function index (0)
        if (self.start) |index| {
            var start_section = Section.init(self.allocator, self, .start);
            defer start_section.deinit();

            try start_section.write(index);
            try start_section.toBytes(writer);
        }

        // Code section
        // 0A                 ; Section ID for Code Section
        // 09                 ; Section size (9 bytes)

        // 01                 ; Function body count (1 function)
        // 07                 ; Function body size (7 bytes)
        // 00                 ; Local count (0)
        // 20 00              ; local.get 0
        // 20 01              ; local.get 1
        // 6A                 ; i32.add
        // 0B                 ; end
        // Write the Code Section
        const body_count = self.functions.items.len;
        if (body_count > 0) {
            var code_section = Section.init(self.allocator, self, .code);
            defer code_section.deinit();

            try code_section.write(body_count);

            // Function body count
            var function_body_section = Section.init(self.allocator, self, .unidentified);

            defer function_body_section.deinit();
            for (self.functions.items) |function| {
                function_body_section.clearRetainingCapacity();

                // Locals
                try function_body_section.write(function.locals.items.len);

                for (function.locals.items) |local| {
                    try function_body_section.write(local.count);
                    try function_body_section.write(local.type);
                }

                // Instructions
                for (function.instructions.items) |instruction| {
                    try instruction.writeInto(&function_body_section);
                }
                try Instruction.END.writeInto(&function_body_section);

                try code_section.write(&function_body_section);
            }

            try code_section.toBytes(writer);
        }
    }

    pub fn toWat(self: *Module, writer: std.io.AnyWriter) !void {
        var wat_writer = WatWriter{ .writer = writer };
        try wat_writer.open("module");
        // Type section
        for (self.function_types.values(), 0..) |entry, i| {
            const entry_fn: FunctionType = entry[1];
            try wat_writer.writeIndent();
            try wat_writer.print("(type (;{d};) ", .{i});
            try wat_writer.write("(func");
            if (entry_fn.params.len > 0 or entry_fn.results.len > 0) {
                for (entry_fn.params) |param| {
                    try wat_writer.print(" (param {s})", .{@tagName(param)});
                }
                for (entry_fn.results) |result| {
                    try wat_writer.print(" (result {s})", .{@tagName(result)});
                }
            } else {
                try wat_writer.write(")");
            }
            try wat_writer.write(")\n");
        }

        // Function section
        // for (self.functions.items, 0..) |function, i| {
        for (self.functions.items, 0..) |function, i| {
            const index = self.function_types.get(function.getFunctionType().hash()) orelse {
                @panic("Function type not found");
            };
            try wat_writer.writeIndent();
            try wat_writer.print("(func (;{d};) ", .{i});
            // try wat_writer.write(function.name);
            try wat_writer.print("(type {d})", .{index[0]});
            for (function.params.items) |param| {
                try wat_writer.print(" (param {s})", .{@tagName(param)});
            }
            for (function.results.items) |result| {
                try wat_writer.print(" (result {s})", .{@tagName(result)});
            }
            wat_writer.indent += 1;
            try wat_writer.breakLine();
            try wat_writer.writeIndent();
            if (function.locals.items.len > 0) {
                try wat_writer.write("(locals");
                for (function.locals.items) |local| {
                    for (0..local.count) |_| {
                        try wat_writer.print(" {s}", .{@tagName(local.type)});
                    }
                }
                try wat_writer.write(")\n");
            }
            for (function.instructions.items) |instruction| {
                switch (instruction) {
                    .@"if" => {
                        try wat_writer.writeIndent();
                        try wat_writer.write("if");
                        try wat_writer.breakLine();
                        wat_writer.indent += 1;
                    },
                    .end => {
                        wat_writer.indent -= 1;
                        try wat_writer.writeIndent();
                        try wat_writer.write("end");
                        try wat_writer.breakLine();
                    },
                    else => {
                        try wat_writer.writeIndent();
                        try instruction.toWat(&wat_writer);
                        try wat_writer.breakLine();
                    },
                }
            }
            wat_writer.indent -= 1;
            try wat_writer.writeIndent();
            try wat_writer.write(")\n");
        }

        try wat_writer.close(); //module
    }
    pub fn dumpBytes(self: *Module) !void {
        const buffer_capacity = 1024;
        var buf = try std.BoundedArray(u8, buffer_capacity).init(0);
        try self.toBytes(buf.writer().any());
        for (buf.slice(), 0..) |byte, i| {
            std.debug.print("{x:02} ", .{byte});
            if ((i + 1) % 4 == 0) {
                std.debug.print("\n", .{});
            }
        }
        std.debug.print("\n", .{});
    }
};

const WatWriter = struct {
    writer: std.io.AnyWriter,
    indent: usize = 0,
    pub fn writeIndent(self: *WatWriter) !void {
        for (0..self.indent) |_| {
            try self.writer.writeAll("  ");
        }
    }
    pub fn inlineComment(self: *WatWriter, comment: []const u8) !void {
        try self.writer.writeAll("(;");
        try self.writer.writeAll(comment);
        try self.writer.writeAll(";)");
    }
    pub fn openInline(self: *WatWriter, expr: []const u8) !void {
        try self.writer.writeAll("(");
        try self.writer.writeAll(expr);
        try self.writer.writeAll("");
    }
    pub fn closeInline(self: *WatWriter) !void {
        try self.writer.writeAll(")");
    }
    pub fn breakLine(self: *WatWriter) !void {
        try self.writer.writeAll("\n");
    }
    pub fn open(self: *WatWriter, expr: []const u8) !void {
        try self.writeIndent();
        self.indent += 1;
        try self.writer.writeAll("(");
        try self.writer.writeAll(expr);
        try self.writer.writeAll("\n");
    }
    pub fn close(self: *WatWriter) !void {
        self.indent -= 1;
        try self.writeIndent();
        try self.writer.writeAll(")");
    }
    pub fn write(self: *WatWriter, str: []const u8) !void {
        try self.writer.writeAll(str);
    }
    pub fn print(self: *WatWriter, comptime format: []const u8, args: anytype) !void {
        try self.writer.print(format, args);
    }
};
// fn writeVarUInt32(writer: std.io.AnyWriter, value: u32) !void {
//     var val = value;
//     while (true) {
//         var byte: u8 = @intCast(val & 0x7F);
//         val = val >> 7;
//         if (val != 0) {
//             byte |= 0x80;
//         }
//         try writer.writeByte(byte);
//     }
// }
pub const Section = struct {
    bytes: std.ArrayListUnmanaged(u8) = .{},
    kind: Kind,
    module: *Module,
    allocator: std.mem.Allocator,
    pub const Kind = enum(u8) {
        custom = 0x00,
        type = 0x01,
        import = 0x02,
        function = 0x03,
        table = 0x04,
        memory = 0x05,
        global = 0x06,
        @"export" = 0x07,
        start = 0x08,
        element = 0x09,
        code = 0x0a,
        data = 0x0b,
        data_count = 0x0c,

        unidentified = 0xFF,
    };
    pub fn init(allocator: std.mem.Allocator, module: *Module, kind: Kind) Section {
        return .{
            .module = module,
            .kind = kind,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Section) void {
        self.bytes.deinit(self.allocator);
    }

    pub fn writeUint32(self: *Section, value: u32) !usize {
        var val = value;
        const start_len = self.bytes.items.len;
        while (true) {
            var byte: u8 = @intCast(val & 0x7F);
            val = val >> 7;
            if (val == 0) {
                try self.bytes.append(self.allocator, byte);
                break;
            } else {
                byte |= 0x80;
                try self.bytes.append(self.allocator, byte);
            }
        }
        return self.bytes.items.len - start_len;
    }

    pub inline fn writeEnum(self: *Section, value: anytype) !usize {
        return try self.writeUint32(@intFromEnum(value));
    }

    pub inline fn writeSlice(self: *Section, T: type, value: []const T) !void {
        for (value) |item| {
            try self.write(item);
        }
    }
    pub fn writeByte(self: *Section, value: u8) !void {
        try self.bytes.append(self.allocator, value);
    }
    pub fn writeDirect(self: *Section, value: []const u8) !void {
        try self.bytes.appendSlice(self.allocator, value);
    }
    pub fn write(self: *Section, value: anytype) !void {
        const T = @TypeOf(value);
        const writer = self.bytes.writer(self.allocator);
        switch (T) {
            *Section => {
                try value.toBytes(self.bytes.writer(self.allocator).any());
            },
            i32, i64 => {
                try std.leb.writeIleb128(writer, value);
            },
            f32, f64 => {
                try self.write(std.mem.asBytes(&value));
            },
            u32, usize => {
                try std.leb.writeUleb128(writer, value);
            },

            comptime_int, u8 => {
                try self.writeByte(value);
            },
            bool => {
                try self.writeByte(if (value) 0x01 else 0x00);
            },

            else => {
                switch (@typeInfo(T)) {
                    .@"enum" => {
                        try self.writeByte(@intFromEnum(value));
                    },
                    .pointer => {
                        for (value) |item| {
                            try self.write(item);
                        }
                    },
                    else => {
                        std.debug.panic("Unsupported type {any}", .{T});
                    },
                }
            },
        }
    }

    pub fn dump(self: *Section) void {
        std.debug.print("Section '{s}'\n", .{@tagName(self.kind)});
        for (self.bytes.items, 0..) |byte, i| {
            std.debug.print("{x:02} ", .{byte});
            if ((i + 1) % 4 == 0) {
                std.debug.print("\n", .{});
            }
        }
        std.debug.print("\n", .{});
    }
    pub fn clearRetainingCapacity(self: *Section) void {
        self.bytes.clearRetainingCapacity();
    }
    pub fn toBytes(self: *Section, writer: std.io.AnyWriter) !void {
        if (self.kind != .unidentified) {
            try writeVarUInt32(writer, @intFromEnum(self.kind));
        }
        try writeVarUInt32(writer, @intCast(self.bytes.items.len));
        try writer.writeAll(self.bytes.items);
    }
};
test "wasm" {
    // const magic_bytes = std.mem.toBytes(MAGIC);
    // std.debug.print("MAGIC: {x}\n", .{magic_bytes});
    // expect(MAGIC == [_]u8{ 0x00, 0x61, 0x73, 0x6d });

    const buffer_capacity = 1024;
    var buf = try std.BoundedArray(u8, buffer_capacity).init(0);

    var module = try Module.init(std.testing.allocator);
    defer module.deinit();
    var func_a = module.makeFunction();
    try func_a.pushParam(.i32);
    try func_a.pushParam(.i32);
    try func_a.pushResult(.i32);

    try func_a.pushLocal(.i32);
    try func_a.pushLocal(.i32);

    try func_a.pushInstruction(.{ .local_get = 0 });
    try func_a.pushInstruction(.{ .local_get = 1 });
    try func_a.pushInstruction(.{ .i32_add = {} });
    const func_a_index = try module.pushFunction(func_a);
    _ = func_a_index; // autofix

    try module.toBytes(buf.writer().any());

    std.debug.print("=========== bytes ==========\n", .{});
    // std.debug.print("{x}\n", .{buf.slice()});
    for (buf.slice(), 0..) |byte, i| {
        std.debug.print("{x:02} ", .{byte});
        if ((i + 1) % 4 == 0) {
            std.debug.print("\n", .{});
        }
    }
    std.debug.print("\n=========== bytes ==========\n", .{});
    var output = try std.fs.cwd().createFile("writer.wasm", .{});
    defer output.close();
    try output.writeAll(buf.slice());
    var section = Section.init(std.testing.allocator, &module, .custom);
    defer section.deinit();
    // try section.writeSlice(u32, &.{ 1, 2, 3, 254 });

    try module.toWat(std.io.getStdErr().writer().any());
    var sec = Section.init(std.testing.allocator, &module, .custom);
    defer sec.deinit();

    // try add.writeInto(&sec);
}
