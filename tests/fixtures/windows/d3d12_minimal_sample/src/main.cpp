#include <d3d12.h>
#include <dxgi1_6.h>
#include <windows.h>
#include <wrl/client.h>

#include <cstdio>
#include <cstdlib>
#include <exception>
#include <stdexcept>
#include <string>

using Microsoft::WRL::ComPtr;

namespace {

constexpr UINT kFrameCount = 2;
constexpr UINT kWidth = 640;
constexpr UINT kHeight = 360;
constexpr char kSuccessMarker[] = "KONYAK_D3D12_MINIMAL_SAMPLE_OK\n";
constexpr char kSuccessSentinelPath[] =
    "C:\\konyak-d3d12-minimal-sample-ok.txt";
constexpr wchar_t kWindowClassName[] = L"KonyakD3D12MinimalSampleWindow";

struct DxState {
  ComPtr<IDXGIFactory4> factory;
  ComPtr<ID3D12Device> device;
  ComPtr<ID3D12CommandQueue> commandQueue;
  ComPtr<IDXGISwapChain3> swapChain;
  ComPtr<ID3D12DescriptorHeap> rtvHeap;
  ComPtr<ID3D12Resource> renderTargets[kFrameCount];
  ComPtr<ID3D12CommandAllocator> commandAllocator;
  ComPtr<ID3D12GraphicsCommandList> commandList;
  ComPtr<ID3D12Fence> fence;
  HANDLE fenceEvent = nullptr;
  UINT rtvDescriptorSize = 0;
  UINT frameIndex = 0;
  UINT64 fenceValue = 0;
};

void throwIfFailed(HRESULT result, const char* operation) {
  if (SUCCEEDED(result)) {
    return;
  }

  char message[128];
  std::snprintf(
      message,
      sizeof(message),
      "%s failed with HRESULT 0x%08lx",
      operation,
      static_cast<unsigned long>(result));
  throw std::runtime_error(message);
}

void throwLastError(const char* operation) {
  const DWORD error = GetLastError();
  char message[128];
  std::snprintf(
      message,
      sizeof(message),
      "%s failed with GetLastError %lu",
      operation,
      static_cast<unsigned long>(error));
  throw std::runtime_error(message);
}

void throwWindowsError(const char* operation, DWORD error) {
  char message[128];
  std::snprintf(
      message,
      sizeof(message),
      "%s failed with GetLastError %lu",
      operation,
      static_cast<unsigned long>(error));
  throw std::runtime_error(message);
}

void writeSuccessSentinel() {
  HANDLE file = CreateFileA(
      kSuccessSentinelPath,
      GENERIC_WRITE,
      0,
      nullptr,
      CREATE_ALWAYS,
      FILE_ATTRIBUTE_NORMAL,
      nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    throwLastError("CreateFileA(success sentinel)");
  }

  DWORD bytesWritten = 0;
  constexpr DWORD markerSize = static_cast<DWORD>(sizeof(kSuccessMarker) - 1);
  const BOOL writeOk = WriteFile(
      file,
      kSuccessMarker,
      markerSize,
      &bytesWritten,
      nullptr);
  const DWORD writeError = GetLastError();
  CloseHandle(file);
  if (!writeOk || bytesWritten != markerSize) {
    throwWindowsError("WriteFile(success sentinel)", writeError);
  }
}

LRESULT CALLBACK windowProc(
    HWND window,
    UINT message,
    WPARAM wparam,
    LPARAM lparam) {
  (void)wparam;
  (void)lparam;

  switch (message) {
    case WM_CLOSE:
      DestroyWindow(window);
      return 0;
    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;
    default:
      return DefWindowProcW(window, message, wparam, lparam);
  }
}

HWND createSampleWindow(HINSTANCE instance) {
  WNDCLASSEXW windowClass = {};
  windowClass.cbSize = sizeof(windowClass);
  windowClass.lpfnWndProc = windowProc;
  windowClass.hInstance = instance;
  windowClass.hCursor = LoadCursorW(nullptr, IDC_ARROW);
  windowClass.lpszClassName = kWindowClassName;

  if (RegisterClassExW(&windowClass) == 0) {
    throw std::runtime_error("RegisterClassExW failed");
  }

  RECT windowRect = {0, 0, static_cast<LONG>(kWidth), static_cast<LONG>(kHeight)};
  if (!AdjustWindowRect(&windowRect, WS_OVERLAPPEDWINDOW, FALSE)) {
    throw std::runtime_error("AdjustWindowRect failed");
  }

  HWND window = CreateWindowExW(
      0,
      kWindowClassName,
      L"Konyak D3D12 Minimal Sample",
      WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT,
      CW_USEDEFAULT,
      static_cast<int>(windowRect.right - windowRect.left),
      static_cast<int>(windowRect.bottom - windowRect.top),
      nullptr,
      nullptr,
      instance,
      nullptr);
  if (window == nullptr) {
    throw std::runtime_error("CreateWindowExW failed");
  }

  ShowWindow(window, SW_SHOWNORMAL);
  UpdateWindow(window);
  return window;
}

D3D12_RESOURCE_BARRIER transitionBarrier(
    ID3D12Resource* resource,
    D3D12_RESOURCE_STATES before,
    D3D12_RESOURCE_STATES after) {
  D3D12_RESOURCE_BARRIER barrier = {};
  barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
  barrier.Transition.pResource = resource;
  barrier.Transition.StateBefore = before;
  barrier.Transition.StateAfter = after;
  barrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
  return barrier;
}

void waitForGpu(DxState& state) {
  const UINT64 fenceToWaitFor = ++state.fenceValue;
  throwIfFailed(
      state.commandQueue->Signal(state.fence.Get(), fenceToWaitFor),
      "ID3D12CommandQueue::Signal");

  if (state.fence->GetCompletedValue() < fenceToWaitFor) {
    throwIfFailed(
        state.fence->SetEventOnCompletion(fenceToWaitFor, state.fenceEvent),
        "ID3D12Fence::SetEventOnCompletion");
    WaitForSingleObject(state.fenceEvent, INFINITE);
  }

  state.frameIndex = state.swapChain->GetCurrentBackBufferIndex();
}

void pumpMessages() {
  MSG message = {};
  while (PeekMessageW(&message, nullptr, 0, 0, PM_REMOVE)) {
    TranslateMessage(&message);
    DispatchMessageW(&message);
  }
}

void initD3D12(HWND window, DxState& state) {
  throwIfFailed(
      CreateDXGIFactory2(0, IID_PPV_ARGS(&state.factory)),
      "CreateDXGIFactory2");

  throwIfFailed(
      D3D12CreateDevice(
          nullptr,
          D3D_FEATURE_LEVEL_11_0,
          IID_PPV_ARGS(&state.device)),
      "D3D12CreateDevice");

  D3D12_COMMAND_QUEUE_DESC queueDesc = {};
  queueDesc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
  throwIfFailed(
      state.device->CreateCommandQueue(
          &queueDesc,
          IID_PPV_ARGS(&state.commandQueue)),
      "ID3D12Device::CreateCommandQueue");

  DXGI_SWAP_CHAIN_DESC1 swapChainDesc = {};
  swapChainDesc.BufferCount = kFrameCount;
  swapChainDesc.Width = kWidth;
  swapChainDesc.Height = kHeight;
  swapChainDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
  swapChainDesc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
  swapChainDesc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
  swapChainDesc.SampleDesc.Count = 1;

  ComPtr<IDXGISwapChain1> swapChain;
  throwIfFailed(
      state.factory->CreateSwapChainForHwnd(
          state.commandQueue.Get(),
          window,
          &swapChainDesc,
          nullptr,
          nullptr,
          &swapChain),
      "IDXGIFactory4::CreateSwapChainForHwnd");
  throwIfFailed(swapChain.As(&state.swapChain), "IDXGISwapChain1::As");
  state.frameIndex = state.swapChain->GetCurrentBackBufferIndex();

  D3D12_DESCRIPTOR_HEAP_DESC rtvHeapDesc = {};
  rtvHeapDesc.NumDescriptors = kFrameCount;
  rtvHeapDesc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_RTV;
  throwIfFailed(
      state.device->CreateDescriptorHeap(
          &rtvHeapDesc,
          IID_PPV_ARGS(&state.rtvHeap)),
      "ID3D12Device::CreateDescriptorHeap");
  state.rtvDescriptorSize = state.device->GetDescriptorHandleIncrementSize(
      D3D12_DESCRIPTOR_HEAP_TYPE_RTV);

  D3D12_CPU_DESCRIPTOR_HANDLE rtvHandle =
      state.rtvHeap->GetCPUDescriptorHandleForHeapStart();
  for (UINT index = 0; index < kFrameCount; ++index) {
    throwIfFailed(
        state.swapChain->GetBuffer(
            index,
            IID_PPV_ARGS(&state.renderTargets[index])),
        "IDXGISwapChain3::GetBuffer");
    state.device->CreateRenderTargetView(
        state.renderTargets[index].Get(),
        nullptr,
        rtvHandle);
    rtvHandle.ptr += state.rtvDescriptorSize;
  }

  throwIfFailed(
      state.device->CreateCommandAllocator(
          D3D12_COMMAND_LIST_TYPE_DIRECT,
          IID_PPV_ARGS(&state.commandAllocator)),
      "ID3D12Device::CreateCommandAllocator");

  throwIfFailed(
      state.device->CreateCommandList(
          0,
          D3D12_COMMAND_LIST_TYPE_DIRECT,
          state.commandAllocator.Get(),
          nullptr,
          IID_PPV_ARGS(&state.commandList)),
      "ID3D12Device::CreateCommandList");
  throwIfFailed(
      state.commandList->Close(),
      "ID3D12GraphicsCommandList::Close");

  throwIfFailed(
      state.device->CreateFence(
          0,
          D3D12_FENCE_FLAG_NONE,
          IID_PPV_ARGS(&state.fence)),
      "ID3D12Device::CreateFence");
  state.fenceEvent = CreateEventW(nullptr, FALSE, FALSE, nullptr);
  if (state.fenceEvent == nullptr) {
    throw std::runtime_error("CreateEventW failed");
  }
}

void drawFrame(DxState& state, UINT frameNumber) {
  throwIfFailed(
      state.commandAllocator->Reset(),
      "ID3D12CommandAllocator::Reset");
  throwIfFailed(
      state.commandList->Reset(state.commandAllocator.Get(), nullptr),
      "ID3D12GraphicsCommandList::Reset");

  ID3D12Resource* renderTarget = state.renderTargets[state.frameIndex].Get();
  D3D12_RESOURCE_BARRIER barrier = transitionBarrier(
      renderTarget,
      D3D12_RESOURCE_STATE_PRESENT,
      D3D12_RESOURCE_STATE_RENDER_TARGET);
  state.commandList->ResourceBarrier(1, &barrier);

  D3D12_CPU_DESCRIPTOR_HANDLE rtvHandle =
      state.rtvHeap->GetCPUDescriptorHandleForHeapStart();
  rtvHandle.ptr += state.frameIndex * state.rtvDescriptorSize;

  const float clearColor[] = {
      0.05f + 0.12f * static_cast<float>(frameNumber % 3),
      0.18f,
      0.34f,
      1.0f,
  };
  state.commandList->ClearRenderTargetView(rtvHandle, clearColor, 0, nullptr);

  barrier = transitionBarrier(
      renderTarget,
      D3D12_RESOURCE_STATE_RENDER_TARGET,
      D3D12_RESOURCE_STATE_PRESENT);
  state.commandList->ResourceBarrier(1, &barrier);
  throwIfFailed(
      state.commandList->Close(),
      "ID3D12GraphicsCommandList::Close");

  ID3D12CommandList* commandLists[] = {state.commandList.Get()};
  state.commandQueue->ExecuteCommandLists(1, commandLists);
  throwIfFailed(state.swapChain->Present(1, 0), "IDXGISwapChain3::Present");
  waitForGpu(state);
}

int parseFrameCount(int argc, wchar_t** argv) {
  constexpr int defaultFrames = 4;
  for (int index = 1; index + 1 < argc; ++index) {
    if (std::wstring(argv[index]) == L"--frames") {
      const int frames = _wtoi(argv[index + 1]);
      return frames > 0 ? frames : defaultFrames;
    }
  }
  return defaultFrames;
}

}  // namespace

int wmain(int argc, wchar_t** argv) {
  DxState state;
  HWND window = nullptr;

  try {
    const int frames = parseFrameCount(argc, argv);
    HINSTANCE instance = GetModuleHandleW(nullptr);
    window = createSampleWindow(instance);
    initD3D12(window, state);

    for (int frame = 0; frame < frames; ++frame) {
      pumpMessages();
      drawFrame(state, static_cast<UINT>(frame));
    }

    waitForGpu(state);
    writeSuccessSentinel();
    std::printf("KONYAK_D3D12_MINIMAL_SAMPLE_OK frames=%d\n", frames);
    CloseHandle(state.fenceEvent);
    DestroyWindow(window);
    return 0;
  } catch (const std::exception& error) {
    std::fprintf(stderr, "KONYAK_D3D12_MINIMAL_SAMPLE_FAILED %s\n", error.what());
    if (state.fenceEvent != nullptr) {
      CloseHandle(state.fenceEvent);
    }
    if (window != nullptr) {
      DestroyWindow(window);
    }
    return 1;
  }
}
