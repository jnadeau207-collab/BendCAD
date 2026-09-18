// SPIKE SHIM (GOV-004). Replaces FreeCAD's Base/Console.h with the smallest
// surface PlaneGCS actually uses: a printf-style Base::Console().log(...).
#pragma once
#include <cstdarg>
#include <cstdio>

namespace Base {

class ConsoleSink {
public:
  void log(const char* format, ...) const {
    if (!verbose || !format)
      return;
    va_list args;
    va_start(args, format);
    std::vfprintf(stderr, format, args);
    va_end(args);
  }
  static inline bool verbose = false;
};

inline ConsoleSink& Console() {
  static ConsoleSink sink;
  return sink;
}

} // namespace Base
