#

using LibArchive
using Test
import Base.Filesystem

## Version
@info("Testing libarchive $(LibArchive.version()::VersionNumber)")

## Error
@testset "Error translation" begin
    @test_throws EOFError LibArchive._la_error(LibArchive.Status.EOF)
    @test_throws ArchiveRetry LibArchive._la_error(LibArchive.Status.RETRY)
    @test_throws ArchiveFailed LibArchive._la_error(LibArchive.Status.FAILED)
    @test_throws ArchiveFatal LibArchive._la_error(LibArchive.Status.FATAL)
    @test_throws ErrorException LibArchive._la_error(Cint(-1024))
end

## Reader error
@testset "Reader error handling" begin
    let
        local reader = LibArchive.Reader()
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
end

# Writer error
@testset "Writer error handling" begin
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
end

@testset "Do block result and exception pass through" begin
    @test_throws BoundsError LibArchive.Writer(_->throw(BoundsError([], 10)))
    @test_throws ArgumentError LibArchive.Reader(_->throw(ArgumentError("a")))
    @test LibArchive.Writer(_->10) === 10
    @test LibArchive.Reader(_->0.1) === 0.1
end

@testset "Availability of filters and formats" begin
    @testset "Reader" begin
        LibArchive.Reader() do reader
            LibArchive.support_filter_all(reader)
        end

        LibArchive.Reader() do reader
            LibArchive.support_filter_bzip2(reader)
            LibArchive.support_filter_compress(reader)
            LibArchive.support_filter_grzip(reader)
            LibArchive.support_filter_lrzip(reader)
            LibArchive.support_filter_lz4(reader)
            LibArchive.support_filter_lzip(reader)
            LibArchive.support_filter_lzop(reader)
            LibArchive.support_filter_lzma(reader)
            LibArchive.support_filter_rpm(reader)
            LibArchive.support_filter_uu(reader)
            LibArchive.support_filter_xz(reader)
            LibArchive.support_filter_zstd(reader)
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
            LibArchive.support_format_rar5(reader)
            LibArchive.support_format_raw(reader)
            LibArchive.support_format_tar(reader)
            LibArchive.support_format_xar(reader)
            LibArchive.support_format_zip(reader)
        end

        LibArchive.Reader() do reader
            LibArchive.set_format(reader, LibArchive.Format.TAR)
            LibArchive.append_filter(reader, LibArchive.FilterType.BZIP2)
        end
    end

    @testset "Writer" begin
        LibArchive.Writer() do writer
            LibArchive.add_filter(writer, LibArchive.FilterType.COMPRESS)
            LibArchive.add_filter(writer, "bzip2")
        end

        LibArchive.Writer() do writer
            LibArchive.add_filter_b64encode(writer)
            LibArchive.add_filter_grzip(writer)
            LibArchive.add_filter_lrzip(writer)
            LibArchive.add_filter_lz4(writer)
            LibArchive.add_filter_lzop(writer)
            LibArchive.add_filter_uuencode(writer)
            LibArchive.add_filter_bzip2(writer)
            LibArchive.add_filter_compress(writer)
            LibArchive.add_filter_gzip(writer)
            LibArchive.add_filter_none(writer)
            if !Sys.isapple()
                LibArchive.add_filter_lzip(writer)
                LibArchive.add_filter_lzma(writer)
                LibArchive.add_filter_xz(writer)
                LibArchive.add_filter_zstd(writer)
            end
        end

        LibArchive.Writer() do writer
            LibArchive.set_format(writer, LibArchive.Format.CPIO)
            LibArchive.set_format(writer, "gnutar")
        end

        LibArchive.Writer() do writer
            LibArchive.set_format_mtree_classic(writer)
            LibArchive.set_format_v7tar(writer)
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
    end
end

# Copy entry
@testset "Deepcopy of Entry" begin
    local entry = LibArchive.Entry()
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

    local entry_cp = deepcopy(entry)
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
@testset "Entry properties" begin
    @testset "Time stamps" begin
        local entry = LibArchive.Entry()
        local t = floor(Int, time())
        local ns = rand(1:(10^8))

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

    @testset "Dev number" begin
        local entry = LibArchive.Entry()
        local dev1 = UInt64(rand(UInt32))
        # There doesn't seem to be a portable way to convert between minor and
        # major dev_t and the full dev_t
        local devmajor2 = UInt64(rand(UInt8))
        local devminor2 = UInt64(rand(UInt8))

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

    @testset "File type" begin
        local entry = LibArchive.Entry()

        for ft in (LibArchive.FileType.MT, LibArchive.FileType.REG,
                   LibArchive.FileType.LNK, LibArchive.FileType.SOCK,
                   LibArchive.FileType.CHR, LibArchive.FileType.BLK,
                   LibArchive.FileType.DIR, LibArchive.FileType.IFO)
            LibArchive.set_filetype(entry, ft)
            @test LibArchive.filetype(entry) == ft
        end

        LibArchive.free(entry)
    end

    Sys.isunix() && @testset "Flags" begin
        local entry = LibArchive.Entry()
        @test_throws ArgumentError LibArchive.fflags_text(entry)

        LibArchive.set_fflags(entry, 1, 2)
        @test LibArchive.fflags(entry) == (1, 2)
        local flags_txt = LibArchive.fflags_text(entry)
        @test !isempty(flags_txt)

        LibArchive.free(entry)

        local entry2 = LibArchive.Entry()
        @test_throws ArgumentError LibArchive.fflags_text(entry2)
        LibArchive.set_fflags(entry2, flags_txt)
        @test LibArchive.fflags(entry2) == (1, 2)
        @test LibArchive.fflags_text(entry2) == flags_txt

        LibArchive.free(entry2)
    end

    @testset "IDs / names" begin
        local entry = LibArchive.Entry()
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
        if Sys.isunix()
            LibArchive.set_gname(entry, "Group αβ")
            @test LibArchive.gname(entry) == "Group αβ"
        end

        LibArchive.set_uname(entry, "user_name1")
        @test LibArchive.uname(entry) == "user_name1"
        if Sys.isunix()
            LibArchive.set_uname(entry, "User γδ")
            @test LibArchive.uname(entry) == "User γδ"
        end

        LibArchive.clear(entry)
        @test_throws ArgumentError LibArchive.gname(entry)
        @test_throws ArgumentError LibArchive.uname(entry)

        LibArchive.free(entry)
    end

    @testset "Path / links" begin
        local entry = LibArchive.Entry()

        @test_throws ArgumentError LibArchive.hardlink(entry)
        LibArchive.set_hardlink(entry, "hard_link1")
        @test LibArchive.hardlink(entry) == "hard_link1"
        if Sys.isunix()
            LibArchive.set_hardlink(entry, "Hard Link α")
            @test LibArchive.hardlink(entry) == "Hard Link α"
        end
        LibArchive.clear(entry)
        @test_throws ArgumentError LibArchive.hardlink(entry)

        @test_throws ArgumentError LibArchive.pathname(entry)
        LibArchive.set_pathname(entry, "path_name2")
        @test LibArchive.pathname(entry) == "path_name2"
        if Sys.isunix()
            LibArchive.set_pathname(entry, "Path Name β")
            @test LibArchive.pathname(entry) == "Path Name β"
        end
        LibArchive.clear(entry)
        @test_throws ArgumentError LibArchive.pathname(entry)

        @test_throws ArgumentError LibArchive.sourcepath(entry)
        LibArchive.set_sourcepath(entry, "source_path3")
        @test LibArchive.sourcepath(entry) == "source_path3"
        if Sys.isunix()
            LibArchive.set_sourcepath(entry, "Source Path γ")
            @test LibArchive.sourcepath(entry) == "Source Path γ"
        end
        LibArchive.clear(entry)
        @test_throws ArgumentError LibArchive.sourcepath(entry)

        @test_throws ArgumentError LibArchive.symlink(entry)
        LibArchive.set_symlink(entry, "sym_link4")
        @test LibArchive.symlink(entry) == "sym_link4"
        if Sys.isunix()
            LibArchive.set_symlink(entry, "Sym Link δ")
            @test LibArchive.symlink(entry) == "Sym Link δ"
        end
        LibArchive.clear(entry)
        @test_throws ArgumentError LibArchive.symlink(entry)

        LibArchive.free(entry)
    end

    @testset "inode / nlink" begin
        local entry = LibArchive.Entry()

        @test !LibArchive.ino_is_set(entry)
        LibArchive.set_ino(entry, 2345)
        @test LibArchive.ino(entry) == 2345
        LibArchive.set_nlink(entry, 10)
        @test LibArchive.nlink(entry) == 10

        LibArchive.clear(entry)
        @test !LibArchive.ino_is_set(entry)

        LibArchive.free(entry)
    end

    @testset "Permission / mode" begin
        local entry = LibArchive.Entry()

        LibArchive.set_perm(entry, 0o644)
        @test LibArchive.perm(entry) == 0o644
        local mode = LibArchive.mode(entry)
        local strmode = LibArchive.strmode(entry)
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

    @testset "Size" begin
        local entry = LibArchive.Entry()

        @test !LibArchive.size_is_set(entry)
        LibArchive.set_size(entry, 100)
        @test LibArchive.size_is_set(entry)
        @test LibArchive.size(entry) == 100
        LibArchive.unset_size(entry)
        @test !LibArchive.size_is_set(entry)

        LibArchive.free(entry)
    end
end

function create_archive(writer, passphrase=nothing, passphrase_cb=false)
    callback_called = Ref(false)
    if passphrase_cb
        LibArchive.set_passphrase(writer, ()->(callback_called[] = true; passphrase))
    elseif passphrase !== nothing
        LibArchive.set_passphrase(writer, passphrase)
    end

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
    close(writer)
    @test !passphrase_cb || callback_called[]
end

function verify_archive(reader, passphrase=nothing, passphrase_cb=false)
    callback_called = Ref(false)
    if passphrase_cb
        LibArchive.set_passphrase(reader, ()->(callback_called[] = true; passphrase))
    elseif passphrase !== nothing
        LibArchive.add_passphrase(reader, passphrase)
    end

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
    @test !passphrase_cb || callback_called[]
end

function cd_tmpdir(cb)
    mktempdir() do d
        cd(d) do
            cb(d)
        end
    end
end

@testset "Creating and reading archive" begin
    @testset "Filename" begin
        cd_tmpdir() do d
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

    Sys.isunix() && @testset "FD" begin
        cd_tmpdir() do d
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

    @testset "In memory" begin
        local buffer = Vector{UInt8}(undef, 4096)
        local used_size = LibArchive.Writer(buffer) do writer
            LibArchive.set_format_gnutar(writer)
            LibArchive.add_filter_bzip2(writer)
            create_archive(writer)
            LibArchive.get_used(writer)
        end

        LibArchive.Reader(buffer, used_size) do reader
            LibArchive.support_filter_bzip2(reader)
            LibArchive.support_format_gnutar(reader)
            verify_archive(reader)
        end
    end

    @testset "    In memory (C pointer)" begin
        local buffer = Libc.malloc(4096)
        local used_size = LibArchive.Writer(buffer, 4096) do writer
            LibArchive.set_format_gnutar(writer)
            LibArchive.add_filter_bzip2(writer)
            create_archive(writer)
            LibArchive.get_used(writer)
        end

        LibArchive.Reader(buffer, used_size) do reader
            LibArchive.support_filter_bzip2(reader)
            LibArchive.support_format_gnutar(reader)
            verify_archive(reader)
        end
        Libc.free(buffer)
    end

    @testset "IO Stream" begin
        local io = IOBuffer()
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
end

function test_zip(passphrase, use_cb_w=false, use_cb_r=false)
    io = IOBuffer()
    LibArchive.Writer(io) do writer
        LibArchive.set_format_zip(writer)
        LibArchive.add_filter_none(writer)
        LibArchive.set_options(writer, "zip:encryption=aes128")
        create_archive(writer, passphrase, use_cb_w)
    end

    seek(io, 0)
    LibArchive.Reader(io) do reader
        LibArchive.support_filter_none(reader)
        LibArchive.support_format_zip(reader)
        verify_archive(reader, passphrase, use_cb_r)
    end
end

@testset "Passphrase" begin
    test_zip("password1234", false, false)
    test_zip("password3142", false, true)
    test_zip("password1324", true, false)
    test_zip("password2143", true, true)
end
