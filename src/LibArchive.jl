#

__precompile__()

module LibArchive

using Compat

if !isdefined(:unsafe_string)
    unsafe_string(args...) = bytestring(args...)
    unsafe_wrap(::Type{Array}, ptr, len) = pointer_to_array(ptr, len)
end

if isdefined(Base, :unsafe_read)
    # I forgot to add `unsafe_read` to `Compat` ;-P
    import Base: unsafe_read, unsafe_write
else
    const unsafe_read = read
    const unsafe_write = write
end

export ArchiveRetry, ArchiveFailed, ArchiveFatal

const depfile = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(depfile)
    include(depfile)
else
    error("LibArchive not properly installed. Please run Pkg.build(\"LibArchive\")")
end

include("constants.jl")

###
# Version

"""
libarchive version number
"""
function version()
    vernum = ccall((:archive_version_number, libarchive), Cint, ())
    vernum, patch = divrem(vernum, Cint(1000))
    major, minor = divrem(vernum, Cint(1000))
    VersionNumber(major, minor, patch)
end

@compat abstract type Archive <: IO end

function archive_guard(func::Function, archive::Archive)
    try
        res = func(archive)
        # Only explicitly close if the function didn't throw an error
        # otherwise, only call free to avoid overriding user exceptions
        close(archive)
        return res
    finally
        free(archive)
    end
end

include("error.jl")
include("callback.jl")
include("archive_utils.jl")
include("entry.jl")
include("reader.jl")
include("writer.jl")
include("format.jl")

# /*
#  * Set archive_match object that will be used in archive_read_disk to
#  * know whether an entry should be skipped. The callback function
#  * _excluded_func will be invoked when an entry is skipped by the result
#  * of archive_match.
#  */
# int	archive_read_disk_set_matching(struct archive *,
# 		    struct archive *_matching, void (*_excluded_func)
# 		    (struct archive *, void *, struct archive_entry *),
# 		    void *_client_data);
# int	archive_read_disk_set_metadata_filter_callback(struct archive *,
# 		    int (*_metadata_filter_func)(struct archive *, void *,
# 		    	struct archive_entry *), void *_client_data);

# /*
#  * ARCHIVE_MATCH API
#  */
# struct archive *archive_match_new(void);
# int	archive_match_free(struct archive *);

# /*
#  * Test if archive_entry is excluded.
#  * This is a convenience function. This is the same as calling all
#  * archive_match_path_excluded, archive_match_time_excluded
#  * and archive_match_owner_excluded.
#  */
# int	archive_match_excluded(struct archive *,
# 		    struct archive_entry *);

# /*
#  * Test if pathname is excluded. The conditions are set by following functions.
#  */
# int	archive_match_path_excluded(struct archive *,
# 		    struct archive_entry *);
# /* Add exclusion pathname pattern. */
# int	archive_match_exclude_pattern(struct archive *, const char *);
# /* Add exclusion pathname pattern from file. */
# int	archive_match_exclude_pattern_from_file(struct archive *,
# 		    const char *, int _nullSeparator);
# /* Add inclusion pathname pattern. */
# int	archive_match_include_pattern(struct archive *, const char *);
# /* Add inclusion pathname pattern from file. */
# int	archive_match_include_pattern_from_file(struct archive *,
# 		    const char *, int _nullSeparator);
# /*
#  * How to get statistic information for inclusion patterns.
#  */
# /* Return the amount number of unmatched inclusion patterns. */
# int	archive_match_path_unmatched_inclusions(struct archive *);
# /* Return the pattern of unmatched inclusion with ARCHIVE_OK.
#  * Return ARCHIVE_EOF if there is no inclusion pattern. */
# int	archive_match_path_unmatched_inclusions_next(
# 		    struct archive *, const char **);

# /*
#  * Test if a file is excluded by its time stamp.
#  * The conditions are set by following functions.
#  */
# int	archive_match_time_excluded(struct archive *,
# 		    struct archive_entry *);

# /* Set inclusion time. */
# int	archive_match_include_time(struct archive *, int _flag,
# 		    time_t _sec, long _nsec);
# /* Set inclusion time by a date string. */
# int	archive_match_include_date(struct archive *, int _flag,
# 		    const char *_datestr);
# /* Set inclusion time by a particluar file. */
# int	archive_match_include_file_time(struct archive *,
# 		    int _flag, const char *_pathname);
# /* Add exclusion entry. */
# int	archive_match_exclude_entry(struct archive *,
# 		    int _flag, struct archive_entry *);

# /*
#  * Test if a file is excluded by its uid ,gid, uname or gname.
#  * The conditions are set by following functions.
#  */
# int	archive_match_owner_excluded(struct archive *,
# 		    struct archive_entry *);
# /* Add inclusion uid, gid, uname and gname. */
# int	archive_match_include_uid(struct archive *, int64_t);
# int	archive_match_include_gid(struct archive *, int64_t);
# int	archive_match_include_uname(struct archive *, const char *);
# int	archive_match_include_gname(struct archive *, const char *);

# /*
#  * ARCHIVE_READ_DISK API
#  *
#  * This is still evolving and somewhat experimental.
#  */
# struct archive *archive_read_disk_new(void);
# /* The names for symlink modes here correspond to an old BSD
#  * command-line argument convention: -L, -P, -H */
# /* Follow all symlinks. */
# int archive_read_disk_set_symlink_logical(struct archive *);
# /* Follow no symlinks. */
# int archive_read_disk_set_symlink_physical(struct archive *);
# /* Follow symlink initially, then not. */
# int archive_read_disk_set_symlink_hybrid(struct archive *);
# /* TODO: Handle Linux stat32/stat64 ugliness. <sigh> */
# int archive_read_disk_entry_from_file(struct archive *,
#     struct archive_entry *, int /* fd */, const struct stat *);
# /* Look up gname for gid or uname for uid. */
# /* Default implementations are very, very stupid. */
# const char *archive_read_disk_gname(struct archive *, int64_t);
# const char *archive_read_disk_uname(struct archive *, int64_t);
# /* "Standard" implementation uses getpwuid_r, getgrgid_r and caches the
#  * results for performance. */
# int	archive_read_disk_set_standard_lookup(struct archive *);
# /* You can install your own lookups if you like. */
# int	archive_read_disk_set_gname_lookup(struct archive *,
#     void * /* private_data */,
#     const char *(* /* lookup_fn */)(void *, int64_t),
#     void (* /* cleanup_fn */)(void *));
# int	archive_read_disk_set_uname_lookup(struct archive *,
#     void * /* private_data */,
#     const char *(* /* lookup_fn */)(void *, int64_t),
#     void (* /* cleanup_fn */)(void *));
# /* Start traversal. */
# int	archive_read_disk_open(struct archive *, const char *);
# /*
#  * Request that current entry be visited.  If you invoke it on every
#  * directory, you'll get a physical traversal.  This is ignored if the
#  * current entry isn't a directory or a link to a directory.  So, if
#  * you invoke this on every returned path, you'll get a full logical
#  * traversal.
#  */
# int	archive_read_disk_descend(struct archive *);
# int	archive_read_disk_can_descend(struct archive *);
# int	archive_read_disk_current_filesystem(struct archive *);
# int	archive_read_disk_current_filesystem_is_synthetic(struct archive *);
# int	archive_read_disk_current_filesystem_is_remote(struct archive *);
# /* Request that the access time of the entry visited by travesal be restored. */
# int  archive_read_disk_set_atime_restored(struct archive *);

# /*
#  * Set behavior. The "flags" argument selects optional behavior.
#  */
# int  archive_read_disk_set_behavior(struct archive *,
# 		    int flags);

# /*-
#  * ARCHIVE_WRITE_DISK API
#  *
#  * To create objects on disk:
#  *   1) Ask archive_write_disk_new for a new archive_write_disk object.
#  *   2) Set any global properties.  In particular, you probably
#  *      want to set the options.
#  *   3) For each entry:
#  *      - construct an appropriate struct archive_entry structure
#  *      - archive_write_header to create the file/dir/etc on disk
#  *      - archive_write_data to write the entry data
#  *   4) archive_write_free to cleanup the writer and release resources
#  *
#  * In particular, you can use this in conjunction with archive_read()
#  * to pull entries out of an archive and create them on disk.
#  */
# struct archive	*archive_write_disk_new(void);
# /* This file will not be overwritten. */
# int archive_write_disk_set_skip_file(struct archive *,
#     int64_t, int64_t);
# /* Set flags to control how the next item gets created.
#  * This accepts a bitmask of ARCHIVE_EXTRACT_XXX flags defined above. */
# int		 archive_write_disk_set_options(struct archive *,
# 		     int flags);
# /*
#  * The lookup functions are given uname/uid (or gname/gid) pairs and
#  * return a uid (gid) suitable for this system.  These are used for
#  * restoring ownership and for setting ACLs.  The default functions
#  * are naive, they just return the uid/gid.  These are small, so reasonable
#  * for applications that don't need to preserve ownership; they
#  * are probably also appropriate for applications that are doing
#  * same-system backup and restore.
#  */
# /*
#  * The "standard" lookup functions use common system calls to lookup
#  * the uname/gname, falling back to the uid/gid if the names can't be
#  * found.  They cache lookups and are reasonably fast, but can be very
#  * large, so they are not used unless you ask for them.  In
#  * particular, these match the specifications of POSIX "pax" and old
#  * POSIX "tar".
#  */
# int	 archive_write_disk_set_standard_lookup(struct archive *);
# /*
#  * If neither the default (naive) nor the standard (big) functions suit
#  * your needs, you can write your own and register them.  Be sure to
#  * include a cleanup function if you have allocated private data.
#  */
# int archive_write_disk_set_group_lookup(struct archive *,
#     void * /* private_data */,
#     int64_t (*)(void *, const char *, int64_t),
#     void (* /* cleanup */)(void *));
# int archive_write_disk_set_user_lookup(struct archive *,
#     void * /* private_data */,
#     int64_t (*)(void *, const char *, int64_t),
#     void (* /* cleanup */)(void *));
# int64_t archive_write_disk_gid(struct archive *, const char *, int64_t);
# int64_t archive_write_disk_uid(struct archive *, const char *, int64_t);

end
