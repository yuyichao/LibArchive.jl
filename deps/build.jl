using BinDeps

@BinDeps.setup

libarchive = library_dependency("libarchive", aliases = ["libarchive"])

@linux_only begin
    provides(Pacman, "libarchive", libarchive)
    provides(AptGet, "libarchive12", libarchive)
end

@BinDeps.install Dict(:libarchive => :libarchive)
