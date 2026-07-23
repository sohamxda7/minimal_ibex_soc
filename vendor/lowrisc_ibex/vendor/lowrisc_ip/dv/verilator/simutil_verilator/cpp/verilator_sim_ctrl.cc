// Copyright lowRISC contributors (OpenTitan project).

// Licensed under the Apache License, Version 2.0, see LICENSE for details.

// SPDX-License-Identifier: Apache-2.0
 
#include "verilator_sim_ctrl.h"
 
#include <getopt.h>

#include <iostream>

#include <signal.h>

#include <sys/stat.h>

#include <verilated.h>
 
#ifndef VM_TRACE

#define VM_TRACE 0

#endif
 
// ============================================================

// 20 MHz clock configuration

// Timescale : 1ns / 1ps

// Period    : 1 / 20MHz = 50 ns

// Half-period (hi or lo) : 25 ns

// time_ increments by 1 per half-cycle → 1 unit = 25 ns

// ============================================================

// CURRENT (wrong for ps-based VCD)

static constexpr double CLK_HALF_PERIOD_NS = 10.0;
 
// CORRECT - return in ps since Verilator internally uses ps

static constexpr double CLK_HALF_PERIOD_PS = 10000.0;  // 25 ns = 25,000 ps
 
double sc_time_stamp() {

  return static_cast<double>(VerilatorSimCtrl::GetInstance().GetTime())

         * CLK_HALF_PERIOD_PS;

}  // 25 ns per half-cycle
 
/**

* Get the current simulation time in nanoseconds.

* Called by $time in Verilog. Timescale is 1ns/1ps so we return nanoseconds.

*/

/*double sc_time_stamp() {

  return static_cast<double>(VerilatorSimCtrl::GetInstance().GetTime())

         * CLK_HALF_PERIOD_NS;

}*/
 
#ifdef VL_USER_STOP

/**

* A simulation stop was requested, e.g. through $stop() or $error()

*/

void vl_stop(const char *filename, int linenum, const char *hier) VL_MT_UNSAFE {

  VerilatorSimCtrl::GetInstance().RequestStop(false);

}

#endif
 
VerilatorSimCtrl &VerilatorSimCtrl::GetInstance() {

  static VerilatorSimCtrl instance;

  return instance;

}
 
void VerilatorSimCtrl::SetTop(VerilatedToplevel *top, CData *sig_clk,

                              CData *sig_rst, VerilatorSimCtrlFlags flags) {

  top_ = top;

  sig_clk_ = sig_clk;

  sig_rst_ = sig_rst;

  flags_ = flags;

}
 
std::pair<int, bool> VerilatorSimCtrl::Exec(int argc, char **argv) {

  bool exit_app = false;

  bool good_cmdline = ParseCommandArgs(argc, argv, exit_app);

  if (exit_app) {

    return std::make_pair(good_cmdline ? 0 : 1, false);

  }
 
  RunSimulation();
 
  int retcode = WasSimulationSuccessful() ? 0 : 1;

  return std::make_pair(retcode, true);

}
 
static bool read_ul_arg(unsigned long *arg_val, const char *arg_name,

                        const char *arg_text) {

  assert(arg_val && arg_name && arg_text);
 
  bool bad_fmt = false;

  bool out_of_range = false;
 
  if (!(('0' <= arg_text[0]) && (arg_text[0] <= '9'))) {

    bad_fmt = true;

  } else {

    char *txt_end;

    errno = 0;

    *arg_val = strtoul(arg_text, &txt_end, 0);
 
    if (*txt_end) {

      bad_fmt = true;

    } else {

      if (errno != 0) {

        assert(errno == ERANGE);

        out_of_range = true;

      }

    }

  }
 
  if (bad_fmt) {

    std::cerr << "ERROR: Bad format for " << arg_name << " argument: `"
<< arg_text << "' is not an unsigned integer.\n";

    return false;

  }

  if (out_of_range) {

    std::cerr << "ERROR: Bad format for " << arg_name << " argument: `"
<< arg_text << "' is too big.\n";

    return false;

  }
 
  return true;

}
 
bool VerilatorSimCtrl::ParseCommandArgs(int argc, char **argv, bool &exit_app) {

  const struct option long_options[] = {

      {"term-after-cycles", required_argument, nullptr, 'c'},

      {"trace",             optional_argument, nullptr, 't'},

      {"help",              no_argument,       nullptr, 'h'},

      {nullptr,             no_argument,       nullptr,  0 }};
 
  while (1) {

    int c = getopt_long(argc, argv, "-:c:th", long_options, nullptr);

    if (c == -1) {

      break;

    }
 
    opterr = 0;
 
    switch (c) {

      case 0:

      case 1:

        break;

      case 't':

        if (!tracing_possible_) {

          std::cerr << "ERROR: Tracing has not been enabled at compile time."
<< std::endl;

          exit_app = true;

          return false;

        }

        if (optarg != nullptr) {

          trace_file_path_.assign(optarg);

        }

        TraceOn();

        break;

      case 'c':

        if (!read_ul_arg(&term_after_cycles_, "term-after-cycles", optarg)) {

          exit_app = true;

          return false;

        }

        break;

      case 'h':

        PrintHelp();

        exit_app = true;

        break;

      case ':':

        std::cerr << "ERROR: Missing argument." << std::endl << std::endl;

        exit_app = true;

        return false;

      case '?':

      default:;

    }

  }
 
  Verilated::commandArgs(argc, argv);
 
  for (auto it = extension_array_.begin(); it != extension_array_.end(); ++it) {

    if (!(*it)->ParseCLIArguments(argc, argv, exit_app)) {

      exit_app = true;

      return false;

      if (exit_app) {

        return true;

      }

    }

  }

  return true;

}
 
void VerilatorSimCtrl::RunSimulation() {

  RegisterSignalHandler();
 
  if (TracingPossible()) {

    std::cout << "Tracing can be toggled by sending SIGUSR1 to this process:"
<< std::endl
<< "$ kill -USR1 " << getpid() << std::endl;

  }
 
  // Confirm clock configuration on startup

  std::cout << "Clock configuration: 50 MHz"
<< " | Timescale: 1ns/1ps"
<< " | Period: 20 ns"
<< " | Half-period: " << CLK_HALF_PERIOD_NS << " ns"
<< std::endl;
 
  for (auto it = extension_array_.begin(); it != extension_array_.end(); ++it) {

    (*it)->PreExec();

  }

  Run();

  for (auto it = extension_array_.begin(); it != extension_array_.end(); ++it) {

    (*it)->PostExec();

  }

  PrintStatistics();

  if (TracingEverEnabled()) {

    std::cout << std::endl
<< "You can view the simulation traces by calling" << std::endl
<< "$ gtkwave " << GetTraceFileName() << std::endl;

  }

}
 
void VerilatorSimCtrl::SetInitialResetDelay(unsigned int cycles) {

  initial_reset_delay_cycles_ = cycles;

}
 
void VerilatorSimCtrl::SetResetDuration(unsigned int cycles) {

  reset_duration_cycles_ = cycles;

}
 
void VerilatorSimCtrl::SetTimeout(unsigned int cycles) {

  term_after_cycles_ = cycles;

}
 
void VerilatorSimCtrl::RequestStop(bool simulation_success) {

  request_stop_ = true;

  simulation_success_ &= simulation_success;

}
 
void VerilatorSimCtrl::RegisterExtension(SimCtrlExtension *ext) {

  extension_array_.push_back(ext);

}
 
VerilatorSimCtrl::VerilatorSimCtrl()

    : top_(nullptr),

      time_(0),

#ifdef VM_TRACE_FMT_FST

      trace_file_path_("sim.fst"),

#else

      trace_file_path_("sim.vcd"),

#endif

      tracing_enabled_(false),

      tracing_enabled_changed_(false),

      tracing_ever_enabled_(false),

      tracing_possible_(VM_TRACE),

      initial_reset_delay_cycles_(2),

      reset_duration_cycles_(2),

      request_stop_(false),

      simulation_success_(true),

      tracer_(VerilatedTracer()),

      term_after_cycles_(0) {

}
 
void VerilatorSimCtrl::RegisterSignalHandler() {

  struct sigaction sigIntHandler;

  sigIntHandler.sa_handler = SignalHandler;

  sigemptyset(&sigIntHandler.sa_mask);

  sigIntHandler.sa_flags = 0;

  sigaction(SIGINT,  &sigIntHandler, NULL);

  sigaction(SIGUSR1, &sigIntHandler, NULL);

}
 
void VerilatorSimCtrl::SignalHandler(int sig) {

  VerilatorSimCtrl &simctrl = VerilatorSimCtrl::GetInstance();

  switch (sig) {

    case SIGINT:

      simctrl.RequestStop(true);

      break;

    case SIGUSR1:

      if (simctrl.TracingEnabled()) {

        simctrl.TraceOff();

      } else {

        simctrl.TraceOn();

      }

      break;

  }

}
 
void VerilatorSimCtrl::PrintHelp() const {

  std::cout << "Execute a simulation model for " << GetName() << "\n\n";

  if (tracing_possible_) {

    std::cout << "-t|--trace\n"

                 "   --trace=FILE\n"

                 "  Write a trace file from the start\n\n";

  }

  std::cout << "-c|--term-after-cycles=N\n"

               "  Terminate simulation after N cycles. 0 means no timeout.\n\n"

               "-h|--help\n"

               "  Show help\n\n"

               "All arguments are passed to the design and can be used "

               "in the design, e.g. by DPI modules.\n\n";

}
 
bool VerilatorSimCtrl::TraceOn() {

  bool old_tracing_enabled = tracing_enabled_;

  tracing_enabled_ = tracing_possible_;

  tracing_ever_enabled_ = tracing_enabled_;

  if (old_tracing_enabled != tracing_enabled_) {

    tracing_enabled_changed_ = true;

  }

  return tracing_enabled_;

}
 
bool VerilatorSimCtrl::TraceOff() {

  if (tracing_enabled_) {

    tracing_enabled_changed_ = true;

  }

  tracing_enabled_ = false;

  return tracing_enabled_;

}
 
void VerilatorSimCtrl::PrintStatistics() const {

  // time_ counts half-cycles; full cycles = time_ / 2

  // At 20 MHz, each full cycle = 50 ns

  double cycles    = static_cast<double>(time_) / 2.0;

  double wall_sec  = GetExecutionTimeMs() / 1000.0;

  double speed_hz  = cycles / wall_sec;

  double speed_khz = speed_hz / 1000.0;

  // Simulated time in nanoseconds: cycles × 50 ns

  double sim_time_ns = cycles * 20.0;

  double sim_time_us = sim_time_ns / 1000.0;
 
  std::cout << std::endl
<< "Simulation statistics" << std::endl
<< "=====================" << std::endl
<< "Clock frequency:  50 MHz (period = 20 ns, timescale = 1ns/1ps)"
<< std::endl
<< "Executed cycles:  " << std::dec << time_ / 2 << std::endl
<< "Simulated time:   " << sim_time_ns << " ns"
<< " (" << sim_time_us << " us)" << std::endl
<< "Wallclock time:   " << wall_sec << " s" << std::endl
<< "Simulation speed: " << speed_hz << " cycles/s "
<< "(" << speed_khz << " kHz)" << std::endl;
 
  int trace_size_byte;

  if (tracing_enabled_ && FileSize(GetTraceFileName(), trace_size_byte)) {

    std::cout << "Trace file size:  " << trace_size_byte << " B" << std::endl;

  }

}
 
std::string VerilatorSimCtrl::GetTraceFileName() const {

  return trace_file_path_;

}
 
void VerilatorSimCtrl::Run() {

  assert(top_ && "Use SetTop() first.");
 
  if (tracing_possible_) {

    Verilated::traceEverOn(true);

    top_->trace(tracer_, 99, 0);

  }
 
  top_->eval();
 
  std::cout << std::endl
<< "Simulation running at 50 MHz (1ns/1ps timescale),"
<< " end by pressing CTRL-c." << std::endl;
 
  time_begin_ = std::chrono::steady_clock::now();

  UnsetReset();

  Trace();
 
  unsigned long start_reset_cycle_ = initial_reset_delay_cycles_;

  unsigned long end_reset_cycle_   = start_reset_cycle_ + reset_duration_cycles_;
 
  while (1) {

    unsigned long cycle_ = time_ / 2;
 
    if (cycle_ == start_reset_cycle_) {

      SetReset();

    } else if (cycle_ == end_reset_cycle_) {

      UnsetReset();

    }
 
    *sig_clk_ = !*sig_clk_;
 
    if (*sig_clk_) {

      for (auto it = extension_array_.begin(); it != extension_array_.end();

           ++it) {

        (*it)->OnClock(time_);

      }

    }
 
    top_->eval();

    time_++;
 
    Trace();
 
    if (request_stop_) {

      std::cout << "Received stop request, shutting down simulation."
<< std::endl;

      break;

    }

    if (Verilated::gotFinish()) {

      std::cout << "Received $finish() from Verilog, shutting down simulation."
<< std::endl;

      break;

    }

    if (term_after_cycles_ && (time_ / 2 >= term_after_cycles_)) {

      std::cout << "Simulation timeout of " << term_after_cycles_
<< " cycles reached, shutting down simulation." << std::endl;

      break;

    }

  }
 
  top_->final();

  time_end_ = std::chrono::steady_clock::now();
 
  if (TracingEverEnabled()) {

    tracer_.close();

  }

}
 
std::string VerilatorSimCtrl::GetName() const {

  if (top_) return top_->name();

  return "unknown";

}
 
unsigned int VerilatorSimCtrl::GetExecutionTimeMs() const {

  return std::chrono::duration_cast<std::chrono::milliseconds>(

             time_end_ - time_begin_)

      .count();

}
 
void VerilatorSimCtrl::SetReset() {

  if (flags_ & ResetPolarityNegative) {

    *sig_rst_ = 0;

  } else {

    *sig_rst_ = 1;

  }

}
 
void VerilatorSimCtrl::UnsetReset() {

  if (flags_ & ResetPolarityNegative) {

    *sig_rst_ = 1;

  } else {

    *sig_rst_ = 0;

  }

}
 
bool VerilatorSimCtrl::FileSize(std::string filepath, int &size_byte) const {

  struct stat statbuf;

  if (stat(filepath.data(), &statbuf) != 0) {

    size_byte = 0;

    return false;

  }

  size_byte = statbuf.st_size;

  return true;

}
 
void VerilatorSimCtrl::Trace() {

  if (tracing_enabled_changed_) {

    if (TracingEnabled()) {

      std::cout << "Tracing enabled." << std::endl;

    } else {

      std::cout << "Tracing disabled." << std::endl;

    }

    tracing_enabled_changed_ = false;

  }
 
  if (!TracingEnabled()) return;
 
  if (!tracer_.isOpen()) {

    tracer_.open(GetTraceFileName().c_str());

    std::cout << "Writing simulation traces to " << GetTraceFileName()
<< std::endl;

  }
 
  // Timescale is 1ns/1ps → dump timestamp in nanoseconds

  // Each time_ unit = one half-cycle = 25 ns at 20 MHz

  // So timestamp = time_ * 25

  tracer_.dump(static_cast<vluint64_t>(GetTime()) * 10000UL);

}
 
