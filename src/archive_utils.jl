###
# Various utility libarchive functions

##
# Accessor functions to read/set various information in
# the struct archive object:

"""
Number of filters in the current filter pipeline.
Filter #0 is the one closest to the format, -1 is a synonym for the
last filter, which is always the pseudo-filter that wraps the
client callbacks.
"""
filter_count(archive::Archive) =
    ccall((:archive_filter_count, libarchive), Cint, (Ptr{Void},), archive)
filter_bytes(archive::Archive, n) =
    ccall((:archive_filter_bytes, libarchive), Int64, (Ptr{Void}, Cint),
          archive, n)
filter_code(archive::Archive, n) =
    ccall((:archive_filter_code, libarchive), Cint, (Ptr{Void}, Cint),
          archive, n)
filter_name(archive::Archive, n) =
    unsafe_string(ccall((:archive_filter_name, libarchive),
                        Ptr{UInt8}, (Ptr{Void}, Cint), archive, n))

Libc.errno(archive::Archive) =
    ccall((:archive_errno, libarchive), Cint, (Ptr{Void},), archive)
function error_string(archive::Archive)
    cstr = ccall((:archive_error_string, libarchive),
                 Ptr{UInt8}, (Ptr{Void},), archive)
    cstr == C_NULL ? "" : unsafe_string(cstr)
end
format_name(archive::Archive) =
    unsafe_string(ccall((:archive_format_name, libarchive),
                        Ptr{UInt8}, (Ptr{Void},), archive))
format(archive::Archive) =
    ccall((:archive_format, libarchive), Cint, (Ptr{Void},), archive)
clear_error(archive::Archive) =
    ccall((:archive_clear_error, libarchive), Void, (Ptr{Void},), archive)
set_error(archive::Archive, code, msg) =
    ccall((:archive_set_error, libarchive),
          Void, (Ptr{Void}, Cint, Ptr{Cchar}, Cstring), archive, code, "%s", msg)
copy_error(dest::Archive, src::Archive) =
    ccall((:archive_copy_error, libarchive),
          Void, (Ptr{Void}, Ptr{Void}), dest, src)
file_count(archive::Archive) =
    ccall((:archive_file_count, libarchive), Cint, (Ptr{Void},), archive)

function set_exception(archive::Archive, ex::ANY)
    status, msg = if isa(ex, EOFError)
        Status.EOF, "end of file"
    elseif isa(ex, ArchiveRetry)
        Status.RETRY, (ex::ArchiveRetry).msg
    elseif isa(ex, ArchiveFailed)
        Status.FAILED, (ex::ArchiveFailed).msg
    elseif isa(ex, ArchiveFatal)
        Status.FATAL, (ex::ArchiveFatal).msg
    else
        Status.FAILED, string(ex)
    end
    # Only set error if there isn't already one
    Libc.errno(archive) == 0 && set_error(archive, status, msg)
    status
end
