// Native unit test for the per-op timeout watchdog (Wave 2.1 slice 3b). It
// drives OperationWatchdog directly over a local atomic flag, so the mechanism
// is pinned DETERMINISTICALLY without a slow OCCT op: an operation that overruns
// its budget trips the shared cancel flag and records the offending op + budget;
// an operation that ends before its deadline never trips; a zero budget disables
// timing; and each operation re-arms with its OWN deadline, so an earlier op's
// budget never leaks onto a later one (the per-op, not per-request, contract).
#include <atomic>
#include <chrono>
#include <cstdio>
#include <string>
#include <thread>

#include "operation_timeout.hpp"

namespace {

using namespace std::chrono_literals;

int g_failures = 0;

void check(const bool condition, const std::string& label) {
  if (condition) {
    std::printf("  ok   %s\n", label.c_str());
  } else {
    std::printf("  FAIL %s\n", label.c_str());
    g_failures += 1;
  }
}

// (1) An operation that outlives its budget trips the flag and is attributed.
void OverrunTripsAndAttributes() {
  std::printf("an operation that overruns its budget trips the cancel flag:\n");
  std::atomic_bool cancelled{false};
  aeth::OperationWatchdog watchdog(cancelled);
  watchdog.BeginRequest(30ms);
  watchdog.BeginOperation("op-overrun");
  std::this_thread::sleep_for(300ms); // >> 30 ms budget
  const aeth::OperationTimeout result = watchdog.Result();
  check(cancelled.load(), "the shared cancel flag was tripped");
  check(result.tripped, "the watchdog recorded a timeout");
  check(result.operationId == "op-overrun", "the timed-out operation id is recorded");
  check(result.budget == 30ms, "the recorded budget matches the request cap");
  watchdog.EndOperation();
}

// (2) An operation that finishes before its deadline never trips.
void UnderrunDoesNotTrip() {
  std::printf("an operation that finishes before its deadline does not trip:\n");
  std::atomic_bool cancelled{false};
  aeth::OperationWatchdog watchdog(cancelled);
  watchdog.BeginRequest(1000ms);
  watchdog.BeginOperation("op-fast");
  std::this_thread::sleep_for(20ms); // well under the 1000 ms budget
  watchdog.EndOperation();
  std::this_thread::sleep_for(100ms); // give a mis-armed watchdog time to fire
  check(!cancelled.load(), "the cancel flag stayed clear");
  check(!watchdog.Result().tripped, "no timeout was recorded");
}

// (3) A zero budget disables timing entirely.
void ZeroBudgetDisablesTiming() {
  std::printf("a zero budget disables per-op timing:\n");
  std::atomic_bool cancelled{false};
  aeth::OperationWatchdog watchdog(cancelled);
  watchdog.BeginRequest(0ms);
  watchdog.BeginOperation("op-untimed");
  std::this_thread::sleep_for(100ms);
  check(!cancelled.load(), "the cancel flag stayed clear with timing disabled");
  check(!watchdog.Result().tripped, "no timeout was recorded with timing disabled");
  watchdog.EndOperation();
}

// (4) Each operation re-arms with its OWN deadline: two short ops whose combined
// wall-clock exceeds the budget do NOT trip (a per-request cap would have), and
// a later long op is attributed to ITSELF, not to an earlier one.
void EachOperationReArms() {
  std::printf("each operation re-arms with its own deadline:\n");
  std::atomic_bool cancelled{false};
  aeth::OperationWatchdog watchdog(cancelled);
  watchdog.BeginRequest(60ms);

  watchdog.BeginOperation("op-1");
  std::this_thread::sleep_for(10ms);
  watchdog.EndOperation();
  watchdog.BeginOperation("op-2");
  std::this_thread::sleep_for(10ms);
  watchdog.EndOperation();
  // Two 10 ms ops = 20 ms of op time within a longer wall window, each far under
  // the 60 ms per-op cap: a per-op governor must not have tripped.
  check(!cancelled.load(), "two short ops within budget did not trip");
  check(!watchdog.Result().tripped, "no timeout recorded across the two short ops");

  watchdog.BeginOperation("op-3-slow");
  std::this_thread::sleep_for(400ms); // >> 60 ms
  const aeth::OperationTimeout result = watchdog.Result();
  check(result.tripped, "the slow third op tripped");
  check(result.operationId == "op-3-slow",
        "the trip is attributed to the slow op, not an earlier one");
  watchdog.EndOperation();
}

// (5) FINDING 1 regression: a user cancel that precedes a not-yet-polling op is
// never re-reported as a timeout. Cancel() disarms the deadline and claims the
// cause, so even after the budget elapses the watchdog does NOT trip.
void UserCancelIsNotMisreportedAsTimeout() {
  std::printf("a user cancel is never re-reported as a timeout:\n");
  std::atomic_bool cancelled{false};
  aeth::OperationWatchdog watchdog(cancelled);
  watchdog.BeginRequest(30ms);
  watchdog.BeginOperation("op-cancel");
  // The user cancels while the op is still running (it never called EndOperation
  // and, as in the real host, may not poll the flag immediately).
  watchdog.Cancel();
  std::this_thread::sleep_for(300ms); // well past the 30 ms budget
  check(!watchdog.Result().tripped, "no timeout is recorded when the request was cancelled first");
}

// (6) FINDING 1, other direction: a genuine timeout that fires BEFORE a later
// cancel keeps its TIMEOUT attribution (first-cause is symmetric).
void TimeoutBeforeCancelKeepsTimeout() {
  std::printf("a timeout that precedes a cancel keeps its attribution:\n");
  std::atomic_bool cancelled{false};
  aeth::OperationWatchdog watchdog(cancelled);
  watchdog.BeginRequest(20ms);
  watchdog.BeginOperation("op-slow");
  std::this_thread::sleep_for(200ms); // trips at ~20 ms
  watchdog.Cancel();                  // a cancel arrives afterwards
  const aeth::OperationTimeout result = watchdog.Result();
  check(result.tripped, "the earlier timeout still wins over a later cancel");
  check(result.operationId == "op-slow", "the timed-out op remains attributed");
}

} // namespace

int main() {
  OverrunTripsAndAttributes();
  UnderrunDoesNotTrip();
  ZeroBudgetDisablesTiming();
  EachOperationReArms();
  UserCancelIsNotMisreportedAsTimeout();
  TimeoutBeforeCancelKeepsTimeout();
  if (g_failures == 0) {
    std::printf("\nALL OPERATION WATCHDOG TESTS PASSED\n");
    return 0;
  }
  std::printf("\n%d OPERATION WATCHDOG CHECK(S) FAILED\n", g_failures);
  return 1;
}
