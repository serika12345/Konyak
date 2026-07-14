#define COBJMACROS

#include <windows.h>
#include <objbase.h>
#include <shlobj.h>
#include <shobjidl.h>

#include <stdio.h>

#define RESOURCE_LAUNCHER 101
#define RESOURCE_CHILD 102

static const wchar_t *const install_directory =
    L"C:\\Program Files\\Konyak Profile Fixture";
static const wchar_t *const launcher_path =
    L"C:\\Program Files\\Konyak Profile Fixture\\profile_fixture_launcher.exe";
static const wchar_t *const child_path =
    L"C:\\Program Files\\Konyak Profile Fixture\\profile_fixture_child.exe";
static const wchar_t *const shortcut_directory =
    L"C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs";
static const wchar_t *const shortcut_path =
    L"C:\\ProgramData\\Microsoft\\Windows\\Start Menu\\Programs\\Konyak Profile Fixture.lnk";
static const wchar_t *const evidence_directory =
    L"C:\\konyak-profile-install-evidence";
static const wchar_t *const evidence_path =
    L"C:\\konyak-profile-install-evidence\\installer-events.log";

static int extract_resource(WORD resource_id, const wchar_t *destination) {
  HRSRC resource = FindResourceW(NULL, MAKEINTRESOURCEW(resource_id), RT_RCDATA);
  HGLOBAL loaded = NULL;
  const void *bytes = NULL;
  DWORD size = 0;
  HANDLE output = INVALID_HANDLE_VALUE;
  DWORD written = 0;

  if (resource == NULL) {
    return 50;
  }
  loaded = LoadResource(NULL, resource);
  size = SizeofResource(NULL, resource);
  bytes = LockResource(loaded);
  if (loaded == NULL || bytes == NULL || size == 0) {
    return 51;
  }
  output = CreateFileW(destination, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS,
                       FILE_ATTRIBUTE_NORMAL, NULL);
  if (output == INVALID_HANDLE_VALUE) {
    return 52;
  }
  if (!WriteFile(output, bytes, size, &written, NULL) || written != size ||
      !FlushFileBuffers(output)) {
    CloseHandle(output);
    return 53;
  }
  CloseHandle(output);
  return 0;
}

static int create_shortcut(void) {
  IShellLinkW *shell_link = NULL;
  IPersistFile *persist_file = NULL;
  HRESULT result = CoCreateInstance(&CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER,
                                    &IID_IShellLinkW, (void **)&shell_link);
  if (FAILED(result)) {
    return 60;
  }
  result = IShellLinkW_SetPath(shell_link, launcher_path);
  if (SUCCEEDED(result)) {
    result = IShellLinkW_SetWorkingDirectory(shell_link, install_directory);
  }
  if (SUCCEEDED(result)) {
    result = IShellLinkW_QueryInterface(shell_link, &IID_IPersistFile,
                                        (void **)&persist_file);
  }
  if (SUCCEEDED(result)) {
    result = IPersistFile_Save(persist_file, shortcut_path, TRUE);
  }
  if (persist_file != NULL) {
    IPersistFile_Release(persist_file);
  }
  IShellLinkW_Release(shell_link);
  return SUCCEEDED(result) ? 0 : 61;
}

static int append_installer_event(void) {
  char event[128];
  int event_size = snprintf(event, sizeof(event), "pid=%lu installed=1\r\n",
                            (unsigned long)GetCurrentProcessId());
  HANDLE file = INVALID_HANDLE_VALUE;
  DWORD written = 0;
  if (event_size <= 0 || event_size >= (int)sizeof(event)) {
    return 70;
  }
  (void)CreateDirectoryW(evidence_directory, NULL);
  file = CreateFileW(evidence_path, FILE_APPEND_DATA, FILE_SHARE_READ, NULL,
                     OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
  if (file == INVALID_HANDLE_VALUE ||
      !WriteFile(file, event, (DWORD)event_size, &written, NULL) ||
      written != (DWORD)event_size) {
    if (file != INVALID_HANDLE_VALUE) {
      CloseHandle(file);
    }
    return 71;
  }
  CloseHandle(file);
  return 0;
}

int wmain(void) {
  HRESULT com_result = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED);
  int directory_result = ERROR_SUCCESS;
  int result = 0;
  if (FAILED(com_result)) {
    return 80;
  }
  directory_result = SHCreateDirectoryExW(NULL, install_directory, NULL);
  if (directory_result != ERROR_SUCCESS &&
      directory_result != ERROR_ALREADY_EXISTS &&
      directory_result != ERROR_FILE_EXISTS) {
    CoUninitialize();
    return 81;
  }
  directory_result = SHCreateDirectoryExW(NULL, shortcut_directory, NULL);
  if (directory_result != ERROR_SUCCESS &&
      directory_result != ERROR_ALREADY_EXISTS &&
      directory_result != ERROR_FILE_EXISTS) {
    CoUninitialize();
    return 82;
  }
  result = extract_resource(RESOURCE_LAUNCHER, launcher_path);
  if (result == 0) {
    result = extract_resource(RESOURCE_CHILD, child_path);
  }
  if (result == 0) {
    result = create_shortcut();
  }
  if (result == 0) {
    result = append_installer_event();
  }
  CoUninitialize();
  return result;
}
