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

include("error.jl")
include("callback.jl")
include("archive_utils.jl")
include("entry.jl")
include("reader.jl")
include("writer.jl")
include("format.jl")

end
