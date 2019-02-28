{ stdenv, lib, fetchFromGitHub, scons, pkgconfig, libX11, libXcursor
, libXinerama, libXrandr, libXrender, libpulseaudio
, libXi ? null, libXext, libXfixes, freetype, openssl
, alsaLib, libGLU, zlib, yasm ? null }: # originally: libpulseaudio ? nil

let
  options = {
    touch = libXi != null;
  # pulseaudio = false; # turning off pulseaudio leads to a different runtime error
  };
in stdenv.mkDerivation rec {
  name    = "godot-${version}";
  version = "3.0.6";

  src = fetchFromGitHub {
    owner  = "SimulaVR";
    repo   = "godot";
    rev    = "${version}-stable";
    sha256 = "0g64h0x8dlv6aa9ggfcidk2mknkfl5li7z1phcav8aqp9srj8avf";
  };

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [
    scons libX11 libXcursor libXinerama libXrandr libXrender
    libXi libXext libXfixes freetype openssl alsaLib libpulseaudio
    libGLU zlib yasm
  ];

  patches = [
    ./pkg_config_additions.patch
    ./dont_clobber_environment.patch
  ];

  enableParallelBuilding = true;

  buildPhase = ''
    scons target=debug platform=x11 prefix=$out -j $NIX_BUILD_CORES \
      ${lib.concatStringsSep " "
          (lib.mapAttrsToList (k: v: "${k}=${builtins.toJSON v}") options)}
  '';

  outputs = [ "out" "dev" "man" ];

  installPhase = ''
    mkdir -p "$out/bin"
    cp bin/godot.* $out/bin/godot
    mkdir "$dev"
    cp -r modules/gdnative/include $dev
    mkdir -p "$man/share/man/man6"
    cp misc/dist/linux/godot.6 "$man/share/man/man6/"
    mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
    cp misc/dist/linux/godot.desktop "$out/share/applications/"
    cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
    cp icon.png "$out/share/icons/godot.png"
    substituteInPlace "$out/share/applications/godot.desktop" \
      --replace "Exec=godot" "Exec=$out/bin/godot"
  '';

  meta = {
    homepage    = "https://godotengine.org";
    description = "Free and Open Source 2D and 3D game engine";
    license     = stdenv.lib.licenses.mit;
    platforms   = [ "i686-linux" "x86_64-linux" ];
    maintainers = [ stdenv.lib.maintainers.twey ];
  };
}