// Windows-only process ownership. No compiler or checker semantics live here.
// A noninheritable kill-on-close Job Object owns the suspended compiler before
// any compiler instruction executes. Parent death, deadline, guard death and
// ordinary completion all reap the complete compiler process tree.
#define UNICODE
#define _UNICODE
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include <wctype.h>

static DWORD parent_pid(void) {
  HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (snapshot == INVALID_HANDLE_VALUE) return 0;
  PROCESSENTRY32W entry;
  ZeroMemory(&entry, sizeof(entry)); entry.dwSize = sizeof(entry);
  DWORD parent = 0;
  if (Process32FirstW(snapshot, &entry)) do {
    if (entry.th32ProcessID == GetCurrentProcessId()) { parent = entry.th32ParentProcessID; break; }
  } while (Process32NextW(snapshot, &entry));
  CloseHandle(snapshot); return parent;
}
static int absolute_file(const wchar_t *p) {
  size_t n = wcslen(p);
  return n > 3 && n < 30000 && !wcschr(p, L'"') && p[n-1] != L'\\' && p[n-1] != L'/' &&
    ((iswalpha(p[0]) && p[1] == L':' && (p[2] == L'\\' || p[2] == L'/')) ||
     (p[0] == L'\\' && p[1] == L'\\'));
}
static int number(const wchar_t *p, DWORD maximum, DWORD *out) {
  if (!p[0]) return 0;
  for (const wchar_t *q = p; *q; ++q) if (*q < L'0' || *q > L'9') return 0;
  wchar_t *end = NULL; unsigned long long value = wcstoull(p, &end, 10);
  if (!end || *end || value == 0 || value > maximum) return 0;
  *out = (DWORD)value; return 1;
}
static HANDLE inherited_std(DWORD key, DWORD access) {
  HANDLE h = GetStdHandle(key), copy = INVALID_HANDLE_VALUE;
  if (h && h != INVALID_HANDLE_VALUE && DuplicateHandle(GetCurrentProcess(), h,
      GetCurrentProcess(), &copy, 0, TRUE, DUPLICATE_SAME_ACCESS)) return copy;
  SECURITY_ATTRIBUTES security = {sizeof(security), NULL, TRUE};
  return CreateFileW(L"NUL", access, FILE_SHARE_READ | FILE_SHARE_WRITE, &security,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
}
int wmain(int argc, wchar_t **argv) {
  DWORD parent_id, timeout;
  if (argc != 6 || !number(argv[1], MAXDWORD, &parent_id) ||
      !number(argv[2], 240000, &timeout) || !absolute_file(argv[3]) ||
      !absolute_file(argv[4]) || !absolute_file(argv[5]) || parent_pid() != parent_id) {
    fputs("PSC1_WINDOWS_JOB_ARGUMENT_OR_PARENT\n", stderr); return 125;
  }
  HANDLE parent = OpenProcess(SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION, FALSE, parent_id);
  FILETIME pc, pe, pk, pu, selfc, se, sk, su;
  if (!parent || !GetProcessTimes(parent, &pc, &pe, &pk, &pu) ||
      !GetProcessTimes(GetCurrentProcess(), &selfc, &se, &sk, &su) ||
      CompareFileTime(&pc, &selfc) > 0 || WaitForSingleObject(parent, 0) != WAIT_TIMEOUT) {
    if (parent) CloseHandle(parent);
    fputs("PSC1_WINDOWS_JOB_PARENT_GONE\n", stderr); return 125;
  }
  HANDLE job = CreateJobObjectW(NULL, NULL);
  JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits;
  ZeroMemory(&limits, sizeof(limits));
  limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
  if (!job || !SetInformationJobObject(job, JobObjectExtendedLimitInformation, &limits, sizeof(limits))) {
    if (job) CloseHandle(job); CloseHandle(parent);
    fputs("PSC1_WINDOWS_JOB_CREATE\n", stderr); return 125;
  }
  size_t length = wcslen(argv[3]) + wcslen(argv[4]) + wcslen(argv[5]) + 10;
  if (length >= 32767) { CloseHandle(job); CloseHandle(parent); return 125; }
  wchar_t *command = (wchar_t *)calloc(length, sizeof(wchar_t));
  if (!command) { CloseHandle(job); CloseHandle(parent); return 125; }
  _snwprintf(command, length, L"\"%ls\" \"%ls\" \"%ls\"", argv[3], argv[4], argv[5]);
  STARTUPINFOW startup; PROCESS_INFORMATION process;
  ZeroMemory(&startup, sizeof(startup)); ZeroMemory(&process, sizeof(process));
  startup.cb = sizeof(startup); startup.dwFlags = STARTF_USESTDHANDLES;
  startup.hStdInput = inherited_std(STD_INPUT_HANDLE, GENERIC_READ);
  startup.hStdOutput = inherited_std(STD_OUTPUT_HANDLE, GENERIC_WRITE);
  startup.hStdError = inherited_std(STD_ERROR_HANDLE, GENERIC_WRITE);
  BOOL created = CreateProcessW(argv[3], command, NULL, NULL, TRUE,
    CREATE_SUSPENDED | CREATE_NO_WINDOW | CREATE_UNICODE_ENVIRONMENT, NULL, NULL, &startup, &process);
  free(command);
  if (startup.hStdInput != INVALID_HANDLE_VALUE) CloseHandle(startup.hStdInput);
  if (startup.hStdOutput != INVALID_HANDLE_VALUE) CloseHandle(startup.hStdOutput);
  if (startup.hStdError != INVALID_HANDLE_VALUE) CloseHandle(startup.hStdError);
  if (!created) {
    fprintf(stderr, "PSC1_WINDOWS_JOB_SPAWN:%lu\n", (unsigned long)GetLastError());
    CloseHandle(job); CloseHandle(parent); return 125;
  }
  if (!AssignProcessToJobObject(job, process.hProcess) ||
      WaitForSingleObject(parent, 0) != WAIT_TIMEOUT || ResumeThread(process.hThread) == (DWORD)-1) {
    TerminateProcess(process.hProcess, 125); WaitForSingleObject(process.hProcess, 5000);
    CloseHandle(process.hThread); CloseHandle(process.hProcess); CloseHandle(job); CloseHandle(parent);
    fputs("PSC1_WINDOWS_JOB_ASSIGN_OR_PARENT\n", stderr); return 125;
  }
  CloseHandle(process.hThread);
  HANDLE waits[2] = {parent, process.hProcess};
  DWORD waited = WaitForMultipleObjects(2, waits, FALSE, timeout), code = 125;
  if (waited == WAIT_OBJECT_0 + 1) {
    if (!GetExitCodeProcess(process.hProcess, &code)) code = 125;
  } else {
    code = waited == WAIT_TIMEOUT ? 124 : 125;
    TerminateJobObject(job, code);
    fputs(waited == WAIT_TIMEOUT ? "PSC1_WINDOWS_JOB_DEADLINE\n" : "PSC1_WINDOWS_JOB_PARENT_EXIT\n", stderr);
  }
  // Also kill descendants of a compiler that exits successfully.
  CloseHandle(job);
  WaitForSingleObject(process.hProcess, 5000);
  CloseHandle(process.hProcess); CloseHandle(parent);
  return (int)code;
}
