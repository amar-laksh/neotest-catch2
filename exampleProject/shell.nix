with import <nixpkgs> { };


mkShell.override
{ stdenv = gcc12Stdenv; }
{
  name = "Standard C++ shell (gcc12) with testing and benchmarking support.";
  nativebuildInputs = [
    ninja
  ];
  buildInputs = [
    fzf
    cmake
    hyperfine
    catch2
    lldb_16
    mold
    ninja
    dos2unix
    clang-tools_15
    which
  ];
  NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
    gcc12Stdenv.cc
  ];
  shellHook = ''
    export LD_LIBRARY_PATH="${lib.makeLibraryPath [ gcc12Stdenv.cc.cc.lib ]}"
  '';
  NIX_LD = lib.fileContents "${gcc12Stdenv.cc}/nix-support/dynamic-linker";
}
