# Bazel build file for my declaration ROM.
#

load(":golden.bzl", "golden_test")
load(":asm.bzl", "asm_library")

cc_test(
  name = "nubus_crc_test",
  srcs = ["nubus_crc_test.cc"],
  deps = [
    ":nubus_crc",
    "@com_google_googletest//:gtest_main",
  ]
)

cc_library(
  name = "nubus_crc",
  srcs = ["nubus_crc.cc"],
  hdrs = ["nubus_crc.h"],
)

cc_binary(
  name = "nubus_checksum",
  srcs = ["nubus_checksum.cc"],
  deps = [":nubus_crc",
       "@com_google_absl//absl/strings",
       "@com_github_gflags_gflags//:gflags",
       "@com_github_glog//:glog"]
)

asm_library(
    name = "nubus_rev_d_obj",
    srcs = "ns816rom.s",
    listing = 1,
    includes = ["atrap.inc",
                "globals.inc",
                "declrom.inc",],
    asm_bin = "/usr/m68k-linux-gnu/bin/as",
    cpu = "68020",
)

# TODO(josephoswald): Convert this and the _bin rule into an objcopy(...) rule
genrule(
  name = "nubus_rev_d_srec",
  srcs = [":nubus_rev_d_obj"],
  outs = ["ns816rom.srec"],
  cmd = ('/usr/m68k-linux-gnu/bin/objcopy $(SRCS) $@ ' +
         ' --input-target=elf32-m68k --output-target=srec '),
)

genrule(
  name = "nubus_rev_d_bin",
  srcs = [":nubus_rev_d_obj"],
  outs = ["ns816rom.bin"],
  cmd = ('/usr/m68k-linux-gnu/bin/objcopy $(SRCS) $@ ' +
         ' --input-target=elf32-m68k --output-target=binary '),
)

# Verifies that the single copy of the nubus_rev_d_bin code matches what is
# read from a Macintosh (with no daughterboard, jumper W1 missing, but that
# should not matter).
golden_test(
  name = "nubus_rev_d_verify",
  file = ":nubus_rev_d_bin",
  golden = "Nubus_NS8_16_Memory_Board_RevD.ROM",
)

# TODO(josephoswald):
#  1. NuBus declaration ROM CRC computation script, inserting result into _obj
#     target file.
#  2. CRC + Address invert + concatenation of duplicates to create full ROM
#     image to be burned
#  3. Verification that a "full ROM image" version of nubus_rev_d_bin is
#     identical to raw image extracted from the ROM in a ROM burner.
