{ stdenv, lib, fetchgit, buildGoModule, zlib, makeWrapper, xcodeenv, androidenv
, xcodeWrapperArgs ? { }
, xcodeWrapper ? xcodeenv.composeXcodeWrapper xcodeWrapperArgs
, withAndroidPkgs ? true
, androidPkgs ? androidenv.composeAndroidPackages {
    includeNDK = true;
    ndkVersion = "22.1.7171670";
  } }:

buildGoModule {
  pname = "gomobile";
  version = "unstable-2022-05-04";

  vendorSha256 = "sha256-AmOy3X+d2OD7ZLbFuy+SptdlgWbZJaXYEgO79M64ufE=";

  src = fetchgit {
    rev = "50dca8fc073d03ff0058102c8e4672ac302cb764";
    name = "gomobile";
    url = "https://go.googlesource.com/mobile";
    sha256 = "sha256-ODSMMZ/qZsrszTsFqsVtRbUho4YESJSxnxQiXVgp6u4=";
  };

  subPackages = [ "bind" "cmd/gobind" "cmd/gomobile" ];

  # Fails with: go: cannot find GOROOT directory
  doCheck = false;

  nativeBuildInputs = [ makeWrapper ]
    ++ lib.optionals stdenv.isDarwin [ xcodeWrapper ];

  # Prevent a non-deterministic temporary directory from polluting the resulting object files
  postPatch = ''
    substituteInPlace cmd/gomobile/env.go --replace \
      'tmpdir, err = ioutil.TempDir("", "gomobile-work-")' \
      'tmpdir = filepath.Join(os.Getenv("NIX_BUILD_TOP"), "gomobile-work")' \
      --replace '"io/ioutil"' ""
    substituteInPlace cmd/gomobile/init.go --replace \
      'tmpdir, err = ioutil.TempDir(gomobilepath, "work-")' \
      'tmpdir = filepath.Join(os.Getenv("NIX_BUILD_TOP"), "work")'
  '';

  # Necessary for GOPATH when using gomobile.
  postInstall = ''
    mkdir -p $out/src/golang.org/x
    ln -s $src $out/src/golang.org/x/mobile
    wrapProgram $out/bin/gomobile \
  '' + lib.optionalString withAndroidPkgs ''
      --prefix PATH : "${androidPkgs.androidsdk}/bin" \
      --set ANDROID_NDK_HOME "${androidPkgs.androidsdk}/libexec/android-sdk/ndk-bundle" \
      --set ANDROID_HOME "${androidPkgs.androidsdk}/libexec/android-sdk" \
  '' + ''
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ zlib ]}"
  '';

  meta = with lib; {
    description = "A tool for building and running mobile apps written in Go";
    homepage = "https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile";
    license = licenses.bsd3;
    platforms = platforms.unix;
    maintainers = with maintainers; [ jakubgs ];
  };
}
