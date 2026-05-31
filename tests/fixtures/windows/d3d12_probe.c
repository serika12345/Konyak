#define COBJMACROS
#define INITGUID
#define WIN32_LEAN_AND_MEAN

#include <d3d12.h>
#include <dxgi1_4.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

static const wchar_t *kClassName = L"KonyakD3D12ProbeWindow";
static const int kWindowWidth = 960;
static const int kWindowHeight = 540;
static wchar_t g_status_text[256] = L"Konyak D3D12 Probe";

typedef struct D3D12Probe {
  IDXGIFactory4 *factory;
  ID3D12Device *device;
  ID3D12CommandQueue *queue;
  IDXGISwapChain3 *swap_chain;
  ID3D12DescriptorHeap *rtv_heap;
  ID3D12Resource *render_targets[2];
  ID3D12CommandAllocator *allocator;
  ID3D12GraphicsCommandList *command_list;
  ID3D12Fence *fence;
  HANDLE fence_event;
  UINT rtv_descriptor_size;
  UINT frame_index;
  UINT64 fence_value;
  D3D12_RAYTRACING_TIER raytracing_tier;
} D3D12Probe;

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
      HBRUSH brush = CreateSolidBrush(RGB(16, 28, 40));
      FillRect(dc, &client_rect, brush);
      DeleteObject(brush);
      SetBkMode(dc, TRANSPARENT);
      SetTextColor(dc, RGB(230, 242, 255));
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
  char *value = getenv("KONYAK_D3D12_PROBE_HOLD_MS");
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
  SetWindowTextW(window, L"Konyak D3D12 Probe Failed");
  ShowWindow(window, SW_SHOWNORMAL);
  UpdateWindow(window);
  InvalidateRect(window, NULL, TRUE);
  fprintf(stderr, "%s failed: 0x%08lx\n", operation, (unsigned long)result);
  hold_window(hold_ms());
  DestroyWindow(window);
  return 1;
}

static int show_dxr_failure(HWND window, D3D12_RAYTRACING_TIER tier) {
  swprintf(
      g_status_text,
      sizeof(g_status_text) / sizeof(g_status_text[0]),
      L"DXR unsupported: RaytracingTier=0x%x",
      (unsigned int)tier);
  SetWindowTextW(window, L"Konyak D3D12 DXR Probe Failed");
  ShowWindow(window, SW_SHOWNORMAL);
  UpdateWindow(window);
  InvalidateRect(window, NULL, TRUE);
  fprintf(
      stderr,
      "DXR unsupported: RaytracingTier=0x%x\n",
      (unsigned int)tier);
  hold_window(hold_ms());
  DestroyWindow(window);
  return 2;
}

static D3D12_RESOURCE_BARRIER transition_barrier(
    ID3D12Resource *resource,
    D3D12_RESOURCE_STATES before,
    D3D12_RESOURCE_STATES after) {
  D3D12_RESOURCE_BARRIER barrier;
  ZeroMemory(&barrier, sizeof(barrier));
  barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
  barrier.Transition.pResource = resource;
  barrier.Transition.StateBefore = before;
  barrier.Transition.StateAfter = after;
  barrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
  return barrier;
}

static D3D12_CPU_DESCRIPTOR_HANDLE rtv_heap_start(
    ID3D12DescriptorHeap *heap) {
  D3D12_CPU_DESCRIPTOR_HANDLE handle;
  ZeroMemory(&handle, sizeof(handle));
  heap->lpVtbl->GetCPUDescriptorHandleForHeapStart(heap, &handle);
  return handle;
}

static HRESULT wait_for_gpu(D3D12Probe *probe) {
  probe->fence_value++;
  HRESULT result = ID3D12CommandQueue_Signal(
      probe->queue,
      probe->fence,
      probe->fence_value);
  if (FAILED(result)) {
    return result;
  }

  if (ID3D12Fence_GetCompletedValue(probe->fence) < probe->fence_value) {
    result = ID3D12Fence_SetEventOnCompletion(
        probe->fence,
        probe->fence_value,
        probe->fence_event);
    if (FAILED(result)) {
      return result;
    }
    WaitForSingleObject(probe->fence_event, INFINITE);
  }
  probe->frame_index = IDXGISwapChain3_GetCurrentBackBufferIndex(
      probe->swap_chain);
  return S_OK;
}

static void cleanup_probe(D3D12Probe *probe) {
  if (probe->queue != NULL && probe->fence != NULL) {
    wait_for_gpu(probe);
  }
  if (probe->fence_event != NULL) {
    CloseHandle(probe->fence_event);
  }
  if (probe->fence != NULL) ID3D12Fence_Release(probe->fence);
  if (probe->command_list != NULL)
    ID3D12GraphicsCommandList_Release(probe->command_list);
  if (probe->allocator != NULL)
    ID3D12CommandAllocator_Release(probe->allocator);
  for (UINT index = 0; index < 2; ++index) {
    if (probe->render_targets[index] != NULL) {
      ID3D12Resource_Release(probe->render_targets[index]);
    }
  }
  if (probe->rtv_heap != NULL)
    ID3D12DescriptorHeap_Release(probe->rtv_heap);
  if (probe->swap_chain != NULL) IDXGISwapChain3_Release(probe->swap_chain);
  if (probe->queue != NULL) ID3D12CommandQueue_Release(probe->queue);
  if (probe->device != NULL) ID3D12Device_Release(probe->device);
  if (probe->factory != NULL) IDXGIFactory4_Release(probe->factory);
}

static HRESULT init_probe(D3D12Probe *probe, HWND window) {
  HRESULT result = CreateDXGIFactory1(&IID_IDXGIFactory4, (void **)&probe->factory);
  if (FAILED(result)) {
    return result;
  }

  result = D3D12CreateDevice(
      NULL,
      D3D_FEATURE_LEVEL_11_0,
      &IID_ID3D12Device,
      (void **)&probe->device);
  if (FAILED(result)) {
    return result;
  }

  D3D12_FEATURE_DATA_D3D12_OPTIONS5 options5;
  ZeroMemory(&options5, sizeof(options5));
  result = ID3D12Device_CheckFeatureSupport(
      probe->device,
      D3D12_FEATURE_D3D12_OPTIONS5,
      &options5,
      sizeof(options5));
  if (FAILED(result)) {
    return result;
  }
  probe->raytracing_tier = options5.RaytracingTier;
  if (probe->raytracing_tier == D3D12_RAYTRACING_TIER_NOT_SUPPORTED) {
    return DXGI_ERROR_UNSUPPORTED;
  }

  D3D12_COMMAND_QUEUE_DESC queue_desc;
  ZeroMemory(&queue_desc, sizeof(queue_desc));
  queue_desc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
  result = ID3D12Device_CreateCommandQueue(
      probe->device,
      &queue_desc,
      &IID_ID3D12CommandQueue,
      (void **)&probe->queue);
  if (FAILED(result)) {
    return result;
  }

  DXGI_SWAP_CHAIN_DESC1 swap_chain_desc;
  ZeroMemory(&swap_chain_desc, sizeof(swap_chain_desc));
  swap_chain_desc.Width = kWindowWidth;
  swap_chain_desc.Height = kWindowHeight;
  swap_chain_desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
  swap_chain_desc.SampleDesc.Count = 1;
  swap_chain_desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
  swap_chain_desc.BufferCount = 2;
  swap_chain_desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;

  IDXGISwapChain1 *swap_chain1 = NULL;
  result = IDXGIFactory4_CreateSwapChainForHwnd(
      probe->factory,
      (IUnknown *)probe->queue,
      window,
      &swap_chain_desc,
      NULL,
      NULL,
      &swap_chain1);
  if (FAILED(result)) {
    return result;
  }
  result = IDXGISwapChain1_QueryInterface(
      swap_chain1,
      &IID_IDXGISwapChain3,
      (void **)&probe->swap_chain);
  IDXGISwapChain1_Release(swap_chain1);
  if (FAILED(result)) {
    return result;
  }
  probe->frame_index = IDXGISwapChain3_GetCurrentBackBufferIndex(
      probe->swap_chain);

  D3D12_DESCRIPTOR_HEAP_DESC heap_desc;
  ZeroMemory(&heap_desc, sizeof(heap_desc));
  heap_desc.NumDescriptors = 2;
  heap_desc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_RTV;
  result = ID3D12Device_CreateDescriptorHeap(
      probe->device,
      &heap_desc,
      &IID_ID3D12DescriptorHeap,
      (void **)&probe->rtv_heap);
  if (FAILED(result)) {
    return result;
  }
  probe->rtv_descriptor_size = ID3D12Device_GetDescriptorHandleIncrementSize(
      probe->device,
      D3D12_DESCRIPTOR_HEAP_TYPE_RTV);

  D3D12_CPU_DESCRIPTOR_HANDLE rtv_handle = rtv_heap_start(probe->rtv_heap);
  for (UINT index = 0; index < 2; ++index) {
    result = IDXGISwapChain3_GetBuffer(
        probe->swap_chain,
        index,
        &IID_ID3D12Resource,
        (void **)&probe->render_targets[index]);
    if (FAILED(result)) {
      return result;
    }
    ID3D12Device_CreateRenderTargetView(
        probe->device,
        probe->render_targets[index],
        NULL,
        rtv_handle);
    rtv_handle.ptr += probe->rtv_descriptor_size;
  }

  result = ID3D12Device_CreateCommandAllocator(
      probe->device,
      D3D12_COMMAND_LIST_TYPE_DIRECT,
      &IID_ID3D12CommandAllocator,
      (void **)&probe->allocator);
  if (FAILED(result)) {
    return result;
  }

  result = ID3D12Device_CreateCommandList(
      probe->device,
      0,
      D3D12_COMMAND_LIST_TYPE_DIRECT,
      probe->allocator,
      NULL,
      &IID_ID3D12GraphicsCommandList,
      (void **)&probe->command_list);
  if (FAILED(result)) {
    return result;
  }
  result = ID3D12GraphicsCommandList_Close(probe->command_list);
  if (FAILED(result)) {
    return result;
  }

  result = ID3D12Device_CreateFence(
      probe->device,
      0,
      D3D12_FENCE_FLAG_NONE,
      &IID_ID3D12Fence,
      (void **)&probe->fence);
  if (FAILED(result)) {
    return result;
  }
  probe->fence_event = CreateEventW(NULL, FALSE, FALSE, NULL);
  if (probe->fence_event == NULL) {
    return HRESULT_FROM_WIN32(GetLastError());
  }
  return S_OK;
}

static HRESULT draw_frame(D3D12Probe *probe, int frame) {
  HRESULT result = ID3D12CommandAllocator_Reset(probe->allocator);
  if (FAILED(result)) {
    return result;
  }
  result = ID3D12GraphicsCommandList_Reset(
      probe->command_list,
      probe->allocator,
      NULL);
  if (FAILED(result)) {
    return result;
  }

  ID3D12Resource *target = probe->render_targets[probe->frame_index];
  D3D12_RESOURCE_BARRIER barrier = transition_barrier(
      target,
      D3D12_RESOURCE_STATE_PRESENT,
      D3D12_RESOURCE_STATE_RENDER_TARGET);
  ID3D12GraphicsCommandList_ResourceBarrier(probe->command_list, 1, &barrier);

  D3D12_CPU_DESCRIPTOR_HANDLE rtv_handle = rtv_heap_start(probe->rtv_heap);
  rtv_handle.ptr += probe->frame_index * probe->rtv_descriptor_size;
  const float t = (float)(frame % 240) / 239.0f;
  const float color[4] = {0.10f, 0.18f + 0.32f * t, 0.26f, 1.0f};
  ID3D12GraphicsCommandList_ClearRenderTargetView(
      probe->command_list,
      rtv_handle,
      color,
      0,
      NULL);

  barrier = transition_barrier(
      target,
      D3D12_RESOURCE_STATE_RENDER_TARGET,
      D3D12_RESOURCE_STATE_PRESENT);
  ID3D12GraphicsCommandList_ResourceBarrier(probe->command_list, 1, &barrier);

  result = ID3D12GraphicsCommandList_Close(probe->command_list);
  if (FAILED(result)) {
    return result;
  }

  ID3D12CommandList *command_lists[] = {
      (ID3D12CommandList *)probe->command_list,
  };
  ID3D12CommandQueue_ExecuteCommandLists(probe->queue, 1, command_lists);
  result = IDXGISwapChain3_Present(probe->swap_chain, 1, 0);
  if (FAILED(result)) {
    return result;
  }
  return wait_for_gpu(probe);
}

static HWND create_window(void) {
  const HINSTANCE instance = GetModuleHandleW(NULL);
  WNDCLASSEXW window_class;
  ZeroMemory(&window_class, sizeof(window_class));
  window_class.cbSize = sizeof(window_class);
  window_class.lpfnWndProc = window_proc;
  window_class.hInstance = instance;
  window_class.lpszClassName = kClassName;
  window_class.hCursor = LoadCursorW(NULL, MAKEINTRESOURCEW(32512));

  if (!RegisterClassExW(&window_class)) {
    fprintf(stderr, "RegisterClassExW failed: %lu\n", GetLastError());
    return NULL;
  }

  RECT window_rect = {0, 0, kWindowWidth, kWindowHeight};
  AdjustWindowRect(&window_rect, WS_OVERLAPPEDWINDOW, FALSE);

  HWND window = CreateWindowExW(
      WS_EX_APPWINDOW,
      kClassName,
      L"Konyak D3D12 GPTK Probe",
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
    return NULL;
  }
  return window;
}

int main(void) {
  HWND window = create_window();
  if (window == NULL) {
    return 1;
  }

  D3D12Probe probe;
  ZeroMemory(&probe, sizeof(probe));

  HRESULT result = init_probe(&probe, window);
  if (FAILED(result)) {
    if (result == DXGI_ERROR_UNSUPPORTED &&
        probe.device != NULL &&
        probe.raytracing_tier == D3D12_RAYTRACING_TIER_NOT_SUPPORTED) {
      cleanup_probe(&probe);
      return show_dxr_failure(window, probe.raytracing_tier);
    }
    cleanup_probe(&probe);
    return show_failure(window, "D3D12 initialization", result);
  }

  swprintf(
      g_status_text,
      sizeof(g_status_text) / sizeof(g_status_text[0]),
      L"KONYAK D3D12 DXR Probe - tier 0x%x",
      (unsigned int)probe.raytracing_tier);
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

    result = draw_frame(&probe, frame);
    if (FAILED(result)) {
      cleanup_probe(&probe);
      return show_failure(window, "D3D12 draw", result);
    }
    Sleep(16);
    frame++;
  }

done:
  printf(
      "KONYAK_D3D12_GPTK_PROBE_OK raytracingTier=0x%x frames=%d\n",
      (unsigned int)probe.raytracing_tier,
      frame);
  cleanup_probe(&probe);
  DestroyWindow(window);
  return 0;
}
