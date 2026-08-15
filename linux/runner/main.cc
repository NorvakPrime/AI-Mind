#include "my_application.h"

#include <cstdlib>

int main(int argc, char** argv) {
  // Force WebKit/WPE to use the CPU renderer. These must be configured before
  // GTK/WebKit and the Flutter engine are initialized.
  setenv("WEBKIT_DISABLE_COMPOSITING_MODE", "1", 1);
  setenv("WEBKIT_DISABLE_DMABUF_RENDERER", "1", 1);
  setenv("WPE_FDO_VIDEODECODE_NODMABUF", "1", 1);
  setenv("WPE_FDO_VIDEODEC_NODMABUF", "1", 1);
  setenv("LIBGL_ALWAYS_SOFTWARE", "1", 1);
  setenv("GALLIUM_DRIVER", "llvmpipe", 1);
  setenv("GSK_RENDERER", "cairo", 1);

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
