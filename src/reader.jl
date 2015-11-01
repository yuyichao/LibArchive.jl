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
    ptr == C_NULL && return
    ccall((:archive_read_free, libarchive), Cint, (Ptr{Void},), ptr)
    archive.ptr = C_NULL
    nothing
end

Base.close(archive::Reader) =
    @_la_call(archive_read_close, (Ptr{Void},), archive)

function Base.cconvert(::Type{Ptr{Void}}, archive::Reader)
    archive.ptr == C_NULL && error("archive already freed")
    archive
end
Base.unsafe_convert(::Type{Ptr{Void}}, archive::Reader) = archive.ptr

function ensure_open(archive::Reader)
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

# """
# Use this for reading multivolume files by filenames.
# NOTE: Must be NULL terminated. Sorting is NOT done.
# """
# int archive_read_open_filenames(struct archive*,
#                                 const char **_filenames, size_t block_size)

###
# Open memory

immutable ReadMemory{T}
    data::T
    size::Int
end

mem_reader{T}(data::T, size=sizeof(data)) = Reader(ReadMemory{T}(data, size))

function do_open{T}(archive::Reader{ReadMemory{T}})
    data = archive.data
    @_la_call(archive_read_open_memory, (Ptr{Void}, Ptr{Void}, Csize_t),
              archive, data.data, data.size)
end

###
# Generic reader

immutable GenericReadData{T}
    data::T
    buff::Vector{UInt8}
end

gen_reader{T}(data::T, buff_size=10240) =
    Reader(GenericReadData{T}(data, Vector{UInt8}(buff_size)))

reader_open(archive::Reader, data) = nothing
function reader_readbytes end
function reader_skip end
function reader_seek end
reader_close(archive::Reader, data) = nothing

function reader_open_callback{T}(c_archive::Ptr{Void},
                                 jl_archive::Ptr{Reader{GenericReadData{T}}})
    status = check_objptr(jl_archive, c_archive)
    status != Status.OK && return status
    archive = unsafe_pointer_to_objref(jl_archive)::Reader{GenericReadData{T}}
    try
        clear_error(archive)
        reader_open(archive, archive.data.data)
        return errno(archive) == 0 ? Cint(0) : Status.WARN
    catch ex
        return set_exception(archive, ex)
    end
end

function reader_read_callback{T}(c_archive::Ptr{Void},
                                 jl_archive::Ptr{Reader{GenericReadData{T}}},
                                 buff::Ptr{Ptr{Void}})
    check_objptr(jl_archive, c_archive) != Status.OK && return Cssize_t(0)
    archive = unsafe_pointer_to_objref(jl_archive)::Reader{GenericReadData{T}}
    try
        clear_error(archive)
        bytes_read = reader_readbytes(archive, archive.data.data,
                                      archive.data.buff)
        unsafe_store!(buff, pointer(archive.data.buff))
        return Cssize_t(bytes_read)
    catch ex
        set_exception(archive, ex)
        return Cssize_t(0)
    end
end

function reader_skip_callback{T}(c_archive::Ptr{Void},
                                 jl_archive::Ptr{Reader{GenericReadData{T}}},
                                 request)
    check_objptr(jl_archive, c_archive) != Status.OK && return Int64(0)
    archive = unsafe_pointer_to_objref(jl_archive)::Reader{GenericReadData{T}}
    try
        clear_error(archive)
        return Int64(reader_skip(archive, archive.data.data, request))
    catch ex
        set_exception(archive, ex)
        return Int64(0)
    end
end

function reader_seek_callback{T}(c_archive::Ptr{Void},
                                 jl_archive::Ptr{Reader{GenericReadData{T}}},
                                 request, whence)
    check_objptr(jl_archive, c_archive) != Status.OK && return Int64(0)
    archive = unsafe_pointer_to_objref(jl_archive)::Reader{GenericReadData{T}}
    try
        clear_error(archive)
        return Int64(reader_seek(archive, archive.data.data, request, whence))
    catch ex
        set_exception(archive, ex)
        return Int64(0)
    end
end

function reader_close_callback{T}(c_archive::Ptr{Void},
                                 jl_archive::Ptr{Reader{GenericReadData{T}}})
    status = check_objptr(jl_archive, c_archive)
    status != Status.OK && return status
    archive = unsafe_pointer_to_objref(jl_archive)::Reader{GenericReadData{T}}
    try
        clear_error(archive)
        reader_close(archive, archive.data.data)
        return errno(archive) == 0 ? Cint(0) : Status.WARN
    catch ex
        return set_exception(archive, ex)
    end
end

reader_readbytes(archive, io::IO, buff) =
    readbytes!(io, buff)
reader_skip(archive, io::IO, sz) =
    (skip(io, sz); sz)

function do_open{T<:GenericReadData}(archive::Reader{T})
    # Set various callbacks
    @_la_call(archive_read_set_callback_data,
              (Ptr{Void}, Any), archive, archive)
    @_la_call(archive_read_set_open_callback,
              (Ptr{Void}, Ptr{Void}), archive,
              to_open_callback(reader_open_callback, Reader{T}))
    @_la_call(archive_read_set_read_callback,
              (Ptr{Void}, Ptr{Void}), archive,
              to_read_callback(reader_read_callback, Reader{T}))
    @_la_call(archive_read_set_seek_callback,
              (Ptr{Void}, Ptr{Void}), archive,
              to_seek_callback(reader_seek_callback, Reader{T}))
    @_la_call(archive_read_set_skip_callback,
              (Ptr{Void}, Ptr{Void}), archive,
              to_skip_callback(reader_skip_callback, Reader{T}))
    @_la_call(archive_read_set_close_callback,
              (Ptr{Void}, Ptr{Void}), archive,
              to_close_callback(reader_close_callback, Reader{T}))
    @_la_call(archive_read_open1, (Ptr{Void},), archive)
end

function next_header(archive::Reader)
    ensure_open(archive)
    entry = Entry(archive)
    @_la_call(archive_read_next_header2, (Ptr{Void}, Ptr{Void}),
              archive, entry)
    entry
end

"""
Retrieve the byte offset in UNCOMPRESSED data where last-read
header started.
"""
header_position(archive::Reader) =
    ccall((:archive_read_header_position, libarchive),
          Int64, (Ptr{Void},), archive)

"Read data from the body of an entry.  Similar to read(2)."
Base.readbytes!(archive::Reader, b::Vector{UInt8}, nb=length(b)) =
    ccall((:archive_read_data, libarchive), Cssize_t,
          (Ptr{Void}, Ptr{Void}, Csize_t), archive, b, nb)

"Seek within the body of an entry.  Similar to lseek(2)."
Base.seek(archive::Reader, offset, what) =
    ccall((:archive_seek_data, libarchive), Int64,
          (Ptr{Void}, Int64, Cint), archive, offset, what)

"Skips entire entry"
Base.skip(archive::Reader) =
    @_la_call(archive_read_data_skip, (Ptr{Void},), archive)

"Writes data to specified filedes"
read_into_fd(archive::Reader, fd::Integer) =
    @_la_call(archive_read_data_into_fd, (Ptr{Void}, Cint), archive, fd)
