using BinDeps

@BinDeps.setup

libarchive = library_dependency("libarchive", aliases = ["libarchive"])

@linux_only begin
    provides(Pacman, "libarchive", libarchive)
    provides(AptGet, "libarchive12", libarchive)
end

@windows_only begin
    using WinRPM
    provides(WinRPM.RPM, "libarchive12", libarchive, os=:Windows)
end

@BinDeps.install Dict(:libarchive => :libarchive)
