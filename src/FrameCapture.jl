module FrameCapture


using Colors
using FileIO
using FixedPointNumbers

# --- DLL path ---
const libpath = joinpath(@__DIR__, "..", "deps", "capture.dll")
isfile(libpath) || error("DLL not found at $libpath")

# --- DLL bindings ---
# CaptureContext is opaque, use Ptr{Cvoid}
const CaptureContextPtr = Ptr{Cvoid}

function init_capture(hwnd::Ptr{Cvoid})::CaptureContextPtr
    return ccall((:init_capture, libpath), CaptureContextPtr, (Ptr{Cvoid},), hwnd)
end

function get_frame(ctx::CaptureContextPtr)::Bool
    return ccall((:get_frame, libpath), Bool, (CaptureContextPtr,), ctx)
end

function get_frame_ptr(ctx::CaptureContextPtr)::Ptr{UInt8}
    return ccall((:get_frame_ptr, libpath), Ptr{UInt8}, (CaptureContextPtr,), ctx)
end

function get_width(ctx::CaptureContextPtr)::Int32
    return ccall((:get_width, libpath), Int32, (CaptureContextPtr,), ctx)
end

function get_height(ctx::CaptureContextPtr)::Int32
    return ccall((:get_height, libpath), Int32, (CaptureContextPtr,), ctx)
end

function release(ctx::CaptureContextPtr)
    ccall((:release, libpath), Cvoid, (CaptureContextPtr,), ctx)
end

# --- Window helper ---
function find_window(title::String)::Ptr{Cvoid}
    c_title = Base.cconvert(Cstring, title)
    hw = ccall((:FindWindowA, "user32"), Ptr{Cvoid}, (Ptr{UInt8}, Ptr{UInt8}), C_NULL, c_title)
    return hw
end

# --- Public API ---

# Dictionary to keep track of contexts by window title
const _contexts = Dict{String, CaptureContextPtr}()

"""
    start_capture(window_title::String)

Finds the window by title and initializes capture.
Returns true if successful.
"""
function start_capture(window_title::String)::Bool
    hwnd = find_window(window_title)
    hwnd == C_NULL && error("Window not found: $window_title")

    ctx = init_capture(hwnd)
    ctx == C_NULL && error("Failed to initialize capture.")
    _contexts[window_title] = ctx
    return true
end

"""
    stop_capture(window_title::String)

Releases resources allocated for the given window capture.
"""
function stop_capture(window_title::String)
    ctx = get(_contexts, window_title, C_NULL)
    ctx != C_NULL && release(ctx)
    delete!(_contexts, window_title)
end

"""
    capture_frame(window_title::String, filename::String)

Captures the current frame of the window and saves it to `filename`.
Returns `(width, height)` of the captured image.
"""
function capture_frame(window_title::String, filename::String)
    ctx = get(_contexts, window_title, C_NULL)
    ctx == C_NULL && error("No capture context for window: $window_title")

    if get_frame(ctx)
        ptr = get_frame_ptr(ctx)
        w, h = get_width(ctx), get_height(ctx)
        bytes = w * h * 4
        buf = unsafe_wrap(Vector{UInt8}, ptr, bytes)

        # Convert BGRA -> RGB
        arr = reshape(buf, 4, w, h)
        img = Array{RGB{N0f8}}(undef, h, w)
        for y in 1:h, x in 1:w
            b, g, r = arr[1, x, y], arr[2, x, y], arr[3, x, y]
            img[y, x] = RGB{N0f8}(r/255, g/255, b/255)
        end

        save(filename, img)
        return w, h
    else
        return 0, 0
    end
end

"""
    get_img(window_title::String)

Returns the current captured frame as an `Array{RGB{N0f8},2}`.
"""
function get_img(window_title::String)
    ctx = get(_contexts, window_title, C_NULL)
    ctx == C_NULL && error("No capture context for window: $window_title")

    if get_frame(ctx)
        ptr = get_frame_ptr(ctx)
        w, h = get_width(ctx), get_height(ctx)
        bytes = w * h * 4
        buf = unsafe_wrap(Vector{UInt8}, ptr, bytes)

        arr = reshape(buf, 4, w, h)
        img = Array{RGB{N0f8}}(undef, h, w)
        for y in 1:h, x in 1:w
            b, g, r = arr[1, x, y], arr[2, x, y], arr[3, x, y]
            img[y, x] = RGB{N0f8}(r/255, g/255, b/255)
        end

        return img
    else
        return nothing
    end
end
export start_capture, stop_capture, capture_frame, get_img

end # module
