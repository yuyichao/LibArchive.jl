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
    bytestring(ccall((:archive_filter_name, libarchive),
                     Cstring, (Ptr{Void}, Cint), archive, n))

Base.errno(archive::Archive) =
    ccall((:archive_errno, libarchive), Cint, (Ptr{Void},), archive)
error_string(archive::Archive) =
    bytestring(ccall((:archive_error_string, libarchive),
                     Cstring, (Ptr{Void},), archive))
format_name(archive::Archive) =
    bytestring(ccall((:archive_format_name, libarchive),
                     Cstring, (Ptr{Void},), archive))
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
    ccall((:archive_file_count, libarchive), Void, (Ptr{Void},), archive)

function check_objptr{T}(ptr::Ptr{T}, c_archive::Ptr{Void})
    if !isa(unsafe_pointer_to_objref(ptr), T)
        ccall((:archive_set_error, libarchive),
              Void, (Ptr{Void}, Cint, Ptr{Cchar}),
              c_archive, Status.FAILED, "TypeError")
        return Status.FAILED
    end
    return Status.OK
end

function set_exception(archive::Archive, ex::ANY)
    status, msg = if isa(ex, EOFError)
        Status.EOF, "end of file"
    elseif isa(ex, ArchiveRetry)
        Status.RETRY, ""
    elseif isa(ex, ArchiveWarn)
        Status.WARN, ""
    elseif isa(ex, ArchiveFailed)
        Status.FAILED, ""
    elseif isa(ex, ArchiveFatal)
        Status.FATAL, ""
    else
        Status.FAILED, ""
    end
    # Only set error if there isn't already one
    errno(archive) == 0 && set_error(archive, status, msg)
    status
end
