#include <windows.h>

__declspec(dllexport) unsigned int konyak_profile_fixture_component(void) {
  return sizeof(void *) * 8u;
}

BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID reserved) {
  (void)instance;
  (void)reason;
  (void)reserved;
  return TRUE;
}
