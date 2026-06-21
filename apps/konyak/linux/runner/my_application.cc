#include "my_application.h"

#include <flutter_linux/flutter_linux.h>

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
