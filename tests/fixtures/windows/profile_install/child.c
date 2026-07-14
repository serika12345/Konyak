#include <windows.h>

#include <stdio.h>
#include <stdlib.h>

static const wchar_t *const evidence_directory =
    L"C:\\konyak-profile-install-evidence";
static const wchar_t *const evidence_path =
    L"C:\\konyak-profile-install-evidence\\child-events.log";

static int append_event(void) {
  const wchar_t *command_line = GetCommandLineW();
  const int utf8_size =
      WideCharToMultiByte(CP_UTF8, 0, command_line, -1, NULL, 0, NULL, NULL);
  char *utf8 = NULL;
  char *event = NULL;
  DWORD written = 0;
  HANDLE file = INVALID_HANDLE_VALUE;
  wchar_t parent_pid[32] = L"missing";
  DWORD parent_length =
      GetEnvironmentVariableW(L"KONYAK_FIXTURE_PARENT_PID", parent_pid, 32);
  int event_size = 0;

  if (utf8_size <= 0) {
    return 20;
  }
  utf8 = (char *)malloc((size_t)utf8_size);
  if (utf8 == NULL ||
      WideCharToMultiByte(CP_UTF8, 0, command_line, -1, utf8, utf8_size, NULL,
                          NULL) == 0) {
    free(utf8);
    return 21;
  }
  if (parent_length == 0 || parent_length >= 32) {
    wcscpy(parent_pid, L"missing");
  }
  event_size = snprintf(NULL, 0, "pid=%lu parent=%ls commandLine=%s\r\n",
                        (unsigned long)GetCurrentProcessId(), parent_pid, utf8);
  if (event_size <= 0) {
    free(utf8);
    return 22;
  }
  event = (char *)malloc((size_t)event_size + 1u);
  if (event == NULL) {
    free(utf8);
    return 23;
  }
  (void)snprintf(event, (size_t)event_size + 1u,
                 "pid=%lu parent=%ls commandLine=%s\r\n",
                 (unsigned long)GetCurrentProcessId(), parent_pid, utf8);

  (void)CreateDirectoryW(evidence_directory, NULL);
  file = CreateFileW(evidence_path, FILE_APPEND_DATA, FILE_SHARE_READ, NULL,
                     OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
  if (file == INVALID_HANDLE_VALUE ||
      !WriteFile(file, event, (DWORD)event_size, &written, NULL) ||
      written != (DWORD)event_size) {
    if (file != INVALID_HANDLE_VALUE) {
      CloseHandle(file);
    }
    free(event);
    free(utf8);
    return 24;
  }
  CloseHandle(file);
  free(event);
  free(utf8);
  return 0;
}

int wmain(void) { return append_event(); }
