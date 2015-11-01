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
    @test !LibArchive.size_is_set(entry)
    LibArchive.set_pathname(entry, "α.txt")
    LibArchive.set_size(entry, 10)
    LibArchive.set_perm(entry, 0o644)
    LibArchive.set_filetype(entry, LibArchive.FileType.REG)

    @test LibArchive.pathname(entry) == "α.txt"
    @test LibArchive.size(entry) == 10
    @test LibArchive.size_is_set(entry)
    @test LibArchive.perm(entry) == 0o644
    @test LibArchive.filetype(entry) == LibArchive.FileType.REG

    entry_cp = deepcopy(entry)
    @test LibArchive.pathname(entry_cp) == "α.txt"
    @test LibArchive.size(entry_cp) == 10
    @test LibArchive.size_is_set(entry_cp)
    @test LibArchive.perm(entry_cp) == 0o644
    @test LibArchive.filetype(entry_cp) == LibArchive.FileType.REG

    LibArchive.clear(entry)
    LibArchive.free(entry)
    LibArchive.free(entry_cp)
end

# Entry properties
info("Test Entry properties")
let
    # Time stamps
    entry = LibArchive.Entry()
    t = floor(Int, time())
    ns = rand(1:(10^8))

    @test !LibArchive.atime_is_set(entry)
    LibArchive.set_atime(entry, t, ns)
    @test LibArchive.atime_is_set(entry)
    @test LibArchive.atime(entry) == t
    @test LibArchive.atime_nsec(entry) == ns
    LibArchive.unset_atime(entry)
    @test !LibArchive.atime_is_set(entry)

    @test !LibArchive.birthtime_is_set(entry)
    LibArchive.set_birthtime(entry, t, ns)
    @test LibArchive.birthtime_is_set(entry)
    @test LibArchive.birthtime(entry) == t
    @test LibArchive.birthtime_nsec(entry) == ns
    LibArchive.unset_birthtime(entry)
    @test !LibArchive.birthtime_is_set(entry)

    @test !LibArchive.ctime_is_set(entry)
    LibArchive.set_ctime(entry, t, ns)
    @test LibArchive.ctime_is_set(entry)
    @test LibArchive.ctime(entry) == t
    @test LibArchive.ctime_nsec(entry) == ns
    LibArchive.unset_ctime(entry)
    @test !LibArchive.ctime_is_set(entry)

    @test !LibArchive.mtime_is_set(entry)
    LibArchive.set_mtime(entry, t, ns)
    @test LibArchive.mtime_is_set(entry)
    @test LibArchive.mtime(entry) == t
    @test LibArchive.mtime_nsec(entry) == ns
    LibArchive.unset_mtime(entry)
    @test !LibArchive.mtime_is_set(entry)

    LibArchive.clear(entry)
    @test !LibArchive.atime_is_set(entry)
    @test !LibArchive.birthtime_is_set(entry)
    @test !LibArchive.ctime_is_set(entry)
    @test !LibArchive.mtime_is_set(entry)
    LibArchive.free(entry)
    @test_throws ErrorException LibArchive.atime_is_set(entry)
end

let
    # dev number
    entry = LibArchive.Entry()
    dev1 = rand(UInt64)
    # There doesn't seem to be a portable way to convert between minor and
    # major dev_t and the full dev_t
    devmajor2 = UInt64(rand(UInt8))
    devminor2 = UInt64(rand(UInt8))

    @test !LibArchive.dev_is_set(entry)
    LibArchive.set_dev(entry, dev1)
    @test LibArchive.dev_is_set(entry)
    @test LibArchive.dev(entry) == dev1
    LibArchive.set_devmajor(entry, devmajor2)
    LibArchive.set_devminor(entry, devminor2)
    @test LibArchive.dev_is_set(entry)
    @test LibArchive.devmajor(entry) == devmajor2
    @test LibArchive.devminor(entry) == devminor2

    LibArchive.set_rdev(entry, dev1)
    @test LibArchive.rdev(entry) == dev1
    LibArchive.set_rdevmajor(entry, devmajor2)
    LibArchive.set_rdevminor(entry, devminor2)
    @test LibArchive.rdevmajor(entry) == devmajor2
    @test LibArchive.rdevminor(entry) == devminor2

    LibArchive.clear(entry)
    @test !LibArchive.dev_is_set(entry)
    LibArchive.free(entry)
end

let
    # file type
    entry = LibArchive.Entry()

    for ft in (LibArchive.FileType.MT, LibArchive.FileType.REG,
               LibArchive.FileType.LNK, LibArchive.FileType.SOCK,
               LibArchive.FileType.CHR, LibArchive.FileType.BLK,
               LibArchive.FileType.DIR, LibArchive.FileType.IFO)
        LibArchive.set_filetype(entry, ft)
        @test LibArchive.filetype(entry) == ft
    end

    LibArchive.free(entry)
end

let
    # fflags
    entry = LibArchive.Entry()
    @test_throws ArgumentError LibArchive.fflags_text(entry)

    LibArchive.set_fflags(entry, 1, 2)
    @test LibArchive.fflags(entry) == (1, 2)
    flags_txt = LibArchive.fflags_text(entry)
    @test !isempty(flags_txt)

    LibArchive.free(entry)

    entry2 = LibArchive.Entry()
    @test_throws ArgumentError LibArchive.fflags_text(entry2)
    LibArchive.set_fflags(entry2, flags_txt)
    @test LibArchive.fflags(entry2) == (1, 2)
    @test LibArchive.fflags_text(entry2) == flags_txt

    LibArchive.free(entry2)
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
