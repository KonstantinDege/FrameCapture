#pragma once
#include <cstdint>   // For uint8_t
#include <Windows.h>

#ifdef __cplusplus
extern "C" {
#endif

    // Opaque handle to a capture context
    typedef struct CaptureContext CaptureContext;

    // Initialize capture for a specific window, returns a context pointer
    __declspec(dllexport) CaptureContext* init_capture(HWND hwnd);

    // Capture a new frame for the given context
    __declspec(dllexport) bool get_frame(CaptureContext* ctx);

    // Get pointer to pixel data (RGBA) for the given context
    __declspec(dllexport) uint8_t* get_frame_ptr(CaptureContext* ctx);

    // Get width of captured frame for the given context
    __declspec(dllexport) int get_width(CaptureContext* ctx);

    // Get height of captured frame for the given context
    __declspec(dllexport) int get_height(CaptureContext* ctx);

    // Release resources associated with the capture context
    __declspec(dllexport) void release(CaptureContext* ctx);

#ifdef __cplusplus
}
#endif
