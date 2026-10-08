{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  versionCheckHook,
}:

let
  # Written by update.sh from Google's release manifest.
  release = lib.importJSON ./release.json;

  platform = {
    x86_64-linux = "linux-x64";
    aarch64-linux = "linux-arm";
  };

  system = stdenvNoCC.hostPlatform.system;
  source = release.platforms.${platform.${system} or (throw "agy-nix: unsupported system ${system}")};
in
stdenvNoCC.mkDerivation {
  pname = "antigravity-cli";
  inherit (release) version;

  src = fetchurl {
    inherit (source) url hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 antigravity $out/bin/agy

    # agy updates itself in the background; the store is read-only, so turn it off.
    wrapProgram $out/bin/agy --set-default AGY_CLI_DISABLE_AUTO_UPDATE true
    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Google's terminal agent client (Antigravity CLI)";
    homepage = "https://antigravity.google";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = lib.attrNames platform;
    mainProgram = "agy";
  };
}
