#

using LibArchive
using Base.Test
import Base.Filesystem
using Compat

## Version
info("Testing libarchive $(LibArchive.version()::VersionNumber)")

## Error
info("Test error translation")
@test_throws EOFError LibArchive._la_error(LibArchive.Status.EOF)
@test_throws ArchiveRetry LibArchive._la_error(LibArchive.Status.RETRY)
@test_throws ArchiveFailed LibArchive._la_error(LibArchive.Status.FAILED)
@test_throws ArchiveFatal LibArchive._la_error(LibArchive.Status.FATAL)
@test_throws ErrorException LibArchive._la_error(Cint(-1024))

## Reader error
info("Test reader error handling")
let
    reader = LibArchive.Reader()
    @test reader.ptr != C_NULL
    LibArchive.free(reader)
    @test reader.ptr == C_NULL
    LibArchive.free(reader)
    @test_throws ErrorException LibArchive.support_filter_all(reader)
end

LibArchive.Reader() do reader
    LibArchive.set_exception(reader, EOFError())
    @test Libc.errno(reader) == LibArchive.Status.EOF
    @test LibArchive.error_string(reader) == "end of file"
    LibArchive.clear_error(reader)

    LibArchive.set_exception(reader, ArchiveRetry("retry"))
    @test Libc.errno(reader) == LibArchive.Status.RETRY
    @test LibArchive.error_string(reader) == "retry"
    LibArchive.clear_error(reader)

    LibArchive.set_exception(reader, ArchiveFailed("failed"))
    @test Libc.errno(reader) == LibArchive.Status.FAILED
    @test LibArchive.error_string(reader) == "failed"
    LibArchive.clear_error(reader)

    LibArchive.set_exception(reader, ArchiveFatal("fatal"))
    @test Libc.errno(reader) == LibArchive.Status.FATAL
    @test LibArchive.error_string(reader) == "fatal"
    LibArchive.Reader() do reader2
        LibArchive.copy_error(reader2, reader)
        @test Libc.errno(reader2) == LibArchive.Status.FATAL
        @test LibArchive.error_string(reader2) == "fatal"
    end
    LibArchive.clear_error(reader)

    err_ex = ErrorException("error")
    LibArchive.set_exception(reader, err_ex)
    @test Libc.errno(reader) == LibArchive.Status.FAILED
    @test LibArchive.error_string(reader) == string(err_ex)
    LibArchive.clear_error(reader)
end

LibArchive.Reader("/this_file_does_not_exist") do reader
    local ex
    try
        LibArchive.next_header(reader)
    catch ex
    end
    @test isa(ex, ArchiveFatal)
    @test !isempty(ex.msg)
end

# Writer error
info("Test writer error handling")
let
    writer = LibArchive.Writer()
    @test writer.ptr != C_NULL
    LibArchive.free(writer)
    @test writer.ptr == C_NULL
    LibArchive.free(writer)
    @test_throws ErrorException LibArchive.add_filter_bzip2(writer)
end

LibArchive.Writer("/this_dir_does_not_exist/file") do writer
    local ex
    try
        LibArchive.finish_entry(writer)
    catch ex
    end
    @test isa(ex, ArchiveFatal)
    @test !isempty(ex.msg)
end

info("Test do block result and exception pass through")

@test_throws BoundsError LibArchive.Writer(_->throw(BoundsError([], 10)))
@test_throws ArgumentError LibArchive.Reader(_->throw(ArgumentError("a")))
@test LibArchive.Writer(_->10) === 10
@test LibArchive.Reader(_->0.1) === 0.1

info("Test availability of filters and formats")
info("    Reader")
LibArchive.Reader() do reader
    LibArchive.support_filter_all(reader)
end

LibArchive.Reader() do reader
    LibArchive.support_filter_bzip2(reader)
    LibArchive.support_filter_compress(reader)
    if LibArchive.version() >= v"3.1.0"
        LibArchive.support_filter_grzip(reader)
        LibArchive.support_filter_lrzip(reader)
        LibArchive.support_filter_lzip(reader)
        LibArchive.support_filter_lzop(reader)
    end
    LibArchive.support_filter_lzma(reader)
    LibArchive.support_filter_rpm(reader)
    LibArchive.support_filter_uu(reader)
    LibArchive.support_filter_xz(reader)
end

LibArchive.Reader() do reader
    LibArchive.support_format_all(reader)
end

LibArchive.Reader() do reader
    LibArchive.support_format_7zip(reader)
    LibArchive.support_format_ar(reader)
    LibArchive.support_format_by_code(reader, LibArchive.Format._7ZIP)
    LibArchive.support_format_cab(reader)
    LibArchive.support_format_cpio(reader)
    LibArchive.support_format_empty(reader)
    LibArchive.support_format_gnutar(reader)
    LibArchive.support_format_iso9660(reader)
    LibArchive.support_format_lha(reader)
    LibArchive.support_format_mtree(reader)
    LibArchive.support_format_rar(reader)
    LibArchive.support_format_raw(reader)
    LibArchive.support_format_tar(reader)
    LibArchive.support_format_xar(reader)
    LibArchive.support_format_zip(reader)
end

if LibArchive.version() >= v"3.1.0"
    LibArchive.Reader() do reader
        LibArchive.set_format(reader, LibArchive.Format.TAR)
        LibArchive.append_filter(reader, LibArchive.FilterType.BZIP2)
    end
end

info("    Writer")
if LibArchive.version() >= v"3.1.0"
    LibArchive.Writer() do writer
        LibArchive.add_filter(writer, LibArchive.FilterType.COMPRESS)
        LibArchive.add_filter(writer, "bzip2")
    end
end

LibArchive.Writer() do writer
    if LibArchive.version() >= v"3.1.0"
        LibArchive.add_filter_b64encode(writer)
        LibArchive.add_filter_grzip(writer)
        LibArchive.add_filter_lrzip(writer)
        LibArchive.add_filter_lzop(writer)
        LibArchive.add_filter_uuencode(writer)
    end
    LibArchive.add_filter_bzip2(writer)
    LibArchive.add_filter_compress(writer)
    LibArchive.add_filter_gzip(writer)
    LibArchive.add_filter_none(writer)
    if !Compat.Sys.isapple()
        LibArchive.add_filter_lzip(writer)
        LibArchive.add_filter_lzma(writer)
        LibArchive.add_filter_xz(writer)
    end
end

LibArchive.Writer() do writer
    LibArchive.set_format(writer, LibArchive.Format.CPIO)
    if LibArchive.version() >= v"3.1.0"
        LibArchive.set_format(writer, "gnutar")
    end
end

LibArchive.Writer() do writer
    if LibArchive.version() >= v"3.1.0"
        LibArchive.set_format_mtree_classic(writer)
        LibArchive.set_format_v7tar(writer)
    end
    LibArchive.set_format_7zip(writer)
    LibArchive.set_format_ar_bsd(writer)
    LibArchive.set_format_ar_svr4(writer)
    LibArchive.set_format_cpio(writer)
    LibArchive.set_format_cpio_newc(writer)
    LibArchive.set_format_gnutar(writer)
    LibArchive.set_format_iso9660(writer)
    LibArchive.set_format_mtree(writer)
    LibArchive.set_format_pax(writer)
    LibArchive.set_format_pax_restricted(writer)
    LibArchive.set_format_shar(writer)
    LibArchive.set_format_shar_dump(writer)
    LibArchive.set_format_ustar(writer)
    LibArchive.set_format_xar(writer)
    LibArchive.set_format_zip(writer)
end

# Copy entry
info("Test deepcopy of Entry")
let
    entry = LibArchive.Entry()
    @test !LibArchive.size_is_set(entry)
    LibArchive.set_pathname(entry, "a.txt")
    LibArchive.set_size(entry, 10)
    LibArchive.set_perm(entry, 0o644)
    LibArchive.set_filetype(entry, LibArchive.FileType.REG)

    @test LibArchive.pathname(entry) == "a.txt"
    @test LibArchive.size(entry) == 10
    @test LibArchive.size_is_set(entry)
    @test LibArchive.perm(entry) == 0o644
    @test LibArchive.filetype(entry) == LibArchive.FileType.REG

    entry_cp = deepcopy(entry)
    @test LibArchive.pathname(entry_cp) == "a.txt"
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
    dev1 = UInt64(rand(UInt32))
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

Compat.Sys.isunix() && let
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

let
    # ids / names
    entry = LibArchive.Entry()
    @test_throws ArgumentError LibArchive.gname(entry)
    @test_throws ArgumentError LibArchive.uname(entry)

    LibArchive.set_gid(entry, 2000)
    LibArchive.set_uid(entry, 2002)
    @test LibArchive.gid(entry) == 2000
    @test LibArchive.uid(entry) == 2002
    @test_throws ArgumentError LibArchive.gname(entry)
    @test_throws ArgumentError LibArchive.uname(entry)

    LibArchive.set_gname(entry, "group_name1")
    @test LibArchive.gname(entry) == "group_name1"
    if Compat.Sys.isunix()
        LibArchive.set_gname(entry, "Group αβ")
        @test LibArchive.gname(entry) == "Group αβ"
    end

    LibArchive.set_uname(entry, "user_name1")
    @test LibArchive.uname(entry) == "user_name1"
    if Compat.Sys.isunix()
        LibArchive.set_uname(entry, "User γδ")
        @test LibArchive.uname(entry) == "User γδ"
    end

    LibArchive.clear(entry)
    @test_throws ArgumentError LibArchive.gname(entry)
    @test_throws ArgumentError LibArchive.uname(entry)

    LibArchive.free(entry)
end

let
    # hardlink, pathname, sourcepath, symlink
    entry = LibArchive.Entry()

    @test_throws ArgumentError LibArchive.hardlink(entry)
    LibArchive.set_hardlink(entry, "hard_link1")
    @test LibArchive.hardlink(entry) == "hard_link1"
    if Compat.Sys.isunix()
        LibArchive.set_hardlink(entry, "Hard Link α")
        @test LibArchive.hardlink(entry) == "Hard Link α"
    end
    LibArchive.clear(entry)
    @test_throws ArgumentError LibArchive.hardlink(entry)

    @test_throws ArgumentError LibArchive.pathname(entry)
    LibArchive.set_pathname(entry, "path_name2")
    @test LibArchive.pathname(entry) == "path_name2"
    if Compat.Sys.isunix()
        LibArchive.set_pathname(entry, "Path Name β")
        @test LibArchive.pathname(entry) == "Path Name β"
    end
    LibArchive.clear(entry)
    @test_throws ArgumentError LibArchive.pathname(entry)

    @test_throws ArgumentError LibArchive.sourcepath(entry)
    LibArchive.set_sourcepath(entry, "source_path3")
    @test LibArchive.sourcepath(entry) == "source_path3"
    if Compat.Sys.isunix()
        LibArchive.set_sourcepath(entry, "Source Path γ")
        @test LibArchive.sourcepath(entry) == "Source Path γ"
    end
    LibArchive.clear(entry)
    @test_throws ArgumentError LibArchive.sourcepath(entry)

    @test_throws ArgumentError LibArchive.symlink(entry)
    LibArchive.set_symlink(entry, "sym_link4")
    @test LibArchive.symlink(entry) == "sym_link4"
    if Compat.Sys.isunix()
        LibArchive.set_symlink(entry, "Sym Link δ")
        @test LibArchive.symlink(entry) == "Sym Link δ"
    end
    LibArchive.clear(entry)
    @test_throws ArgumentError LibArchive.symlink(entry)

    LibArchive.free(entry)
end

let
    # ino and nlink
    entry = LibArchive.Entry()

    @test !LibArchive.ino_is_set(entry)
    LibArchive.set_ino(entry, 2345)
    @test LibArchive.ino(entry) == 2345
    LibArchive.set_nlink(entry, 10)
    @test LibArchive.nlink(entry) == 10

    LibArchive.clear(entry)
    @test !LibArchive.ino_is_set(entry)

    LibArchive.free(entry)
end

let
    # perm and mode
    entry = LibArchive.Entry()

    LibArchive.set_perm(entry, 0o644)
    @test LibArchive.perm(entry) == 0o644
    mode = LibArchive.mode(entry)
    strmode = LibArchive.strmode(entry)
    @test mode != 0
    @test !isempty(strmode)
    LibArchive.clear(entry)

    LibArchive.set_perm(entry, 0o600)
    @test LibArchive.perm(entry) == 0o600
    LibArchive.set_mode(entry, mode)
    @test LibArchive.perm(entry) == 0o644
    @test LibArchive.mode(entry) == mode
    @test LibArchive.strmode(entry) == strmode

    LibArchive.free(entry)
end

let
    # size
    entry = LibArchive.Entry()

    @test !LibArchive.size_is_set(entry)
    LibArchive.set_size(entry, 100)
    @test LibArchive.size_is_set(entry)
    @test LibArchive.size(entry) == 100
    LibArchive.unset_size(entry)
    @test !LibArchive.size_is_set(entry)

    LibArchive.free(entry)
end

# Create archive
info("Test creating and reading archive")
function create_archive(writer)
    entry = LibArchive.Entry(writer)
    LibArchive.set_pathname(entry, "test.txt")
    LibArchive.set_size(entry, 10)
    LibArchive.set_perm(entry, 0o644)
    LibArchive.set_filetype(entry, LibArchive.FileType.REG)
    LibArchive.write_header(writer, entry)
    write(writer, "012345678")
    write(writer, UInt8('9'))
    LibArchive.finish_entry(writer)

    entry = LibArchive.Entry(writer)
    LibArchive.set_pathname(entry, "test_a.txt")
    LibArchive.set_filetype(entry, LibArchive.FileType.LNK)
    LibArchive.set_symlink(entry, "test.txt")
    LibArchive.set_perm(entry, 0o755)
    LibArchive.write_header(writer, entry)
    LibArchive.finish_entry(writer)

    @test LibArchive.file_count(writer) == 2
end

function verify_archive(reader)
    entry = LibArchive.next_header(reader)
    @test LibArchive.pathname(entry) == "test.txt"
    @test LibArchive.size(entry) == 10
    @test LibArchive.perm(entry) == 0o644
    @test LibArchive.filetype(entry) == LibArchive.FileType.REG
    @test read(reader, String) == "0123456789"
    LibArchive.free(entry)

    entry = LibArchive.next_header(reader)
    @test LibArchive.pathname(entry) == "test_a.txt"
    @test LibArchive.filetype(entry) == LibArchive.FileType.LNK
    @test LibArchive.symlink(entry) == "test.txt"
    @test LibArchive.perm(entry) == 0o755
    LibArchive.free(entry)

    @test_throws EOFError LibArchive.next_header(reader)
    @test LibArchive.file_count(reader) == 2
end

info("    Filename")
mktempdir() do d
    cd(d) do
        LibArchive.Writer("./test.tar.bz2") do writer
            LibArchive.set_format_gnutar(writer)
            LibArchive.add_filter_bzip2(writer)
            LibArchive.set_bytes_per_block(writer, 4096)
            @test LibArchive.get_bytes_per_block(writer) == 4096
            LibArchive.set_bytes_in_last_block(writer, 1)
            @test LibArchive.get_bytes_in_last_block(writer) == 1
            create_archive(writer)
            @test LibArchive.format(writer) == LibArchive.Format.TAR_GNUTAR
            @test LibArchive.format_name(writer) == "GNU tar"
        end

        LibArchive.Reader("./test.tar.bz2") do reader
            LibArchive.support_filter_bzip2(reader)
            LibArchive.support_format_gnutar(reader)
            verify_archive(reader)
            @test LibArchive.filter_count(reader) > 0
            LibArchive.filter_bytes(reader, 0)
            @test (LibArchive.filter_code(reader, 0) ==
                   LibArchive.FilterType.BZIP2)
            @test LibArchive.filter_name(reader, 0) == "bzip2"
        end
    end
end

Compat.Sys.isunix() && mktempdir() do d
    cd(d) do
        info("    FD")
        fd = ccall(:open, Cint, (Cstring, Cint, Cint),
                   "./test.tar.gz",
                   Filesystem.JL_O_WRONLY | Filesystem.JL_O_CREAT,
                   0o644)
        LibArchive.Writer(fd) do writer
            LibArchive.set_format_gnutar(writer)
            LibArchive.add_filter_gzip(writer)
            create_archive(writer)
        end
        ccall(:close, Cint, (Cint,), fd)

        fd = ccall(:open, Cint, (Cstring, Cint),
                   "./test.tar.gz", Filesystem.JL_O_RDONLY)
        LibArchive.Reader(fd) do reader
            LibArchive.support_filter_gzip(reader)
            LibArchive.support_format_gnutar(reader)
            verify_archive(reader)
        end
        ccall(:close, Cint, (Cint,), fd)
    end
end

info("    In memory")
let
    buffer = Vector{UInt8}(4096)
    used_size = LibArchive.Writer(buffer) do writer
        LibArchive.set_format_gnutar(writer)
        LibArchive.add_filter_bzip2(writer)
        create_archive(writer)
        # We need to flush the writer for `get_used` to return useful result
        close(writer)
        LibArchive.get_used(writer)
    end

    LibArchive.Reader(buffer, used_size) do reader
        LibArchive.support_filter_bzip2(reader)
        LibArchive.support_format_gnutar(reader)
        verify_archive(reader)
    end
end

info("    In memory (C pointer)")
let
    buffer = Libc.malloc(4096)
    used_size = LibArchive.Writer(buffer, 4096) do writer
        LibArchive.set_format_gnutar(writer)
        LibArchive.add_filter_bzip2(writer)
        create_archive(writer)
        # We need to flush the writer for `get_used` to return useful result
        close(writer)
        LibArchive.get_used(writer)
    end

    LibArchive.Reader(buffer, used_size) do reader
        LibArchive.support_filter_bzip2(reader)
        LibArchive.support_format_gnutar(reader)
        verify_archive(reader)
    end
    Libc.free(buffer)
end

info("    IO Stream")
let
    io = IOBuffer()
    LibArchive.Writer(io) do writer
        LibArchive.set_format_gnutar(writer)
        LibArchive.add_filter_none(writer)
        create_archive(writer)
    end

    seek(io, 0)
    LibArchive.Reader(io) do reader
        LibArchive.support_filter_none(reader)
        LibArchive.support_format_gnutar(reader)
        verify_archive(reader)
    end
end
