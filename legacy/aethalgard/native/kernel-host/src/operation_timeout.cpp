#include "operation_timeout.hpp"

namespace aeth {

OperationWatchdog::OperationWatchdog(std::atomic_bool& cancelled)
    : cancelled_(cancelled), thread_([this] { Run(); }) {}

OperationWatchdog::~OperationWatchdog() {
  {
    std::scoped_lock lock(mutex_);
    stop_ = true;
  }
  cv_.notify_all();
  if (thread_.joinable())
    thread_.join();
}

void OperationWatchdog::BeginRequest(std::chrono::milliseconds opTimeout) {
  {
    std::scoped_lock lock(mutex_);
    timeout_ = opTimeout;
    tripped_ = OperationTimeout{};
    cause_ = Cause::None;
    armed_ = false;
    ++generation_;
  }
  cv_.notify_all();
}

void OperationWatchdog::Cancel() {
  {
    std::scoped_lock lock(mutex_);
    // First-cause: only claim the request if no cause has been set. If a
    // deadline already tripped (Cause::Timeout), leave it — the timeout genuinely
    // came first. Disarm regardless so the watchdog cannot trip after this.
    if (cause_ == Cause::None)
      cause_ = Cause::UserCancel;
    armed_ = false;
    ++generation_;
  }
  cv_.notify_all();
}

void OperationWatchdog::BeginOperation(const std::string& operationId) {
  {
    std::scoped_lock lock(mutex_);
    if (timeout_.count() <= 0)
      return; // timing disabled for this request
    operationId_ = operationId;
    deadline_ = std::chrono::steady_clock::now() + timeout_;
    armed_ = true;
    ++generation_;
  }
  cv_.notify_all();
}

void OperationWatchdog::EndOperation() {
  {
    std::scoped_lock lock(mutex_);
    if (!armed_)
      return;
    armed_ = false;
    ++generation_;
  }
  cv_.notify_all();
}

OperationTimeout OperationWatchdog::Result() const {
  std::scoped_lock lock(mutex_);
  return tripped_;
}

void OperationWatchdog::Run() {
  std::unique_lock lock(mutex_);
  while (true) {
    cv_.wait(lock, [this] { return stop_ || armed_; });
    if (stop_)
      return;
    const std::uint64_t generation = generation_;
    const std::chrono::steady_clock::time_point deadline = deadline_;
    // Wait out the deadline, but wake early if the op ended / a new op began
    // (generation changed) or we're stopping.
    const bool woken = cv_.wait_until(
        lock, deadline, [this, generation] { return stop_ || generation_ != generation; });
    if (woken)
      continue; // stopped, disarmed, or re-armed — re-evaluate from the top
    // The deadline elapsed while still on the same armed operation. First-cause:
    // trip ONLY if no cause has been claimed. A concurrent Cancel() bumps the
    // generation (so we would have woken above) or, if it grabbed the lock after
    // us, sees Cause::Timeout and defers — so a user cancel that actually came
    // first can never be reported as a timeout. Record the trip under this lock
    // BEFORE flipping the flag the ops poll, so a boundary that observes the flag
    // and then locks this mutex sees the trip.
    armed_ = false;
    if (cause_ != Cause::None)
      continue;
    cause_ = Cause::Timeout;
    tripped_.tripped = true;
    tripped_.operationId = operationId_;
    tripped_.budget = timeout_;
    cancelled_.store(true);
  }
}

} // namespace aeth
