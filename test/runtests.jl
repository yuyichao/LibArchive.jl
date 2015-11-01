#

using LibArchive
using Base.Test

## Version
info("Test version")
@test isa(LibArchive.version(), VersionNumber)

## Error
info("Test error translation")
@test_throws EOFError LibArchive._la_error(LibArchive.Status.EOF)
@test_throws ArchiveRetry LibArchive._la_error(LibArchive.Status.RETRY)
@test_throws ArchiveWarn LibArchive._la_error(LibArchive.Status.WARN)
@test_throws ArchiveFailed LibArchive._la_error(LibArchive.Status.FAILED)
@test_throws ArchiveFatal LibArchive._la_error(LibArchive.Status.FATAL)

## Reader error
info("Test reader error handling")
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
info("Test writer error handling")
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

# Copy entry
info("Test deepcopy of Entry")
let
    entry = LibArchive.Entry()
    LibArchive.set_pathname(entry, "test.txt")
    LibArchive.set_size(entry, 10)
    LibArchive.set_perm(entry, 0o644)
    LibArchive.set_filetype(entry, LibArchive.FileType.REG)

    @test LibArchive.pathname(entry) == "test.txt"
    @test LibArchive.size(entry) == 10
    @test LibArchive.size_is_set(entry)
    @test LibArchive.perm(entry) == 0o644
    @test LibArchive.filetype(entry) == LibArchive.FileType.REG

    entry_cp = deepcopy(entry)
    @test LibArchive.pathname(entry_cp) == "test.txt"
    @test LibArchive.size(entry_cp) == 10
    @test LibArchive.size_is_set(entry_cp)
    @test LibArchive.perm(entry_cp) == 0o644
    @test LibArchive.filetype(entry_cp) == LibArchive.FileType.REG
end

# Create archive
info("Test creating archive")
function create_archive(writer)
    entry = LibArchive.Entry(writer)
    LibArchive.set_pathname(entry, "test.txt")
    LibArchive.set_size(entry, 10)
    LibArchive.set_perm(entry, 0o644)
    LibArchive.set_filetype(entry, LibArchive.FileType.REG)
    LibArchive.write_header(writer, entry)
    LibArchive.write_data(writer, ("0123456789").data)
    LibArchive.finish_entry(writer)
end

mktempdir() do d
    cd(d) do
        writer = LibArchive.file_writer("./test.tar.bz2")
        LibArchive.set_format_gnutar(writer)
        LibArchive.add_filter_bzip2(writer)
        LibArchive.set_bytes_per_block(writer, 4096)
        @test LibArchive.get_bytes_per_block(writer) == 4096
        LibArchive.set_bytes_in_last_block(writer, 1)
        @test LibArchive.get_bytes_in_last_block(writer) == 1
        create_archive(writer)
        close(writer)
        LibArchive.free(writer)
    end
end
