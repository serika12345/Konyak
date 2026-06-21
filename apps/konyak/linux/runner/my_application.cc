#include "my_application.h"

#include <X11/Xatom.h>
#include <X11/Xlib.h>
#include <flutter_linux/flutter_linux.h>
#include <gdk/gdkx.h>
#include <unistd.h>

#include <algorithm>
#include <cctype>
#include <fstream>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  GtkWindow* window;
  FlMethodChannel* window_channel;
  GtkWidget* drag_region_event_box;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

static void set_window_icon(GtkWindow* window) {
  g_autofree gchar* executable_path = g_file_read_link("/proc/self/exe", nullptr);
  if (executable_path == nullptr) {
    return;
  }

  g_autofree gchar* executable_dir = g_path_get_dirname(executable_path);
  g_autofree gchar* icon_path =
      g_build_filename(executable_dir, "data", "app_icon_256.png", nullptr);
  gtk_window_set_icon_from_file(window, icon_path, nullptr);
}

static gboolean fl_value_lookup_double(FlValue* map, const gchar* key,
                                       gdouble* result) {
  FlValue* value = fl_value_lookup_string(map, key);
  if (value == nullptr) {
    return FALSE;
  }

  FlValueType value_type = fl_value_get_type(value);
  if (value_type == FL_VALUE_TYPE_FLOAT) {
    *result = fl_value_get_float(value);
    return TRUE;
  }
  if (value_type == FL_VALUE_TYPE_INT) {
    *result = static_cast<gdouble>(fl_value_get_int(value));
    return TRUE;
  }

  return FALSE;
}

static gboolean fl_value_lookup_bool(FlValue* map, const gchar* key) {
  if (map == nullptr || fl_value_get_type(map) != FL_VALUE_TYPE_MAP) {
    return FALSE;
  }

  FlValue* value = fl_value_lookup_string(map, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_BOOL) {
    return FALSE;
  }

  return fl_value_get_bool(value);
}

static std::set<pid_t> root_process_ids_from_args(FlValue* args) {
  std::set<pid_t> process_ids;
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return process_ids;
  }

  FlValue* value = fl_value_lookup_string(args, "descendantOfProcessIds");
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_LIST) {
    return process_ids;
  }

  const size_t length = fl_value_get_length(value);
  for (size_t index = 0; index < length; index++) {
    FlValue* item = fl_value_get_list_value(value, index);
    if (item == nullptr || fl_value_get_type(item) != FL_VALUE_TYPE_INT) {
      continue;
    }

    const gint64 process_id = fl_value_get_int(item);
    if (process_id > 0) {
      process_ids.insert(static_cast<pid_t>(process_id));
    }
  }

  return process_ids;
}

static std::string lowercased(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(),
                 [](unsigned char item) { return std::tolower(item); });
  return value;
}

static std::string process_executable_path(pid_t process_id) {
  gchar link_path[64];
  g_snprintf(link_path, sizeof(link_path), "/proc/%d/exe", process_id);

  gchar path[4096];
  const ssize_t length = readlink(link_path, path, sizeof(path) - 1);
  if (length <= 0) {
    return "";
  }

  path[length] = '\0';
  return std::string(path);
}

static bool is_wine_process_path(const std::string& path) {
  const std::string normalized_path = lowercased(path);
  return normalized_path.find("/wine") != std::string::npos ||
         normalized_path.find("wine64") != std::string::npos ||
         normalized_path.find("wine-preloader") != std::string::npos ||
         normalized_path.find("wine64-preloader") != std::string::npos ||
         normalized_path.find("proton") != std::string::npos ||
         normalized_path.find("crossover") != std::string::npos;
}

static pid_t parent_process_id(pid_t process_id) {
  gchar stat_path[64];
  g_snprintf(stat_path, sizeof(stat_path), "/proc/%d/stat", process_id);

  std::ifstream stat_file(stat_path);
  std::string stat;
  std::getline(stat_file, stat);
  if (stat.empty()) {
    return 0;
  }

  const size_t comm_end = stat.rfind(')');
  if (comm_end == std::string::npos || comm_end + 2 >= stat.size()) {
    return 0;
  }

  std::istringstream fields(stat.substr(comm_end + 2));
  char state = '\0';
  pid_t parent_id = 0;
  fields >> state >> parent_id;
  return parent_id > 0 ? parent_id : 0;
}

static bool is_descendant_process(pid_t process_id,
                                  const std::set<pid_t>& root_process_ids) {
  if (root_process_ids.empty()) {
    return false;
  }

  std::set<pid_t> visited_process_ids;
  pid_t current_process_id = process_id;
  while (current_process_id > 0 &&
         visited_process_ids.find(current_process_id) ==
             visited_process_ids.end()) {
    if (root_process_ids.find(current_process_id) !=
        root_process_ids.end()) {
      return true;
    }

    visited_process_ids.insert(current_process_id);
    current_process_id = parent_process_id(current_process_id);
  }

  return false;
}

#ifdef GDK_WINDOWING_X11
struct X11DisplayConnection {
  Display* display;
  bool should_close;
};

static X11DisplayConnection open_x11_window_list_display() {
  GdkDisplay* gdk_display = gdk_display_get_default();
  if (gdk_display != nullptr && GDK_IS_X11_DISPLAY(gdk_display)) {
    return {gdk_x11_display_get_xdisplay(gdk_display), false};
  }

  const gchar* display_name = g_getenv("DISPLAY");
  if (display_name == nullptr || display_name[0] == '\0') {
    return {nullptr, false};
  }

  return {XOpenDisplay(display_name), true};
}

static Window app_x11_window(MyApplication* self, Display* display) {
  GdkDisplay* gdk_display = gdk_display_get_default();
  if (gdk_display == nullptr || !GDK_IS_X11_DISPLAY(gdk_display) ||
      display != gdk_x11_display_get_xdisplay(gdk_display)) {
    return None;
  }

  GdkWindow* app_gdk_window = gtk_widget_get_window(GTK_WIDGET(self->window));
  return app_gdk_window == nullptr ? None
                                   : gdk_x11_window_get_xid(app_gdk_window);
}

static std::vector<Window> x11_client_windows(Display* display) {
  std::vector<Window> windows;
  const Window root_window = DefaultRootWindow(display);
  const Atom client_list_atom =
      XInternAtom(display, "_NET_CLIENT_LIST", True);
  if (client_list_atom == None) {
    return windows;
  }

  Atom actual_type = None;
  int actual_format = 0;
  unsigned long item_count = 0;
  unsigned long bytes_after = 0;
  unsigned char* data = nullptr;
  const int status = XGetWindowProperty(
      display, root_window, client_list_atom, 0, 1024, False, XA_WINDOW,
      &actual_type, &actual_format, &item_count, &bytes_after, &data);

  if (status != Success || actual_type == None || data == nullptr) {
    if (data != nullptr) {
      XFree(data);
    }
    return windows;
  }

  if (actual_format == 32) {
    Window* window_items = reinterpret_cast<Window*>(data);
    windows.assign(window_items, window_items + item_count);
  }

  XFree(data);
  return windows;
}

static pid_t x11_window_process_id(Display* display, Window window) {
  const Atom pid_atom = XInternAtom(display, "_NET_WM_PID", True);
  if (pid_atom == None) {
    return 0;
  }

  Atom actual_type = None;
  int actual_format = 0;
  unsigned long item_count = 0;
  unsigned long bytes_after = 0;
  unsigned char* data = nullptr;
  const int status =
      XGetWindowProperty(display, window, pid_atom, 0, 1, False, XA_CARDINAL,
                         &actual_type, &actual_format, &item_count,
                         &bytes_after, &data);

  if (status != Success || actual_type == None || actual_format != 32 ||
      item_count == 0 || data == nullptr) {
    if (data != nullptr) {
      XFree(data);
    }
    return 0;
  }

  const unsigned long process_id = *reinterpret_cast<unsigned long*>(data);
  XFree(data);
  return process_id > 0 ? static_cast<pid_t>(process_id) : 0;
}

static bool x11_window_is_visible_application_window(Display* display,
                                                     Window window) {
  XWindowAttributes attributes;
  if (XGetWindowAttributes(display, window, &attributes) == 0) {
    return false;
  }

  return attributes.map_state == IsViewable && !attributes.override_redirect &&
         attributes.width >= 80 && attributes.height >= 60;
}
#endif

static FlValue* visible_external_window_ids(MyApplication* self,
                                            FlValue* args) {
  g_autoptr(FlValue) result = fl_value_new_list();

  const std::set<pid_t> root_process_ids = root_process_ids_from_args(args);
  const gboolean include_wine_process_windows =
      fl_value_lookup_bool(args, "includeWineProcessWindows");
  if (root_process_ids.empty() && !include_wine_process_windows) {
    return fl_value_ref(result);
  }

#ifdef GDK_WINDOWING_X11
  const X11DisplayConnection connection = open_x11_window_list_display();
  if (connection.display == nullptr) {
    // Native Wayland does not expose other clients' windows to GTK. If there
    // is no XWayland DISPLAY either, Flutter waits for the CLI result.
    return fl_value_ref(result);
  }

  Display* display = connection.display;
  const Window app_window = app_x11_window(self, display);

  for (const Window window : x11_client_windows(display)) {
    if (window == None || window == app_window ||
        !x11_window_is_visible_application_window(display, window)) {
      continue;
    }

    const pid_t process_id = x11_window_process_id(display, window);
    if (process_id <= 0) {
      continue;
    }

    const bool matches_process =
        is_descendant_process(process_id, root_process_ids) ||
        (include_wine_process_windows &&
         is_wine_process_path(process_executable_path(process_id)));
    if (!matches_process) {
      continue;
    }

    g_autofree gchar* window_id = g_strdup_printf("%lu", window);
    fl_value_append_take(result, fl_value_new_string(window_id));
  }

  if (connection.should_close) {
    XCloseDisplay(display);
  }
#endif

  return fl_value_ref(result);
}

static gboolean update_drag_region(MyApplication* self, FlValue* args) {
  if (args == nullptr || fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FALSE;
  }

  gdouble left = 0;
  gdouble top = 0;
  gdouble right = 0;
  gdouble bottom = 0;
  if (!fl_value_lookup_double(args, "left", &left) ||
      !fl_value_lookup_double(args, "top", &top) ||
      !fl_value_lookup_double(args, "right", &right) ||
      !fl_value_lookup_double(args, "bottom", &bottom) || right <= left ||
      bottom <= top) {
    return FALSE;
  }

  if (self->drag_region_event_box == nullptr) {
    return FALSE;
  }

  gtk_widget_set_margin_start(self->drag_region_event_box,
                              static_cast<gint>(left));
  gtk_widget_set_margin_top(self->drag_region_event_box, static_cast<gint>(top));
  gtk_widget_set_size_request(self->drag_region_event_box,
                              static_cast<gint>(right - left),
                              static_cast<gint>(bottom - top));
  gtk_widget_show(self->drag_region_event_box);
  return TRUE;
}

static gboolean drag_region_button_press_cb(GtkWidget* event_box,
                                            GdkEventButton* event,
                                            gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  GtkWindow* window = self->window;
  if (window == nullptr || event->type != GDK_BUTTON_PRESS ||
      event->button != 1) {
    return FALSE;
  }

  gtk_window_begin_move_drag(window, event->button,
                             static_cast<gint>(event->x_root),
                             static_cast<gint>(event->y_root), event->time);
  return TRUE;
}

static GtkWidget* create_drag_region_event_box(MyApplication* self) {
  GtkWidget* event_box = gtk_event_box_new();
  GtkEventBox* drag_region_event_box = GTK_EVENT_BOX(event_box);
  gtk_event_box_set_visible_window(drag_region_event_box, FALSE);
  gtk_event_box_set_above_child(drag_region_event_box, TRUE);
  gtk_widget_set_halign(event_box, GTK_ALIGN_START);
  gtk_widget_set_valign(event_box, GTK_ALIGN_START);
  gtk_widget_set_no_show_all(event_box, TRUE);
  gtk_widget_add_events(event_box, GDK_BUTTON_PRESS_MASK);
  g_signal_connect(event_box, "button-press-event",
                   G_CALLBACK(drag_region_button_press_cb), self);
  return event_box;
}

static void linux_window_method_call_cb(FlMethodChannel* channel,
                                        FlMethodCall* method_call,
                                        gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  GtkWindow* window = self->window;

  if (window == nullptr) {
    fl_method_call_respond_error(method_call, "window-unavailable",
                                 "The Konyak window is not available.", nullptr,
                                 nullptr);
    return;
  }

  if (g_strcmp0(method, "setWindowDragRegion") == 0) {
    if (!update_drag_region(self, fl_method_call_get_args(method_call))) {
      fl_method_call_respond_error(
          method_call, "invalid-arguments",
          "Window drag region must include left, top, right, and bottom.",
          nullptr, nullptr);
      return;
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
    return;
  }

  if (g_strcmp0(method, "visibleExternalWindowIds") == 0) {
    g_autoptr(FlValue) window_ids =
        visible_external_window_ids(self, fl_method_call_get_args(method_call));
    fl_method_call_respond_success(method_call, window_ids, nullptr);
    return;
  }

  if (g_strcmp0(method, "clearWindowDragRegion") == 0) {
    if (self->drag_region_event_box != nullptr) {
      gtk_widget_hide(self->drag_region_event_box);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
    return;
  }

  if (g_strcmp0(method, "minimizeWindow") == 0) {
    gtk_window_iconify(window);
    fl_method_call_respond_success(method_call, nullptr, nullptr);
    return;
  }

  if (g_strcmp0(method, "toggleMaximizeWindow") == 0) {
    if (gtk_window_is_maximized(window)) {
      gtk_window_unmaximize(window);
    } else {
      gtk_window_maximize(window);
    }
    fl_method_call_respond_success(method_call, nullptr, nullptr);
    return;
  }

  if (g_strcmp0(method, "closeWindow") == 0) {
    fl_method_call_respond_success(method_call, nullptr, nullptr);
    gtk_window_close(window);
    return;
  }

  fl_method_call_respond_not_implemented(method_call, nullptr);
}

static void create_linux_window_channel(MyApplication* self, FlView* view) {
  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();

  self->window_channel = fl_method_channel_new(
      messenger, "konyak/linux_window", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->window_channel, linux_window_method_call_cb, self, nullptr);
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  self->window = window;
  set_window_icon(window);
  gtk_window_set_title(window, "");
  gtk_window_set_decorated(window, FALSE);

  gtk_window_set_default_size(window, 800, 500);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);

  GtkOverlay* overlay = GTK_OVERLAY(gtk_overlay_new());
  gtk_widget_show(GTK_WIDGET(overlay));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(overlay));
  gtk_container_add(GTK_CONTAINER(overlay), GTK_WIDGET(view));
  gtk_widget_show(GTK_WIDGET(view));

  self->drag_region_event_box = create_drag_region_event_box(self);
  gtk_overlay_add_overlay(overlay, self->drag_region_event_box);

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  create_linux_window_channel(self, view);

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_object(&self->window_channel);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);
  gdk_set_program_class(APPLICATION_ID);
  gtk_window_set_default_icon_name(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
