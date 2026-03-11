# Generates Artifacts.toml for Yazi.jl
#
# For each platform, downloads the upstream yazi zip, repacks the binary
# directory as a .tar.gz, uploads it to this repo's GitHub release, then
# writes an Artifacts.toml entry pointing at that tarball.
#
# Requires: gh CLI authenticated with write access to this repo.
# Run with: julia scripts/yazi.jl

using Downloads: download
using SHA
using Pkg
using Pkg.Artifacts: bind_artifact!
using Base.BinaryPlatforms
using TOML

const _project = TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))
const YAZI_VERSION = "v" * _project["yazi_version"]
const UPSTREAM_URL = "https://github.com/sxyazi/yazi/releases/download/$YAZI_VERSION"
const ARTIFACT_TOML = joinpath(@__DIR__, "..", "Artifacts.toml")

# This repo — where repacked tarballs are uploaded
const THIS_REPO = "sandyspiers/Yazi.jl"
const HOSTED_URL = "https://github.com/$THIS_REPO/releases/download/$YAZI_VERSION"

const PLATFORMS = [
    ("yazi-x86_64-unknown-linux-gnu",  Platform("x86_64",  "linux")),
    ("yazi-aarch64-unknown-linux-gnu", Platform("aarch64", "linux")),
    ("yazi-x86_64-apple-darwin",       Platform("x86_64",  "macos")),
    ("yazi-aarch64-apple-darwin",      Platform("aarch64", "macos")),
    ("yazi-x86_64-pc-windows-msvc",    Platform("x86_64",  "windows")),
]

println("Creating GitHub release $YAZI_VERSION on $THIS_REPO ...")
run(`gh release create $YAZI_VERSION --repo $THIS_REPO --title "yazi $YAZI_VERSION" --notes "Repacked yazi $YAZI_VERSION binaries for Julia artifact system."`)

mktempdir() do tmpdir
    for (stem, platform) in PLATFORMS
        println("\n[$stem]")

        # Download upstream zip
        zip_name = "$stem.zip"
        zip_path = joinpath(tmpdir, zip_name)
        println("  Downloading $zip_name ...")
        download("$UPSTREAM_URL/$zip_name", zip_path)

        # Extract; zip contains a single subdirectory named after the stem
        extract_dir = joinpath(tmpdir, stem * "_extract")
        mkpath(extract_dir)
        run(`unzip -q $zip_path -d $extract_dir`)
        binary_dir = joinpath(extract_dir, stem)

        # Repack the binary directory contents (not the directory itself)
        # so the artifact root contains the binaries directly
        tarball_name = "$stem.tar.gz"
        tarball_path = joinpath(tmpdir, tarball_name)
        run(`tar -czf $tarball_path -C $binary_dir .`)

        # Compute hashes of the repacked tarball
        file_sha256 = open(io -> bytes2hex(sha256(io)), tarball_path)
        tree_bytes  = Pkg.GitTools.tree_hash(SHA.SHA1_CTX, binary_dir)
        tree_sha1   = Pkg.Types.SHA1(tree_bytes)

        println("  sha256:        $file_sha256")
        println("  git-tree-sha1: $(bytes2hex(tree_bytes))")

        # Upload tarball to this repo's release
        hosted_url = "$HOSTED_URL/$tarball_name"
        println("  Uploading to $hosted_url ...")
        run(`gh release upload $YAZI_VERSION $tarball_path --repo $THIS_REPO`)

        bind_artifact!(
            ARTIFACT_TOML,
            "yazi",
            tree_sha1;
            platform      = platform,
            download_info = [(hosted_url, file_sha256)],
            lazy          = false,
            force         = true,
        )
        println("  Bound for $(triplet(platform))")
    end
end

println("\nArtifacts.toml written to $ARTIFACT_TOML")
