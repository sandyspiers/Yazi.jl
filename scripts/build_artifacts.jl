# Downloads artifacts and publishes them as a github release
using ArtifactUtils
using Base.BinaryPlatforms
using Pkg
using TOML

Pkg.instantiate()

const PROJECT_DIR = joinpath(@__DIR__, "..")
const PROJECT_TOML = joinpath(PROJECT_DIR, "Project.toml")
const ARTIFACTS_TOML = joinpath(PROJECT_DIR, "Artifacts.toml")
const PROJECT_DICT = TOML.parsefile(PROJECT_TOML)

const YAZI = "yazi"
const YAZI_VERSION = PROJECT_DICT["yazi"]["version"]
const UPSTREAM_URL = "https://github.com/sxyazi/yazi/releases/download/v$YAZI_VERSION"

const PLATFORMS = [
    ("yazi-x86_64-unknown-linux-gnu",  Platform("x86_64",  "linux")),
    ("yazi-aarch64-unknown-linux-gnu", Platform("aarch64", "linux")),
    ("yazi-x86_64-apple-darwin",       Platform("x86_64",  "macos")),
    ("yazi-aarch64-apple-darwin",      Platform("aarch64", "macos")),
    ("yazi-x86_64-pc-windows-msvc",    Platform("x86_64",  "windows")),
]

mktempdir() do tmpdir
    for (stem, platform) in PLATFORMS
        println("\n[$stem]")
        archive_name = "$stem.zip"
        archive_path = joinpath(tmpdir, archive_name)

        println("  Downloading $archive_name ...")
        download("$UPSTREAM_URL/$archive_name", archive_path)

        println("  Extracting ...")
        extract_dir = joinpath(tmpdir, stem)
        mkpath(extract_dir)
        run(`unzip -q $archive_path -d $extract_dir`)

        # Ensure execute bit is set — unzip on Linux strips it from Windows binaries
        println("  Make executable..")
        binary_dir = joinpath(extract_dir, stem)
        run(`chmod -R 755 $binary_dir`)

        println("  Publishing ...")
        artifact_id = artifact_from_directory(binary_dir)
        release = upload_to_release(artifact_id; tag="v$YAZI_VERSION")

        println("  Add artifact ...")
        add_artifact!(ARTIFACTS_TOML, YAZI, release; platform=platform, force=true)
    end
end
