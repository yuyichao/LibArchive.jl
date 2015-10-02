###
# Format and filters

support_filter_all(archive::Reader) =
    @_la_call(archive_read_support_filter_all, (Ptr{Void},), archive)
support_filter_bzip2(archive::Reader) =
    @_la_call(archive_read_support_filter_bzip2, (Ptr{Void},), archive)
support_filter_compress(archive::Reader) =
    @_la_call(archive_read_support_filter_compress, (Ptr{Void},), archive)
support_filter_gzip(archive::Reader) =
    @_la_call(archive_read_support_filter_gzip, (Ptr{Void},), archive)
support_filter_grzip(archive::Reader) =
    @_la_call(archive_read_support_filter_grzip, (Ptr{Void},), archive)
support_filter_lrzip(archive::Reader) =
    @_la_call(archive_read_support_filter_lrzip, (Ptr{Void},), archive)
support_filter_lzip(archive::Reader) =
    @_la_call(archive_read_support_filter_lzip, (Ptr{Void},), archive)
support_filter_lzma(archive::Reader) =
    @_la_call(archive_read_support_filter_lzma, (Ptr{Void},), archive)
support_filter_lzop(archive::Reader) =
    @_la_call(archive_read_support_filter_lzop, (Ptr{Void},), archive)
support_filter_none(archive::Reader) =
    @_la_call(archive_read_support_filter_none, (Ptr{Void},), archive)
"""
Data is fed through the specified external program before being dearchived.
Note that this disables automatic detection of the compression format, so it
makes no sense to specify this in conjunction with any other decompression
option.
"""
support_filter_program(archive::Reader, cmd) =
    @_la_call(archive_read_support_filter_program,
              (Ptr{Void}, Cstring), archive, cmd)
support_filter_program_signature(archive::Reader, cmd, sig) =
    @_la_call(archive_read_support_filter_program_signature,
              (Ptr{Void}, Cstring, Ptr{Void}, Csize_t),
              archive, cmd, sig, sizeof(sig))
support_filter_rpm(archive::Reader) =
    @_la_call(archive_read_support_filter_rpm, (Ptr{Void},), archive)
support_filter_uu(archive::Reader) =
    @_la_call(archive_read_support_filter_uu, (Ptr{Void},), archive)
support_filter_xz(archive::Reader) =
    @_la_call(archive_read_support_filter_xz, (Ptr{Void},), archive)

support_format_7zip(archive::Reader) =
    @_la_call(archive_read_support_format_7zip, (Ptr{Void},), archive)
support_format_all(archive::Reader) =
    @_la_call(archive_read_support_format_all, (Ptr{Void},), archive)
support_format_ar(archive::Reader) =
    @_la_call(archive_read_support_format_ar, (Ptr{Void},), archive)
support_format_by_code(archive::Reader, code) =
    @_la_call(archive_read_support_format_by_code,
              (Ptr{Void}, Cint), archive, code)
support_format_cab(archive::Reader) =
    @_la_call(archive_read_support_format_cab, (Ptr{Void},), archive)
support_format_cpio(archive::Reader) =
    @_la_call(archive_read_support_format_cpio, (Ptr{Void},), archive)
support_format_empty(archive::Reader) =
    @_la_call(archive_read_support_format_empty, (Ptr{Void},), archive)
support_format_gnutar(archive::Reader) =
    @_la_call(archive_read_support_format_gnutar, (Ptr{Void},), archive)
support_format_iso9660(archive::Reader) =
    @_la_call(archive_read_support_format_iso9660, (Ptr{Void},), archive)
support_format_lha(archive::Reader) =
    @_la_call(archive_read_support_format_lha, (Ptr{Void},), archive)
support_format_mtree(archive::Reader) =
    @_la_call(archive_read_support_format_mtree, (Ptr{Void},), archive)
support_format_rar(archive::Reader) =
    @_la_call(archive_read_support_format_rar, (Ptr{Void},), archive)
support_format_raw(archive::Reader) =
    @_la_call(archive_read_support_format_raw, (Ptr{Void},), archive)
support_format_tar(archive::Reader) =
    @_la_call(archive_read_support_format_tar, (Ptr{Void},), archive)
support_format_xar(archive::Reader) =
    @_la_call(archive_read_support_format_xar, (Ptr{Void},), archive)
support_format_zip(archive::Reader) =
    @_la_call(archive_read_support_format_zip, (Ptr{Void},), archive)

# Functions to manually set the format and filters to be used. This is
# useful to bypass the bidding process when the format and filters to use
# is known in advance.
set_format(archive::Reader, fmt) =
    @_la_call(archive_read_set_format, (Ptr{Void}, Cint), archive, fmt)
append_filter(archive::Reader, filter) =
    @_la_call(archive_read_append_filter, (Ptr{Void}, Cint), archive, filter)
append_filter_program(archive::Reader, cmd) =
    @_la_call(archive_read_append_filter_program, (Ptr{Void}, Cstring),
              archive, cmd)
append_filter_program_signature(archive::Reader, cmd, sig) =
    @_la_call(archive_read_append_filter_program_signature,
              (Ptr{Void}, Cstring, Ptr{Void}, Csize_t),
              archive, cmd, sig, sizeof(sig))
