#

__precompile__()

module LibArchive

export ArchiveRetry, ArchiveFailed, ArchiveFatal

const depfile = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(depfile)
    include(depfile)
else
    error("LibArchive not properly installed. Please run Pkg.build(\"LibArchive\")")
end

include("constants.jl")

###
# Version

"""
libarchive version number
"""
function version()
    vernum = ccall((:archive_version_number, libarchive), Cint, ())
    vernum, patch = divrem(vernum, Cint(1000))
    major, minor = divrem(vernum, Cint(1000))
    VersionNumber(major, minor, patch)
end

abstract Archive

function archive_guard(func::Function, archive::Archive)
    try
        res = func(archive)
        # Only explicitly close if the function didn't throw an error
        # otherwise, only call free to avoid overriding user exceptions
        close(archive)
        return res
    finally
        free(archive)
    end
end

include("error.jl")
include("callback.jl")
include("archive_utils.jl")
include("entry.jl")
include("reader.jl")
include("writer.jl")
include("format.jl")

end
