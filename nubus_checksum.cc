/* nubus_checksum.cc

   Computes and inserts a 32-bit "CRC" checksum for a Macintosh NuBus
   declaration ROM. It is actually not a standard CRC polynomial, but a simpler
   checksum, described in "Designing Cards and Drivers for the Macintosh
   Family."

   Command line:

     nubus_checksum --input_file infile --output_file outfile

   This assumes infile is a raw binary file with a declaration ROM image
   at the end. The program reads the declaration ROM length field and
   magic number field as an integrity check, then computes the checksum
   and inserts it into the CRC field of outfile.

*/

#include <cstdint>
#include <fstream>
#include <ios>
#include <iostream>
#include <limits>
#include <string>

#include "absl/strings/str_cat.h"
#include "gflags/gflags.h"
#include "glog/logging.h"
#include "nubus_crc.h"

using std::uint32_t;

DEFINE_string(input_file, "",
	      "File containing binary image of a NuBus declaration ROM.");
DEFINE_string(output_file, "",
	      "Binary image to be dumped with proper checksum.");
namespace {

uint32_t read_32(std::ifstream& file) {
  unsigned char word[4];
  file.read(reinterpret_cast<char*>(word), 4);
  uint32_t result = 0;
  result |= word[0] << 24;
  result |= word[1] << 16;
  result |= word[2] << 8;
  result |= word[3];
  return result;
}

}  // namespace

class NuBusFormatBlock {
 public:
  bool valid(std::streamsize file_length) {
    if (test_pattern_ != kMagicNumber) {
      LOG(ERROR) << "Test pattern incorrect: " << test_pattern_;
      return false;
    }
    if (directory_offset_ & 0xff000000) {
      LOG(ERROR) << "Directory offset upper byte looks invalid. "
		 << (directory_offset_ >> 24);
      return false;
    }
    // directory offset indicates end - 20 + (signed directory offset)
    // ought to be within rom length of the end.
    if (length_ < kFormatLength) {
      LOG(ERROR) << "ROM length " << length_ <<
	" too short to hold format block.";
      return false;
    }
    if (length_ > file_length) {
      LOG(ERROR) << "rom_length " << length_ << " larger than file "
		 << file_length;
      return false;
    }
    if (reserved_ != 0) {
      LOG(ERROR) << "Non-zero reserved byte: " << reserved_;
    }
    if (format_ != 1) {
      LOG(ERROR) << "Unexpected format " << format_;
      return false;
    }
    return true;
  }

  static NuBusFormatBlock* ReadNuBusFormatBlock(std::ifstream& file,
						std::streamsize file_length) {
    if (file_length < kFormatLength) {
      LOG(ERROR) << "Too short to contain a format block " << file_length
		 << " bytes, less than " << kFormatLength;
      return nullptr;
    }
    file.seekg(file_length - kFormatLength);
    if (!file) {
      LOG(ERROR) << "Error seeking format block";
      return nullptr;
    }
    uint32_t directory_offset = read_32(file);
    VLOG(1) << "directory offset: 0x" <<
      absl::StrCat(absl::Hex(directory_offset));
    uint32_t rom_length = read_32(file);
    VLOG(1) << "rom_length: 0x" << absl::StrCat(absl::Hex(rom_length));
    uint32_t crc = read_32(file);
    VLOG(1) << "crc: 0x" << absl::StrCat(absl::Hex(crc));
    char revision_level = file.get();
    VLOG(1) << "revision_level: " << (int) revision_level;
    char format = file.get();
    uint32_t test_pattern = read_32(file);
    VLOG(1) << "test_pattern: 0x" << absl::StrCat(absl::Hex(test_pattern));
    char reserved = file.get();
    char byte_lanes = file.get();
    VLOG(1) << "byte_lanes: 0x" << absl::StrCat(absl::Hex(byte_lanes & 0xff));

    return new NuBusFormatBlock(byte_lanes, reserved, test_pattern,
				format, revision_level, crc, rom_length,
				directory_offset);
  }

  static const int32_t kMagicNumber = 0x5a932bc7;
  static const int32_t kFormatLength = 20;

  char byte_lanes_;
  char reserved_;
  int32_t test_pattern_;
  char format_;
  char revision_level_;
  int32_t crc_;
  int32_t length_;
  int32_t directory_offset_;

private:  
  NuBusFormatBlock(const char byte_lanes, const char reserved,
		   const int32_t test_pattern, const char format,
		   const char revision_level, const int32_t crc,
		   const int32_t length, const int32_t directory_offset)
    : byte_lanes_(byte_lanes), reserved_(reserved),
      test_pattern_(test_pattern), format_(format),
      revision_level_(revision_level), crc_(crc), length_(length),
      directory_offset_(directory_offset) {}
};


class NuBusImage {
public:
  static NuBusImage* ReadFromFile(std::ifstream& file,
				  std::streamsize file_length) {
    NuBusFormatBlock* format = NuBusFormatBlock::ReadNuBusFormatBlock(
						       file, file_length);
    if (!format || !format->valid(file_length)) {
      LOG(ERROR) << "Does not appear to be a NuBus declaration ROM.";
      return nullptr;
    }

    char* bytes = new char[format->length_];
    if (!bytes) {
      LOG(ERROR) << "Could not allocate bytes " << format->length_;
      return nullptr;
    }
    file.seekg(file_length - format->length_);
    if (!file) {
      LOG(ERROR) << "Error seeking contents";
    }
    file.read(bytes, format->length_);
    return new NuBusImage(format, format->length_, bytes);
  }

  NuBusFormatBlock* format_;
  uint32_t byte_len_;
  char* bytes_;

  uint32_t ComputeCRC() {
    uint32_t crc_offset = byte_len_ - 12;
    NuBusCRCComputer crc;
    for (uint32_t i = 0; i < byte_len_; ++i) {
      if (i >= crc_offset && i < crc_offset + 4) {
	crc.Accumulate(0);
	VLOG(2) << "i = " << i << " Skipping byte "
		<< absl::StrCat(absl::Hex(bytes_[i]));
      } else {
	crc.Accumulate(bytes_[i]);
	VLOG(2) << "i = " << i << " byte "
		<< absl::StrCat(absl::Hex(bytes_[i]));
      }
      VLOG(2) << " after: crc = " << absl::StrCat(absl::Hex(crc.CRCValue()));
    }
    return crc.CRCValue();
  }

 private: 
  NuBusImage(NuBusFormatBlock* format, int32_t byte_len,
	     char* contents) :
    format_(format),
    byte_len_(byte_len),
    bytes_(contents) {}
};


int main(int argc, char** argv) {
  gflags::ParseCommandLineFlags(&argc, &argv, true);
  google::InitGoogleLogging(argv[0]);

  const std::string& input_file_name = FLAGS_input_file;
  if (input_file.empty() || FLAGS_output_file.empty()) {
  int32_t output_length = FLAGS_output_size;
  if (output_length < 0) {
    LOG(FATAL) << "--output_size must be positive.";
  }
    LOG(FATAL) << "Must specify --input_file and --output_file.";
  }

  std::ifstream infile(input_file_name, std::ios::binary|std::ios::in);
  if (!infile.is_open()) {
    LOG(FATAL) << "Error opening " << input_file_name;
  }  
  infile.ignore(std::numeric_limits<std::streamsize>::max());
  infile.clear();  // reset EOF
  std::streamsize length = infile.gcount();
  VLOG(1) << "File length is " << length << " bytes";

  if (output_length == 0) {
    output_length = input_length;
  }
  if (output_length < input_length) {
    infile.close();
    LOG(FATAL) << "--output_size must be at least input_length: "
	       << input_length;
  }
  NuBusImage* image = NuBusImage::ReadFromFile(infile, length);
  if (!image) {
    LOG(FATAL) << "Does not appear to be a NuBus declaration ROM.";
  }

  VLOG(2) << "Found an apparently valid ROM.";

  uint32_t crc = image->ComputeCRC();
  LOG(INFO) << "Computed CRC: 0x" << std::hex << crc;
  
  infile.close();
  if (!infile) {
    LOG(FATAL) << "Error closing input: " << input_file_name;
  }

  return 0;
}
