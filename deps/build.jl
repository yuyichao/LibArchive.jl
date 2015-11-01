using BinDeps

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

@linux_only begin
    provides(Pacman, "libarchive", libarchive)
    provides(AptGet, "libarchive12", libarchive)
end

@windows_only begin
    using WinRPM
    provides(WinRPM.RPM, "libarchive12", libarchive, os=:Windows)
end

@osx_only begin
    using Homebrew
    provides(Homebrew.HB, "libarchive", libarchive, os=:Darwin)
end

@BinDeps.install Dict(:libarchive => :libarchive)
