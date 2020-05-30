###
# Format and filters

# Format (i.e. how files are packed together)

# Reader

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

const _format_ids = Dict{String,Cint}(
    "7zip"=>Format._7ZIP,
    "ar"=>Format.AR_BSD,
    "arbsd"=>Format.AR_BSD,
    "argnu"=>Format.AR_GNU,
    "arsvr4"=>Format.AR_GNU,
    "bsdtar"=>Format.TAR_PAX_RESTRICTED,
    "cd9660"=>Format.ISO9660,
    "cpio"=>Format.CPIO_POSIX,
    "gnutar"=>Format.TAR_GNUTAR,
    "iso"=>Format.ISO9660,
    "iso9660"=>Format.ISO9660,
    "mtree"=>Format.MTREE,
    "mtree-classic"=>Format.MTREE,
    "newc"=>Format.CPIO_SVR4_NOCRC,
    "odc"=>Format.CPIO_POSIX,
    "oldtar"=>Format.TAR,
    "pax"=>Format.TAR_PAX_INTERCHANGE,
    "paxr"=>Format.TAR_PAX_RESTRICTED,
    "posix"=>Format.TAR_PAX_INTERCHANGE,
    "raw"=>Format.RAW,
    "rpax"=>Format.TAR_PAX_RESTRICTED,
    "shar"=>Format.SHAR_BASE,
    "shardump"=>Format.SHAR_DUMP,
    "ustar"=>Format.TAR_USTAR,
    "v7tar"=>Format.TAR,
    "v7"=>Format.TAR,
    "warc"=>Format.WARC,
    "xar"=>Format.XAR,
    "zip"=>Format.ZIP,
)

# Functions to manually set the format and filters to be used. This is
# useful to bypass the bidding process when the format and filters to use
# is known in advance.
set_format(archive::Reader, fmt::Integer) =
    @_la_call(archive_read_set_format, (Ptr{Cvoid}, Cint), archive, fmt)
function set_format(archive::Reader, fmt::AbstractString)
    id = get(_format_ids, fmt, Cint(-1))
    if id < 0
        throw(ArchiveFatal("No such format '$fmt'"))
    end
    @_la_call(archive_read_set_format, (Ptr{Cvoid}, Cint), archive, id)
end
set_format_7zip(archive::Reader) = set_format(archive, Format._7ZIP)
set_format_ar_bsd(archive::Reader) = set_format(archive, Format.AR_BSD)
set_format_ar_gnu(archive::Reader) = set_format(archive, Format.AR_GNU)
const set_format_ar_svr4 = set_format_ar_gnu
set_format_cpio(archive::Reader) = set_format(archive, Format.CPIO_POSIX)
set_format_cpio_newc(archive::Reader) = set_format(archive, Format.CPIO_SVR4_NOCRC)
set_format_gnutar(archive::Reader) = set_format(archive, Format.TAR_GNUTAR)
set_format_iso9660(archive::Reader) = set_format(archive, Format.ISO9660)
set_format_mtree(archive::Reader) = set_format(archive, Format.MTREE)
set_format_mtree_classic(archive::Reader) = set_format(archive, Format.MTREE)
set_format_pax(archive::Reader) = set_format(archive, Format.TAR_PAX_INTERCHANGE)
set_format_pax_restricted(archive::Reader) = set_format(archive, Format.TAR_PAX_RESTRICTED)
set_format_raw(archive::Reader) = set_format(archive, Format.RAW)
set_format_shar(archive::Reader) = set_format(archive, Format.SHAR_BASE)
set_format_shar_dump(archive::Reader) = set_format(archive, Format.SHAR_DUMP)
set_format_ustar(archive::Reader) = set_format(archive, Format.TAR_USTAR)
set_format_v7tar(archive::Reader) = set_format(archive, Format.TAR)
set_format_warc(archive::Reader) = set_format(archive, Format.WARC)
set_format_xar(archive::Reader) = set_format(archive, Format.XAR)
set_format_zip(archive::Reader) = set_format(archive, Format.ZIP)

# Writer

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
set_format_ar_gnu(archive::Writer) =
    @_la_call(archive_write_set_format_ar_svr4, (Ptr{Cvoid},), archive)
# const set_format_ar_svr4 = set_format_ar_gnu
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
set_format_raw(archive::Writer) =
    @_la_call(archive_write_set_format_raw, (Ptr{Cvoid},), archive)
set_format_shar(archive::Writer) =
    @_la_call(archive_write_set_format_shar, (Ptr{Cvoid},), archive)
set_format_shar_dump(archive::Writer) =
    @_la_call(archive_write_set_format_shar_dump, (Ptr{Cvoid},), archive)
set_format_ustar(archive::Writer) =
    @_la_call(archive_write_set_format_ustar, (Ptr{Cvoid},), archive)
set_format_v7tar(archive::Writer) =
    @_la_call(archive_write_set_format_v7tar, (Ptr{Cvoid},), archive)
set_format_warc(archive::Writer) =
    @_la_call(archive_write_set_format_warc, (Ptr{Cvoid},), archive)
set_format_xar(archive::Writer) =
    @_la_call(archive_write_set_format_xar, (Ptr{Cvoid},), archive)
set_format_zip(archive::Writer) =
    @_la_call(archive_write_set_format_zip, (Ptr{Cvoid},), archive)
zip_set_compression_deflate(archive::Writer) =
    @_la_call(archive_write_zip_set_compression_deflate, (Ptr{Cvoid},), archive)
zip_set_compression_store(archive::Writer) =
    @_la_call(archive_write_zip_set_compression_store, (Ptr{Cvoid},), archive)

# filter (i.e. compression and other post-processing on the packed files)

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
add_filter_lz4(archive::Writer) =
    @_la_call(archive_write_add_filter_lz4, (Ptr{Cvoid},), archive)
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
