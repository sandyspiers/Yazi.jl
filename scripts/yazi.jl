# Generates Artifacts.toml for Yazi.jl
# Downloads pre-built yazi binaries from GitHub releases, computes hashes,
# and writes Artifacts.toml entries pointing back at the release URLs.
#
# Run with: julia scripts/yazi.jl

using Downloads: download
using SHA
using Pkg
using Pkg.Artifacts: bind_artifact!
using Base.BinaryPlatforms
using TOML

const _project_toml = TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
const YAZI_VERSION = "v" * _project_toml["yazi_version"]
const BASE_URL = "https://github.com/sxyazi/yazi/releases/download/$YAZI_VERSION"
const ARTIFACT_TOML = joinpath(@__DIR__, "..", "Artifacts.toml")

const PLATFORMS = [
    ("yazi-x86_64-unknown-linux-gnu", Platform("x86_64", "linux")),
    ("yazi-aarch64-unknown-linux-gnu", Platform("aarch64", "linux")),
    ("yazi-x86_64-apple-darwin", Platform("x86_64", "macos")),
    ("yazi-aarch64-apple-darwin", Platform("aarch64", "macos")),
    ("yazi-x86_64-pc-windows-msvc", Platform("x86_64", "windows")),
]

mktempdir() do tmpdir
    for (stem, platform) in PLATFORMS
        archive = "$stem.zip"
        url = "$BASE_URL/$archive"
        archive_path = joinpath(tmpdir, archive)

        println("[$stem]")
        println("  Downloading...")
        download(url, archive_path)

        # sha256 of the downloaded archive file
        file_sha256 = open(io -> bytes2hex(sha256(io)), archive_path)

        # the zip contains a single subdirectory named after the stem
        extract_dir = joinpath(tmpdir, stem)
        mkpath(extract_dir)
        run(`unzip -q $archive_path -d $extract_dir`)

        # Compute git-tree-sha1 of the binary subdirectory (not the zip root)
        binary_dir = joinpath(extract_dir, stem)
        tree_bytes = Pkg.GitTools.tree_hash(SHA.SHA1_CTX, binary_dir)
        tree_sha1 = Pkg.Types.SHA1(tree_bytes)

        println("  sha256:        $file_sha256")
        println("  git-tree-sha1: $(bytes2hex(tree_bytes))")

        bind_artifact!(
            ARTIFACT_TOML,
            "yazi",
            tree_sha1;
            platform=platform,
            download_info=[(url, file_sha256)],
            lazy=false,
            force=true,
        )
        println("  Bound for $(triplet(platform))\n")
    end
end

println("Artifacts.toml written to $ARTIFACT_TOML")
