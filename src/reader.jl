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

abstract type ReaderData end

mutable struct Reader{T<:ReaderData} <: Archive
    data::T
    ptr::Ptr{Cvoid}
    opened::Bool
    function Reader{T}(data::T) where T
        ptr = ccall((:archive_read_new, libarchive), Ptr{Cvoid}, ())
        ptr == C_NULL && throw(OutOfMemoryError())
        return Reader{T}(data, ptr, false)
    end
    # For pre-openned archive. (e.g. from LibALPM)
    function Reader{T}(data::T, ptr::Ptr{Cvoid}, opened::Bool) where T
        obj = new(data, ptr, opened)
        finalizer(obj, free)
        obj
    end
end

Reader(data::T) where {T<:ReaderData} = Reader{T}(data)

function free(archive::Reader)
    ptr = archive.ptr
    ptr == C_NULL && return
    ccall((:archive_read_free, libarchive), Cint, (Ptr{Cvoid},), ptr)
    archive.ptr = C_NULL
    nothing
end

Base.close(archive::Reader) =
    @_la_call(archive_read_close, (Ptr{Cvoid},), archive)

function Base.cconvert(::Type{Ptr{Cvoid}}, archive::Reader)
    archive.ptr == C_NULL && error("archive already freed")
    archive
end
Base.unsafe_convert(::Type{Ptr{Cvoid}}, archive::Reader) = archive.ptr

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

struct ReadFileName{T} <: ReaderData
    name::T
    block_size::Int
end

Reader(fname::AbstractString; block_size=10240) =
    Reader(ReadFileName(fname, Int(block_size)::Int))
Reader(; block_size=10240) =
    Reader(ReadFileName(nothing, Int(block_size)::Int))

function do_open(archive::Reader{ReadFileName{T}}) where T
    data = archive.data
    @_la_call(archive_read_open_filename, (Ptr{Cvoid}, Cstring, Csize_t),
              archive, data.name, data.block_size)
end

function do_open(archive::Reader{ReadFileName{Cvoid}})
    data = archive.data
    @_la_call(archive_read_open_filename, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t),
              archive, C_NULL, data.block_size)
end

struct ReadFD <: ReaderData
    fd::Cint
    block_size::Int
end

Reader(fd::Integer; block_size=10240) =
    Reader(ReadFD(Cint(fd), Int(block_size)::Int))

function do_open(archive::Reader{ReadFD})
    data = archive.data
    @_la_call(archive_read_open_fd, (Ptr{Cvoid}, Cint, Csize_t),
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

struct ReadMemory{T,TO} <: ReaderData
    ptr::T
    obj::TO # Reference for GC
    size::Int
end

Reader(ptr::T, size, obj::TO=nothing) where {T<:Ptr,TO} =
    Reader(ReadMemory{T,TO}(ptr, obj, size))
Reader(ary::Vector, size=sizeof(ary)) = Reader(pointer(ary), size, ary)

Base.unsafe_convert(::Type{Ptr{Cvoid}}, mem_data::ReadMemory) = mem_data.ptr

function do_open(archive::Reader{T}) where {T<:ReadMemory}
    data = archive.data
    @_la_call(archive_read_open_memory, (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t),
              archive, data, data.size)
end

###
# Generic reader

struct GenericReadData{T} <: ReaderData
    data::T
    buff::Vector{UInt8}
end

Reader(data::T, buff_size=10240) where {T} =
    Reader(GenericReadData{T}(data, Vector{UInt8}(undef, buff_size)))

reader_open(archive::Reader, data) = nothing
function reader_readbytes end
function reader_skip end
function reader_seek end
reader_close(archive::Reader, data) = nothing

function reader_open_callback(c_archive, archive)
    try
        clear_error(archive)
        reader_open(archive, archive.data.data)
        return Libc.errno(archive) == 0 ? Cint(0) : Status.WARN
    catch ex
        return set_exception(archive, ex)
    end
end

function reader_read_callback(c_archive, archive, buff::Ptr{Ptr{Cvoid}})
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

function reader_skip_callback(c_archive, archive, request)
    try
        clear_error(archive)
        return Int64(reader_skip(archive, archive.data.data, request))
    catch ex
        set_exception(archive, ex)
        return Int64(0)
    end
end

function reader_seek_callback(c_archive, archive, request, whence)
    try
        clear_error(archive)
        return Int64(reader_seek(archive, archive.data.data, request, whence))
    catch ex
        set_exception(archive, ex)
        return Int64(0)
    end
end

function reader_close_callback(c_archive, archive)
    try
        clear_error(archive)
        reader_close(archive, archive.data.data)
        return Libc.errno(archive) == 0 ? Cint(0) : Status.WARN
    catch ex
        return set_exception(archive, ex)
    end
end

reader_readbytes(archive, io::IO, buff) = readbytes!(io, buff)
reader_skip(archive, io::IO, sz) =
    (skip(io, sz); sz)

function do_open(archive::Reader{T}) where {T<:GenericReadData}
    # Set various callbacks
    @_la_call(archive_read_set_callback_data,
              (Ptr{Cvoid}, Any), archive, archive)
    @_la_call(archive_read_set_open_callback,
              (Ptr{Cvoid}, Ptr{Cvoid}), archive,
              @to_open_callback(reader_open_callback, Reader{T}))
    @_la_call(archive_read_set_read_callback,
              (Ptr{Cvoid}, Ptr{Cvoid}), archive,
              @to_read_callback(reader_read_callback, Reader{T}))
    @_la_call(archive_read_set_seek_callback,
              (Ptr{Cvoid}, Ptr{Cvoid}), archive,
              @to_seek_callback(reader_seek_callback, Reader{T}))
    @_la_call(archive_read_set_skip_callback,
              (Ptr{Cvoid}, Ptr{Cvoid}), archive,
              @to_skip_callback(reader_skip_callback, Reader{T}))
    @_la_call(archive_read_set_close_callback,
              (Ptr{Cvoid}, Ptr{Cvoid}), archive,
              @to_close_callback(reader_close_callback, Reader{T}))
    @_la_call(archive_read_open1, (Ptr{Cvoid},), archive)
end

function next_header(archive::Reader)
    ensure_open(archive)
    entry = Entry(archive)
    @_la_call(archive_read_next_header2, (Ptr{Cvoid}, Ptr{Cvoid}),
              archive, entry)
    entry
end

"""
Retrieve the byte offset in UNCOMPRESSED data where last-read
header started.
"""
header_position(archive::Reader) =
    ccall((:archive_read_header_position, libarchive),
          Int64, (Ptr{Cvoid},), archive)

"Read data from the body of an entry.  Similar to read(2)."
@inline function unsafe_archive_read(archive::Reader, ptr::Ptr{UInt8}, sz::UInt)
    nb = ccall((:archive_read_data, libarchive), Cssize_t,
               (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t), archive, ptr, sz)
    nb < 0 && _la_error(Cint(nb), archive)
    nb % Csize_t
end

"Read data from the body of an entry.  Similar to read(2)."
function unsafe_read(archive::Reader, ptr::Ptr{UInt8}, sz::UInt)
    unsafe_archive_read(archive, ptr, sz) != sz && throw(EOFError())
    nothing
end

"Read data from the body of an entry.  Similar to read(2)."
function Base.read(archive::Reader, ::Type{UInt8})
    b = Ref{UInt8}()
    unsafe_read(archive, Base.unsafe_convert(Ptr{UInt8}, b), UInt(1))
    b[]
end

"Read data from the body of an entry.  Similar to read(2)."
function Base.readbytes!(archive::Reader, b::Array{UInt8}, nb=length(b))
    nbread = unsafe_archive_read(archive, Base.unsafe_convert(Ptr{UInt8}, b),
                                 UInt(nb))
    nbread < nb && resize!(b, nbread)
    nbread
end

"Read data from the body of an entry.  Similar to read(2)."
function Base.read(archive::Reader)
    # Maybe we can optimize this with block read?
    block_size = UInt(1024)
    res = Vector{UInt8}(undef, block_size)
    pos = 1
    while true
        ptr = Base.unsafe_convert(Ptr{UInt8}, Ref(res, pos))
        nbread = unsafe_archive_read(archive, ptr, block_size)
        if nbread < block_size
            resize!(res, nbread + pos - 1)
            return res
        end
        pos = Int(pos + block_size)
        resize!(res, pos + block_size - 1)
    end
end

"Read data from the body of an entry.  Similar to read(2)."
@inline Base.readavailable(archive::Reader) = read(archive)

"Seek within the body of an entry.  Similar to lseek(2)."
Base.seek(archive::Reader, offset, what) =
    ccall((:archive_seek_data, libarchive), Int64,
          (Ptr{Cvoid}, Int64, Cint), archive, offset, what)

"Skips entire entry"
Base.skip(archive::Reader) =
    @_la_call(archive_read_data_skip, (Ptr{Cvoid},), archive)

"Writes data to specified filedes"
read_into_fd(archive::Reader, fd::Integer) =
    @_la_call(archive_read_data_into_fd, (Ptr{Cvoid}, Cint), archive, fd)

Reader(f::Function) = archive_guard(f, Reader())
Reader(f::Function, args...; kws...) =
    archive_guard(f, Reader(args...; kws...))

# /*
#  * Set read options.
#  */
# /* Apply option to the format only. */
# int archive_read_set_format_option(struct archive *_a,
# 			    const char *m, const char *o,
# 			    const char *v);
# /* Apply option to the filter only. */
# int archive_read_set_filter_option(struct archive *_a,
# 			    const char *m, const char *o,
# 			    const char *v);
# /* Apply option to both the format and the filter. */
# int archive_read_set_option(struct archive *_a,
# 			    const char *m, const char *o,
# 			    const char *v);
# /* Apply option string to both the format and the filter. */
# int archive_read_set_options(struct archive *_a,
# 			    const char *opts);

# /*
#  * A zero-copy version of archive_read_data that also exposes the file offset
#  * of each returned block.  Note that the client has no way to specify
#  * the desired size of the block.  The API does guarantee that offsets will
#  * be strictly increasing and that returned blocks will not overlap.
#  */
# int archive_read_data_block(struct archive *a,
#                    const void **buff, size_t *size, int64_t *offset);

# /*-
#  * Convenience function to recreate the current entry (whose header
#  * has just been read) on disk.
#  *
#  * This does quite a bit more than just copy data to disk. It also:
#  *  - Creates intermediate directories as required.
#  *  - Manages directory permissions:  non-writable directories will
#  *    be initially created with write permission enabled; when the
#  *    archive is closed, dir permissions are edited to the values specified
#  *    in the archive.
#  *  - Checks hardlinks:  hardlinks will not be extracted unless the
#  *    linked-to file was also extracted within the same session. (TODO)
#  */

# /* The "flags" argument selects optional behavior, 'OR' the flags you want. */

# int archive_read_extract(struct archive *, struct archive_entry *,
# 		     int flags);
# int archive_read_extract2(struct archive *, struct archive_entry *,
# 		     struct archive * /* dest */);
# void	 archive_read_extract_set_progress_callback(struct archive *,
#      void (*_progress_func)(void *), void *_user_data);

# /* Record the dev/ino of a file that will not be written.  This is
#  * generally set to the dev/ino of the archive being read. */
# void		archive_read_extract_set_skip_file(struct archive *,
#      int64_t, int64_t);
