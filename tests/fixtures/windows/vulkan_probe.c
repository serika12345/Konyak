#define WIN32_LEAN_AND_MEAN
#define VK_NO_PROTOTYPES
#define VK_USE_PLATFORM_WIN32_KHR
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>
#include <vulkan/vulkan.h>

#include "vulkan_triangle_spv.h"

#define ARRAY_SIZE(value) (sizeof(value) / sizeof((value)[0]))

static const uint32_t kWindowWidth = 800;
static const uint32_t kWindowHeight = 480;
static const char *g_window_text = "KONYAK Vulkan triangle";

static PFN_vkGetInstanceProcAddr pfn_vkGetInstanceProcAddr;
static PFN_vkGetDeviceProcAddr pfn_vkGetDeviceProcAddr;
static PFN_vkCreateInstance pfn_vkCreateInstance;
static PFN_vkEnumerateInstanceExtensionProperties
    pfn_vkEnumerateInstanceExtensionProperties;
static PFN_vkDestroyInstance pfn_vkDestroyInstance;
static PFN_vkCreateWin32SurfaceKHR pfn_vkCreateWin32SurfaceKHR;
static PFN_vkDestroySurfaceKHR pfn_vkDestroySurfaceKHR;
static PFN_vkEnumeratePhysicalDevices pfn_vkEnumeratePhysicalDevices;
static PFN_vkGetPhysicalDeviceQueueFamilyProperties
    pfn_vkGetPhysicalDeviceQueueFamilyProperties;
static PFN_vkGetPhysicalDeviceSurfaceSupportKHR
    pfn_vkGetPhysicalDeviceSurfaceSupportKHR;
static PFN_vkGetPhysicalDeviceSurfaceCapabilitiesKHR
    pfn_vkGetPhysicalDeviceSurfaceCapabilitiesKHR;
static PFN_vkGetPhysicalDeviceSurfaceFormatsKHR
    pfn_vkGetPhysicalDeviceSurfaceFormatsKHR;
static PFN_vkGetPhysicalDeviceSurfacePresentModesKHR
    pfn_vkGetPhysicalDeviceSurfacePresentModesKHR;
static PFN_vkEnumerateDeviceExtensionProperties
    pfn_vkEnumerateDeviceExtensionProperties;
static PFN_vkCreateDevice pfn_vkCreateDevice;
static PFN_vkDestroyDevice pfn_vkDestroyDevice;
static PFN_vkGetDeviceQueue pfn_vkGetDeviceQueue;
static PFN_vkCreateSwapchainKHR pfn_vkCreateSwapchainKHR;
static PFN_vkDestroySwapchainKHR pfn_vkDestroySwapchainKHR;
static PFN_vkGetSwapchainImagesKHR pfn_vkGetSwapchainImagesKHR;
static PFN_vkAcquireNextImageKHR pfn_vkAcquireNextImageKHR;
static PFN_vkQueuePresentKHR pfn_vkQueuePresentKHR;
static PFN_vkCreateImageView pfn_vkCreateImageView;
static PFN_vkDestroyImageView pfn_vkDestroyImageView;
static PFN_vkCreateRenderPass pfn_vkCreateRenderPass;
static PFN_vkDestroyRenderPass pfn_vkDestroyRenderPass;
static PFN_vkCreateShaderModule pfn_vkCreateShaderModule;
static PFN_vkDestroyShaderModule pfn_vkDestroyShaderModule;
static PFN_vkCreatePipelineLayout pfn_vkCreatePipelineLayout;
static PFN_vkDestroyPipelineLayout pfn_vkDestroyPipelineLayout;
static PFN_vkCreateGraphicsPipelines pfn_vkCreateGraphicsPipelines;
static PFN_vkDestroyPipeline pfn_vkDestroyPipeline;
static PFN_vkCreateFramebuffer pfn_vkCreateFramebuffer;
static PFN_vkDestroyFramebuffer pfn_vkDestroyFramebuffer;
static PFN_vkCreateCommandPool pfn_vkCreateCommandPool;
static PFN_vkDestroyCommandPool pfn_vkDestroyCommandPool;
static PFN_vkAllocateCommandBuffers pfn_vkAllocateCommandBuffers;
static PFN_vkBeginCommandBuffer pfn_vkBeginCommandBuffer;
static PFN_vkEndCommandBuffer pfn_vkEndCommandBuffer;
static PFN_vkCmdBeginRenderPass pfn_vkCmdBeginRenderPass;
static PFN_vkCmdEndRenderPass pfn_vkCmdEndRenderPass;
static PFN_vkCmdBindPipeline pfn_vkCmdBindPipeline;
static PFN_vkCmdDraw pfn_vkCmdDraw;
static PFN_vkCreateFence pfn_vkCreateFence;
static PFN_vkDestroyFence pfn_vkDestroyFence;
static PFN_vkWaitForFences pfn_vkWaitForFences;
static PFN_vkResetFences pfn_vkResetFences;
static PFN_vkQueueSubmit pfn_vkQueueSubmit;
static PFN_vkQueueWaitIdle pfn_vkQueueWaitIdle;
static PFN_vkDeviceWaitIdle pfn_vkDeviceWaitIdle;

typedef struct VulkanApp {
  HMODULE vulkan_library;
  VkInstance instance;
  VkSurfaceKHR surface;
  VkPhysicalDevice physical_device;
  VkDevice device;
  VkQueue queue;
  uint32_t queue_family;
  VkSwapchainKHR swapchain;
  VkFormat swapchain_format;
  VkExtent2D extent;
  uint32_t image_count;
  VkImage images[8];
  VkImageView image_views[8];
  VkFramebuffer framebuffers[8];
  VkRenderPass render_pass;
  VkPipelineLayout pipeline_layout;
  VkPipeline pipeline;
  VkCommandPool command_pool;
  VkCommandBuffer command_buffers[8];
  VkFence image_acquired;
  VkFence in_flight;
} VulkanApp;

static void print_vk_error(const char *operation, VkResult result) {
  fprintf(stderr, "%s failed with VkResult %ld\n", operation, (long)result);
}

static int probe_hold_ms(void) {
  const char *value = getenv("KONYAK_VULKAN_PROBE_HOLD_MS");
  if (value == NULL || value[0] == '\0') {
    return 12000;
  }
  int parsed = atoi(value);
  if (parsed < 1000) {
    return 1000;
  }
  if (parsed > 60000) {
    return 60000;
  }
  return parsed;
}

static LRESULT CALLBACK probe_window_proc(HWND hwnd, UINT message,
                                          WPARAM wparam, LPARAM lparam) {
  switch (message) {
  case WM_PAINT: {
    PAINTSTRUCT paint;
    HDC dc = BeginPaint(hwnd, &paint);
    RECT rect;
    GetClientRect(hwnd, &rect);
    HBRUSH background = CreateSolidBrush(RGB(18, 24, 32));
    FillRect(dc, &rect, background);
    DeleteObject(background);
    SetBkMode(dc, TRANSPARENT);
    SetTextColor(dc, RGB(230, 238, 246));
    DrawTextA(dc, g_window_text, -1, &rect, DT_CENTER | DT_TOP);
    EndPaint(hwnd, &paint);
    return 0;
  }
  case WM_CLOSE:
    DestroyWindow(hwnd);
    return 0;
  case WM_DESTROY:
    PostQuitMessage(0);
    return 0;
  default:
    return DefWindowProcA(hwnd, message, wparam, lparam);
  }
}

static HWND create_probe_window(void) {
  HINSTANCE instance = GetModuleHandleA(NULL);
  const char class_name[] = "KonyakVulkanTriangleWindow";
  WNDCLASSA window_class;
  ZeroMemory(&window_class, sizeof(window_class));
  window_class.lpfnWndProc = probe_window_proc;
  window_class.hInstance = instance;
  window_class.lpszClassName = class_name;
  window_class.hCursor = LoadCursorA(NULL, IDC_ARROW);

  if (RegisterClassA(&window_class) == 0 &&
      GetLastError() != ERROR_CLASS_ALREADY_EXISTS) {
    fprintf(stderr, "RegisterClassA failed: %lu\n", GetLastError());
    return NULL;
  }

  HWND hwnd =
      CreateWindowExA(WS_EX_TOPMOST, class_name, "Konyak Vulkan Triangle",
                      WS_OVERLAPPEDWINDOW | WS_VISIBLE, CW_USEDEFAULT,
                      CW_USEDEFAULT, (int)kWindowWidth, (int)kWindowHeight,
                      NULL, NULL, instance, NULL);
  if (hwnd == NULL) {
    fprintf(stderr, "CreateWindowExA failed: %lu\n", GetLastError());
    return NULL;
  }
  ShowWindow(hwnd, SW_SHOWNORMAL);
  SetForegroundWindow(hwnd);
  BringWindowToTop(hwnd);
  UpdateWindow(hwnd);
  return hwnd;
}

static PFN_vkVoidFunction load_instance_proc(VkInstance instance,
                                             const char *name) {
  return pfn_vkGetInstanceProcAddr(instance, name);
}

static PFN_vkVoidFunction load_device_proc(VkDevice device, const char *name) {
  return pfn_vkGetDeviceProcAddr(device, name);
}

static int instance_extension_available(const char *name) {
  uint32_t count = 0;
  if (pfn_vkEnumerateInstanceExtensionProperties(NULL, &count, NULL) !=
      VK_SUCCESS) {
    return 0;
  }
  VkExtensionProperties properties[256];
  if (count > ARRAY_SIZE(properties)) {
    count = ARRAY_SIZE(properties);
  }
  if (pfn_vkEnumerateInstanceExtensionProperties(NULL, &count, properties) !=
      VK_SUCCESS) {
    return 0;
  }
  for (uint32_t index = 0; index < count; ++index) {
    if (strcmp(name, properties[index].extensionName) == 0) {
      return 1;
    }
  }
  return 0;
}

static int device_extension_available(VkPhysicalDevice physical_device,
                                      const char *name) {
  uint32_t count = 0;
  if (pfn_vkEnumerateDeviceExtensionProperties(physical_device, NULL, &count,
                                               NULL) != VK_SUCCESS) {
    return 0;
  }
  VkExtensionProperties properties[256];
  if (count > ARRAY_SIZE(properties)) {
    count = ARRAY_SIZE(properties);
  }
  if (pfn_vkEnumerateDeviceExtensionProperties(physical_device, NULL, &count,
                                               properties) != VK_SUCCESS) {
    return 0;
  }
  for (uint32_t index = 0; index < count; ++index) {
    if (strcmp(name, properties[index].extensionName) == 0) {
      return 1;
    }
  }
  return 0;
}

static int load_vulkan_library(VulkanApp *app) {
  app->vulkan_library = LoadLibraryA("vulkan-1.dll");
  if (app->vulkan_library == NULL) {
    fprintf(stderr, "LoadLibraryA(vulkan-1.dll) failed: %lu\n", GetLastError());
    return 2;
  }

  union {
    FARPROC source;
    PFN_vkGetInstanceProcAddr target;
  } get_instance_proc_addr = {
      GetProcAddress(app->vulkan_library, "vkGetInstanceProcAddr"),
  };
  pfn_vkGetInstanceProcAddr = get_instance_proc_addr.target;
  if (pfn_vkGetInstanceProcAddr == NULL) {
    fprintf(stderr, "vkGetInstanceProcAddr was not exported.\n");
    return 3;
  }

  pfn_vkCreateInstance =
      (PFN_vkCreateInstance)load_instance_proc(NULL, "vkCreateInstance");
  pfn_vkEnumerateInstanceExtensionProperties =
      (PFN_vkEnumerateInstanceExtensionProperties)load_instance_proc(
          NULL, "vkEnumerateInstanceExtensionProperties");
  if (pfn_vkCreateInstance == NULL ||
      pfn_vkEnumerateInstanceExtensionProperties == NULL) {
    fprintf(stderr, "Failed to resolve global Vulkan functions.\n");
    return 4;
  }
  return 0;
}

static int create_instance(VulkanApp *app) {
  const char *extensions[3] = {
      VK_KHR_SURFACE_EXTENSION_NAME,
      VK_KHR_WIN32_SURFACE_EXTENSION_NAME,
  };
  uint32_t extension_count = 2;
  VkInstanceCreateFlags flags = 0;
  if (instance_extension_available(VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME)) {
    extensions[extension_count++] = VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME;
    flags |= VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR;
  }

  const VkApplicationInfo app_info = {
      .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
      .pApplicationName = "Konyak Vulkan Triangle",
      .applicationVersion = VK_MAKE_VERSION(1, 0, 0),
      .pEngineName = "Konyak",
      .engineVersion = VK_MAKE_VERSION(1, 0, 0),
      .apiVersion = VK_API_VERSION_1_0,
  };
  const VkInstanceCreateInfo instance_info = {
      .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
      .flags = flags,
      .pApplicationInfo = &app_info,
      .enabledExtensionCount = extension_count,
      .ppEnabledExtensionNames = extensions,
  };

  VkResult result = pfn_vkCreateInstance(&instance_info, NULL, &app->instance);
  if (result != VK_SUCCESS) {
    print_vk_error("vkCreateInstance", result);
    return 5;
  }

#define LOAD_INSTANCE(name)                                                    \
  pfn_##name = (PFN_##name)load_instance_proc(app->instance, #name)
  LOAD_INSTANCE(vkDestroyInstance);
  LOAD_INSTANCE(vkCreateWin32SurfaceKHR);
  LOAD_INSTANCE(vkDestroySurfaceKHR);
  LOAD_INSTANCE(vkEnumeratePhysicalDevices);
  LOAD_INSTANCE(vkGetPhysicalDeviceQueueFamilyProperties);
  LOAD_INSTANCE(vkGetPhysicalDeviceSurfaceSupportKHR);
  LOAD_INSTANCE(vkGetPhysicalDeviceSurfaceCapabilitiesKHR);
  LOAD_INSTANCE(vkGetPhysicalDeviceSurfaceFormatsKHR);
  LOAD_INSTANCE(vkGetPhysicalDeviceSurfacePresentModesKHR);
  LOAD_INSTANCE(vkEnumerateDeviceExtensionProperties);
  LOAD_INSTANCE(vkCreateDevice);
#undef LOAD_INSTANCE

  if (pfn_vkDestroyInstance == NULL || pfn_vkCreateWin32SurfaceKHR == NULL ||
      pfn_vkEnumeratePhysicalDevices == NULL || pfn_vkCreateDevice == NULL) {
    fprintf(stderr, "Failed to resolve instance Vulkan functions.\n");
    return 6;
  }
  return 0;
}

static int create_surface(VulkanApp *app, HWND hwnd) {
  VkWin32SurfaceCreateInfoKHR surface_info = {
      .sType = VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR,
      .hinstance = GetModuleHandleA(NULL),
      .hwnd = hwnd,
  };
  VkResult result =
      pfn_vkCreateWin32SurfaceKHR(app->instance, &surface_info, NULL,
                                  &app->surface);
  if (result != VK_SUCCESS) {
    print_vk_error("vkCreateWin32SurfaceKHR", result);
    return 7;
  }
  return 0;
}

static int select_physical_device(VulkanApp *app) {
  uint32_t physical_device_count = 0;
  VkResult result = pfn_vkEnumeratePhysicalDevices(app->instance,
                                                   &physical_device_count, NULL);
  if (result != VK_SUCCESS || physical_device_count == 0) {
    print_vk_error("vkEnumeratePhysicalDevices", result);
    return 8;
  }

  VkPhysicalDevice physical_devices[16];
  if (physical_device_count > ARRAY_SIZE(physical_devices)) {
    physical_device_count = ARRAY_SIZE(physical_devices);
  }
  result = pfn_vkEnumeratePhysicalDevices(app->instance, &physical_device_count,
                                          physical_devices);
  if (result != VK_SUCCESS) {
    print_vk_error("vkEnumeratePhysicalDevices(list)", result);
    return 9;
  }

  for (uint32_t device_index = 0; device_index < physical_device_count;
       ++device_index) {
    uint32_t queue_family_count = 0;
    pfn_vkGetPhysicalDeviceQueueFamilyProperties(
        physical_devices[device_index], &queue_family_count, NULL);
    VkQueueFamilyProperties queue_families[64];
    if (queue_family_count > ARRAY_SIZE(queue_families)) {
      queue_family_count = ARRAY_SIZE(queue_families);
    }
    pfn_vkGetPhysicalDeviceQueueFamilyProperties(
        physical_devices[device_index], &queue_family_count, queue_families);

    for (uint32_t queue_index = 0; queue_index < queue_family_count;
         ++queue_index) {
      VkBool32 present_supported = VK_FALSE;
      pfn_vkGetPhysicalDeviceSurfaceSupportKHR(
          physical_devices[device_index], queue_index, app->surface,
          &present_supported);
      if ((queue_families[queue_index].queueFlags & VK_QUEUE_GRAPHICS_BIT) !=
              0 &&
          present_supported == VK_TRUE &&
          device_extension_available(physical_devices[device_index],
                                     VK_KHR_SWAPCHAIN_EXTENSION_NAME)) {
        app->physical_device = physical_devices[device_index];
        app->queue_family = queue_index;
        return 0;
      }
    }
  }

  fprintf(stderr, "No Vulkan device supports graphics, present, and swapchain.\n");
  return 10;
}

static int create_device(VulkanApp *app) {
  float priority = 1.0f;
  const VkDeviceQueueCreateInfo queue_info = {
      .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
      .queueFamilyIndex = app->queue_family,
      .queueCount = 1,
      .pQueuePriorities = &priority,
  };

  const char *extensions[2] = {VK_KHR_SWAPCHAIN_EXTENSION_NAME};
  uint32_t extension_count = 1;
  if (device_extension_available(app->physical_device,
                                 "VK_KHR_portability_subset")) {
    extensions[extension_count++] = "VK_KHR_portability_subset";
  }

  const VkDeviceCreateInfo device_info = {
      .sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
      .queueCreateInfoCount = 1,
      .pQueueCreateInfos = &queue_info,
      .enabledExtensionCount = extension_count,
      .ppEnabledExtensionNames = extensions,
  };

  VkResult result =
      pfn_vkCreateDevice(app->physical_device, &device_info, NULL, &app->device);
  if (result != VK_SUCCESS) {
    print_vk_error("vkCreateDevice", result);
    return 11;
  }

  pfn_vkGetDeviceProcAddr =
      (PFN_vkGetDeviceProcAddr)load_instance_proc(app->instance,
                                                  "vkGetDeviceProcAddr");
  if (pfn_vkGetDeviceProcAddr == NULL) {
    fprintf(stderr, "vkGetDeviceProcAddr was not resolved.\n");
    return 12;
  }

#define LOAD_DEVICE(name)                                                      \
  pfn_##name = (PFN_##name)load_device_proc(app->device, #name)
  LOAD_DEVICE(vkDestroyDevice);
  LOAD_DEVICE(vkGetDeviceQueue);
  LOAD_DEVICE(vkCreateSwapchainKHR);
  LOAD_DEVICE(vkDestroySwapchainKHR);
  LOAD_DEVICE(vkGetSwapchainImagesKHR);
  LOAD_DEVICE(vkAcquireNextImageKHR);
  LOAD_DEVICE(vkQueuePresentKHR);
  LOAD_DEVICE(vkCreateImageView);
  LOAD_DEVICE(vkDestroyImageView);
  LOAD_DEVICE(vkCreateRenderPass);
  LOAD_DEVICE(vkDestroyRenderPass);
  LOAD_DEVICE(vkCreateShaderModule);
  LOAD_DEVICE(vkDestroyShaderModule);
  LOAD_DEVICE(vkCreatePipelineLayout);
  LOAD_DEVICE(vkDestroyPipelineLayout);
  LOAD_DEVICE(vkCreateGraphicsPipelines);
  LOAD_DEVICE(vkDestroyPipeline);
  LOAD_DEVICE(vkCreateFramebuffer);
  LOAD_DEVICE(vkDestroyFramebuffer);
  LOAD_DEVICE(vkCreateCommandPool);
  LOAD_DEVICE(vkDestroyCommandPool);
  LOAD_DEVICE(vkAllocateCommandBuffers);
  LOAD_DEVICE(vkBeginCommandBuffer);
  LOAD_DEVICE(vkEndCommandBuffer);
  LOAD_DEVICE(vkCmdBeginRenderPass);
  LOAD_DEVICE(vkCmdEndRenderPass);
  LOAD_DEVICE(vkCmdBindPipeline);
  LOAD_DEVICE(vkCmdDraw);
  LOAD_DEVICE(vkCreateFence);
  LOAD_DEVICE(vkDestroyFence);
  LOAD_DEVICE(vkWaitForFences);
  LOAD_DEVICE(vkResetFences);
  LOAD_DEVICE(vkQueueSubmit);
  LOAD_DEVICE(vkQueueWaitIdle);
  LOAD_DEVICE(vkDeviceWaitIdle);
#undef LOAD_DEVICE

  if (pfn_vkCreateSwapchainKHR == NULL || pfn_vkCreateGraphicsPipelines == NULL ||
      pfn_vkQueuePresentKHR == NULL) {
    fprintf(stderr, "Failed to resolve device Vulkan functions.\n");
    return 13;
  }
  pfn_vkGetDeviceQueue(app->device, app->queue_family, 0, &app->queue);
  return 0;
}

static VkSurfaceFormatKHR choose_surface_format(VulkanApp *app) {
  uint32_t format_count = 0;
  pfn_vkGetPhysicalDeviceSurfaceFormatsKHR(app->physical_device, app->surface,
                                           &format_count, NULL);
  VkSurfaceFormatKHR formats[32];
  if (format_count > ARRAY_SIZE(formats)) {
    format_count = ARRAY_SIZE(formats);
  }
  pfn_vkGetPhysicalDeviceSurfaceFormatsKHR(app->physical_device, app->surface,
                                           &format_count, formats);
  for (uint32_t index = 0; index < format_count; ++index) {
    if (formats[index].format == VK_FORMAT_B8G8R8A8_UNORM &&
        formats[index].colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
      return formats[index];
    }
  }
  return formats[0];
}

static VkPresentModeKHR choose_present_mode(VulkanApp *app) {
  uint32_t mode_count = 0;
  pfn_vkGetPhysicalDeviceSurfacePresentModesKHR(app->physical_device,
                                                app->surface, &mode_count,
                                                NULL);
  VkPresentModeKHR modes[16];
  if (mode_count > ARRAY_SIZE(modes)) {
    mode_count = ARRAY_SIZE(modes);
  }
  pfn_vkGetPhysicalDeviceSurfacePresentModesKHR(app->physical_device,
                                                app->surface, &mode_count,
                                                modes);
  for (uint32_t index = 0; index < mode_count; ++index) {
    if (modes[index] == VK_PRESENT_MODE_MAILBOX_KHR) {
      return modes[index];
    }
  }
  return VK_PRESENT_MODE_FIFO_KHR;
}

static int create_swapchain(VulkanApp *app) {
  VkSurfaceCapabilitiesKHR capabilities;
  VkResult result = pfn_vkGetPhysicalDeviceSurfaceCapabilitiesKHR(
      app->physical_device, app->surface, &capabilities);
  if (result != VK_SUCCESS) {
    print_vk_error("vkGetPhysicalDeviceSurfaceCapabilitiesKHR", result);
    return 14;
  }

  VkSurfaceFormatKHR surface_format = choose_surface_format(app);
  app->swapchain_format = surface_format.format;
  app->extent = capabilities.currentExtent;
  if (app->extent.width == UINT32_MAX) {
    app->extent.width = kWindowWidth;
    app->extent.height = kWindowHeight;
  }

  uint32_t image_count = capabilities.minImageCount + 1;
  if (capabilities.maxImageCount > 0 && image_count > capabilities.maxImageCount) {
    image_count = capabilities.maxImageCount;
  }

  const VkSwapchainCreateInfoKHR swapchain_info = {
      .sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
      .surface = app->surface,
      .minImageCount = image_count,
      .imageFormat = surface_format.format,
      .imageColorSpace = surface_format.colorSpace,
      .imageExtent = app->extent,
      .imageArrayLayers = 1,
      .imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
      .imageSharingMode = VK_SHARING_MODE_EXCLUSIVE,
      .preTransform = capabilities.currentTransform,
      .compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
      .presentMode = choose_present_mode(app),
      .clipped = VK_TRUE,
  };

  result =
      pfn_vkCreateSwapchainKHR(app->device, &swapchain_info, NULL,
                               &app->swapchain);
  if (result != VK_SUCCESS) {
    print_vk_error("vkCreateSwapchainKHR", result);
    return 15;
  }

  pfn_vkGetSwapchainImagesKHR(app->device, app->swapchain, &app->image_count,
                              NULL);
  if (app->image_count > ARRAY_SIZE(app->images)) {
    app->image_count = ARRAY_SIZE(app->images);
  }
  result = pfn_vkGetSwapchainImagesKHR(app->device, app->swapchain,
                                       &app->image_count, app->images);
  if (result != VK_SUCCESS) {
    print_vk_error("vkGetSwapchainImagesKHR", result);
    return 16;
  }

  for (uint32_t index = 0; index < app->image_count; ++index) {
    const VkImageViewCreateInfo view_info = {
        .sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO,
        .image = app->images[index],
        .viewType = VK_IMAGE_VIEW_TYPE_2D,
        .format = app->swapchain_format,
        .components = {VK_COMPONENT_SWIZZLE_IDENTITY,
                       VK_COMPONENT_SWIZZLE_IDENTITY,
                       VK_COMPONENT_SWIZZLE_IDENTITY,
                       VK_COMPONENT_SWIZZLE_IDENTITY},
        .subresourceRange = {VK_IMAGE_ASPECT_COLOR_BIT, 0, 1, 0, 1},
    };
    result = pfn_vkCreateImageView(app->device, &view_info, NULL,
                                   &app->image_views[index]);
    if (result != VK_SUCCESS) {
      print_vk_error("vkCreateImageView", result);
      return 17;
    }
  }
  return 0;
}

static int create_render_pass(VulkanApp *app) {
  const VkAttachmentDescription color_attachment = {
      .format = app->swapchain_format,
      .samples = VK_SAMPLE_COUNT_1_BIT,
      .loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR,
      .storeOp = VK_ATTACHMENT_STORE_OP_STORE,
      .stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE,
      .stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE,
      .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
      .finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
  };
  const VkAttachmentReference color_ref = {
      .attachment = 0,
      .layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL,
  };
  const VkSubpassDescription subpass = {
      .pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS,
      .colorAttachmentCount = 1,
      .pColorAttachments = &color_ref,
  };
  const VkSubpassDependency dependency = {
      .srcSubpass = VK_SUBPASS_EXTERNAL,
      .dstSubpass = 0,
      .srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
      .dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT,
      .dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT,
  };
  const VkRenderPassCreateInfo render_pass_info = {
      .sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO,
      .attachmentCount = 1,
      .pAttachments = &color_attachment,
      .subpassCount = 1,
      .pSubpasses = &subpass,
      .dependencyCount = 1,
      .pDependencies = &dependency,
  };
  VkResult result = pfn_vkCreateRenderPass(app->device, &render_pass_info, NULL,
                                           &app->render_pass);
  if (result != VK_SUCCESS) {
    print_vk_error("vkCreateRenderPass", result);
    return 18;
  }
  return 0;
}

static int create_shader_module(VulkanApp *app, const unsigned char *bytes,
                                uint32_t byte_count,
                                VkShaderModule *shader_module) {
  const VkShaderModuleCreateInfo shader_info = {
      .sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
      .codeSize = byte_count,
      .pCode = (const uint32_t *)bytes,
  };
  VkResult result =
      pfn_vkCreateShaderModule(app->device, &shader_info, NULL, shader_module);
  if (result != VK_SUCCESS) {
    print_vk_error("vkCreateShaderModule", result);
    return 19;
  }
  return 0;
}

static int create_pipeline(VulkanApp *app) {
  VkShaderModule vertex_shader = VK_NULL_HANDLE;
  VkShaderModule fragment_shader = VK_NULL_HANDLE;
  int status = create_shader_module(app, kTriangleVertexShader,
                                    kTriangleVertexShaderSize, &vertex_shader);
  if (status != 0) {
    return status;
  }
  status = create_shader_module(app, kTriangleFragmentShader,
                                kTriangleFragmentShaderSize, &fragment_shader);
  if (status != 0) {
    return status;
  }

  const VkPipelineShaderStageCreateInfo shader_stages[2] = {
      {
          .sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
          .stage = VK_SHADER_STAGE_VERTEX_BIT,
          .module = vertex_shader,
          .pName = "main",
      },
      {
          .sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
          .stage = VK_SHADER_STAGE_FRAGMENT_BIT,
          .module = fragment_shader,
          .pName = "main",
      },
  };
  const VkPipelineVertexInputStateCreateInfo vertex_input = {
      .sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
  };
  const VkPipelineInputAssemblyStateCreateInfo input_assembly = {
      .sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
      .topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST,
  };
  const VkViewport viewport = {
      .x = 0.0f,
      .y = 0.0f,
      .width = (float)app->extent.width,
      .height = (float)app->extent.height,
      .minDepth = 0.0f,
      .maxDepth = 1.0f,
  };
  const VkRect2D scissor = {
      .offset = {0, 0},
      .extent = app->extent,
  };
  const VkPipelineViewportStateCreateInfo viewport_state = {
      .sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
      .viewportCount = 1,
      .pViewports = &viewport,
      .scissorCount = 1,
      .pScissors = &scissor,
  };
  const VkPipelineRasterizationStateCreateInfo rasterizer = {
      .sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
      .polygonMode = VK_POLYGON_MODE_FILL,
      .cullMode = VK_CULL_MODE_BACK_BIT,
      .frontFace = VK_FRONT_FACE_CLOCKWISE,
      .lineWidth = 1.0f,
  };
  const VkPipelineMultisampleStateCreateInfo multisampling = {
      .sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
      .rasterizationSamples = VK_SAMPLE_COUNT_1_BIT,
  };
  const VkPipelineColorBlendAttachmentState color_blend_attachment = {
      .colorWriteMask = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT |
                        VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT,
  };
  const VkPipelineColorBlendStateCreateInfo color_blending = {
      .sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
      .attachmentCount = 1,
      .pAttachments = &color_blend_attachment,
  };
  const VkPipelineLayoutCreateInfo layout_info = {
      .sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
  };
  VkResult result = pfn_vkCreatePipelineLayout(app->device, &layout_info, NULL,
                                               &app->pipeline_layout);
  if (result != VK_SUCCESS) {
    print_vk_error("vkCreatePipelineLayout", result);
    return 20;
  }
  const VkGraphicsPipelineCreateInfo pipeline_info = {
      .sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
      .stageCount = 2,
      .pStages = shader_stages,
      .pVertexInputState = &vertex_input,
      .pInputAssemblyState = &input_assembly,
      .pViewportState = &viewport_state,
      .pRasterizationState = &rasterizer,
      .pMultisampleState = &multisampling,
      .pColorBlendState = &color_blending,
      .layout = app->pipeline_layout,
      .renderPass = app->render_pass,
      .subpass = 0,
  };
  result = pfn_vkCreateGraphicsPipelines(app->device, VK_NULL_HANDLE, 1,
                                         &pipeline_info, NULL, &app->pipeline);
  pfn_vkDestroyShaderModule(app->device, vertex_shader, NULL);
  pfn_vkDestroyShaderModule(app->device, fragment_shader, NULL);
  if (result != VK_SUCCESS) {
    print_vk_error("vkCreateGraphicsPipelines", result);
    return 21;
  }
  return 0;
}

static int create_framebuffers_and_commands(VulkanApp *app) {
  for (uint32_t index = 0; index < app->image_count; ++index) {
    const VkFramebufferCreateInfo framebuffer_info = {
        .sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO,
        .renderPass = app->render_pass,
        .attachmentCount = 1,
        .pAttachments = &app->image_views[index],
        .width = app->extent.width,
        .height = app->extent.height,
        .layers = 1,
    };
    VkResult result = pfn_vkCreateFramebuffer(app->device, &framebuffer_info,
                                              NULL, &app->framebuffers[index]);
    if (result != VK_SUCCESS) {
      print_vk_error("vkCreateFramebuffer", result);
      return 22;
    }
  }

  const VkCommandPoolCreateInfo pool_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
      .queueFamilyIndex = app->queue_family,
  };
  VkResult result =
      pfn_vkCreateCommandPool(app->device, &pool_info, NULL, &app->command_pool);
  if (result != VK_SUCCESS) {
    print_vk_error("vkCreateCommandPool", result);
    return 23;
  }
  const VkCommandBufferAllocateInfo allocate_info = {
      .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
      .commandPool = app->command_pool,
      .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
      .commandBufferCount = app->image_count,
  };
  result = pfn_vkAllocateCommandBuffers(app->device, &allocate_info,
                                        app->command_buffers);
  if (result != VK_SUCCESS) {
    print_vk_error("vkAllocateCommandBuffers", result);
    return 24;
  }

  for (uint32_t index = 0; index < app->image_count; ++index) {
    const VkCommandBufferBeginInfo begin_info = {
        .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
    };
    result = pfn_vkBeginCommandBuffer(app->command_buffers[index], &begin_info);
    if (result != VK_SUCCESS) {
      print_vk_error("vkBeginCommandBuffer", result);
      return 25;
    }
    const VkClearValue clear_color = {{{0.035f, 0.05f, 0.075f, 1.0f}}};
    const VkRenderPassBeginInfo render_pass_info = {
        .sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO,
        .renderPass = app->render_pass,
        .framebuffer = app->framebuffers[index],
        .renderArea = {{0, 0}, app->extent},
        .clearValueCount = 1,
        .pClearValues = &clear_color,
    };
    pfn_vkCmdBeginRenderPass(app->command_buffers[index], &render_pass_info,
                             VK_SUBPASS_CONTENTS_INLINE);
    pfn_vkCmdBindPipeline(app->command_buffers[index],
                          VK_PIPELINE_BIND_POINT_GRAPHICS, app->pipeline);
    pfn_vkCmdDraw(app->command_buffers[index], 3, 1, 0, 0);
    pfn_vkCmdEndRenderPass(app->command_buffers[index]);
    result = pfn_vkEndCommandBuffer(app->command_buffers[index]);
    if (result != VK_SUCCESS) {
      print_vk_error("vkEndCommandBuffer", result);
      return 26;
    }
  }

  const VkFenceCreateInfo acquire_fence_info = {
      .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
  };
  const VkFenceCreateInfo fence_info = {
      .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
      .flags = VK_FENCE_CREATE_SIGNALED_BIT,
  };
  result =
      pfn_vkCreateFence(app->device, &acquire_fence_info, NULL,
                        &app->image_acquired);
  if (result != VK_SUCCESS) {
    print_vk_error("vkCreateFence(image)", result);
    return 28;
  }
  result = pfn_vkCreateFence(app->device, &fence_info, NULL, &app->in_flight);
  if (result != VK_SUCCESS) {
    print_vk_error("vkCreateFence", result);
    return 29;
  }
  return 0;
}

static int init_vulkan(VulkanApp *app, HWND hwnd) {
  int status = load_vulkan_library(app);
  if (status != 0) return status;
  status = create_instance(app);
  if (status != 0) return status;
  status = create_surface(app, hwnd);
  if (status != 0) return status;
  status = select_physical_device(app);
  if (status != 0) return status;
  status = create_device(app);
  if (status != 0) return status;
  status = create_swapchain(app);
  if (status != 0) return status;
  status = create_render_pass(app);
  if (status != 0) return status;
  status = create_pipeline(app);
  if (status != 0) return status;
  return create_framebuffers_and_commands(app);
}

static int draw_frame(VulkanApp *app) {
  pfn_vkWaitForFences(app->device, 1, &app->in_flight, VK_TRUE, UINT64_MAX);
  pfn_vkResetFences(app->device, 1, &app->in_flight);

  uint32_t image_index = 0;
  VkResult result = pfn_vkAcquireNextImageKHR(
      app->device, app->swapchain, UINT64_MAX, VK_NULL_HANDLE,
      app->image_acquired, &image_index);
  if (result != VK_SUCCESS && result != VK_SUBOPTIMAL_KHR) {
    print_vk_error("vkAcquireNextImageKHR", result);
    return 30;
  }

  result = pfn_vkWaitForFences(app->device, 1, &app->image_acquired, VK_TRUE,
                               UINT64_MAX);
  if (result != VK_SUCCESS) {
    print_vk_error("vkWaitForFences(image)", result);
    return 31;
  }
  pfn_vkResetFences(app->device, 1, &app->image_acquired);

  const VkSubmitInfo submit_info = {
      .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
      .commandBufferCount = 1,
      .pCommandBuffers = &app->command_buffers[image_index],
  };
  result = pfn_vkQueueSubmit(app->queue, 1, &submit_info, app->in_flight);
  if (result != VK_SUCCESS) {
    print_vk_error("vkQueueSubmit", result);
    return 32;
  }

  result = pfn_vkWaitForFences(app->device, 1, &app->in_flight, VK_TRUE,
                               UINT64_MAX);
  if (result != VK_SUCCESS) {
    print_vk_error("vkWaitForFences(render)", result);
    return 33;
  }

  const VkPresentInfoKHR present_info = {
      .sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
      .swapchainCount = 1,
      .pSwapchains = &app->swapchain,
      .pImageIndices = &image_index,
  };
  result = pfn_vkQueuePresentKHR(app->queue, &present_info);
  if (result != VK_SUCCESS && result != VK_SUBOPTIMAL_KHR) {
    print_vk_error("vkQueuePresentKHR", result);
    return 34;
  }
  return 0;
}

static void cleanup_vulkan(VulkanApp *app) {
  if (app->device != VK_NULL_HANDLE) {
    pfn_vkDeviceWaitIdle(app->device);
    if (app->in_flight != VK_NULL_HANDLE)
      pfn_vkDestroyFence(app->device, app->in_flight, NULL);
    if (app->image_acquired != VK_NULL_HANDLE)
      pfn_vkDestroyFence(app->device, app->image_acquired, NULL);
    if (app->command_pool != VK_NULL_HANDLE)
      pfn_vkDestroyCommandPool(app->device, app->command_pool, NULL);
    for (uint32_t index = 0; index < app->image_count; ++index) {
      if (app->framebuffers[index] != VK_NULL_HANDLE)
        pfn_vkDestroyFramebuffer(app->device, app->framebuffers[index], NULL);
    }
    if (app->pipeline != VK_NULL_HANDLE)
      pfn_vkDestroyPipeline(app->device, app->pipeline, NULL);
    if (app->pipeline_layout != VK_NULL_HANDLE)
      pfn_vkDestroyPipelineLayout(app->device, app->pipeline_layout, NULL);
    if (app->render_pass != VK_NULL_HANDLE)
      pfn_vkDestroyRenderPass(app->device, app->render_pass, NULL);
    for (uint32_t index = 0; index < app->image_count; ++index) {
      if (app->image_views[index] != VK_NULL_HANDLE)
        pfn_vkDestroyImageView(app->device, app->image_views[index], NULL);
    }
    if (app->swapchain != VK_NULL_HANDLE)
      pfn_vkDestroySwapchainKHR(app->device, app->swapchain, NULL);
    pfn_vkDestroyDevice(app->device, NULL);
  }
  if (app->surface != VK_NULL_HANDLE)
    pfn_vkDestroySurfaceKHR(app->instance, app->surface, NULL);
  if (app->instance != VK_NULL_HANDLE)
    pfn_vkDestroyInstance(app->instance, NULL);
  if (app->vulkan_library != NULL)
    FreeLibrary(app->vulkan_library);
}

int main(void) {
  HWND hwnd = create_probe_window();
  if (hwnd == NULL) {
    return 1;
  }

  VulkanApp app;
  ZeroMemory(&app, sizeof(app));
  int status = init_vulkan(&app, hwnd);
  if (status != 0) {
    cleanup_vulkan(&app);
    return status;
  }

  status = draw_frame(&app);
  if (status != 0) {
    cleanup_vulkan(&app);
    return status;
  }

  printf("KONYAK_VULKAN_PROBE_OK triangle swapchain images=%lu\n",
         (unsigned long)app.image_count);
  g_window_text = "KONYAK Vulkan triangle - swapchain present OK";

  const DWORD deadline = GetTickCount() + (DWORD)probe_hold_ms();
  MSG message;
  for (;;) {
    while (PeekMessageA(&message, NULL, 0, 0, PM_REMOVE)) {
      if (message.message == WM_QUIT) {
        cleanup_vulkan(&app);
        return 0;
      }
      TranslateMessage(&message);
      DispatchMessageA(&message);
    }

    if ((int32_t)(GetTickCount() - deadline) >= 0) {
      DestroyWindow(hwnd);
    }
    Sleep(16);
  }
}
