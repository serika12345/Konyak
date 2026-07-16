#include <stdio.h>
#include <string.h>

int main(void) {
  static const char expected[] = "KONYAK_CWD_PROBE_OK\n";
  char contents[sizeof(expected)] = {0};
  FILE *relative_data = fopen("konyak-relative-data.txt", "rb");
  size_t bytes_read;

  if (relative_data == NULL) {
    return 2;
  }

  bytes_read = fread(contents, 1, sizeof(contents) - 1, relative_data);
  if (ferror(relative_data) != 0 || fclose(relative_data) != 0) {
    return 3;
  }

  return bytes_read == sizeof(expected) - 1 && strcmp(contents, expected) == 0
             ? 0
             : 4;
}
