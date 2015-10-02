###
# Reading an archive
#
# Basic outline for reading an archive in C:
#     1. Ask `archive_read_new` for an archive reader object.
#     2. Update any global properties as appropriate.
#        In particular, you'll certainly want to call appropriate
#        `archive_read_support_XXX` functions.
#     3. Call `archive_read_open_XXX` to open the archive
#     4. Repeatedly call `archive_read_next_header` to get information about
#        successive archive entries.  Call `archive_read_data` to extract
#        data for entries of interest.
#     5. Call `archive_read_free` to end processing.

type Reader
    ptr::Ptr{Void}
    function Reader()
        ptr = ccall((:archive_read_new, libarchive), Ptr{Void}, ())
        ptr == C_NULL && throw(OutOfMemoryError())
        obj = new(ptr)
        finalizer(obj, free)
        obj
    end
end

function free(archive::Reader)
    ptr = archive.ptr
    ptr == C_NULL && return Status.OK
    archive.ptr = C_NULL
    ccall((:archive_read_free, libarchive), Cint, (Ptr{Void},), ptr)
end

function Base.cconvert(::Type{Ptr{Void}}, archive::Reader)
    archive.ptr == C_NULL && error("archive already freed")
    archive
end
Base.unsafe_convert(::Type{Ptr{Void}}, archive::Reader) = archive.ptr
