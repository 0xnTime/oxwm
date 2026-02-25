const std = @import("std");
const xlib = @import("xlib.zig");

pub const EventType = enum(c_int) {
    key_press = xlib.KeyPress,
    key_release = xlib.KeyRelease,
    button_press = xlib.ButtonPress,
    button_release = xlib.ButtonRelease,
    motion_notify = xlib.MotionNotify,
    enter_notify = xlib.EnterNotify,
    leave_notify = xlib.LeaveNotify,
    focus_in = xlib.FocusIn,
    focus_out = xlib.FocusOut,
    keymap_notify = xlib.KeymapNotify,
    expose = xlib.Expose,
    graphics_expose = xlib.GraphicsExpose,
    no_expose = xlib.NoExpose,
    visibility_notify = xlib.VisibilityNotify,
    create_notify = xlib.CreateNotify,
    destroy_notify = xlib.DestroyNotify,
    unmap_notify = xlib.UnmapNotify,
    map_notify = xlib.MapNotify,
    map_request = xlib.MapRequest,
    reparent_notify = xlib.ReparentNotify,
    configure_notify = xlib.ConfigureNotify,
    configure_request = xlib.ConfigureRequest,
    gravity_notify = xlib.GravityNotify,
    resize_request = xlib.ResizeRequest,
    circulate_notify = xlib.CirculateNotify,
    circulate_request = xlib.CirculateRequest,
    property_notify = xlib.PropertyNotify,
    selection_clear = xlib.SelectionClear,
    selection_request = xlib.SelectionRequest,
    selection_notify = xlib.SelectionNotify,
    colormap_notify = xlib.ColormapNotify,
    client_message = xlib.ClientMessage,
    mapping_notify = xlib.MappingNotify,
    generic_event = xlib.GenericEvent,
    _,
};

pub fn getEventType(event: *const xlib.XEvent) EventType {
    return @enumFromInt(event.type);
}

pub fn eventName(event_type: EventType) []const u8 {
    if (@intFromEnum(event_type) > @intFromEnum(EventType.generic_event)) return "unknown";

    return @tagName(event_type);
}

test eventName {
    const testing = std.testing;

    const name = eventName(.key_press);
    try testing.expectEqualStrings("key_press", name);

    try testing.expectEqualStrings("unknown", eventName(@enumFromInt(100)));
}
