#include "Worker.hpp"
#include "App.hpp"
#include "../common/println.hpp"
#include<thread>

Worker::Worker ():
running(false)   
{}

#ifndef __WXMSW__
Worker::~Worker () {
stop();
}
#endif

void Worker::start () {
#ifdef __WXMSW__
std::thread t([this](){ run(); });
t.detach();
#else
if (thread.joinable()) return;
running=true;
thread = std::thread([this](){ run(); });
#endif
}

void Worker::submit (const Task& task) {
taskQueue.Post(task);
}

void Worker::stop () {
#ifdef __WXMSW__
running=false;
submit([](){});
#else
if (!thread.joinable()) return;
running=false;
submit([](){});
thread.join();
#endif
}

void Worker::run () {
try {
Task task;
#ifdef __WXMSW__
running=true;
#endif
println("Starting worker thread");
while(running) {
taskQueue.Receive(task);
task();
}
println("Stopping worker thread");
} catch (std::exception& e) {
println("Exception! {}: {}", typeid(e).name(), e.what());
}
}
