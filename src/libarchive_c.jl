#

include("../deps/deps.jl")
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

include("error.jl")
include("callback.jl")
include("reader.jl")
include("format.jl")
