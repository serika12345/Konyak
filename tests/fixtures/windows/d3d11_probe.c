#define COBJMACROS
#define WIN32_LEAN_AND_MEAN

#include <d3d11.h>
#include <dxgi.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

static const wchar_t *kClassName = L"KonyakD3D11ProbeWindow";
static const int kWindowWidth = 960;
static const int kWindowHeight = 540;
static wchar_t g_status_text[256] = L"Konyak D3D11 Probe";

static LRESULT CALLBACK window_proc(
    HWND window,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
  switch (message) {
    case WM_CLOSE:
      DestroyWindow(window);
      return 0;
    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;
    case WM_PAINT: {
      PAINTSTRUCT paint;
      HDC dc = BeginPaint(window, &paint);
      RECT client_rect;
      GetClientRect(window, &client_rect);
      HBRUSH brush = CreateSolidBrush(RGB(96, 16, 24));
      FillRect(dc, &client_rect, brush);
      DeleteObject(brush);
      SetBkMode(dc, TRANSPARENT);
      SetTextColor(dc, RGB(255, 245, 245));
      DrawTextW(
          dc,
          g_status_text,
          -1,
          &client_rect,
          DT_CENTER | DT_VCENTER | DT_SINGLELINE);
      EndPaint(window, &paint);
      return 0;
    }
    default:
      return DefWindowProcW(window, message, wparam, lparam);
  }
}

static DWORD hold_ms(void) {
  char *value = getenv("KONYAK_D3D11_PROBE_HOLD_MS");
  if (value == NULL || value[0] == '\0') {
    value = getenv("KONYAK_OPTIONAL_PROBE_HOLD_MS");
  }
  if (value == NULL || value[0] == '\0') {
    return 12000;
  }

  const long parsed = strtol(value, NULL, 10);
  if (parsed < 1000) {
    return 1000;
  }
  if (parsed > 60000) {
    return 60000;
  }
  return (DWORD)parsed;
}

static void hold_window(DWORD duration) {
  const DWORD started_at = GetTickCount();
  MSG message;
  while ((GetTickCount() - started_at) < duration) {
    while (PeekMessageW(&message, NULL, 0, 0, PM_REMOVE)) {
      if (message.message == WM_QUIT) {
        return;
      }
      TranslateMessage(&message);
      DispatchMessageW(&message);
    }
    Sleep(16);
  }
}

static int show_failure(HWND window, const char *operation, HRESULT result) {
  swprintf(
      g_status_text,
      sizeof(g_status_text) / sizeof(g_status_text[0]),
      L"%S failed: 0x%08lx",
      operation,
      (unsigned long)result);
  SetWindowTextW(window, L"Konyak D3D11 Probe Failed");
  ShowWindow(window, SW_SHOWNORMAL);
  UpdateWindow(window);
  InvalidateRect(window, NULL, TRUE);
  fprintf(stderr, "%s failed: 0x%08lx\n", operation, (unsigned long)result);
  hold_window(hold_ms());
  DestroyWindow(window);
  return 1;
}

int main(void) {
  const HINSTANCE instance = GetModuleHandleW(NULL);
  WNDCLASSEXW window_class = {0};
  window_class.cbSize = sizeof(window_class);
  window_class.lpfnWndProc = window_proc;
  window_class.hInstance = instance;
  window_class.lpszClassName = kClassName;
  window_class.hCursor = LoadCursorW(NULL, MAKEINTRESOURCEW(32512));

  if (!RegisterClassExW(&window_class)) {
    fprintf(stderr, "RegisterClassExW failed: %lu\n", GetLastError());
    return 1;
  }

  RECT window_rect = {0, 0, kWindowWidth, kWindowHeight};
  AdjustWindowRect(&window_rect, WS_OVERLAPPEDWINDOW, FALSE);

  HWND window = CreateWindowExW(
      WS_EX_APPWINDOW,
      kClassName,
      L"Konyak D3D11 Probe",
      WS_OVERLAPPEDWINDOW | WS_VISIBLE,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      window_rect.right - window_rect.left,
      window_rect.bottom - window_rect.top,
      NULL,
      NULL,
      instance,
      NULL);
  if (window == NULL) {
    fprintf(stderr, "CreateWindowExW failed: %lu\n", GetLastError());
    return 1;
  }

  DXGI_SWAP_CHAIN_DESC swap_chain_desc = {0};
  swap_chain_desc.BufferDesc.Width = kWindowWidth;
  swap_chain_desc.BufferDesc.Height = kWindowHeight;
  swap_chain_desc.BufferDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
  swap_chain_desc.BufferDesc.RefreshRate.Numerator = 60;
  swap_chain_desc.BufferDesc.RefreshRate.Denominator = 1;
  swap_chain_desc.SampleDesc.Count = 1;
  swap_chain_desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
  swap_chain_desc.BufferCount = 1;
  swap_chain_desc.OutputWindow = window;
  swap_chain_desc.Windowed = TRUE;
  swap_chain_desc.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

  const D3D_FEATURE_LEVEL requested_levels[] = {
      D3D_FEATURE_LEVEL_11_0,
      D3D_FEATURE_LEVEL_10_1,
      D3D_FEATURE_LEVEL_10_0,
  };

  D3D_FEATURE_LEVEL created_level = D3D_FEATURE_LEVEL_10_0;
  IDXGISwapChain *swap_chain = NULL;
  ID3D11Device *device = NULL;
  ID3D11DeviceContext *context = NULL;

  HRESULT result = D3D11CreateDeviceAndSwapChain(
      NULL,
      D3D_DRIVER_TYPE_HARDWARE,
      NULL,
      0,
      requested_levels,
      (UINT)(sizeof(requested_levels) / sizeof(requested_levels[0])),
      D3D11_SDK_VERSION,
      &swap_chain_desc,
      &swap_chain,
      &device,
      &created_level,
      &context);
  if (FAILED(result)) {
    return show_failure(window, "D3D11CreateDeviceAndSwapChain", result);
  }

  ID3D11Texture2D *back_buffer = NULL;
  result = IDXGISwapChain_GetBuffer(
      swap_chain,
      0,
      &IID_ID3D11Texture2D,
      (void **)&back_buffer);
  if (FAILED(result)) {
    return show_failure(window, "IDXGISwapChain_GetBuffer", result);
  }

  ID3D11RenderTargetView *render_target = NULL;
  result = ID3D11Device_CreateRenderTargetView(
      device,
      (ID3D11Resource *)back_buffer,
      NULL,
      &render_target);
  ID3D11Texture2D_Release(back_buffer);
  if (FAILED(result)) {
    return show_failure(window, "ID3D11Device_CreateRenderTargetView", result);
  }

  ID3D11DeviceContext_OMSetRenderTargets(context, 1, &render_target, NULL);

  ShowWindow(window, SW_SHOWNORMAL);
  UpdateWindow(window);

  const DWORD started_at = GetTickCount();
  const DWORD duration = hold_ms();
  MSG message;
  int frame = 0;

  while ((GetTickCount() - started_at) < duration) {
    while (PeekMessageW(&message, NULL, 0, 0, PM_REMOVE)) {
      if (message.message == WM_QUIT) {
        goto done;
      }
      TranslateMessage(&message);
      DispatchMessageW(&message);
    }

    const float t = (float)(frame % 240) / 239.0f;
    const float color[4] = {0.08f + 0.25f * t, 0.18f, 0.45f - 0.20f * t, 1.0f};
    ID3D11DeviceContext_ClearRenderTargetView(context, render_target, color);
    IDXGISwapChain_Present(swap_chain, 1, 0);
    Sleep(16);
    frame++;
  }

done:
  printf(
      "KONYAK_D3D11_PROBE_OK featureLevel=0x%04x frames=%d\n",
      (unsigned int)created_level,
      frame);

  ID3D11RenderTargetView_Release(render_target);
  ID3D11DeviceContext_Release(context);
  ID3D11Device_Release(device);
  IDXGISwapChain_Release(swap_chain);
  DestroyWindow(window);
  return 0;
}
