#

# This will be changed to `Cint` in libarchive 4.0
const _la_mode_t = Cushort
const _Cdev_t = UInt64

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

abstract Archive

include("error.jl")
include("callback.jl")
include("archive_utils.jl")
include("entry.jl")
include("reader.jl")
include("writer.jl")
include("format.jl")
