#ifndef _____WORKER_THREAD_1
#define _____WORKER_THREAD_1
#include <wx/msgqueue.h>
#ifndef __WXMSW__
#include<atomic>
#endif
#include<functional>
#include<memory>
#ifndef __WXMSW__
#include<thread>
#endif

struct Worker {
typedef std::function<void()> Task;
wxMessageQueue<Task> taskQueue;
#ifdef __WXMSW__
bool running;
#else
std::atomic_bool running;
std::thread thread;
#endif

Worker ();
#ifndef __WXMSW__
~Worker ();
#endif
void submit (const Task&);
void start ();
void stop ();
void run ();
};


#endif
