#pragma once

#include <atomic>
#include <stdexcept>

#include <Message_ProgressIndicator.hxx>

namespace aeth {

class Cancelled final : public std::runtime_error {
public:
  Cancelled() : std::runtime_error("evaluation cancelled") {}
};

class CancellationProgress final : public Message_ProgressIndicator {
public:
  explicit CancellationProgress(const std::atomic_bool& cancelled);

protected:
  bool UserBreak() override;
  void Show(const Message_ProgressScope& scope, bool force) override;

private:
  const std::atomic_bool& cancelled_;
};

occ::handle<CancellationProgress> MakeCancellationProgress(const std::atomic_bool& cancelled);

} // namespace aeth
