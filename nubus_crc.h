// nubus_crc.h
//
// A utility to compute a checksum as performed by the Macintosh to detect
// NuBus configuration ROMs.
//

#include <cstdint>

class NuBusCRCComputer {

public:
  explicit NuBusCRCComputer() : crc_(0) {}
  std::uint32_t CRCValue() { return crc_; }
  void Accumulate(const std::uint8_t byte);
  
private:
  uint32_t crc_;
};
