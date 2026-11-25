#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);

  // Ajustar resolución inicial de la ventana al área útil del monitor actual.
  RECT work_area = {0, 0, 1280, 720};
  ::SystemParametersInfo(SPI_GETWORKAREA, 0, &work_area, 0);
  const UINT dpi = ::GetDpiForSystem();
  const double scale = dpi > 0 ? static_cast<double>(dpi) / 96.0 : 1.0;
  const int work_width =
      static_cast<int>((work_area.right - work_area.left) / scale);
  const int work_height =
      static_cast<int>((work_area.bottom - work_area.top) / scale);
  const int target_width =
      work_width > 960 ? static_cast<int>(work_width * 0.85) : work_width - 24;
  const int target_height =
      work_height > 640 ? static_cast<int>(work_height * 0.88) : work_height - 24;
  const int window_width = target_width > 480 ? target_width : 480;
  const int window_height = target_height > 480 ? target_height : 480;
  const int origin_x = static_cast<int>(work_area.left / scale) +
                       (work_width - window_width) / 2;
  const int origin_y = static_cast<int>(work_area.top / scale) +
                       (work_height - window_height) / 2;

  Win32Window::Point origin(origin_x > 0 ? origin_x : 10,
                            origin_y > 0 ? origin_y : 10);
  Win32Window::Size size(window_width, window_height);
  if (!window.Create(L"Brilliant Ravensburger", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
