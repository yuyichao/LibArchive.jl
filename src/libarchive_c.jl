#

const depfile = joinpath(dirname(@__FILE__),"..","deps","deps.jl")
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
    major = vernum ÷ 1000_000
    vernum -= major * 1000_000
    minor = vernum ÷ 1000
    vernum -= minor * 1000
    VersionNumber(major, minor, vernum)
end

abstract Archive

include("error.jl")
include("callback.jl")
include("archive_utils.jl")
include("entry.jl")
include("reader.jl")
include("writer.jl")
include("format.jl")
