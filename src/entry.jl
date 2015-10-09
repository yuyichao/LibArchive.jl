###
# Archive entry

###
# Basic object manipulation

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
    # function Entry()
    #     ptr = ccall((:archive_entry_new, libarchive), Ptr{Void}, ())
    #     ptr == C_NULL && throw(OutOfMemoryError())
    #     Entry(ptr)
    # end
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
                            Libc.TmStruct, (Ptr{Void},), entry)
atime_nsec(entry::Entry) = ccall((:archive_entry_atime_nsec, libarchive),
                                 Clong, (Ptr{Void},), entry)
atime_is_set(entry::Entry) = ccall((:archive_entry_atime_is_set, libarchive),
                                   Cint, (Ptr{Void},), entry) != 0
birthtime(entry::Entry) = ccall((:archive_entry_birthtime, libarchive),
                                Libc.TmStruct, (Ptr{Void},), entry)
birthtime_nsec(entry::Entry) =
    ccall((:archive_entry_birthtime_nsec, libarchive),
          Clong, (Ptr{Void},), entry)
birthtime_is_set(entry::Entry) =
    ccall((:archive_entry_birthtime_is_set, libarchive),
          Cint, (Ptr{Void},), entry) != 0
ctime(entry::Entry) = ccall((:archive_entry_ctime, libarchive),
                            Libc.TmStruct, (Ptr{Void},), entry)
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
