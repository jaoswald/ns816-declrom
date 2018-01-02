/* nubus_checksum.cc

   Computes and inserts a 32-bit "CRC" checksum for a Macintosh NuBus
   declaration ROM. It is actually not a standard CRC polynomial, but a simpler
   checksum, described in "Designing Cards and Drivers for the Macintosh
   Family."

   Command line:

     nubus_checksum infile outfile

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

#include "nubus_crc.h"

using std::cerr;
using std::cout;
using std::uint32_t;

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
      cerr << "Test pattern incorrect: " << test_pattern_;
      // return false;
    }
    if (directory_offset_ & 0xff000000) {
      cerr << "Directory offset upper byte looks invalid. "
	   << (directory_offset_ >> 24) << std::endl;
      // return false;
    }
    // directory offset indicates end - 20 + (signed directory offset)
    // ought to be within rom length of the end.
    if (length_ < kFormatLength) {
      cerr << "ROM length " << length_ << " too short to hold format block."
	   << std::endl;
      // return false;
    }
    if (length_ > file_length) {
      cerr << "rom_length " << length_ << " larger than file "
	   << file_length;
      // return false;
    }
    if (reserved_ != 0) {
      cerr << "Non-zero reserved byte: " << reserved_;
    }
    if (format_ != 1) {
      cerr << "Unexpected format " << format_;
      // return false;
    }
    return true;
  }

  static NuBusFormatBlock* ReadNuBusFormatBlock(std::ifstream& file,
						std::streamsize file_length) {
    if (file_length < kFormatLength) {
      cerr << "Too short to contain a format block " << file_length
	   << " bytes, less than " << kFormatLength;
      return nullptr;
    }
    file.seekg(file_length - kFormatLength);
    if (!file) {
      cerr << "Error seeking format block";
      return nullptr;
    }
    uint32_t directory_offset = read_32(file);
    cout << "directory offset: 0x" << std::hex << directory_offset <<
      std::endl;
    uint32_t rom_length = read_32(file);
    cout << "rom_length: 0x" << std::hex << rom_length << std::endl;
    uint32_t crc = read_32(file);
    cout << "crc: 0x" << std::hex << crc << std::endl;
    char revision_level = file.get();
    cout << "revision_level: " << std::dec << ((uint) revision_level & 0xff)
	 << std::endl;
    char format = file.get();
    uint32_t test_pattern = read_32(file);
    cout << "test_pattern: 0x" << std::hex << test_pattern << std::endl;
    char reserved = file.get();
    char byte_lanes = file.get();
    cout << "byte_lanes: 0x" << std::hex << ((uint) byte_lanes & 0xff)
	 << std::endl;

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
      cerr << "Does not appear to be a NuBus declaration ROM." << std::endl;
      return nullptr;
    }

    char* bytes = new char[format->length_];
    if (!bytes) {
      cerr << "Could not allocate bytes" << std::endl;
      return nullptr;
    }
    file.seekg(file_length - format->length_);
    if (!file) {
      cerr << "Error seeking contents";
      return nullptr;
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
#if(0)
	cerr << "i = " << i << " Skipping byte " << std::hex <<
	  (uint) bytes_[i];
#endif	
      } else {
	crc.Accumulate(bytes_[i]);
#if(0)
	cerr << "i = " << i << " byte " << std::hex <<
	  (((uint) bytes_[i]) & 0xff);
#endif
      }
#if(0)
      cerr << " after: crc = " << std::hex << crc.CRCValue() << std::endl;;
#endif
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
  if (argc != 3) {
    fprintf(stderr, "Command arguments: %s infile outfile\n", argv[0]);
    return -1;
  }

  std::ifstream infile(argv[1], std::ios::binary|std::ios::in);
  if (!infile.is_open()) {
    cerr << "Error opening " << argv[1] << std::endl;
    return -1;
  }  
  infile.ignore(std::numeric_limits<std::streamsize>::max());
  infile.clear();  // reset EOF
  std::streamsize length = infile.gcount();
  cout << "File length is " << length << " bytes" << std::endl;

  NuBusImage* image = NuBusImage::ReadFromFile(infile, length);
  if (!image) {
    cerr << "Does not appear to be a NuBus declaration ROM." << std::endl;
    return -1;
  }

  cerr << "Found an apparently valid ROM." << std::endl;

  uint32_t crc = image->ComputeCRC();
  cout << "Computed CRC: 0x" << std::hex << crc << std::endl;
  
  infile.close();
  if (!infile) {
    cerr << "Error closing input: " << argv[1] << std::endl;
    return -1;
  }

  return 0;
}
