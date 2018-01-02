#include "nubus_crc.h"

void NuBusCRCComputer::Accumulate(const uint8_t byte) {
  // Rotate sum left by one bit (with ROL.L #1 instruction)
  bool top_bit = (crc_ >> 31) & 1;
#if(0)
  if (top_bit) {
    cerr << "top bit set";
  }
#endif
  uint32_t rot_crc = ((0x7fffffff & crc_) << 1) + (top_bit ? 1 : 0);
  // Add the byte to sum
  crc_ = rot_crc + byte;
}
