sed -i '/crate.from_cargo(/i \
crate.annotation(\n    crate = "aws-lc-sys",\n    build_script_env = {\n        "CRATE_CC_NO_DEFAULTS": "1",\n        "CFLAGS": "-O0",\n        "OPT_LEVEL": "0",\n    },\n)\n' MODULE.bazel
