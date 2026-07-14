#include <windows.h>

#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>

static const wchar_t *const evidence_directory =
    L"C:\\konyak-profile-install-evidence";
static const wchar_t *const evidence_path =
    L"C:\\konyak-profile-install-evidence\\launcher-events.log";

static int append_event(void) {
  const wchar_t *command_line = GetCommandLineW();
  const int utf8_size =
      WideCharToMultiByte(CP_UTF8, 0, command_line, -1, NULL, 0, NULL, NULL);
  char *utf8 = NULL;
  char *event = NULL;
  DWORD written = 0;
  HANDLE file = INVALID_HANDLE_VALUE;
  int event_size = 0;

  if (utf8_size <= 0) {
    return 30;
  }
  utf8 = (char *)malloc((size_t)utf8_size);
  if (utf8 == NULL ||
      WideCharToMultiByte(CP_UTF8, 0, command_line, -1, utf8, utf8_size, NULL,
                          NULL) == 0) {
    free(utf8);
    return 31;
  }
  event_size = snprintf(NULL, 0, "pid=%lu commandLine=%s\r\n",
                        (unsigned long)GetCurrentProcessId(), utf8);
  if (event_size <= 0) {
    free(utf8);
    return 32;
  }
  event = (char *)malloc((size_t)event_size + 1u);
  if (event == NULL) {
    free(utf8);
    return 33;
  }
  (void)snprintf(event, (size_t)event_size + 1u,
                 "pid=%lu commandLine=%s\r\n",
                 (unsigned long)GetCurrentProcessId(), utf8);
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
    return 34;
  }
  CloseHandle(file);
  free(event);
  free(utf8);
  return 0;
}

static int child_path(wchar_t *path, DWORD capacity) {
  DWORD length = GetModuleFileNameW(NULL, path, capacity);
  wchar_t *separator = NULL;
  const wchar_t *child_name = L"profile_fixture_child.exe";

  if (length == 0 || length >= capacity) {
    return 40;
  }
  separator = wcsrchr(path, L'\\');
  if (separator == NULL) {
    return 41;
  }
  separator[1] = L'\0';
  if (wcslen(path) + wcslen(child_name) + 1u > capacity) {
    return 42;
  }
  wcscat(path, child_name);
  return 0;
}

int wmain(void) {
  wchar_t executable[MAX_PATH];
  wchar_t command_line[MAX_PATH + 128];
  wchar_t parent_pid[32];
  STARTUPINFOW startup;
  PROCESS_INFORMATION process;
  DWORD child_exit_code = 1;
  int result = append_event();

  if (result != 0) {
    return result;
  }
  result = child_path(executable, MAX_PATH);
  if (result != 0) {
    return result;
  }
  if (_snwprintf(command_line, MAX_PATH + 128,
                 L"\"%ls\" --launcher-argument=present", executable) < 0) {
    return 43;
  }
  (void)_snwprintf(parent_pid, 32, L"%lu",
                   (unsigned long)GetCurrentProcessId());
  if (!SetEnvironmentVariableW(L"KONYAK_FIXTURE_PARENT_PID", parent_pid)) {
    return 44;
  }
  ZeroMemory(&startup, sizeof(startup));
  startup.cb = sizeof(startup);
  ZeroMemory(&process, sizeof(process));
  if (!CreateProcessW(executable, command_line, NULL, NULL, FALSE, 0, NULL,
                      NULL, &startup, &process)) {
    return 45;
  }
  if (WaitForSingleObject(process.hProcess, 30000) != WAIT_OBJECT_0 ||
      !GetExitCodeProcess(process.hProcess, &child_exit_code)) {
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    return 46;
  }
  CloseHandle(process.hThread);
  CloseHandle(process.hProcess);
  return (int)child_exit_code;
}
