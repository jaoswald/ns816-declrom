# asm.bzl
#
# Bazel build rules for cross-assembly. Initially developed for Gnu Assembler
# targeting the m68k architecture.
#
# Author: Joseph A. Oswald, III <josephoswald@gmail.com>
#

#
# asm_library(
#   name = "asm"
#   srcs = ["asm.s"],  // One file only
#   [out = ["asm.o"]]
#   includes = ["macros.inc",  // header dependencies
#               "defs.inc"],
#   listing = 1,  // to generate asm.l output
#   cpu = "68020",
#   opts = [...]  // additional command line options
#   asm_bin = "/usr/m68k-linux-gnu/bin/as"
# )

# TODO(jaoswald): not sure why ctx.outputs.out.basename includes ".o" suffix
def _output_basename(output_file):
  if (output_file.basename.endswith(".o")):
      return output_file.basename[:-2]
  else:
      return output_file.basename

def _asm(ctx):
  src_file = ctx.file.srcs # source file, ctx.attrs.srcs is input file target

  args = ctx.actions.args()
  args.add(src_file)

  out = ctx.outputs.out
  listing_basename = _output_basename(ctx.outputs.out) + ".l"
  args.add("-m" + ctx.attr.cpu)
  args.add("-o")
  args.add(ctx.outputs.out.path)

  inputs = ctx.attr.srcs.files
  include_dirs = []
  for target in ctx.attr.includes:
    inputs = inputs + target.files
    # TODO(josephoswald): de-duplicate
    for f in target.files:
      include_dirs.append(f.dirname)

  for d in include_dirs:
    args.add("-I{}".format(d))

  emit_listing = ctx.attr.listing
  if emit_listing:
    args.add("-a")
    listing_file = ctx.actions.declare_file(listing_basename)
    outs = [out, listing_file]
    command_redirect = "> " + listing_file.path
  else:
    outs = [out]
    listing_file = None
    command_redirect = ""

  command_line = "{asm_bin} $@ {redirection}".format(
    asm_bin = ctx.attr.asm_bin,
    redirection = command_redirect)
  ctx.actions.run_shell(
    outputs = outs,
    inputs = inputs,
    arguments = [args],
    command = command_line,
    mnemonic = "Assemble")

asm_library = rule(
  implementation=_asm,
  attrs={
    "srcs": attr.label(mandatory=True, allow_single_file=True),
    "includes": attr.label_list(allow_files=True),
    "listing": attr.bool(default=False),
    "cpu": attr.string(mandatory=True),
    "opts": attr.string_list(),
    # TODO(josephoswald): this should be able to refer to an element
    # of a toolchain, confirmed to support the target CPU. But I don't
    # understand all the Bazel support for these things.
    #"asm_bin": attr.label(allow_files=True, executable=True, cfg="target")
    "asm_bin": attr.string(mandatory=True)
  },
  outputs = {"out": "%{name}.o"}
)
