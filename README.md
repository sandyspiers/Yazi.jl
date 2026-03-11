# Yazi.jl

This package provides a thin Julia wrapper around the fantastic terminal file manager [yazi](https://yazi-rs.github.io/). The yazi binary is bundled as a Julia artifact — no separate installation required.

## Installation

Currently, this package is not registered, so you need to use the following to install:

```julia
using Pkg
Pkg.add(url="https://github.com/sandyspiers/Yazi.jl")
```

## Usage

```julia
using Yazi

# Explore interactively (blocks until yazi exits)
yazi_explore()                  # current directory
yazi_explore("/some/other/dir") # specific path

# Pick files
file  = yazi_file()             # pick one  → String or nothing
files = yazi_files()            # pick many → Vector{String}

# Pick directories
dir  = yazi_dir()               # pick one  → String or nothing
dirs = yazi_dirs()              # pick many → Vector{String}

# Use containing=true to pick files but return their parent directories
dir  = yazi_dir(containing=true)
dirs = yazi_dirs(containing=true)

# Including a batch of files in the REPL,
# that you can choose using Yazi
include.(yazi_files())
```

## Updating yazi

Updating is handeled by github runners,
so all you need to do is update the yazi version in `Project.toml`,
and then wait for github to create the release and update the `Artifacts.toml`.
