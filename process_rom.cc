/* process_rom.cc

   Process up to 4 ROM images into a single binary blob suitable for burning
   into a NuBus declaration ROM for the National Semiconductor NS8/16 NuBus
   Memory card.

   The card has two features which must be handled:

   * The address lines are *active low*, which effectively reverses the
     sequence of the bytes. (ROM address 0 appears at 0xFFF in the Mac).
   * The ROM contains four banks, selected by control of the A13 and A14 lines,
     which are in turn controlled by U14 pin 11 and jumper W1 (U14 pin 3)
     respectively. This program allows up to 4 images to be chosen (although
     the Rev D. hardware apparently uses 4 identical images).

   process_rom [--bank_size=8192]
     --output_file=<binary output file name>

     Each input file must be exactly bank_size bytes long.
     The input_XX arguments other than --input_00, if omitted, default to
     duplicating input_00

     --input_00=<binary input for A14=0, A13=0>
     [--input_01=<binary input for A14=0, A13=1>]
     [--input_10=<binary input for A14=1, A13=0>]
     [--input_11=<binary input for A14=1, A13=1>]
*/

#include <string>
#include <fstream>
#include <iostream>

#include "gflags/gflags.h"
#include "glog/logging.h"

DEFINE_string(output_file, "", "Output file for raw binary output.");
DEFINE_int32(bank_size, 8192, "Size of ROM bank in bytes.");
DEFINE_string(input_00, "", "Input file for high-order address bits 00");
DEFINE_string(input_01, "", "Input file for high-order address bits 01");
DEFINE_string(input_10, "", "Input file for high-order address bits 10");
DEFINE_string(input_11, "", "Input file for high-order address bits 11");

namespace {

using std::string;

/* returns false if input file does not exactly contain bank_size bytes or
   cannot be read. */
bool ReadBank(const string& file_name, char* buf, const int32_t bank_size) {
  std::ifstream infile(file_name, std::ios::binary|std::ios::in);
  if (!infile.is_open()) {
    LOG(ERROR) << "Error opening " << file_name;
    return false;
  }  
  infile.read(buf, bank_size);
  const std::streamsize bytes_read = infile.gcount();
  bool ok = true;
  if (bytes_read != bank_size) {
    LOG(ERROR) << "Read " << bytes_read << " bytes, expected bank_size "
	       << bank_size;
    ok = false;
  }
  infile.close();
  if (!infile) {
    LOG(ERROR) << "Error closing input.";
    ok = false;
  }
  return ok;
}

void ReverseBank(char* buf, const int32_t bank_size) {
  for (int i = 0; i < bank_size / 2; ++i) {
    const int32_t other = bank_size - i - 1;
    char c = buf[i];
    buf[i] = buf[other];
    buf[other] = c;
  }
}

} // namespace

int main(int argc, char** argv) {
  gflags::ParseCommandLineFlags(&argc, &argv, true);
  google::InitGoogleLogging(argv[0]);

  const std::string& output_name = FLAGS_output_file;
  if (output_name.empty()) {
    LOG(FATAL) << "Must specify --output_file.";
  }
  const std::string& input_00_name = FLAGS_input_00;
  if (input_00_name.empty()) {
    LOG(FATAL) << "Must specify --input_00 input file.";
  }
  int32_t bank_size = FLAGS_bank_size;
  if (bank_size <= 0) {
    LOG(FATAL) << "--bank_size must be positive.";
  }

  if(FLAGS_input_01.empty()) { LOG(INFO) << "Duplicating input_00 for 01"; }
  if(FLAGS_input_10.empty()) { LOG(INFO) << "Duplicating input_00 for 10"; }
  if(FLAGS_input_11.empty()) { LOG(INFO) << "Duplicating input_00 for 11"; }
  const std::string& input_01_name = FLAGS_input_01.empty() ? input_00_name :
    FLAGS_input_01;
  const std::string& input_10_name = FLAGS_input_10.empty() ? input_00_name :
    FLAGS_input_10;
  const std::string& input_11_name = FLAGS_input_11.empty() ? input_00_name :
    FLAGS_input_11;

  char* bank_buffer = new char[bank_size]();
  CHECK_NE(static_cast<char*>(nullptr), bank_buffer)
    << "Allocating " << bank_size;
  std::ofstream outfile(output_name,
			std::ios::binary|std::ios::out|std::ios::trunc);
  if (!outfile.is_open()) {
    LOG(FATAL) << "Could not open " << output_name << " for output";
  }

  bool ok = true;
#define PROCESS_BANK(name)				\
  ok &= ReadBank(name, bank_buffer, bank_size);		\
  if (!ok) {						\
    outfile.close();					\
    LOG(FATAL) << "Reading " << name;			\
  }							\
  ReverseBank(bank_buffer, bank_size);			\
  if (!outfile.write(bank_buffer, bank_size)) {		\
    LOG(FATAL) << "Writing output for " << name;	\
  }							\
  
  // order 00, 01, 10, 11 is not reversed.
  PROCESS_BANK(input_00_name);
  PROCESS_BANK(input_01_name);
  PROCESS_BANK(input_10_name);
  PROCESS_BANK(input_11_name);
  outfile.close();
  if (!outfile) {
    LOG(FATAL) << "Error closing " << output_name;
  }
  return 0;
}

