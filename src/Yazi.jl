module Yazi

using Artifacts

export yazi_bin, yazi_explore, yazi_file, yazi_files, yazi_dir, yazi_dirs

const _EXE = Sys.iswindows() ? "yazi.exe" : "yazi"

"""
    yazi_bin() -> String

Return the path to the `yazi` binary for the current platform.
"""
yazi_bin() = joinpath(artifact"yazi", _EXE)

"""
    yazi_explore(path=pwd())

Open yazi interactively at `path`. Blocks until yazi exits.
"""
function yazi_explore(path::AbstractString=pwd())
    run(`$(yazi_bin()) $path`)
    return nothing
end

"""
    yazi_files(path=pwd()) -> Vector{String}

Open yazi as a file chooser at `path`. Returns all paths selected by the user,
or an empty vector if the user quits without selecting anything.
"""
function yazi_files(path::AbstractString=pwd())
    tmpfile = tempname()
    try
        run(`$(yazi_bin()) $path --chooser-file=$tmpfile`)
        isfile(tmpfile) || return String[]
        return filter(!isempty, readlines(tmpfile))
    finally
        isfile(tmpfile) && rm(tmpfile)
    end
end

"""
    yazi_file(path=pwd()) -> Union{String, Nothing}

Open yazi as a file chooser at `path`. Returns the first selected path,
or `nothing` if the user quits without selecting anything.
"""
function yazi_file(path::AbstractString=pwd())
    chosen = yazi_files(path)
    if isempty(chosen)
        return nothing
    end
    return first(chosen)
end

"""
    yazi_dirs(path=pwd(); containing=false) -> Vector{String}

Open yazi as a directory chooser at `path`. Returns all directories selected
by the user, or an empty vector if the user quits without selecting anything.

If `containing=true`, returns the unique parent directories of selected paths.
Selected directories are returned as-is; selected files are replaced with their
parent directory.
"""
function yazi_dirs(path::AbstractString=pwd(); containing::Bool=false)
    if containing
        return unique(map(p -> isdir(p) ? p : dirname(p), yazi_files(path)))
    end
    return filter(isdir, yazi_files(path))
end

"""
    yazi_dir(path=pwd(); containing=false) -> Union{String, Nothing}

Open yazi as a directory chooser at `path`. Returns the first selected
directory, or `nothing` if the user quits without selecting anything.

If `containing=true`, opens a file chooser instead and returns the parent
directory of the selected file.
"""
function yazi_dir(path::AbstractString=pwd(); containing::Bool=false)
    chosen = yazi_dirs(path; containing)
    return isempty(chosen) ? nothing : first(chosen)
end

end # module Yazi
