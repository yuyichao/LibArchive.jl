using BinDeps
using Compat

@BinDeps.setup

function validate_libarchive(name, handle)
    try
        p = Libdl.dlsym(handle, :archive_read_free)
        return p != C_NULL
    catch
        return false
    end
end

libarchive = library_dependency("libarchive",
                                aliases=["libarchive", "libarchive-12"],
                                validate=validate_libarchive)

if is_linux()
    provides(Pacman, "libarchive", libarchive)
    provides(AptGet, "libarchive12", libarchive)
    provides(Yum, "libarchive", libarchive)
end

if is_windows()
    using WinRPM
    provides(WinRPM.RPM, "libarchive12", libarchive, os=:Windows)
end

if is_apple()
    using Homebrew
    provides(Homebrew.HB, "libarchive", libarchive, os=:Darwin)
end

@BinDeps.install Dict(:libarchive => :libarchive)
