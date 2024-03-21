const std = @import("std");
const WINAPI = std.os.windows.WINAPI;

pub fn main() void {
    // get handle to the current exe
    const hInstance = win32.GetModuleHandleA(null) orelse return;

    // register a custom window class for the current exe, with our defined window procedure
    const atom = win32.RegisterClassExA( &.{
        .lpfnWndProc = myWndProc,
        .hInstance = hInstance,
        .hCursor = win32.LoadCursorA(null,@ptrFromInt(32512)), // default arrow cursor
        .lpszClassName = "MyWindowClass",
    } );

    // quit if we failed to register the class that we're trying to create a window from
    if (atom==0) return; 

    // actually create the window
    const hwnd = win32.CreateWindowExA(
        0, // no extended style
        @ptrFromInt(@as(usize,@intCast(atom))), // unique atom that the OS assigned to our registered class
        "MyWindow", // title of the window
        win32.WS_VISIBLE | win32.WS_SYSMENU, // window is visible with close button
        win32.CW_USEDEFAULT, // default x
        win32.CW_USEDEFAULT, // default y
        win32.CW_USEDEFAULT, // default w
        win32.CW_USEDEFAULT, // default h
        null, // not a child of any window
        null, // no default menubar
        null, // the class is from the current exe
        null, // nothing in particular that needs to be passed
    );

    // main program loop
    while(hwnd) |_| {
        var msg: win32.MSG = undefined;
        switch(win32.GetMessageA(&msg,null,0,0)) {
            0 => break, // normal close
            -1 => break, // error close
            else => {
                _ = win32.DispatchMessageA(&msg); // pass msg to its respective window procedure 
            }
        } 
    }
}

fn myWndProc(hwnd: *anyopaque, uMsg: u32, wParam: usize, lParam: isize) callconv(WINAPI) isize {
    switch(uMsg) {        
        0x0010 => { // WM_CLOSE
            _ = win32.PostQuitMessage(0); // signal the main program to quit
        },
        else => {},
    }
    return win32.DefWindowProcA(hwnd, uMsg, wParam, lParam); // pass unhandled messages to default handler
}

const win32 = struct {
    // WinAPI constants
    const CW_USEDEFAULT: i32 = @bitCast(@as(u32, 0x80000000)); // sign bit of an i32
    const WS_VISIBLE = 0x10000000; // flag to make window initially visible
    const WS_SYSMENU = 0x00080000; // flag make window have close button

    // WinAPI typedefs
    const MSG = extern struct {
        hWnd: ?*anyopaque,
        message: u32,
        wParam: usize,
        lParam: isize,
        time: u32,
        pt: std.os.windows.POINT,
        lPrivate: u32
    };
    const WNDCLASSEXA = extern struct {
        cbSize: u32 = @sizeOf(@This()),
        style: u32 = 0,
        lpfnWndProc: *const fn (*anyopaque, u32, usize, isize) callconv(WINAPI) isize,
        cbClsExtra: i32 = 0,
        cbWndExtra: i32 = 0,
        hInstance: *anyopaque,
        hIcon: ?*anyopaque = null,
        hCursor: ?*anyopaque = null,
        hbrBackground: ?*anyopaque = null,
        lpszMenuName: ?[*:0]const u8 = null,
        lpszClassName: [*:0]const u8,
        hIconSm: ?*anyopaque = null,
    };

    // WinAPI DLL functions
    extern "kernel32" fn GetModuleHandleA(?[*:0]const u8) callconv(WINAPI) ?*anyopaque;
    extern "user32" fn GetMessageA(*MSG, ?*anyopaque, u32, u32) callconv(WINAPI) i32;
    extern "user32" fn DispatchMessageA(*MSG) callconv(WINAPI) isize;
    extern "user32" fn DefWindowProcA(*anyopaque, u32, usize, isize) callconv(WINAPI) isize;
    extern "user32" fn PostQuitMessage(i32) callconv(WINAPI) void;
    extern "user32" fn LoadCursorA(?*anyopaque, ?*anyopaque) callconv(WINAPI) ?*anyopaque;
    extern "user32" fn RegisterClassExA(*const WNDCLASSEXA) callconv(WINAPI) u16;
    extern "user32" fn CreateWindowExA(
        u32, // extended style
        ?*anyopaque, // class name/class atom
        ?[*:0]const u8, // window name
        u32, // basic style
        i32,i32,i32,i32, // x,y,w,h
        ?*anyopaque, // parent
        ?*anyopaque, // menu
        ?*anyopaque, // hInstance
        ?*anyopaque, // info to pass to WM_CREATE callback inside wndproc
    ) callconv(WINAPI) ?*anyopaque;
};