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

Base.close(archive::Writer) =
    @_la_call(archive_write_close, (Ptr{Void},), archive)

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

set_bytes_per_block(archive::Writer, bytes_per_block) =
    @_la_call(archive_write_set_bytes_per_block, (Ptr{Void}, Cint),
              archive, bytes_per_block)
get_bytes_per_block(archive::Writer) =
    ccall((:archive_write_get_bytes_per_block, libarchive),
          Cint, (Ptr{Void},), archive)

set_bytes_in_last_block(archive::Writer, bytes_in_last_block) =
    @_la_call(archive_write_set_bytes_in_last_block, (Ptr{Void}, Cint),
              archive, bytes_in_last_block)
get_bytes_in_last_block(archive::Writer) =
    ccall((:archive_write_get_bytes_in_last_block, libarchive),
          Cint, (Ptr{Void},), archive)

"""
The dev/ino of a file that won't be archived. This is used
to avoid recursively adding an archive to itself.
"""
set_skip_file(archive::Writer, dev, ino) =
    @_la_call(archive_write_set_skip_file, (Ptr{Void}, Int64, Int64),
              archive, dev, ino)

###
# Open filename

immutable WriteFileName{T}
    name::T
end

file_writer(fname=nothing) =
    Writer(WriteFileName(fname))

function do_open{T}(archive::Writer{WriteFileName{T}})
    data = archive.data
    @_la_call(archive_write_open_filename, (Ptr{Void}, Cstring),
              archive, data.name)
end

function do_open(archive::Writer{WriteFileName{Void}})
    @_la_call(archive_write_open_filename, (Ptr{Void}, Ptr{Void}),
              archive, C_NULL)
end

immutable WriteFD
    fd::Cint
end

file_writer{T<:Integer}(fd::T) =
    Writer(WriteFD(Cint(fd)))

function do_open(archive::Writer{WriteFD})
    data = archive.data
    @_la_call(archive_write_open_fd, (Ptr{Void}, Cint), archive, data.fd)
end

###
# Open memory

immutable WriteMemory{T}
    data::T
    used::typeof(Ref{Csize_t}())
end

mem_writer(data) = Writer(WriteMemory(data, Ref(Csize_t(0))))

function do_open{T}(archive::Writer{WriteMemory{T}})
    data = archive.data.data
    @_la_call(archive_write_open_memory,
              (Ptr{Void}, Ptr{Void}, Csize_t, Ptr{Csize_t}),
              archive, data, sizeof(data), archive.data.used)
end

get_used{T}(archive::Writer{WriteMemory{T}}) = archive.data.used[]

###
# Generic writer

immutable GenericWriteData{T}
    data::T
end

gen_writer{T}(data::T) = Writer(GenericWriteData{T}(data))

writer_open(archive::Writer, data) = nothing
function writer_writebytes end
writer_close(archive::Writer, data) = nothing

function writer_open_callback{T}(c_archive::Ptr{Void},
                                 jl_archive::Ptr{Writer{GenericWriteData{T}}})
    status = check_objptr(jl_archive, c_archive)
    status != Status.OK && return status
    archive = unsafe_pointer_to_objref(jl_archive)::Writer{GenericWriteData{T}}
    try
        clear_error(archive)
        writer_open(archive, archive.data.data)
        return errno(archive) == 0 ? Cint(0) : Status.WARN
    catch ex
        return set_exception(archive, ex)
    end
end

function writer_write_callback{T}(c_archive::Ptr{Void},
                                  jl_archive::Ptr{Writer{GenericWriteData{T}}},
                                  buff::Ptr{Void}, length::Csize_t)
    check_objptr(jl_archive, c_archive) != Status.OK && return Cssize_t(0)
    archive = unsafe_pointer_to_objref(jl_archive)::Writer{GenericWriteData{T}}
    try
        clear_error(archive)
        ary = pointer_to_array(Ptr{UInt8}(buff), length)
        return writer_writebytes(archive, archive.data.data, ary)
    catch ex
        set_exception(archive, ex)
        return Cssize_t(-1)
    end
end

function writer_close_callback{T}(c_archive::Ptr{Void},
                                  jl_archive::Ptr{Writer{GenericWriteData{T}}})
    status = check_objptr(jl_archive, c_archive)
    status != Status.OK && return status
    archive = unsafe_pointer_to_objref(jl_archive)::Writer{GenericWriteData{T}}
    try
        clear_error(archive)
        writer_close(archive, archive.data.data)
        return errno(archive) == 0 ? Cint(0) : Status.WARN
    catch ex
        return set_exception(archive, ex)
    end
end

writer_writebytes(archive, io::IO, ary) = write(io, ary)

function do_open{T<:GenericWriteData}(archive::Writer{T})
    @_la_call(archive_write_open,
              (Ptr{Void}, Any, Ptr{Void}, Ptr{Void}, Ptr{Void}),
              archive, archive,
              to_open_callback(writer_open_callback, Writer{T}),
              to_write_callback(writer_write_callback, Writer{T}),
              to_close_callback(writer_close_callback, Writer{T}))
end

function write_header(archive::Writer, entry::Entry)
    ensure_open(archive)
    @_la_call(archive_write_header, (Ptr{Void}, Ptr{Void}), archive, entry)
end

function write_data(archive::Writer, data)
    ensure_open(archive)
    ccall((:archive_write_data, libarchive),
          Cssize_t, (Ptr{Void}, Ptr{Void}, Csize_t),
          archive, data, sizeof(data))
end

function finish_entry(archive::Writer)
    ensure_open(archive)
    @_la_call(archive_write_finish_entry, (Ptr{Void},), archive)
end

"""
Marks the archive as FATAL so that a subsequent free() operation
won't try to close() cleanly.  Provides a fast abort capability
when the client discovers that things have gone wrong.
"""
write_fail(archive::Writer) =
    @_la_call(archive_write_fail, (Ptr{Void},), archive)
