#include "pch.h"
#include "capture.h"
#include <cstring>  // For memset


static HWND g_hwnd = nullptr;
static HDC g_hdcWindow = nullptr;
static HDC g_hdcMemDC = nullptr;
static HBITMAP g_hBitmap = nullptr;
static BITMAPINFO g_bmpInfo = {};
static uint8_t* g_pixels = nullptr;
static int g_width = 0;
static int g_height = 0;

struct CaptureContext {
    HWND hwnd = nullptr;
    HDC hdcWindow = nullptr;
    HDC hdcMemDC = nullptr;
    HBITMAP hBitmap = nullptr;
    BITMAPINFO bmpInfo = {};
    uint8_t* pixels = nullptr;
    int width = 0;
    int height = 0;
};


CaptureContext* init_capture(HWND hwnd)
{
    if (!hwnd) return nullptr;

    CaptureContext* ctx = new CaptureContext();
    ctx->hwnd = hwnd;

    RECT rc;
    if (!GetClientRect(hwnd, &rc)) { delete ctx; return nullptr; }

    ctx->width = rc.right - rc.left;
    ctx->height = rc.bottom - rc.top;

    ctx->hdcWindow = GetDC(hwnd);
    if (!ctx->hdcWindow) { delete ctx; return nullptr; }

    ctx->hdcMemDC = CreateCompatibleDC(ctx->hdcWindow);
    if (!ctx->hdcMemDC) { ReleaseDC(hwnd, ctx->hdcWindow); delete ctx; return nullptr; }

    ctx->hBitmap = CreateCompatibleBitmap(ctx->hdcWindow, ctx->width, ctx->height);
    if (!ctx->hBitmap) { DeleteDC(ctx->hdcMemDC); ReleaseDC(hwnd, ctx->hdcWindow); delete ctx; return nullptr; }

    SelectObject(ctx->hdcMemDC, ctx->hBitmap);

    std::memset(&ctx->bmpInfo, 0, sizeof(BITMAPINFO));
    ctx->bmpInfo.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    ctx->bmpInfo.bmiHeader.biWidth = ctx->width;
    ctx->bmpInfo.bmiHeader.biHeight = -ctx->height; // top-down
    ctx->bmpInfo.bmiHeader.biPlanes = 1;
    ctx->bmpInfo.bmiHeader.biBitCount = 32;
    ctx->bmpInfo.bmiHeader.biCompression = BI_RGB;

    ctx->pixels = new uint8_t[ctx->width * ctx->height * 4]; // RGBA

    return ctx;
}


bool get_frame(CaptureContext* ctx)
{
    if (!ctx || !ctx->hdcWindow || !ctx->hdcMemDC || !ctx->hBitmap) return false;

    if (!BitBlt(ctx->hdcMemDC, 0, 0, ctx->width, ctx->height, ctx->hdcWindow, 0, 0, SRCCOPY | CAPTUREBLT))
        return false;

    if (!GetDIBits(ctx->hdcMemDC, ctx->hBitmap, 0, ctx->height, ctx->pixels, &ctx->bmpInfo, DIB_RGB_COLORS))
        return false;

    return true;
}


uint8_t* get_frame_ptr(CaptureContext* ctx) { return ctx ? ctx->pixels : nullptr; }
int get_width(CaptureContext* ctx) { return ctx ? ctx->width : 0; }
int get_height(CaptureContext* ctx) { return ctx ? ctx->height : 0; }


void release(CaptureContext* ctx)
{
    if (!ctx) return;

    if (ctx->pixels) delete[] ctx->pixels;
    if (ctx->hBitmap) DeleteObject(ctx->hBitmap);
    if (ctx->hdcMemDC) DeleteDC(ctx->hdcMemDC);
    if (ctx->hdcWindow) ReleaseDC(ctx->hwnd, ctx->hdcWindow);

    delete ctx;
}
