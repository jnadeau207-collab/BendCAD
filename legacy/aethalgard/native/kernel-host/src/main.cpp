#include <cstdio>
#include <cstdlib>
#include <exception>
#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>

#include <Message.hxx>
#include <Message_PrinterOStream.hxx>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#include <windows.h>
#endif

#include "protocol.hpp"
#include "server.hpp"

namespace {

void ConfigureBundledResources(const char* executable) {
#ifdef _WIN32
  static_cast<void>(executable);
  const wchar_t* configured = _wgetenv(L"CSF_OCCTResourcePath");
  if (configured != nullptr && configured[0] != L'\0')
    return;
  std::wstring modulePath(32'768, L'\0');
  const DWORD length =
      GetModuleFileNameW(nullptr, modulePath.data(), static_cast<DWORD>(modulePath.size()));
  if (length == 0 || length >= modulePath.size())
    throw std::runtime_error("kernel-host executable path is unavailable");
  modulePath.resize(length);
  const auto root = std::filesystem::weakly_canonical(modulePath).parent_path().parent_path();
  const auto resources = (root / L"share" / L"opencascade" / L"resources").native();
  if (_wputenv_s(L"CSF_OCCTResourcePath", resources.c_str()) != 0)
    throw std::runtime_error("OCCT resource path could not be configured");
#else
  const char* configured = std::getenv("CSF_OCCTResourcePath");
  if (configured != nullptr && configured[0] != '\0')
    return;
  const auto root = std::filesystem::weakly_canonical(executable).parent_path().parent_path();
  const auto resources = (root / "share" / "opencascade" / "resources").string();
  setenv("CSF_OCCTResourcePath", resources.c_str(), 0);
#endif
}

void ConfigureOcctDiagnostics() {
  const occ::handle<Message_Messenger>& messenger = Message::DefaultMessenger();
  messenger->ChangePrinters().Clear();
  const occ::handle<Message_PrinterOStream> printer =
      new Message_PrinterOStream("cerr", false, Message_Info);
  printer->SetToColorize(false);
  messenger->AddPrinter(printer);
}

std::FILE* OpenBinaryStream() {
#ifdef _WIN32
  _setmode(_fileno(stdin), _O_BINARY);
  _setmode(_fileno(stdout), _O_BINARY);
  if (_setmode(3, _O_BINARY) == -1)
    return nullptr;
  return _fdopen(3, "wb");
#else
  return fdopen(3, "wb");
#endif
}

} // namespace

int main(int argc, char** argv) {
  try {
    if (argc > 0 && argv[0] != nullptr)
      ConfigureBundledResources(argv[0]);
    ConfigureOcctDiagnostics();
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);
    std::FILE* binary = OpenBinaryStream();
    aeth::ProtocolWriter writer(std::cout, binary);
    aeth::KernelServer server(writer);
    nlohmann::json request;
    while (aeth::ReadControlFrame(std::cin, request))
      server.HandleRequest(request);
    server.Stop();
    std::fclose(binary);
    return EXIT_SUCCESS;
  } catch (const std::exception& error) {
    std::cerr << "fatal kernel-host error: " << error.what() << '\n';
    return EXIT_FAILURE;
  } catch (...) {
    std::cerr << "fatal kernel-host error: unknown exception\n";
    return EXIT_FAILURE;
  }
}
