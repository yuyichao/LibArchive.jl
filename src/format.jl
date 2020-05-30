###
# Format and filters

# Reader

support_filter_all(archive::Reader) =
    @_la_call(archive_read_support_filter_all, (Ptr{Cvoid},), archive)
support_filter_bzip2(archive::Reader) =
    @_la_call(archive_read_support_filter_bzip2, (Ptr{Cvoid},), archive)
support_filter_compress(archive::Reader) =
    @_la_call(archive_read_support_filter_compress, (Ptr{Cvoid},), archive)
support_filter_gzip(archive::Reader) =
    @_la_call(archive_read_support_filter_gzip, (Ptr{Cvoid},), archive)
support_filter_grzip(archive::Reader) =
    @_la_call(archive_read_support_filter_grzip, (Ptr{Cvoid},), archive)
support_filter_lrzip(archive::Reader) =
    @_la_call(archive_read_support_filter_lrzip, (Ptr{Cvoid},), archive)
support_filter_lz4(archive::Reader) =
    @_la_call(archive_read_support_filter_lz4, (Ptr{Cvoid},), archive)
support_filter_lzip(archive::Reader) =
    @_la_call(archive_read_support_filter_lzip, (Ptr{Cvoid},), archive)
support_filter_lzma(archive::Reader) =
    @_la_call(archive_read_support_filter_lzma, (Ptr{Cvoid},), archive)
support_filter_lzop(archive::Reader) =
    @_la_call(archive_read_support_filter_lzop, (Ptr{Cvoid},), archive)
support_filter_none(archive::Reader) =
    @_la_call(archive_read_support_filter_none, (Ptr{Cvoid},), archive)
"""
Data is fed through the specified external program before being dearchived.
Note that this disables automatic detection of the compression format, so it
makes no sense to specify this in conjunction with any other decompression
option.
"""
support_filter_program(archive::Reader, cmd) =
    @_la_call(archive_read_support_filter_program,
              (Ptr{Cvoid}, Cstring), archive, cmd)
support_filter_program_signature(archive::Reader, cmd, sig) =
    @_la_call(archive_read_support_filter_program_signature,
              (Ptr{Cvoid}, Cstring, Ptr{Cvoid}, Csize_t),
              archive, cmd, sig, sizeof(sig))
support_filter_rpm(archive::Reader) =
    @_la_call(archive_read_support_filter_rpm, (Ptr{Cvoid},), archive)
support_filter_uu(archive::Reader) =
    @_la_call(archive_read_support_filter_uu, (Ptr{Cvoid},), archive)
support_filter_xz(archive::Reader) =
    @_la_call(archive_read_support_filter_xz, (Ptr{Cvoid},), archive)
support_filter_zstd(archive::Reader) =
    @_la_call(archive_read_support_filter_zstd, (Ptr{Cvoid},), archive)

support_format_7zip(archive::Reader) =
    @_la_call(archive_read_support_format_7zip, (Ptr{Cvoid},), archive)
support_format_all(archive::Reader) =
    @_la_call(archive_read_support_format_all, (Ptr{Cvoid},), archive)
support_format_ar(archive::Reader) =
    @_la_call(archive_read_support_format_ar, (Ptr{Cvoid},), archive)
support_format_by_code(archive::Reader, code) =
    @_la_call(archive_read_support_format_by_code,
              (Ptr{Cvoid}, Cint), archive, code)
support_format_cab(archive::Reader) =
    @_la_call(archive_read_support_format_cab, (Ptr{Cvoid},), archive)
support_format_cpio(archive::Reader) =
    @_la_call(archive_read_support_format_cpio, (Ptr{Cvoid},), archive)
support_format_empty(archive::Reader) =
    @_la_call(archive_read_support_format_empty, (Ptr{Cvoid},), archive)
support_format_gnutar(archive::Reader) =
    @_la_call(archive_read_support_format_gnutar, (Ptr{Cvoid},), archive)
support_format_iso9660(archive::Reader) =
    @_la_call(archive_read_support_format_iso9660, (Ptr{Cvoid},), archive)
support_format_lha(archive::Reader) =
    @_la_call(archive_read_support_format_lha, (Ptr{Cvoid},), archive)
support_format_mtree(archive::Reader) =
    @_la_call(archive_read_support_format_mtree, (Ptr{Cvoid},), archive)
support_format_rar(archive::Reader) =
    @_la_call(archive_read_support_format_rar, (Ptr{Cvoid},), archive)
support_format_rar5(archive::Reader) =
    @_la_call(archive_read_support_format_rar5, (Ptr{Cvoid},), archive)
support_format_raw(archive::Reader) =
    @_la_call(archive_read_support_format_raw, (Ptr{Cvoid},), archive)
support_format_tar(archive::Reader) =
    @_la_call(archive_read_support_format_tar, (Ptr{Cvoid},), archive)
support_format_xar(archive::Reader) =
    @_la_call(archive_read_support_format_xar, (Ptr{Cvoid},), archive)
support_format_warc(archive::Reader) =
    @_la_call(archive_read_support_format_warc, (Ptr{Cvoid},), archive)
support_format_zip(archive::Reader) =
    @_la_call(archive_read_support_format_zip, (Ptr{Cvoid},), archive)
support_format_zip_streamable(archive::Reader) =
    @_la_call(archive_read_support_format_zip_streamable, (Ptr{Cvoid},), archive)
support_format_zip_seekable(archive::Reader) =
    @_la_call(archive_read_support_format_zip_seekable, (Ptr{Cvoid},), archive)

# Functions to manually set the format and filters to be used. This is
# useful to bypass the bidding process when the format and filters to use
# is known in advance.
set_format(archive::Reader, fmt) =
    @_la_call(archive_read_set_format, (Ptr{Cvoid}, Cint), archive, fmt)
append_filter(archive::Reader, filter) =
    @_la_call(archive_read_append_filter, (Ptr{Cvoid}, Cint), archive, filter)
append_filter_program(archive::Reader, cmd) =
    @_la_call(archive_read_append_filter_program, (Ptr{Cvoid}, Cstring),
              archive, cmd)
append_filter_program_signature(archive::Reader, cmd, sig) =
    @_la_call(archive_read_append_filter_program_signature,
              (Ptr{Cvoid}, Cstring, Ptr{Cvoid}, Csize_t),
              archive, cmd, sig, sizeof(sig))

# Writer

"A convenience function to set the filter based on the code."
add_filter(archive::Writer, filter_code::Integer) =
    @_la_call(archive_write_add_filter, (Ptr{Cvoid}, Cint),
              archive, filter_code)
add_filter(archive::Writer, name::AbstractString) =
    @_la_call(archive_write_add_filter_by_name, (Ptr{Cvoid}, Cstring),
              archive, name)
add_filter_b64encode(archive::Writer) =
    @_la_call(archive_write_add_filter_b64encode, (Ptr{Cvoid},), archive)
add_filter_bzip2(archive::Writer) =
    @_la_call(archive_write_add_filter_bzip2, (Ptr{Cvoid},), archive)
add_filter_compress(archive::Writer) =
    @_la_call(archive_write_add_filter_compress, (Ptr{Cvoid},), archive)
add_filter_grzip(archive::Writer) =
    @_la_call(archive_write_add_filter_grzip, (Ptr{Cvoid},), archive)
add_filter_gzip(archive::Writer) =
    @_la_call(archive_write_add_filter_gzip, (Ptr{Cvoid},), archive)
add_filter_lrzip(archive::Writer) =
    @_la_call(archive_write_add_filter_lrzip, (Ptr{Cvoid},), archive)
add_filter_lzip(archive::Writer) =
    @_la_call(archive_write_add_filter_lzip, (Ptr{Cvoid},), archive)
add_filter_lzma(archive::Writer) =
    @_la_call(archive_write_add_filter_lzma, (Ptr{Cvoid},), archive)
add_filter_lzop(archive::Writer) =
    @_la_call(archive_write_add_filter_lzop, (Ptr{Cvoid},), archive)
add_filter_none(archive::Writer) =
    @_la_call(archive_write_add_filter_none, (Ptr{Cvoid},), archive)
add_filter_program(archive::Writer, cmd::AbstractString) =
    @_la_call(archive_write_add_filter_program,
              (Ptr{Cvoid}, Cstring), archive, cmd)
add_filter_uuencode(archive::Writer) =
    @_la_call(archive_write_add_filter_uuencode, (Ptr{Cvoid},), archive)
add_filter_xz(archive::Writer) =
    @_la_call(archive_write_add_filter_xz, (Ptr{Cvoid},), archive)
add_filter_zstd(archive::Writer) =
    @_la_call(archive_write_add_filter_zstd, (Ptr{Cvoid},), archive)

"A convenience function to set the format based on the code or name."
set_format(archive::Writer, format_code::Integer) =
    @_la_call(archive_write_set_format, (Ptr{Cvoid}, Cint),
              archive, format_code)
set_format(archive::Writer, name::AbstractString) =
    @_la_call(archive_write_set_format_by_name, (Ptr{Cvoid}, Cstring),
              archive, name)
set_format_7zip(archive::Writer) =
    @_la_call(archive_write_set_format_7zip, (Ptr{Cvoid},), archive)
set_format_ar_bsd(archive::Writer) =
    @_la_call(archive_write_set_format_ar_bsd, (Ptr{Cvoid},), archive)
set_format_ar_svr4(archive::Writer) =
    @_la_call(archive_write_set_format_ar_svr4, (Ptr{Cvoid},), archive)
set_format_cpio(archive::Writer) =
    @_la_call(archive_write_set_format_cpio, (Ptr{Cvoid},), archive)
set_format_cpio_newc(archive::Writer) =
    @_la_call(archive_write_set_format_cpio_newc, (Ptr{Cvoid},), archive)
set_format_gnutar(archive::Writer) =
    @_la_call(archive_write_set_format_gnutar, (Ptr{Cvoid},), archive)
set_format_iso9660(archive::Writer) =
    @_la_call(archive_write_set_format_iso9660, (Ptr{Cvoid},), archive)
set_format_mtree(archive::Writer) =
    @_la_call(archive_write_set_format_mtree, (Ptr{Cvoid},), archive)
set_format_mtree_classic(archive::Writer) =
    @_la_call(archive_write_set_format_mtree_classic, (Ptr{Cvoid},), archive)
set_format_pax(archive::Writer) =
    @_la_call(archive_write_set_format_pax, (Ptr{Cvoid},), archive)
set_format_pax_restricted(archive::Writer) =
    @_la_call(archive_write_set_format_pax_restricted, (Ptr{Cvoid},), archive)
set_format_shar(archive::Writer) =
    @_la_call(archive_write_set_format_shar, (Ptr{Cvoid},), archive)
set_format_shar_dump(archive::Writer) =
    @_la_call(archive_write_set_format_shar_dump, (Ptr{Cvoid},), archive)
set_format_ustar(archive::Writer) =
    @_la_call(archive_write_set_format_ustar, (Ptr{Cvoid},), archive)
set_format_v7tar(archive::Writer) =
    @_la_call(archive_write_set_format_v7tar, (Ptr{Cvoid},), archive)
set_format_xar(archive::Writer) =
    @_la_call(archive_write_set_format_xar, (Ptr{Cvoid},), archive)
set_format_zip(archive::Writer) =
    @_la_call(archive_write_set_format_zip, (Ptr{Cvoid},), archive)
zip_set_compression_deflate(archive::Writer) =
    @_la_call(archive_write_zip_set_compression_deflate, (Ptr{Cvoid},), archive)
zip_set_compression_store(archive::Writer) =
    @_la_call(archive_write_zip_set_compression_store, (Ptr{Cvoid},), archive)
