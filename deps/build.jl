using BinDeps
using Compat

@BinDeps.setup

libarchive = library_dependency("libarchive", aliases = ["libarchive"])

@linux_only begin
    provides(Pacman, "libarchive", libarchive)
end

@BinDeps.install @compat Dict(:libarchive => :libarchive)
