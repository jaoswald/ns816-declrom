"""Use diff to confirm that 'file' is identical to a 'golden' file.

"""

# FIXME(jaoswald): "outputs cannot be empty", looks like they are pushing
# me toward something like
# https://github.com/bazelbuild/examples/blob/master/rules/test_rule/line_length.bzl
# which generates a short shell script, writes that shell script out as
# an executable.
#
def _diff_file(f, golden):
    """Return shell command for comparing file 'f' to file 'golden'."""
    return """
  echo Comparing {file} to {golden}...
  diff --report-identical-files {file} {golden}
  """.format(file = f.short_path, golden = golden.short_path)

def _impl(ctx):
    script = _diff_file(ctx.file.file, ctx.file.golden)
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = script,
    )
    runfiles = ctx.runfiles(files = [ctx.file.file, ctx.file.golden])
    return DefaultInfo(
        executable = ctx.outputs.executable,
        runfiles = runfiles,
    )

golden_test = rule(
    implementation = _impl,
    attrs = {
        "file": attr.label(mandatory = True, allow_single_file = True),
        "golden": attr.label(mandatory = True, allow_single_file = True),
    },
    test = True,
)
