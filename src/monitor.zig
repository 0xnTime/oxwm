const std = @import("std");
const xlib = @import("x11/xlib.zig");
const Client = @import("client.zig").Client;

pub const Layout = struct {
    symbol: []const u8,
    arrange_fn: ?*const fn (*Monitor) void,
};

// TODO: Make clearer, document? refactor?
pub const Pertag = struct {
    curtag: u32 = 1,
    prevtag: u32 = 1,
    nmasters: [10]i32 = [_]i32{1} ** 10,
    mfacts: [10]f32 = [_]f32{0.55} ** 10,
    sellts: [10]u32 = [_]u32{0} ** 10,
    ltidxs: [10][5]?*const Layout = [_][5]?*const Layout{.{ null, null, null, null, null }} ** 10,
    showbars: [10]bool = [_]bool{true} ** 10,
};

// TODO: Make clearer, document? refactor?
pub const Monitor = struct {
    lt_symbol: [16]u8 = std.mem.zeroes([16]u8),
    mfact: f32 = 0.55,
    nmaster: i32 = 1,
    num: i32 = 0,
    bar_y: i32 = 0,
    mon_x: i32 = 0,
    mon_y: i32 = 0,
    mon_w: i32 = 0,
    mon_h: i32 = 0,
    win_x: i32 = 0,
    win_y: i32 = 0,
    win_w: i32 = 0,
    win_h: i32 = 0,
    gap_inner_h: i32 = 0,
    gap_inner_v: i32 = 0,
    gap_outer_h: i32 = 0,
    gap_outer_v: i32 = 0,
    scroll_offset: i32 = 0,
    sel_tags: u32 = 0,
    sel_lt: u32 = 0,
    tagset: [2]u32 = .{ 1, 1 },
    show_bar: bool = true,
    top_bar: bool = true,
    clients: ?*Client = null,
    sel: ?*Client = null,
    stack: ?*Client = null,
    next: ?*Monitor = null,
    bar_win: xlib.Window = 0,
    lt: [5]?*const Layout = .{null} ** 5,
    pertag: Pertag = .{},
};

// NOTE: `monitors` and `selected_monitor` will soon be removed, they will
// move to `WindowManager` fields in a future refactor step.  All new
// code should prefer receiving a `*Monitor` or `?*Monitor` as a parameter
// rather than reaching into these globals directly.

pub var monitors: ?*Monitor = null;
pub var selected_monitor: ?*Monitor = null;

var allocator: std.mem.Allocator = undefined;

/// Must be called once before any other function in this module.
pub fn init(alloc: std.mem.Allocator) void {
    allocator = alloc;
}

/// Allocates and zero-initialises a new `Monitor`.
pub fn create() ?*Monitor {
    const mon = allocator.create(Monitor) catch return null;
    mon.* = Monitor{};
    return mon;
}

/// Frees a monitor previously returned by `create`.
pub fn destroy(mon: *Monitor) void {
    allocator.destroy(mon);
}

/// Returns the monitor whose bar window or client matches `win`, falling
/// back to a pointer-position query when `win` is the root window.
///
/// `display` and `root` are passed explicitly rather than cached in module
/// state, this keeps ownership clear and avoids a stale-pointer hazard.
pub fn window_to_monitor(display: *xlib.Display, root: xlib.Window, win: xlib.Window) ?*Monitor {
    if (win == root) {
        var root_x: c_int = undefined;
        var root_y: c_int = undefined;
        var dummy_win: xlib.Window = undefined;
        var dummy_int: c_int = undefined;
        var dummy_uint: c_uint = undefined;
        if (xlib.XQueryPointer(display, root, &dummy_win, &dummy_win, &root_x, &root_y, &dummy_int, &dummy_int, &dummy_uint) != 0) {
            return rect_to_monitor(root_x, root_y, 1, 1);
        }
    }

    var current = monitors;
    while (current) |monitor| {
        if (monitor.bar_win == win) return monitor;
        current = monitor.next;
    }

    const client = @import("client.zig").window_to_client(monitors, win);
    if (client) |found_client| {
        return found_client.monitor;
    }

    return selected_monitor;
}

/// Returns the monitor with the greatest intersection area with the given
/// rectangle, or `selected_monitor` if no intersection is found.
pub fn rect_to_monitor(x: i32, y: i32, width: i32, height: i32) ?*Monitor {
    var result = selected_monitor;
    var max_area: i32 = 0;

    var current = monitors;
    while (current) |monitor| {
        const intersect_x = @max(0, @min(x + width, monitor.win_x + monitor.win_w) - @max(x, monitor.win_x));
        const intersect_y = @max(0, @min(y + height, monitor.win_y + monitor.win_h) - @max(y, monitor.win_y));
        const area = intersect_x * intersect_y;
        if (area > max_area) {
            max_area = area;
            result = monitor;
        }
        current = monitor.next;
    }
    return result;
}

/// Returns the next or previous monitor relative to `selected_monitor`.
///
/// Positive `direction` moves forward through the linked list (wrapping to
/// the head); negative moves backward (wrapping to the tail).
///
// TODO:
// - Change direction to an enum/enum_literal
// - Rename function
pub fn dir_to_monitor(direction: i32) ?*Monitor {
    var target: ?*Monitor = null;

    if (direction > 0) {
        target = if (selected_monitor) |current| current.next else null;
        if (target == null) {
            target = monitors;
        }
    } else if (selected_monitor == monitors) {
        // Already at head, walk to tail.
        var last = monitors;
        while (last) |iter| {
            if (iter.next == null) {
                target = iter;
                break;
            }
            last = iter.next;
        }
    } else {
        // Walk until we find the node just before selected_monitor.
        var previous = monitors;
        while (previous) |iter| {
            if (iter.next == selected_monitor) {
                target = iter;
                break;
            }
            previous = iter.next;
        }
    }
    return target;
}
