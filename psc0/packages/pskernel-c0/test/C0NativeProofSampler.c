/*
 * Diagnostic-only C0 native stack sampling via SIGUSR1.
 * This library is injected solely by an opt-in CI performance investigation.
 * It is NEVER linked into the trusted kernel, prover or checker build.
 * The signal handler invokes backtrace_symbols_fd for diagnostics; this is
 * not async-signal-safe and must never be used in production.
 */
#define _GNU_SOURCE
#include <execinfo.h>
#include <signal.h>
#include <unistd.h>
#include <string.h>

static volatile sig_atomic_t sample_number = 0;

static void snapshot(int signal_number) {
    (void)signal_number;
    void *frames[65];
    int count = backtrace(frames, 65);
    const char banner[] = "\nC0_WF_PROFILE_SAMPLE_BEGIN\n";
    const char end[] = "C0_WF_PROFILE_SAMPLE_END\n";
    sample_number++;
    (void)write(STDERR_FILENO, banner, sizeof(banner)-1);
    backtrace_symbols_fd(frames, count, STDERR_FILENO);
    (void)write(STDERR_FILENO, end, sizeof(end)-1);
}

__attribute__((constructor))
static void install_sampler(void) {
    struct sigaction action;
    memset(&action, 0, sizeof(action));
    action.sa_handler = snapshot;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_RESTART;
    (void)sigaction(SIGUSR1, &action, NULL);
}
