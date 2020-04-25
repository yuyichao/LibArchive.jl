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

abstract type WriterData end

mutable struct Writer{T<:WriterData} <: Archive
    data::T
    ptr::Ptr{Cvoid}
    opened::Bool
    function Writer{T}(data::T) where T
        ptr = ccall((:archive_write_new, libarchive), Ptr{Cvoid}, ())
        ptr == C_NULL && throw(OutOfMemoryError())
        obj = new(data, ptr, false)
        finalizer(obj, free)
        obj
    end
end

Writer(data::T) where {T<:WriterData} = Writer{T}(data)

function free(archive::Writer)
    ptr = archive.ptr
    ptr == C_NULL && return
    ccall((:archive_write_free, libarchive), Cint, (Ptr{Cvoid},), ptr)
    archive.ptr = C_NULL
    nothing
end

Base.close(archive::Writer) =
    @_la_call(archive_write_close, (Ptr{Cvoid},), archive)

function Base.cconvert(::Type{Ptr{Cvoid}}, archive::Writer)
    archive.ptr == C_NULL && error("archive already freed")
    archive
end
Base.unsafe_convert(::Type{Ptr{Cvoid}}, archive::Writer) = archive.ptr

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
    @_la_call(archive_write_set_bytes_per_block, (Ptr{Cvoid}, Cint),
              archive, bytes_per_block)
get_bytes_per_block(archive::Writer) =
    ccall((:archive_write_get_bytes_per_block, libarchive),
          Cint, (Ptr{Cvoid},), archive)

set_bytes_in_last_block(archive::Writer, bytes_in_last_block) =
    @_la_call(archive_write_set_bytes_in_last_block, (Ptr{Cvoid}, Cint),
              archive, bytes_in_last_block)
get_bytes_in_last_block(archive::Writer) =
    ccall((:archive_write_get_bytes_in_last_block, libarchive),
          Cint, (Ptr{Cvoid},), archive)

"""
The dev/ino of a file that won't be archived. This is used
to avoid recursively adding an archive to itself.
"""
set_skip_file(archive::Writer, dev, ino) =
    @_la_call(archive_write_set_skip_file, (Ptr{Cvoid}, Int64, Int64),
              archive, dev, ino)

###
# Open filename

struct WriteFileName{T} <: WriterData
    name::T
end

Writer(fname::AbstractString) = Writer(WriteFileName(fname))
Writer() = Writer(WriteFileName(nothing))

function do_open(archive::Writer{WriteFileName{T}}) where T
    data = archive.data
    @_la_call(archive_write_open_filename, (Ptr{Cvoid}, Cstring),
              archive, data.name)
end

function do_open(archive::Writer{WriteFileName{Cvoid}})
    @_la_call(archive_write_open_filename, (Ptr{Cvoid}, Ptr{Cvoid}),
              archive, C_NULL)
end

struct WriteFD <: WriterData
    fd::Cint
end

Writer(fd::T) where {T<:Integer} = Writer(WriteFD(Cint(fd)))

function do_open(archive::Writer{WriteFD})
    data = archive.data
    @_la_call(archive_write_open_fd, (Ptr{Cvoid}, Cint), archive, data.fd)
end

###
# Open memory

struct WriteMemory{T,TO} <: WriterData
    ptr::T
    obj::TO # Reference for GC
    size::Csize_t
    used::typeof(Ref{Csize_t}())
end

Writer(ptr::T, size, obj::TO=nothing) where {T<:Ptr,TO} =
    Writer(WriteMemory{T,TO}(ptr, obj, size, Ref(Csize_t(0))))
Writer(ary::Vector, size=sizeof(ary)) = Writer(pointer(ary), size, ary)

Base.unsafe_convert(::Type{Ptr{Cvoid}}, mem_data::WriteMemory) = mem_data.ptr

function do_open(archive::Writer{T}) where {T<:WriteMemory}
    data = archive.data
    @_la_call(archive_write_open_memory,
              (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t, Ptr{Csize_t}),
              archive, data, data.size, data.used)
end

get_used(archive::Writer{T}) where {T<:WriteMemory} = archive.data.used[]

###
# Generic writer

struct GenericWriteData{T} <: WriterData
    data::T
end

Writer(data::T) where {T} = Writer(GenericWriteData{T}(data))

writer_open(archive::Writer, data) = nothing
function writer_writebytes end
writer_close(archive::Writer, data) = nothing

function writer_open_callback(c_archive, archive)
    try
        clear_error(archive)
        writer_open(archive, archive.data.data)
        return Libc.errno(archive) == 0 ? Cint(0) : Status.WARN
    catch ex
        return set_exception(archive, ex)
    end
end

function writer_write_callback(c_archive, archive, buff::Ptr{Cvoid},
                               length::Csize_t)
    try
        clear_error(archive)
        ary = unsafe_wrap(Array, Ptr{UInt8}(buff), length)
        return Cssize_t(writer_writebytes(archive, archive.data.data, ary))
    catch ex
        set_exception(archive, ex)
        return Cssize_t(-1)
    end
end

function writer_close_callback(c_archive, archive)
    try
        clear_error(archive)
        writer_close(archive, archive.data.data)
        return Libc.errno(archive) == 0 ? Cint(0) : Status.WARN
    catch ex
        return set_exception(archive, ex)
    end
end

writer_writebytes(archive, io::IO, ary) = write(io, ary)

function do_open(archive::Writer{T}) where {T<:GenericWriteData}
    @_la_call(archive_write_open,
              (Ptr{Cvoid}, Any, Ptr{Cvoid}, Ptr{Cvoid}, Ptr{Cvoid}),
              archive, archive,
              @to_open_callback(writer_open_callback, Writer{T}),
              @to_write_callback(writer_write_callback, Writer{T}),
              @to_close_callback(writer_close_callback, Writer{T}))
end

function write_header(archive::Writer, entry::Entry)
    ensure_open(archive)
    @_la_call(archive_write_header, (Ptr{Cvoid}, Ptr{Cvoid}), archive, entry)
end

@inline function unsafe_archive_write(archive::Writer, buf, len)
    ensure_open(archive)
    nb = ccall((:archive_write_data, libarchive),
               Cssize_t, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t), archive, buf, len)
    nb < 0 && _la_error(Cint(nb), archive)
    nb % Csize_t
end

unsafe_write(archive::Writer, buf::Ptr{UInt8}, len::UInt) =
    unsafe_archive_write(archive, buf, len)
Base.write(archive::Writer, c::UInt8) =
    unsafe_archive_write(archive, Ref(c), 1)

function finish_entry(archive::Writer)
    ensure_open(archive)
    @_la_call(archive_write_finish_entry, (Ptr{Cvoid},), archive)
end

"""
Marks the archive as FATAL so that a subsequent free() operation
won't try to close() cleanly.  Provides a fast abort capability
when the client discovers that things have gone wrong.
"""
write_fail(archive::Writer) =
    @_la_call(archive_write_fail, (Ptr{Cvoid},), archive)

Writer(f::Function) = archive_guard(f, Writer())
Writer(f::Function, args...; kws...) =
    archive_guard(f, Writer(args...; kws...))

# /*
#  * Set write options.
#  */
# /* Apply option to the format only. */
# int archive_write_set_format_option(struct archive *_a,
# 			    const char *m, const char *o,
# 			    const char *v);
# /* Apply option to the filter only. */
# int archive_write_set_filter_option(struct archive *_a,
# 			    const char *m, const char *o,
# 			    const char *v);
# /* Apply option to both the format and the filter. */
# int archive_write_set_option(struct archive *_a,
# 			    const char *m, const char *o,
# 			    const char *v);
# /* Apply option string to both the format and the filter. */
# int archive_write_set_options(struct archive *_a,
# 			    const char *opts);

# /* This interface is currently only available for archive_write_disk handles.  */
# ssize_t	 archive_write_data_block(struct archive *,
# 				    const void *, size_t, int64_t);
