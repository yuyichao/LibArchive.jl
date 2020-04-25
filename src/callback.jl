###
# Helpers for libarchive callbacks

"""
    ssize_t archive_read_callback(struct archive*,
                                  void *client_data, const void **buffer)

Returns pointer and size of next block of data from archive.
"""
macro to_read_callback(f, T)
    :(@cfunction($f, Cssize_t, (Ptr{Cvoid}, Ref{$(esc(T))}, Ptr{Ptr{Cvoid}})))
end

"""
    int64_t archive_skip_callback(struct archive*,
                                  void *client_data, int64_t request)

Skips at most request bytes from archive and returns the skipped amount.
This may skip fewer bytes than requested; it may even skip zero bytes.
If you do skip fewer bytes than requested, libarchive will invoke your
read callback and discard data as necessary to make up the full skip.
"""
macro to_skip_callback(f, T)
    :(@cfunction($f, Int64, (Ptr{Cvoid}, Ref{$(esc(T))}, Int64)))
end

"""
    int64_t archive_seek_callback(struct archive*,
                                  void *client_data, int64_t offset, int whence)

Seeks to specified location in the file and returns the position.
Whence values are SEEK_SET, SEEK_CUR, SEEK_END from stdio.h.
Return ARCHIVE_FATAL if the seek fails for any reason.
"""
macro to_seek_callback(f, T)
    :(@cfunction($f, Int64, (Ptr{Cvoid}, Ref{$(esc(T))}, Int64, Cint)))
end

"""
    ssize_t archive_write_callback(struct archive*,
                                   void *client_data,
                                   const void *buffer, size_t length);

Returns size actually written, zero on EOF, -1 on error.
"""
macro to_write_callback(f, T)
    :(@cfunction($f, Cssize_t, (Ptr{Cvoid}, Ref{$(esc(T))}, Ptr{Cvoid}, Csize_t)))
end

"""
    int archive_open_callback(struct archive*, void *client_data)
"""
macro to_open_callback(f, T)
    :(@cfunction($f, Cint, (Ptr{Cvoid}, Ref{$(esc(T))})))
end

"""
    int archive_close_callback(struct archive*, void *client_data)
"""
macro to_close_callback(f, T)
    :(@cfunction($f, Cint, (Ptr{Cvoid}, Ref{$(esc(T))})))
end

# """
#     int archive_switch_callback(struct archive*, void *client_data1,
#                                 void *client_data2)
#
# Switches from one client data object to the next/prev client data object.
# This is useful for reading from different data blocks such as a set of files
# that make up one large file.
# """
# to_switch_callback{T1,T2}(func::Function, ::Type{T1}=Cvoid, ::Type{T2}=Cvoid) =
#     @cfunction($f, Cint, Tuple{Ptr{Cvoid},Ptr{T1},Ptr{T2}})
