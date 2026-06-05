#include "../../text/TextMarkerFinder.hpp"
#include "../../app/PluginInterface.hpp"

#ifdef __WIN32
#define export extern "C" __declspec(dllexport)
#else
#define export extern "C"
#endif

export bool LoadPlugin (PluginInterface& plugin) {
wxMessageBox("Yes it works!", plugin.GetTranslations().get("error", "failed"), wxICON_ERROR);
return true;
}
