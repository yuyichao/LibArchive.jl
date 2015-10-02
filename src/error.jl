###
# Error

immutable ArchiveRetry <: Exception end
immutable ArchiveWarn <: Exception end
immutable ArchiveFailed <: Exception end
immutable ArchiveFatal <: Exception end

@noinline function _la_error(err::Cint)
    err == Status.EOF && throw(EOFError())
    err == Status.RETRY && throw(ArchiveRetry())
    err == Status.WARN && throw(ArchiveWarn())
    err == Status.FAILED && throw(ArchiveFailed())
    err == Status.FATAL && throw(ArchiveFatal())
    error("Unknown error $err")
end

macro _la_call(name, types, args...)
    call_ex = esc(:(ccall(($(QuoteNode(name)), $libarchive),
                          Cint, $types, $(args...))))
    quote
        status = $call_ex
        if status != Status.OK
            _la_error(status)
        end
    end
end
