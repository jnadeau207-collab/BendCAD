#pragma once

#include <atomic>
#include <chrono>
#include <mutex>
#include <string>
#include <thread>

#include <nlohmann/json.hpp>

#include "geometry.hpp"
#include "operation_timeout.hpp"
#include "protocol.hpp"

namespace aeth {

class KernelServer final {
public:
  explicit KernelServer(ProtocolWriter& writer);
  ~KernelServer();
  KernelServer(const KernelServer&) = delete;
  KernelServer& operator=(const KernelServer&) = delete;

  void HandleRequest(const nlohmann::json& request);
  void Stop();

private:
  void HandleHealth(const std::string& requestId);
  void HandleStats(const std::string& requestId);
  void HandleCancel(const nlohmann::json& request);
  void StartWork(nlohmann::json request);
  void RunWork(nlohmann::json request);

  nlohmann::json Evaluate(const nlohmann::json& request);
  nlohmann::json ExportMesh(const nlohmann::json& request);
  nlohmann::json EvaluateDefinition(const nlohmann::json& request);
  nlohmann::json ResolveMateFramesRequest(const nlohmann::json& request);
  nlohmann::json ShapeEvaluatedBodies(const std::vector<EvaluatedBody>& bodies, std::uint32_t epoch,
                                      std::uint32_t lodTier, bool includeTopology,
                                      bool includeElementNames, ElementNameBook* elementNames,
                                      const char* idKey);
  nlohmann::json MutationCase(const nlohmann::json& request);
  nlohmann::json OcafCase(const nlohmann::json& request);
  nlohmann::json Export(const nlohmann::json& request);
  nlohmann::json HlrProject(const nlohmann::json& request);
  nlohmann::json ExportXde(const nlohmann::json& request);
  nlohmann::json Interference(const nlohmann::json& request);
  nlohmann::json Inspect(const nlohmann::json& request);
  nlohmann::json InspectXde(const nlohmann::json& request);
  nlohmann::json Query(const nlohmann::json& request);
  nlohmann::json Simulate(const nlohmann::json& request);
  nlohmann::json SolveSketchRequest(const nlohmann::json& request);
  nlohmann::json MoldDraftAnalysis(const nlohmann::json& request);

  static nlohmann::json MakeSuccess(const std::string& requestId, const nlohmann::json& result);
  static nlohmann::json MakeError(const std::string& requestId, const std::string& code,
                                  const std::string& message, const std::string& operationId = {},
                                  const nlohmann::json& details = nlohmann::json());
  void WriteSuccess(const std::string& requestId, const nlohmann::json& result);
  void WriteError(const std::string& requestId, const std::string& code, const std::string& message,
                  const std::string& operationId = {});

  ProtocolWriter& writer_;
  std::thread worker_;
  std::mutex stateMutex_;
  std::string currentRequest_;
  std::atomic_bool busy_{false};
  std::atomic_bool cancelled_{false};
  std::atomic_uint32_t epoch_{0};
  std::atomic_uint32_t streamSequence_{0};
  DocumentEvaluator evaluator_;
  const std::chrono::steady_clock::time_point startTime_{std::chrono::steady_clock::now()};
  OperationWatchdog watchdog_{cancelled_};
};

} // namespace aeth
