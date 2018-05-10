###
# Error

immutable ArchiveRetry <: Exception
    msg
end
immutable ArchiveFailed <: Exception
    msg
end
immutable ArchiveFatal <: Exception
    msg
end

_la_error_msg(archive::Archive) = error_string(archive)
_la_error_msg(other) = ""

@noinline function _la_error(err::Cint, obj=nothing)
    err == Status.EOF && throw(EOFError())
    err == Status.RETRY && throw(ArchiveRetry(_la_error_msg(obj)))
    if err == Status.WARN
        warn("LibArchive: $(_la_error_msg(obj))")
        return
    end
    err == Status.FAILED && throw(ArchiveFailed(_la_error_msg(obj)))
    err == Status.FATAL && throw(ArchiveFatal(_la_error_msg(obj)))
    error("Unknown error $err")
end

macro _la_call(name, types, args...)
    call_ex = esc(:(ccall(($(QuoteNode(name)), $libarchive),
                          Cint, $types, $(args...))))
    if length(args) >= 1
        error_expr = :(_la_error(status, $(esc(:($(args[1]))))))
    else
        error_expr = :(_la_error(status))
    end
    quote
        status = $call_ex
        if status != Status.OK
            $error_expr
        end
    end
end
