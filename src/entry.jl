###
# Archive entry

###
# Basic object manipulation

# This will be changed to `Cint` in libarchive 4.0
const _la_mode_t = Cushort
const _Cdev_t = UInt64

type Entry
    ptr::Ptr{Void}
    function Entry(ptr::Ptr{Void})
        obj = new(ptr)
        finalizer(obj, free)
        obj
    end
    function Entry(archive::Archive)
        ptr = ccall((:archive_entry_new2, libarchive), Ptr{Void},
                    (Ptr{Void},), archive)
        ptr == C_NULL && throw(OutOfMemoryError())
        Entry(ptr)
    end
    # Mostly for testing purpose
    function Entry()
        ptr = ccall((:archive_entry_new, libarchive), Ptr{Void}, ())
        ptr == C_NULL && throw(OutOfMemoryError())
        Entry(ptr)
    end
end

function Base.deepcopy_internal(entry::Entry, stackdict::ObjectIdDict)
    ptr = ccall((:archive_entry_clone, libarchive),
                Ptr{Void}, (Ptr{Void},), entry)
    ptr == C_NULL && throw(OutOfMemoryError())
    new_entry = Entry(ptr)
    stackdict[entry] = new_entry
    new_entry
end

function clear(entry::Entry)
    ccall((:archive_entry_clear, libarchive), Ptr{Void}, (Ptr{Void},), entry)
    entry
end

function free(entry::Entry)
    ptr = entry.ptr
    ptr == C_NULL && return
    ccall((:archive_entry_free, libarchive), Void, (Ptr{Void},), ptr)
    entry.ptr = C_NULL
    nothing
end

function Base.cconvert(::Type{Ptr{Void}}, entry::Entry)
    entry.ptr == C_NULL && error("entry already freed")
    entry
end
Base.unsafe_convert(::Type{Ptr{Void}}, entry::Entry) = entry.ptr

# Retrieve fields from an archive_entry.
#
# There are a number of implicit conversions among these fields.  For
# example, if a regular string field is set and you read the _w wide
# character field, the entry will implicitly convert narrow-to-wide
# using the current locale.  Similarly, dev values are automatically
# updated when you write devmajor or devminor and vice versa.
#
# In addition, fields can be "set" or "unset."  Unset string fields
# return NULL, non-string fields have _is_set() functions to test
# whether they've been set.  You can "unset" a string field by
# assigning NULL; non-string fields have _unset() functions to
# unset them.
#
# Note: There is one ambiguity in the above; string fields will
# also return NULL when implicit character set conversions fail.
# This is usually what you want.

atime(entry::Entry) = ccall((:archive_entry_atime, libarchive),
                            Int, (Ptr{Void},), entry)
atime_nsec(entry::Entry) = ccall((:archive_entry_atime_nsec, libarchive),
                                 Clong, (Ptr{Void},), entry)
atime_is_set(entry::Entry) = ccall((:archive_entry_atime_is_set, libarchive),
                                   Cint, (Ptr{Void},), entry) != 0
birthtime(entry::Entry) = ccall((:archive_entry_birthtime, libarchive),
                                Int, (Ptr{Void},), entry)
birthtime_nsec(entry::Entry) =
    ccall((:archive_entry_birthtime_nsec, libarchive),
          Clong, (Ptr{Void},), entry)
birthtime_is_set(entry::Entry) =
    ccall((:archive_entry_birthtime_is_set, libarchive),
          Cint, (Ptr{Void},), entry) != 0
ctime(entry::Entry) = ccall((:archive_entry_ctime, libarchive),
                            Int, (Ptr{Void},), entry)
ctime_nsec(entry::Entry) = ccall((:archive_entry_ctime_nsec, libarchive),
                                 Clong, (Ptr{Void},), entry)
ctime_is_set(entry::Entry) = ccall((:archive_entry_ctime_is_set, libarchive),
                                   Cint, (Ptr{Void},), entry) != 0
dev(entry::Entry) = ccall((:archive_entry_dev, libarchive),
                          _Cdev_t, (Ptr{Void},), entry)
dev_is_set(entry::Entry) = ccall((:archive_entry_dev_is_set, libarchive),
                                 Cint, (Ptr{Void},), entry) != 0
devmajor(entry::Entry) = ccall((:archive_entry_devmajor, libarchive),
                               _Cdev_t, (Ptr{Void},), entry)
devminor(entry::Entry) = ccall((:archive_entry_devminor, libarchive),
                               _Cdev_t, (Ptr{Void},), entry)
filetype(entry::Entry) = Cint(ccall((:archive_entry_filetype, libarchive),
                                    _la_mode_t, (Ptr{Void},), entry))
function fflags(entry::Entry)
    set = Ref{Culong}(0)
    clear = Ref{Culong}(0)
    ccall((:archive_entry_fflags, libarchive),
          Void, (Ptr{Void}, Ptr{Culong}, Ptr{Culong}), entry, set, clear)
    set[], clear[]
end
fflags_text(entry::Entry) =
    bytestring(ccall((:archive_entry_fflags_text, libarchive),
                     Cstring, (Ptr{Void},), entry))
gid(entry::Entry) =
    ccall((:archive_entry_gid, libarchive), Int64, (Ptr{Void},), entry)
gname(entry::Entry) =
    bytestring(ccall((:archive_entry_gname, libarchive),
                     Cstring, (Ptr{Void},), entry))

hardlink(entry::Entry) =
    bytestring(ccall((:archive_entry_hardlink, libarchive),
                     Cstring, (Ptr{Void},), entry))
ino(entry::Entry) =
    ccall((:archive_entry_ino, libarchive), Int64, (Ptr{Void},), entry)
ino_is_set(entry::Entry) =
    ccall((:archive_entry_ino_is_set, libarchive),
          Cint, (Ptr{Void},), entry) != 0

mode(entry::Entry) =
    Cint(ccall((:archive_entry_mode, libarchive),
               _la_mode_t, (Ptr{Void},), entry))

mtime(entry::Entry) = ccall((:archive_entry_mtime, libarchive),
                            Int, (Ptr{Void},), entry)
mtime_nsec(entry::Entry) = ccall((:archive_entry_mtime_nsec, libarchive),
                                 Clong, (Ptr{Void},), entry)
mtime_is_set(entry::Entry) = ccall((:archive_entry_mtime_is_set, libarchive),
                                   Cint, (Ptr{Void},), entry) != 0

nlink(entry::Entry) =
    ccall((:archive_entry_nlink, libarchive), Cuint, (Ptr{Void},), entry)
pathname(entry::Entry) =
    bytestring(ccall((:archive_entry_pathname, libarchive),
                     Cstring, (Ptr{Void},), entry))

perm(entry::Entry) =
    Cint(ccall((:archive_entry_perm, libarchive),
               _la_mode_t, (Ptr{Void},), entry))
rdev(entry::Entry) =
    ccall((:archive_entry_rdev, libarchive), _Cdev_t, (Ptr{Void},), entry)
rdevmajor(entry::Entry) =
    ccall((:archive_entry_rdevmajor, libarchive), _Cdev_t, (Ptr{Void},), entry)
rdevminor(entry::Entry) =
    ccall((:archive_entry_rdevminor, libarchive), _Cdev_t, (Ptr{Void},), entry)
sourcepath(entry::Entry) =
    bytestring(ccall((:archive_entry_sourcepath, libarchive),
                     Cstring, (Ptr{Void},), entry))
size(entry::Entry) =
    ccall((:archive_entry_size, libarchive), Int64, (Ptr{Void},), entry)
size_is_set(entry::Entry) =
    ccall((:archive_entry_size_is_set, libarchive),
          Cint, (Ptr{Void},), entry) != 0
strmode(entry::Entry) =
    bytestring(ccall((:archive_entry_strmode, libarchive),
                     Cstring, (Ptr{Void},), entry))
symlink(entry::Entry) =
    bytestring(ccall((:archive_entry_symlink, libarchive),
                     Cstring, (Ptr{Void},), entry))
uid(entry::Entry) =
    ccall((:archive_entry_uid, libarchive), Int64, (Ptr{Void},), entry)
uname(entry::Entry) =
    bytestring(ccall((:archive_entry_uname, libarchive),
                     Cstring, (Ptr{Void},), entry))

set_atime(entry::Entry, t, ns) =
    ccall((:archive_entry_set_atime, libarchive),
          Void, (Ptr{Void}, Int, Clong), entry, t, ns)
unset_atime(entry::Entry) =
    ccall((:archive_entry_unset_atime, libarchive), Void, (Ptr{Void},), entry)
set_birthtime(entry::Entry, t, ns) =
    ccall((:archive_entry_set_birthtime, libarchive),
          Void, (Ptr{Void}, Int, Clong), entry, t, ns)
unset_birthtime(entry::Entry) =
    ccall((:archive_entry_unset_birthtime, libarchive),
          Void, (Ptr{Void},), entry)
set_ctime(entry::Entry, t, ns) =
    ccall((:archive_entry_set_ctime, libarchive),
          Void, (Ptr{Void}, Int, Clong), entry, t, ns)
unset_ctime(entry::Entry) =
    ccall((:archive_entry_unset_ctime, libarchive), Void, (Ptr{Void},), entry)
set_dev(entry::Entry, dev) =
    ccall((:archive_entry_set_dev, libarchive),
          Void, (Ptr{Void}, _Cdev_t), entry, dev)
set_devmajor(entry::Entry, dev) =
    ccall((:archive_entry_set_devmajor, libarchive),
          Void, (Ptr{Void}, _Cdev_t), entry, dev)
set_devminor(entry::Entry, dev) =
    ccall((:archive_entry_set_devminor, libarchive),
          Void, (Ptr{Void}, _Cdev_t), entry, dev)
set_filetype(entry::Entry, ftype) =
    ccall((:archive_entry_set_filetype, libarchive),
          Void, (Ptr{Void}, Cuint), entry, ftype)
set_fflags(entry::Entry, set, clear) =
    ccall((:archive_entry_set_fflags, libarchive),
          Void, (Ptr{Void}, Culong, Culong), entry, set, clear)
set_fflags(entry::Entry, fflags::AbstractString) =
    (ccall((:archive_entry_copy_fflags_text, libarchive),
           Ptr{Void}, (Ptr{Void}, Cstring), entry, fflags); nothing)
set_gid(entry::Entry, gid) =
    ccall((:archive_entry_set_gid, libarchive),
          Void, (Ptr{Void}, Int64), entry, gid)
set_gname(entry::Entry, gname::ASCIIString) =
    (ccall((:archive_entry_set_gname, libarchive),
           Void, (Ptr{Void}, Cstring), entry, gname); 0)
set_gname(entry::Entry, gname::AbstractString) =
    ccall((:archive_entry_update_gname_utf8, libarchive),
          Cint, (Ptr{Void}, Cstring), entry, gname)
set_hardlink(entry::Entry, hl::ASCIIString) =
    (ccall((:archive_entry_set_hardlink, libarchive),
           Void, (Ptr{Void}, Cstring), entry, hl); 0)
set_hardlink(entry::Entry, hl::AbstractString) =
    ccall((:archive_entry_update_hardlink_utf8, libarchive),
          Cint, (Ptr{Void}, Cstring), entry, hl)
set_ino(entry::Entry, ino) =
    ccall((:archive_entry_set_ino, libarchive),
          Void, (Ptr{Void}, Int64), entry, ino)
set_link(entry::Entry, link::ASCIIString) =
    (ccall((:archive_entry_set_link, libarchive),
           Void, (Ptr{Void}, Cstring), entry, link); 0)
set_link(entry::Entry, link::AbstractString) =
    ccall((:archive_entry_update_link_utf8, libarchive),
          Cint, (Ptr{Void}, Cstring), entry, link)
set_mode(entry::Entry, mode) =
    ccall((:archive_entry_set_mode, libarchive),
          Void, (Ptr{Void}, _la_mode_t), entry, mode)
set_mtime(entry::Entry, t, ns) =
    ccall((:archive_entry_set_mtime, libarchive),
          Void, (Ptr{Void}, Int, Clong), entry, t, ns)
unset_mtime(entry::Entry) =
    ccall((:archive_entry_unset_mtime, libarchive), Void, (Ptr{Void},), entry)
set_nlink(entry::Entry, nlink) =
    ccall((:archive_entry_set_nlink, libarchive),
          Void, (Ptr{Void}, Cuint), entry, nlink)
set_pathname(entry::Entry, path::ASCIIString) =
    (ccall((:archive_entry_set_pathname, libarchive),
           Void, (Ptr{Void}, Cstring), entry, path); 0)
set_pathname(entry::Entry, path::AbstractString) =
    ccall((:archive_entry_update_pathname_utf8, libarchive),
          Cint, (Ptr{Void}, Cstring), entry, path)
set_perm(entry::Entry, perm) =
    ccall((:archive_entry_set_perm, libarchive),
          Void, (Ptr{Void}, _la_mode_t), entry, perm)
set_rdev(entry::Entry, rdev) =
    ccall((:archive_entry_set_rdev, libarchive),
          Void, (Ptr{Void}, _Cdev_t), entry, rdev)
set_rdevmajor(entry::Entry, rdev) =
    ccall((:archive_entry_set_rdevmajor, libarchive),
          Void, (Ptr{Void}, _Cdev_t), entry, rdev)
set_rdevminor(entry::Entry, rdev) =
    ccall((:archive_entry_set_rdevminor, libarchive),
          Void, (Ptr{Void}, _Cdev_t), entry, rdev)
set_size(entry::Entry, size) =
    ccall((:archive_entry_set_size, libarchive),
          Void, (Ptr{Void}, Int64), entry, size)
unset_size(entry::Entry) =
    ccall((:archive_entry_unset_size, libarchive), Void, (Ptr{Void},), entry)
set_sourcepath(entry::Entry, path::AbstractString) =
    ccall((:archive_entry_copy_sourcepath, libarchive),
          Void, (Ptr{Void}, Cstring), entry, path)
set_symlink(entry::Entry, sym::ASCIIString) =
    (ccall((:archive_entry_set_symlink, libarchive),
           Void, (Ptr{Void}, Cstring), entry, sym); 0)
set_symlink(entry::Entry, sym::AbstractString) =
    ccall((:archive_entry_update_symlink_utf8, libarchive),
          Cint, (Ptr{Void}, Cstring), entry, sym)
set_uid(entry::Entry, uid) =
    ccall((:archive_entry_set_uid, libarchive),
          Void, (Ptr{Void}, Int64), entry, uid)
set_uname(entry::Entry, uname::ASCIIString) =
    (ccall((:archive_entry_set_uname, libarchive),
           Void, (Ptr{Void}, Cstring), entry, uname); 0)
set_uname(entry::Entry, uname::AbstractString) =
    ccall((:archive_entry_update_uname_utf8, libarchive),
          Cint, (Ptr{Void}, Cstring), entry, uname)

# Storage for Mac OS-specific AppleDouble metadata information.
# Apple-format tar files store a separate binary blob containing
# encoded metadata with ACL, extended attributes, etc.
# This provides a place to store that blob.
function mac_metadata(entry::Entry)
    _sz = Ref{Csize_t}()
    ptr = ccall((:archive_entry_mac_metadata, libarchive),
                Ptr{Void}, (Ptr{Void}, Ptr{Csize_t}), entry, _sz)
    sz = _sz[]
    data = Vector{UInt8}(sz)
    ccall(:memcpy, Ptr{Void}, (Ptr{Void}, Ptr{Void}, Csize_t), data, ptr, sz)
    data
end
set_mac_metadata(entry::Entry, data::Vector{UInt8}) =
    ccall((:archive_entry_copy_mac_metadata, libarchive),
          Void, (Ptr{Void}, Ptr{Void}, Csize_t), entry, data, sizeof(data))

# ACL routines.  This used to simply store and return text-format ACL
# strings, but that proved insufficient for a number of reasons:
#   = clients need control over uname/uid and gname/gid mappings
#   = there are many different ACL text formats
#   = would like to be able to read/convert archives containing ACLs
#     on platforms that lack ACL libraries
#
# This last point, in particular, forces me to implement a reasonably
# complete set of ACL support routines.

# Set the ACL by clearing it and adding entries one at a time.
# Unlike the POSIX.1e ACL routines, you must specify the type
# (access/default) for each entry.  Internally, the ACL data is just
# a soup of entries.  API calls here allow you to retrieve just the
# entries of interest.  This design (which goes against the spirit of
# POSIX.1e) is useful for handling archive formats that combine
# default and access information in a single ACL list.
acl_clear(entry::Entry) =
    ccall((:archive_entry_acl_clear, libarchive), Void, (Ptr{Void},), entry)
acl_add_entry(entry::Entry, typ, perm, tag, qual, name::AbstractString) =
    @_la_call(archive_entry_acl_add_entry,
              (Ptr{Void}, Cint, Cint, Cint, Cint, Cstring),
              entry, typ, perm, tag, qual, name)

# To retrieve the ACL, first "reset", then repeatedly ask for the
# "next" entry.  The want_type parameter allows you to request only
# certain types of entries.
acl_reset(entry::Entry, want) =
    ccall((:archive_entry_acl_reset, libarchive), Cint,
          (Ptr{Void}, Cint), entry, want)
function acl_next(entry::Entry, want)
    typ = Ref{Cint}()
    perm = Ref{Cint}()
    tag = Ref{Cint}()
    qual = Ref{Cint}()
    name = Ref{Ptr{UInt8}}()
    @_la_call(archive_entry_acl_next,
              (Ptr{Void}, Cint, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint},
               Ptr{Ptr{UInt8}}), entry, want, typ, perm, tag, qual, name)
    typ[], perm[], tag[], qual[], bytestring(name[])
end

"""
Construct a text-format ACL.  The flags argument is a bitmask that
can include any of the following:

* `ACL.Type.ACCESS` - Include POSIX.1e "access" entries.
* `ACL.Type.DEFAULT` - Include POSIX.1e "default" entries.
* `ACL.Type.NFS4` - Include NFS4 entries.
* `ACL.Style.EXTRA_ID` - Include extra numeric ID field in
  each ACL entry. ('star' introduced this for POSIX.1e, this flag
  also applies to NFS4.)
* `ACL.Style.MARK_DEFAULT` - Include "default:" before each
  default ACL entry, as used in old Solaris ACLs.
"""
acl_text(entry::Entry, flags) =
    bytestring(ccall((:archive_entry_acl_text, libarchive), Cstring,
                     (Ptr{Void}, Cint), entry, flags))

"Return a count of entries matching `want`"
acl_count(entry::Entry, want) =
    ccall((:archive_entry_acl_count, libarchive), Cint, (Ptr{Void}, Cint),
          entry, want)

# Return an opaque ACL object.
# There's not yet anything clients can actually do with this...
# acl(entry::Entry) =
#     ccall((:archive_entry_acl, libarchive), Ptr{archive_acl},
#           (Ptr{Void},), entry)

# extended attributes
xattr_clear(entry::Entry) =
    ccall((:archive_entry_xattr_clear, libarchive), Void, (Ptr{Void},), entry)
xattr_add_entry(entry::Entry, name::AbstractString, value) =
    ccall((:archive_entry_xattr_add_entry, libarchive), Void,
          (Ptr{Void}, Cstring, Ptr{Void}, Csize_t),
          entry, name, value, sizeof(value))

# To retrieve the xattr list, first "reset", then repeatedly ask for the
# "next" entry.
xattr_count(entry::Entry) =
    ccall((:archive_entry_xattr_count, libarchive), Cint, (Ptr{Void},), entry)
xattr_reset(entry::Entry) =
    ccall((:archive_entry_xattr_reset, libarchive), Cint, (Ptr{Void},), entry)
function xattr_next(entry::Entry)
    name = Ref{Ptr{UInt8}}()
    value = Ref{Ptr{Void}}()
    len = Ref{Csize_t}()
    @_la_call(archive_entry_xattr_next,
              (Ptr{Void}, Ptr{Ptr{UInt8}}, Ptr{Ptr{Void}}, Ptr{Csize_t}),
              entry, name, value, len)
    buff = Vector{UInt8}(len[])
    ccall(:memcpy, Ptr{Void}, (Ptr{Void}, Ptr{Void}, Csize_t),
          buff, value[], len[])
    bytestring(name[]), buff
end

# sparse
sparse_clear(entry::Entry) =
    ccall((:archive_entry_sparse_clear, libarchive), Void, (Ptr{Void},), entry)
sparse_add_entry(entry::Entry, offset, len) =
    ccall((:archive_entry_sparse_add_entry, libarchive), Void,
          (Ptr{Void}, Int64, Int64), entry, offset, len)

# To retrieve the xattr list, first "reset", then repeatedly ask for the
# "next" entry.
sparse_count(entry::Entry) =
    ccall((:archive_entry_sparse_count, libarchive), Cint, (Ptr{Void},), entry)
sparse_reset(entry::Entry) =
    ccall((:archive_entry_sparse_reset, libarchive), Cint, (Ptr{Void},), entry)
function sparse_next(entry::Entry)
    offset = Ref{Int64}()
    len = Ref{Int64}()
    @_la_call(archive_entry_sparse_next,
              (Ptr{Void}, Ptr{Int64}, Ptr{Int64}), entry, offset, len)
    offset[], len[]
end
