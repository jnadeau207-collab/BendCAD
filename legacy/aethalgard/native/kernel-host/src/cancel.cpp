#include "cancel.hpp"

namespace aeth {

CancellationProgress::CancellationProgress(const std::atomic_bool& cancelled)
    : cancelled_(cancelled) {}

bool CancellationProgress::UserBreak() { return cancelled_.load(std::memory_order_relaxed); }

void CancellationProgress::Show(const Message_ProgressScope&, const bool) {}

occ::handle<CancellationProgress> MakeCancellationProgress(const std::atomic_bool& cancelled) {
  return new CancellationProgress(cancelled);
}

} // namespace aeth
