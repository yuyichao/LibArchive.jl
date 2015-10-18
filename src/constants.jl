#

# Use module instead of baremodule to support document
module Status
"Found end of archive"
const EOF = Cint(1)
"Operation was successful"
const OK = Cint(0)
"Retry might succeed"
const RETRY = Cint(-10)
"Partial success"
const WARN = Cint(-20)
"Current operation cannot complete"
const FAILED = Cint(-25)
"No more operations are possible"
const FATAL = Cint(-30)
end

module FilterType
const NONE = Cint(0)
const GZIP = Cint(1)
const BZIP2 = Cint(2)
const COMPRESS = Cint(3)
const PROGRAM = Cint(4)
const LZMA = Cint(5)
const XZ = Cint(6)
const UU = Cint(7)
const RPM = Cint(8)
const LZIP = Cint(9)
const LRZIP = Cint(10)
const LZOP = Cint(11)
const GRZIP = Cint(12)
end

module Format
const BASE_MASK = Cint(0xff0000)
const CPIO = Cint(0x10000)
const CPIO_POSIX = Cint(CPIO | 1)
const CPIO_BIN_LE = Cint(CPIO | 2)
const CPIO_BIN_BE = Cint(CPIO | 3)
const CPIO_SVR4_NOCRC = Cint(CPIO | 4)
const CPIO_SVR4_CRC = Cint(CPIO | 5)
const CPIO_AFIO_LARGE = Cint(CPIO | 6)
const SHAR = Cint(0x20000)
const SHAR_BASE = Cint(SHAR | 1)
const SHAR_DUMP = Cint(SHAR | 2)
const TAR = Cint(0x30000)
const TAR_USTAR = Cint(TAR | 1)
const TAR_PAX_INTERCHANGE = Cint(TAR | 2)
const TAR_PAX_RESTRICTED = Cint(TAR | 3)
const TAR_GNUTAR = Cint(TAR | 4)
const ISO9660 = Cint(0x40000)
const ISO9660_ROCKRIDGE = Cint(ISO9660 | 1)
const ZIP = Cint(0x50000)
const EMPTY = Cint(0x60000)
const AR = Cint(0x70000)
const AR_GNU = Cint(AR | 1)
const AR_BSD = Cint(AR | 2)
const MTREE = Cint(0x80000)
const RAW = Cint(0x90000)
const XAR = Cint(0xA0000)
const LHA = Cint(0xB0000)
const CAB = Cint(0xC0000)
const RAR = Cint(0xD0000)
const _7ZIP = Cint(0xE0000)
end

module ExtractFlag
"Default: Do not try to set owner/group."
const OWNER = Cint(0x0001)
"Default: Do obey umask, do not restore SUID/SGID/SVTX bits."
const PERM = Cint(0x0002)
"Default: Do not restore mtime/atime."
const TIME = Cint(0x0004)
"Default: Replace existing files."
const NO_OVERWRITE = Cint(0x0008)
"Default: Try create first, unlink only if create fails with EEXIST."
const UNLINK = Cint(0x0010)
"Default: Do not restore ACLs."
const ACL = Cint(0x0020)
"Default: Do not restore fflags."
const FFLAGS = Cint(0x0040)
"Default: Do not restore xattrs."
const XATTR = Cint(0x0080)
"""
Default: Do not try to guard against extracts redirected by symlinks.
Note: With UNLINK, will remove any intermediate symlink.
"""
const SECURE_SYMLINKS = Cint(0x0100)
"Default: Do not reject entries with '..' as path elements."
const SECURE_NODOTDOT = Cint(0x0200)
"Default: Create parent directories as needed."
const NO_AUTODIR = Cint(0x0400)
"Default: Overwrite files, even if one on disk is newer."
const NO_OVERWRITE_NEWER = Cint(0x0800)
"Detect blocks of 0 and write holes instead."
const SPARSE = Cint(0x1000)
"""
Default: Do not restore Mac extended metadata.
This has no effect except on Mac OS.
"""
const MAC_METADATA = Cint(0x2000)
"""
Default: Use HFS+ compression if it was compressed.
This has no effect except on Mac OS v10.6 or later.
"""
const NO_HFS_COMPRESSION = Cint(0x4000)
"""
Default: Do not use HFS+ compression if it was not compressed.
This has no effect except on Mac OS v10.6 or later.
"""
const HFS_COMPRESSION_FORCED = Cint(0x8000)
end

module ReadDiskFlag
"""
Request that the access time of the entry visited by travesal be restored.
This is the same as archive_read_disk_set_atime_restored.
"""
const RESTORE_ATIME = Cint(0x0001)
"Default: Do not skip an entry which has nodump flags."
const HONOR_NODUMP = Cint(0x0002)
"""
Default: Skip a mac resource fork file whose prefix is "._" because of
using copyfile.
"""
const MAC_COPYFILE = Cint(0x0004)
"Default: Do not traverse mount points."
const NO_TRAVERSE_MOUNTS = Cint(0x0008)
end

"""
Flags to tell a matching type of time stamps. These are used for
following functinos.
"""
module MatchFlag
"Time flag: mtime to be tested"
const MTIME = Cint(0x0100)
"Time flag: ctime to be tested"
const CTIME = Cint(0x0200)
"Comparison flag: Match the time if it is newer than"
const NEWER = Cint(0x0001)
"Comparison flag: Match the time if it is older than"
const OLDER = Cint(0x0002)
"Comparison flag: Match the time if it is equal to"
const EQUAL = Cint(0x0010)
end

module FileType
import LibArchive: _la_mode_t
const MT = _la_mode_t(0o170000)
const REG = _la_mode_t(0o100000)
const LNK = _la_mode_t(0o120000)
const SOCK = _la_mode_t(0o140000)
const CHR = _la_mode_t(0o020000)
const BLK = _la_mode_t(0o060000)
const DIR = _la_mode_t(0o040000)
const IFO = _la_mode_t(0o010000)
end

module ACL
# Permission bits.

const EXECUTE = Cint(0x00000001)
const WRITE = Cint(0x00000002)
const READ = Cint(0x00000004)
const READ_DATA = Cint(0x00000008)
const LIST_DIRECTORY = Cint(0x00000008)
const WRITE_DATA = Cint(0x00000010)
const ADD_FILE = Cint(0x00000010)
const APPEND_DATA = Cint(0x00000020)
const ADD_SUBDIRECTORY = Cint(0x00000020)
const READ_NAMED_ATTRS = Cint(0x00000040)
const WRITE_NAMED_ATTRS = Cint(0x00000080)
const DELETE_CHILD = Cint(0x00000100)
const READ_ATTRIBUTES = Cint(0x00000200)
const WRITE_ATTRIBUTES = Cint(0x00000400)
const DELETE = Cint(0x00000800)
const READ_ACL = Cint(0x00001000)
const WRITE_ACL = Cint(0x00002000)
const WRITE_OWNER = Cint(0x00004000)
const SYNCHRONIZE = Cint(0x00008000)

const PERMS_POSIX1E = EXECUTE | WRITE | READ
const PERMS_NFS4 = (EXECUTE | READ_DATA | LIST_DIRECTORY | WRITE_DATA |
                    ADD_FILE | APPEND_DATA | ADD_SUBDIRECTORY |
                    READ_NAMED_ATTRS | WRITE_NAMED_ATTRS | DELETE_CHILD |
                    READ_ATTRIBUTES | WRITE_ATTRIBUTES | DELETE | READ_ACL |
                    WRITE_ACL | WRITE_OWNER | SYNCHRONIZE)

# Inheritance values (NFS4 ACLs only); included in permset.
const FILE_INHERIT = Cint(0x02000000)
const DIRECTORY_INHERIT = Cint(0x04000000)
const NO_PROPAGATE_INHERIT = Cint(0x08000000)
const INHERIT_ONLY = Cint(0x10000000)
const SUCCESSFUL_ACCESS = Cint(0x20000000)
const FAILED_ACCESS = Cint(0x40000000)

const INHERITANCE_NFS4 = (FILE_INHERIT | DIRECTORY_INHERIT |
                          NO_PROPAGATE_INHERIT | INHERIT_ONLY |
                          SUCCESSFUL_ACCESS | FAILED_ACCESS)

module Type
# We need to be able to specify combinations of these.
const ACCESS = Cint(256)  # POSIX.1e only
const DEFAULT = Cint(512) # POSIX.1e only
const ALLOW = Cint(1024) # NFS4 only
const DENY = Cint(2048) # NFS4 only
const AUDIT = Cint(4096) # NFS4 only
const ALARM = Cint(8192) # NFS4 only
const POSIX1E = (ACCESS | DEFAULT)
const NFS4 = (ALLOW | DENY | AUDIT | ALARM)
end

# Tag values mimic POSIX.1e
"Specified user."
const USER = Cint(10001)
"User who owns the file."
const USER_OBJ = Cint(10002)
"Specified group."
const GROUP = Cint(10003)
"Group who owns the file."
const GROUP_OBJ = Cint(10004)
"Modify group access (POSIX.1e only)"
const MASK = Cint(10005)
"Public (POSIX.1e only)"
const OTHER = Cint(10006)
"Everyone (NFS4 only)"
const EVERYONE = Cint(10107)
end
