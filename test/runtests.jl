#

using LibArchive
using Base.Test

## Version
@test isa(LibArchive.version(), VersionNumber)

## Error
@test_throws EOFError LibArchive._la_error(LibArchive.Status.EOF)
@test_throws ArchiveRetry LibArchive._la_error(LibArchive.Status.RETRY)
@test_throws ArchiveWarn LibArchive._la_error(LibArchive.Status.WARN)
@test_throws ArchiveFailed LibArchive._la_error(LibArchive.Status.FAILED)
@test_throws ArchiveFatal LibArchive._la_error(LibArchive.Status.FATAL)

## Read
let
    archive_read = LibArchive.Reader(nothing)
    @test archive_read.ptr != C_NULL
    LibArchive.free(archive_read)
    @test archive_read.ptr == C_NULL
    LibArchive.free(archive_read)
    @test_throws ErrorException LibArchive.support_filter_all(archive_read)
end

mktempdir() do d
    cd(d) do
        writer = LibArchive.file_writer("./test.tar.bz2")
        LibArchive.set_format_gnutar(writer)
        LibArchive.add_filter_bzip2(writer)
        entry = LibArchive.Entry(writer)
        LibArchive.set_pathname(entry, "test.txt")
        LibArchive.set_size(entry, 10)
        LibArchive.set_perm(entry, 0o644)
        LibArchive.set_filetype(entry, LibArchive.FileType.REG)
        LibArchive.write_header(writer, entry)
        LibArchive.write_data(writer, ("0123456789").data)
        LibArchive.finish_entry(writer)
        close(writer)
        LibArchive.free(writer)
    end
end
