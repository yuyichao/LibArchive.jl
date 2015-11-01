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

## Reader error
let
    archive_reader = LibArchive.Reader(nothing)
    @test archive_reader.ptr != C_NULL
    LibArchive.free(archive_reader)
    @test archive_reader.ptr == C_NULL
    LibArchive.free(archive_reader)
    @test_throws ErrorException LibArchive.support_filter_all(archive_reader)

    archive_reader = LibArchive.file_reader("/this_file_does_not_exist")
    local ex
    try
        LibArchive.next_header(archive_reader)
    catch ex
    end
    @test isa(ex, LibArchive.ArchiveFatal)
    @test !isempty(ex.msg)
end

# Writer error
let
    archive_writer = LibArchive.Writer(nothing)
    @test archive_writer.ptr != C_NULL
    LibArchive.free(archive_writer)
    @test archive_writer.ptr == C_NULL
    LibArchive.free(archive_writer)
    @test_throws ErrorException LibArchive.add_filter_bzip2(archive_writer)

    archive_writer = LibArchive.file_writer("/this_dir_does_not_exist/file")
    local ex
    try
        LibArchive.finish_entry(archive_writer)
    catch ex
    end
    @test isa(ex, LibArchive.ArchiveFatal)
    @test !isempty(ex.msg)
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
