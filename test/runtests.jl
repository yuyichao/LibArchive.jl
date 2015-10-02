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
    archive_read = LibArchive.Reader()
    @test archive_read.ptr != C_NULL
    LibArchive.free(archive_read)
    @test archive_read.ptr == C_NULL
    LibArchive.free(archive_read)
    @test_throws ErrorException LibArchive.support_filter_all(archive_read)
end
