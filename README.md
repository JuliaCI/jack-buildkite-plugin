# jack-buildkite-plugin
This plugin will support transparent downloading and preparation of JLLs for sourcing binary dependencies for your buildkite steps.

## Usage

Usage example:
```
steps:
  - label: "run code"
    plugins:
      - JuliaCI/julia#v1:v
          version: 1
      - staticfloat/sandbox#v1:
          rootfs_url: "https://github.com/staticfloat/Sandbox.jl/releases/download/debian-minimal-927c9e7f/debian_minimal.tar.gz"
          rootfs_treehash: "5b44fab874ec426cad9b80b7dffd2b3f927c9e7f"
      - JuliaCI/jack#v1:
          install:
            # Install a precise version of `make_jll`
            - "make_jll#v1.0.0+0"
            # Just grab the latest version of FFMPEG_jll that we can find
            - "FFMPEG_jll"
    commands: |
      make --version
      ffmpeg --version
```

## Implementation

Internally, this plugin uses `julia` to download all the necessary JLLs using `Pkg.add()`, and then just uses [`JLLPrefixes`](https://github.com/JuliaPackaging/JLLPrefixes.jl/) to create a symlink tree for each JLL and all its dependencies in a specified prefix within the sandbox (usually in `/usr/local/bin`).
