###
# Helpers for libarchive callbacks

"""
    ssize_t archive_read_callback(struct archive*,
                                  void *client_data, const void **buffer)

Returns pointer and size of next block of data from archive.
"""
to_read_callback(func::Function) =
    cfunction(func, Cssize_t, Tuple{Ptr{Void},Ptr{Void},Ptr{Void}})

"""
    int64_t archive_skip_callback(struct archive*,
                                  void *client_data, int64_t request)

Skips at most request bytes from archive and returns the skipped amount.
This may skip fewer bytes than requested; it may even skip zero bytes.
If you do skip fewer bytes than requested, libarchive will invoke your
read callback and discard data as necessary to make up the full skip.
"""
to_skip_callback(func::Function) =
    cfunction(func, Int64, Tuple{Ptr{Void},Ptr{Void},Int64})

"""
    int64_t archive_seek_callback(struct archive*,
                                  void *client_data, int64_t offset, int whence)

Seeks to specified location in the file and returns the position.
Whence values are SEEK_SET, SEEK_CUR, SEEK_END from stdio.h.
Return ARCHIVE_FATAL if the seek fails for any reason.
"""
to_seek_callback(func::Function) =
    cfunction(func, Int64, Tuple{Ptr{Void},Ptr{Void},Int64,Cint})

"""
    ssize_t archive_write_callback(struct archive*,
                                   void *client_data,
                                   const void *buffer, size_t length);

Returns size actually written, zero on EOF, -1 on error.
"""
to_write_callback(func::Function) =
    cfunction(func, Cssize_t, Tuple{Ptr{Void},Ptr{Void},Ptr{Void},Csize_t})

"""
    int archive_open_callback(struct archive*, void *client_data)
"""
to_open_callback(func::Function) =
    cfunction(func, Cint, Tuple{Ptr{Void},Ptr{Void}})

"""
    int archive_close_callback(struct archive*, void *client_data)
"""
to_close_callback(func::Function) =
    cfunction(func, Cint, Tuple{Ptr{Void},Ptr{Void}})

"""
    int archive_switch_callback(struct archive*, void *client_data1,
                                void *client_data2)

Switches from one client data object to the next/prev client data object.
This is useful for reading from different data blocks such as a set of files
that make up one large file.
"""
to_switch_callback(func::Function) =
    cfunction(func, Cint, Tuple{Ptr{Void},Ptr{Void},Ptr{Void}})
