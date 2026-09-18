#pragma once

#include <atomic>
#include <chrono>
#include <cstdint>
#include <filesystem>
#include <stdexcept>
#include <string>
#include <system_error>

#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#else
#include <cerrno>
#include <fcntl.h>
#include <unistd.h>
#endif

namespace aeth {

inline std::filesystem::path NextStepTempPath(const std::filesystem::path& outputPath) {
  static std::atomic<std::uint64_t> sequence{0};
  const auto ticks = std::chrono::steady_clock::now().time_since_epoch().count();
#ifdef _WIN32
  const auto processId = static_cast<unsigned long long>(GetCurrentProcessId());
#else
  const auto processId = static_cast<unsigned long long>(getpid());
#endif

  for (unsigned int attempt = 0; attempt < 128; ++attempt) {
    const auto ordinal = sequence.fetch_add(1, std::memory_order_relaxed);
    std::filesystem::path candidate = outputPath;
    candidate += std::filesystem::path(".aeth-step-tmp-" + std::to_string(processId) + "-" +
                                       std::to_string(ticks) + "-" + std::to_string(ordinal));

    std::error_code error;
    const bool exists = std::filesystem::exists(candidate, error);
    if (error) {
      throw std::system_error(error, "could not inspect STEP temporary path");
    }
    if (!exists) {
      return candidate;
    }
  }

  throw std::runtime_error("could not allocate a unique STEP temporary path");
}

inline void FsyncFile(const std::filesystem::path& path) {
#ifdef _WIN32
  const HANDLE handle = CreateFileW(path.c_str(), GENERIC_READ | GENERIC_WRITE,
                                    FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
                                    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (handle == INVALID_HANDLE_VALUE) {
    throw std::system_error(static_cast<int>(GetLastError()), std::system_category(),
                            "could not open STEP temporary file for durable flush");
  }

  if (FlushFileBuffers(handle) == 0) {
    const DWORD error = GetLastError();
    CloseHandle(handle);
    throw std::system_error(static_cast<int>(error), std::system_category(),
                            "could not durably flush STEP temporary file");
  }
  if (CloseHandle(handle) == 0) {
    throw std::system_error(static_cast<int>(GetLastError()), std::system_category(),
                            "could not close STEP temporary file after durable flush");
  }
#else
  const int descriptor = open(path.c_str(), O_RDONLY);
  if (descriptor < 0) {
    throw std::system_error(errno, std::generic_category(),
                            "could not open STEP temporary file for fsync");
  }
  if (fsync(descriptor) != 0) {
    const int error = errno;
    close(descriptor);
    throw std::system_error(error, std::generic_category(), "could not fsync STEP temporary file");
  }
  if (close(descriptor) != 0) {
    throw std::system_error(errno, std::generic_category(),
                            "could not close STEP temporary file after fsync");
  }
#endif
}

inline void RenameOverTarget(const std::filesystem::path& temporaryPath,
                             const std::filesystem::path& outputPath) {
#ifdef _WIN32
  if (MoveFileExW(temporaryPath.c_str(), outputPath.c_str(),
                  MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH) == 0) {
    throw std::system_error(static_cast<int>(GetLastError()), std::system_category(),
                            "could not publish STEP output atomically");
  }
#else
  std::error_code error;
  std::filesystem::rename(temporaryPath, outputPath, error);
  if (error) {
    throw std::system_error(error, "could not publish STEP output atomically");
  }

  const std::filesystem::path directory =
      outputPath.parent_path().empty() ? std::filesystem::path(".") : outputPath.parent_path();
  const int descriptor = open(directory.c_str(), O_RDONLY | O_DIRECTORY);
  if (descriptor < 0) {
    throw std::system_error(errno, std::generic_category(),
                            "could not open STEP output directory for fsync");
  }
  if (fsync(descriptor) != 0) {
    const int fsyncError = errno;
    close(descriptor);
    throw std::system_error(fsyncError, std::generic_category(),
                            "could not fsync STEP output directory");
  }
  if (close(descriptor) != 0) {
    throw std::system_error(errno, std::generic_category(),
                            "could not close STEP output directory after fsync");
  }
#endif
}

inline void RemoveTempBestEffort(const std::filesystem::path& path) noexcept {
  std::error_code ignored;
  std::filesystem::remove(path, ignored);
}

} // namespace aeth
