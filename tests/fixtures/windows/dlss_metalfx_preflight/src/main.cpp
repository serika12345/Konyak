#include <d3d12.h>
#include <dxgi1_6.h>
#include <windows.h>
#include <wrl/client.h>

#include <cwchar>
#include <cstdio>
#include <exception>
#include <stdexcept>
#include <string>

using Microsoft::WRL::ComPtr;

namespace {

constexpr UINT kFrameCount = 2;
constexpr UINT kWidth = 640;
constexpr UINT kHeight = 360;
constexpr char kSuccessMarker[] = "KONYAK_DLSS_METALFX_PREFLIGHT_OK\n";
constexpr wchar_t kDefaultSuccessSentinelPath[] =
    L"C:\\konyak-dlss-metalfx-preflight-ok.txt";
constexpr wchar_t kDefaultEvidencePath[] =
    L"C:\\konyak-dlss-metalfx-preflight-evidence.txt";
constexpr wchar_t kWindowClassName[] =
    L"KonyakDlssMetalFxPreflightWindow";

struct Options {
  int frames = 4;
  bool requireMetalFxEnvironment = false;
  bool requireNvidiaShims = false;
  std::wstring sentinelPath = kDefaultSuccessSentinelPath;
  std::wstring evidencePath = kDefaultEvidencePath;
};

struct ModuleProbe {
  HMODULE handle = nullptr;
  bool loaded = false;
  DWORD errorCode = 0;
  std::wstring path;
};

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

  char message[160];
  std::snprintf(
      message,
      sizeof(message),
      "%s failed with HRESULT 0x%08lx",
      operation,
      static_cast<unsigned long>(result));
  throw std::runtime_error(message);
}

void throwWindowsError(const char* operation, DWORD error) {
  char message[160];
  std::snprintf(
      message,
      sizeof(message),
      "%s failed with GetLastError %lu",
      operation,
      static_cast<unsigned long>(error));
  throw std::runtime_error(message);
}

std::string utf8FromWide(const std::wstring& text) {
  if (text.empty()) {
    return "";
  }

  const int size = WideCharToMultiByte(
      CP_UTF8,
      0,
      text.c_str(),
      static_cast<int>(text.size()),
      nullptr,
      0,
      nullptr,
      nullptr);
  if (size <= 0) {
    return "";
  }

  std::string output(static_cast<size_t>(size), '\0');
  WideCharToMultiByte(
      CP_UTF8,
      0,
      text.c_str(),
      static_cast<int>(text.size()),
      output.data(),
      size,
      nullptr,
      nullptr);
  return output;
}

std::wstring environmentValue(const wchar_t* name) {
  const DWORD required = GetEnvironmentVariableW(name, nullptr, 0);
  if (required == 0) {
    return L"";
  }

  std::wstring value(required, L'\0');
  const DWORD written = GetEnvironmentVariableW(name, value.data(), required);
  if (written == 0 || written >= required) {
    return L"";
  }

  value.resize(written);
  return value;
}

void writeTextFile(const std::wstring& path, const std::string& content) {
  HANDLE file = CreateFileW(
      path.c_str(),
      GENERIC_WRITE,
      0,
      nullptr,
      CREATE_ALWAYS,
      FILE_ATTRIBUTE_NORMAL,
      nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    throwWindowsError("CreateFileW", GetLastError());
  }

  DWORD bytesWritten = 0;
  const DWORD contentSize = static_cast<DWORD>(content.size());
  const BOOL writeOk =
      WriteFile(file, content.data(), contentSize, &bytesWritten, nullptr);
  const DWORD writeError = GetLastError();
  CloseHandle(file);

  if (!writeOk || bytesWritten != contentSize) {
    throwWindowsError("WriteFile", writeError);
  }
}

ModuleProbe probeModule(const wchar_t* name) {
  ModuleProbe probe;

  if (std::wcscmp(name, L"nvngx.dll") == 0) {
    probe.handle = LoadLibraryW(L"nvngx.dll");
  } else if (std::wcscmp(name, L"nvapi64.dll") == 0) {
    probe.handle = LoadLibraryW(L"nvapi64.dll");
  } else {
    probe.handle = LoadLibraryW(name);
  }

  probe.loaded = probe.handle != nullptr;
  if (!probe.loaded) {
    probe.errorCode = GetLastError();
    return probe;
  }

  wchar_t modulePath[MAX_PATH] = {};
  const DWORD pathSize = GetModuleFileNameW(
      probe.handle,
      modulePath,
      static_cast<DWORD>(MAX_PATH));
  if (pathSize > 0 && pathSize < static_cast<DWORD>(MAX_PATH)) {
    probe.path = modulePath;
  }

  return probe;
}

void closeModule(ModuleProbe& probe) {
  if (probe.handle != nullptr) {
    FreeLibrary(probe.handle);
    probe.handle = nullptr;
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
      L"Konyak DLSS MetalFX Preflight",
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
      0.10f,
      0.16f + 0.08f * static_cast<float>(frameNumber % 4),
      0.26f,
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

Options parseOptions(int argc, wchar_t** argv) {
  Options options;

  for (int index = 1; index < argc; ++index) {
    const std::wstring argument(argv[index]);
    if (argument == L"--frames" && index + 1 < argc) {
      const int frames = _wtoi(argv[++index]);
      options.frames = frames > 0 ? frames : options.frames;
    } else if (argument == L"--sentinel" && index + 1 < argc) {
      options.sentinelPath = argv[++index];
    } else if (argument == L"--evidence" && index + 1 < argc) {
      options.evidencePath = argv[++index];
    } else if (argument == L"--require-metalfx-env") {
      options.requireMetalFxEnvironment = true;
    } else if (argument == L"--require-nv-shims") {
      options.requireNvidiaShims = true;
    }
  }

  return options;
}

std::string evidenceText(
    const Options& options,
    const ModuleProbe& nvngx,
    const ModuleProbe& nvapi64,
    const std::wstring& metalFx,
    const std::wstring& dxr,
    const std::wstring& gptkPath,
    const std::string& marker,
    const std::string& error,
    bool d3d12Presented) {
  std::string text;
  text += "marker=" + marker + "\n";
  if (!error.empty()) {
    text += "error=" + error + "\n";
  }
  text += "frames=" + std::to_string(options.frames) + "\n";
  text += std::string("d3d12_presented=") +
      (d3d12Presented ? "true" : "false") + "\n";
  text += "D3DM_ENABLE_METALFX=" + utf8FromWide(metalFx) + "\n";
  text += "D3DM_SUPPORT_DXR=" + utf8FromWide(dxr) + "\n";
  text += "CX_APPLEGPTK_LIBD3DSHARED_PATH=" + utf8FromWide(gptkPath) + "\n";
  text += std::string("nvngx_loaded=") + (nvngx.loaded ? "true" : "false") +
      "\n";
  text += "nvngx_error=" + std::to_string(nvngx.errorCode) + "\n";
  text += "nvngx_path=" + utf8FromWide(nvngx.path) + "\n";
  text += std::string("nvapi64_loaded=") +
      (nvapi64.loaded ? "true" : "false") + "\n";
  text += "nvapi64_error=" + std::to_string(nvapi64.errorCode) + "\n";
  text += "nvapi64_path=" + utf8FromWide(nvapi64.path) + "\n";
  return text;
}

}  // namespace

int wmain(int argc, wchar_t** argv) {
  Options options;
  DxState state;
  HWND window = nullptr;
  ModuleProbe nvngx;
  ModuleProbe nvapi64;
  std::wstring metalFx;
  std::wstring dxr;
  std::wstring gptkPath;
  bool d3d12Presented = false;

  try {
    options = parseOptions(argc, argv);
    metalFx = environmentValue(L"D3DM_ENABLE_METALFX");
    dxr = environmentValue(L"D3DM_SUPPORT_DXR");
    gptkPath = environmentValue(L"CX_APPLEGPTK_LIBD3DSHARED_PATH");

    nvngx = probeModule(L"nvngx.dll");
    nvapi64 = probeModule(L"nvapi64.dll");

    if (options.requireMetalFxEnvironment && metalFx != L"1") {
      throw std::runtime_error("D3DM_ENABLE_METALFX was not set to 1");
    }
    if (options.requireNvidiaShims && (!nvngx.loaded || !nvapi64.loaded)) {
      throw std::runtime_error("NVIDIA NGX shim DLLs were not both loadable");
    }

    HINSTANCE instance = GetModuleHandleW(nullptr);
    window = createSampleWindow(instance);
    initD3D12(window, state);

    for (int frame = 0; frame < options.frames; ++frame) {
      pumpMessages();
      drawFrame(state, static_cast<UINT>(frame));
    }
    d3d12Presented = true;

    waitForGpu(state);
    writeTextFile(
        options.evidencePath,
        evidenceText(
            options,
            nvngx,
            nvapi64,
            metalFx,
            dxr,
            gptkPath,
            "KONYAK_DLSS_METALFX_PREFLIGHT_OK",
            "",
            d3d12Presented));
    writeTextFile(options.sentinelPath, kSuccessMarker);
    std::printf(
        "KONYAK_DLSS_METALFX_PREFLIGHT_OK frames=%d nvngx=%d nvapi64=%d\n",
        options.frames,
        nvngx.loaded ? 1 : 0,
        nvapi64.loaded ? 1 : 0);

    closeModule(nvngx);
    closeModule(nvapi64);
    CloseHandle(state.fenceEvent);
    DestroyWindow(window);
    return 0;
  } catch (const std::exception& error) {
    std::fprintf(
        stderr,
        "KONYAK_DLSS_METALFX_PREFLIGHT_FAILED %s\n",
        error.what());
    try {
      writeTextFile(
          options.evidencePath,
          evidenceText(
              options,
              nvngx,
              nvapi64,
              metalFx,
              dxr,
              gptkPath,
              "KONYAK_DLSS_METALFX_PREFLIGHT_FAILED",
              error.what(),
              d3d12Presented));
    } catch (...) {
    }
    closeModule(nvngx);
    closeModule(nvapi64);
    if (state.fenceEvent != nullptr) {
      CloseHandle(state.fenceEvent);
    }
    if (window != nullptr) {
      DestroyWindow(window);
    }
    return 1;
  }
}
