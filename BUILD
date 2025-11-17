# Bazel build file for my declaration ROM.
#

load(":golden.bzl", "golden_test")
load(":asm.bzl", "asm_library")

cc_test(
  name = "nubus_crc_test",
  srcs = ["nubus_crc_test.cc"],
  deps = [
    ":nubus_crc",
    "@googletest//:gtest_main",
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
       "@abseil-cpp//absl/strings",
       "@gflags//:gflags",
       "@glog//:glog"]
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

# Generated without zero-padding to match the visible ROM length.
genrule(
  name = "nubus_rev_d_bin_raw",
  srcs = [":nubus_rev_d_obj"],
  outs = ["ns816rom_raw.bin"],
  cmd = ('/usr/m68k-linux-gnu/bin/objcopy $(SRCS) $@ ' +
         '--input-target=elf32-m68k --output-target=binary '),
)

# With (re-)computed checksum, padded to 4K.
genrule(
  name = "nubus_rev_d_bin_4k",
  srcs = [":nubus_rev_d_bin_raw"],
  outs = ["ns816rom.bin"],
  cmd = "./$(location nubus_checksum) --input_file $(SRCS) " +
        "--output_file $(OUTS) --output_size 4096 ",
  tools = ["nubus_checksum"],
)

# Verifies that the single copy of the nubus_rev_d_bin code matches what is
# read from a Macintosh (with no daughterboard, jumper W1 missing, but that
# should not matter).
golden_test(
  name = "nubus_rev_d_verify",
  file = ":nubus_rev_d_bin_4k",
  golden = "Nubus_NS8_16_Memory_Board_RevD.ROM",
)

# With (re-)computed checksum, padded to full 8K.
genrule(
  name = "nubus_rev_d_bin_8k",
  srcs = [":nubus_rev_d_bin_raw"],
  outs = ["ns816rom_8k.bin"],
  cmd = "./$(location nubus_checksum) --input_file $(SRCS) " +
        "--output_file $(OUTS) --output_size 8192 ",
  tools = ["nubus_checksum"],
)

asm_library(
    name = "nubus_quadra_obj",
    srcs = "ns816_quadra.s",
    listing = 1,
    includes = ["atrap.inc",
                "globals.inc",
                "declrom.inc",],
    asm_bin = "/usr/m68k-linux-gnu/bin/as",
    cpu = "68040",
)

# Without computed checksum.
genrule(
  name = "nubus_quadra_bin_raw",
  srcs = [":nubus_quadra_obj"],
  outs = ["ns816_quadra_raw.bin"],
  cmd = ('/usr/m68k-linux-gnu/bin/objcopy $(SRCS) $@ ' +
         ' --input-target=elf32-m68k --output-target=binary '),
)

# With computed checksum, padded to 8K.
genrule(
  name = "nubus_quadra_bin",
  srcs = [":nubus_quadra_bin_raw"],
  outs = ["ns816_quadra.bin"],
  cmd = "./$(location nubus_checksum) --input_file $(SRCS) " +
        "--output_file $(OUTS) --output_size 8192 ",
  tools = ["nubus_checksum"],
)

cc_binary(
  name = "process_rom",
  srcs = ["process_rom.cc"],
  deps = [
       "@gflags//:gflags",
       "@glog//:glog"]
)

# Combined, byte-reversed ROM in binary.
genrule(
  name = "nubus_rev_d_prom_bin",
  srcs = [":nubus_rev_d_bin_8k"],
  outs = ["ns816prom.bin"],
  cmd = "./$(location process_rom) --input_00 $(SRCS) " +
        "--output_file $(OUTS) --bank_size 8192 ",
  tools = ["process_rom"],
)

# Verifies that the PROM-ready version of the nubus_rev_d_bin code matches
# what is read from the EPROM programmer.
golden_test(
  name = "nubus_rev_d_prom_verify",
  file = ":nubus_rev_d_prom_bin",
  golden = "ns816prom_golden.bin"
)

# Combined, byte-reversed ROM in binary for Quadra.
genrule(
  name = "nubus_quadra_prom_bin",
  srcs = [":nubus_quadra_bin"],
  outs = ["ns816_quadra_prom.bin"],
  cmd = "./$(location process_rom) --input_00 $(SRCS) " +
        "--output_file $(OUTS) --bank_size 8192 ",
  tools = ["process_rom"],
)

# TODO(josephoswald): S-record outputs.
# Quadra PROM for burning, in S-record format.

# TODO(josephoswald):
#  2. Verification that a "full ROM image" version of nubus_rev_d_bin is
#     identical to raw image extracted from the ROM in a ROM burner.
