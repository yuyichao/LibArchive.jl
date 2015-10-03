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
#
# Basic outline for reading an archive in Julia:
#     1. Create a LibArchive.Reader
#     2. Update any global properties as appropriate.
#        In particular, you'll certainly want to call appropriate
#        LibArchive.support_XXX functions.
#     3. Read the entries (API TBD). LibArchive.jl will call libarchive
#        open functions if needed.
#     4. Call LibArchive.free to end processing.

type Reader{T} <: Archive
    ptr::Ptr{Void}
    data::T
    opened::Bool
    function Reader(data::T)
        ptr = ccall((:archive_read_new, libarchive), Ptr{Void}, ())
        ptr == C_NULL && throw(OutOfMemoryError())
        obj = new(ptr, data, false)
        finalizer(obj, free)
        obj
    end
end

Reader{T}(data::T) = Reader{T}(data)

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

function ensure_open(archive::Reader)
    archive.opened && return
    archive.opened = true
    do_open(archive)
    nothing
end

###
# Open filename

immutable ReadFileName{T}
    name::T
    block_size::Int
end

file_reader(fname=nothing, block_size=10240) =
    Reader(ReadFileName(fname, Int(block_size)))

function do_open{T}(archive::Reader{ReadFileName{T}})
    data = archive.data
    @_la_call(archive_read_open_filename, (Ptr{Void}, Cstring, Csize_t),
              archive, data.name, data.block_size)
end

function do_open(archive::Reader{ReadFileName{Void}})
    data = archive.data
    @_la_call(archive_read_open_filename, (Ptr{Void}, Ptr{Void}, Csize_t),
              archive, C_NULL, data.block_size)
end

immutable ReadFD
    fd::Cint
    block_size::Int
end

file_reader{T<:Integer}(fd::T, block_size=10240) =
    Reader(ReadFD(Cint(fd), Int(block_size)))

function do_open(archive::Reader{ReadFD})
    data = archive.data
    @_la_call(archive_read_open_fd, (Ptr{Void}, Cint, Csize_t),
              archive, data.fd, data.block_size)
end

###
# Open memory

immutable ReadMemory{T}
    data::T
end

mem_reader(data) = Reader(ReadMemory(data))

function do_open{T}(archive::Reader{ReadMemory{T}})
    data = archive.data.data
    @_la_call(archive_read_open_memory, (Ptr{Void}, Ptr{Void}, Csize_t),
              archive, data, sizeof(data))
end
