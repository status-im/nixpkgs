{deployAndroidPackage, lib, package, os, autoPatchelfHook, pkgs}:

deployAndroidPackage {
  inherit package os;
  nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optional (os == "linux") [ pkgs.stdenv.glibc pkgs.stdenv.cc.cc pkgs.ncurses5 ];
  patchInstructions = lib.optionalString (os == "linux") ''
    autoPatchelf $packageBaseDir/bin
  '';
}
