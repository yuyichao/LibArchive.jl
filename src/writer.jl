###
# Creating an archive
#
# To create an archive in C:
#     1. Ask `archive_write_new` for an archive writer object.
#     2. Set any global properties. In particular, you should set
#        the compression and format to use.
#     3. Call `archive_write_open` to open the file (most people
#         will use `archive_write_open_file` or `archive_write_open_fd`,
#         which provide convenient canned I/O callbacks for you).
#     4. For each entry:
#         * construct an appropriate `struct archive_entry` structure
#         * `archive_write_header` to write the header
#         * `archive_write_data` to write the entry data
#     5. `archive_write_close` to close the output
#     6. `archive_write_free` to cleanup the writer and release resources
#
# To create an archive in Julia:
#     1. Create a LibArchive.Writer
#     2. Set any global properties. In particular, you should set
#        the compression and format to use.
#     3. Write each entries. LibArchive.jl will call libarchive
#        open functions if needed.
#     4. Call LibArchive.free to end processing.

type Writer{T} <: Archive
    ptr::Ptr{Void}
    data::T
    opened::Bool
    function Writer(data::T)
        ptr = ccall((:archive_write_new, libarchive), Ptr{Void}, ())
        ptr == C_NULL && throw(OutOfMemoryError())
        obj = new(ptr, data, false)
        finalizer(obj, free)
        obj
    end
end
Writer{T}(data::T) = Writer{T}(data)

function free(archive::Writer)
    ptr = archive.ptr
    ptr == C_NULL && return
    ccall((:archive_write_free, libarchive), Cint, (Ptr{Void},), ptr)
    archive.ptr = C_NULL
    nothing
end

function Base.cconvert(::Type{Ptr{Void}}, archive::Writer)
    archive.ptr == C_NULL && error("archive already freed")
    archive
end
Base.unsafe_convert(::Type{Ptr{Void}}, archive::Writer) = archive.ptr

function ensure_open(archive::Writer)
    archive.opened && return
    archive.opened = true
    try
        do_open(archive)
    catch
        archive.opened = false
        rethrow()
    end
    nothing
end
