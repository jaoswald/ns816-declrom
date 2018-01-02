#include "nubus_crc.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace {

std::uint32_t NuBusCRC(const char *str, unsigned int len) {
  NuBusCRCComputer crc;
  for (unsigned int i = 0; i < len; ++i) {
    crc.Accumulate(static_cast<std::uint8_t>(str[i]));
  }
  return crc.CRCValue();
}

}  // namespace

TEST(NubusCRCTest, Short) {
  const char kTestString[] = "123456789";
  EXPECT_EQ(25541, NuBusCRC(kTestString, strlen(kTestString)));
  EXPECT_EQ(51082, NuBusCRC(kTestString, strlen(kTestString)+1));
}

TEST(NubusCRCTest, Medium) {
  const char kTestString[] = "123456789abcdefghijklmnopqrstuwxyz"
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  EXPECT_EQ(2033713062, NuBusCRC(kTestString, strlen(kTestString)));
  EXPECT_EQ(4067426124, NuBusCRC(kTestString, strlen(kTestString)+1));
}
