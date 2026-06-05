#include "App.hpp"
#include <wx/ipc.h>
#include <wx/snglinst.h>
#include <memory>

std::unique_ptr<wxSingleInstanceChecker> singleInstanceChecker;
wxServer* ipcServer = nullptr;

struct IPCConnection: wxConnection {
bool OnExec (const wxString& topic, const wxString& cmd) override {
auto& app = wxGetApp();
app.DoQuickJump(cmd);
switch(app.GetWindowMode()) {
case MODE_NB:
case MODE_AUINB:
break;
}
return true;
}};


struct IPCClient: wxClient {
IPCConnection* OnMakeConnection () final override { return new IPCConnection(); }
inline IPCConnection* Connect () { return static_cast<IPCConnection*>(MakeConnection("localhost", APP_NAME ".sock", APP_NAME " .ipc")); }
};

struct IPCServer: wxServer {
IPCServer (): wxServer() { Create(APP_NAME ".sock"); }
IPCConnection* OnAcceptConnection (const wxString& topic) final override { return new IPCConnection(); }
};

bool CheckSingleInstance (const std::vector<wxString>& cmdArgs) {
singleInstanceChecker = std::make_unique<wxSingleInstanceChecker>();
if (!singleInstanceChecker->Create(APP_NAME)) {
wxLogWarning("Unable to initialize single-instance checker for " APP_NAME);
singleInstanceChecker.reset();
return false;
}
if (singleInstanceChecker->IsAnotherRunning()) {
IPCClient client;
std::unique_ptr<IPCConnection> connection(client.Connect());
if (connection) for (auto& arg: cmdArgs) connection->Execute(arg);
singleInstanceChecker.reset();
return true;
}
ipcServer = new IPCServer();
return false;
}

void CloseSingleInstance () {
if (ipcServer) delete ipcServer;
ipcServer = nullptr;
singleInstanceChecker.reset();
}



