{
  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05"; };
  outputs = inputs@{ nixpkgs, ... }:
    let
      eachSystem = systems: f:
        let
          op = attrs: system:
            let
              ret = f system;
              op = attrs: key:
                let
                  appendSystem = key: system: ret: { ${system} = ret.${key}; };
                in attrs // {
                  ${key} = (attrs.${key} or { })
                    // (appendSystem key system ret);
                };
            in builtins.foldl' op attrs (builtins.attrNames ret);
        in builtins.foldl' op { } systems;
      defaultSystems = [ "x86_64-linux" "aarch64-darwin" ];
    in eachSystem defaultSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
        basename = "appname";
        src = pkgs.nix-gitignore.gitignoreSource [ ".git" ] ./.;
        package = (pkgs.lib.importJSON (src + "/package.json"));
        nodeVersion =
          builtins.elemAt (pkgs.lib.versions.splitVersion pkgs.nodejs.version)
          0;
        webappDrv = buildMode:
          pkgs.mkYarnPackage rec {
            name = package.name;
            version = package.version;
            src = pkgs.nix-gitignore.gitignoreSource [ ".git" ] ./.;
            preConfigure = ''
              substituteInPlace package.json --replace "webpack --config webpack.web.config.mjs" "yarn exec webpack-cli -- --mode=development --config webpack.web.config.mjs --env buildMode=${buildMode}"
            '';
            buildPhase = ''
              yarn run build:webapp
            '';
            installPhase = "cp -r ./deps/${name}/release/renderer $out";
            distPhase = "true";
          };
        webapp = webappDrv "webapp";
        server = pkgs.mkYarnPackage rec {
          name = basename + "-server";
          version = "1.0.0";
          src = ./src/server;
          buildPhase = ''
            mkdir -p deps/${name}/build
            cp -r ${webappDrv "server"}/* deps/${name}/build/
            chmod -R 755 deps/${name}/build/*
          '';
        };
        electronBuilds = {
          "23.1.0" = {
            "linux-x64" = pkgs.fetchurl {
              url =
                "https://github.com/electron/electron/releases/download/v23.1.0/electron-v23.1.0-linux-x64.zip";
              sha256 = "sha256-fqwx/a+xhUr2W9Rr6L8xGFEH2xl5PeUs5HfEj8jSDyk=";
            };
            "win32-x64" = pkgs.fetchurl {
              url =
                "https://github.com/electron/electron/releases/download/v23.1.0/electron-v23.1.0-win32-x64.zip";
              sha256 = "sha256-UnbuaHBFnxbuhGk3Uwamp8A+Rp9ZyETmAQZWvGQo8OY=";
            };
            "win32-ia32" = pkgs.fetchurl {
              url =
                "https://github.com/electron/electron/releases/download/v23.1.0/electron-v23.1.0-win32-ia32.zip";
              sha256 = "sha256-GAB7V4P9t5qMCpQk0/ZJkLnPo09UtWmTJ/M+UKG+gyg=";
            };
            "darwin-x64" = pkgs.fetchurl {
              url =
                "https://github.com/electron/electron/releases/download/v23.1.0/electron-v23.1.0-darwin-x64.zip";
              sha256 = "sha256-+MnFGuGQzKSya//09sOjq27viLPTysdhvzfFxTPD8+0=";
            };
            "darwin-arm64" = pkgs.fetchurl {
              url =
                "https://github.com/electron/electron/releases/download/v23.1.0/electron-v23.1.0-darwin-arm64.zip";
              sha256 = "sha256-rXQthvZCDMSc2xzpPwqRnqNCjKkCh4u7MkHuYDAw7/8=";
            };
          };
        };
        electronZipDir = let electronBuild = electronBuilds."23.1.0";
        in pkgs.linkFarm "electron-zip-dir" [
          {
            name = "${electronBuild.linux-x64.name}";
            path = electronBuild.linux-x64;
          }
          {
            name = "${electronBuild.win32-x64.name}";
            path = electronBuild.win32-x64;
          }
          {
            name = "${electronBuild.win32-ia32.name}";
            path = electronBuild.win32-ia32;
          }
          {
            name = "${electronBuild.darwin-x64.name}";
            path = electronBuild.darwin-x64;
          }
          {
            name = "${electronBuild.darwin-arm64.name}";
            path = electronBuild.darwin-arm64;
          }
        ];
        buildZip = arch:
          pkgs.mkYarnPackage rec {
            name = package.name;
            version = package.version;
            src = pkgs.nix-gitignore.gitignoreSource [ ".git" ] ./.;
            electron_zip_dir = electronZipDir;
            ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
            extraBuildInputs = [ pkgs.zip ];
            # DEBUG = "*"; 
            buildPhase = ''
              mkdir home
              touch home/.skip-forge-system-check
              rm ./deps/${name}/${name}
              HOME="$(realpath home)" yarn run electron-forge -- make --arch ${arch} --platform darwin --targets @electron-forge/maker-zip
            '';
            installPhase =
              "cp -r ./deps/${name}/out/make/zip/darwin/${arch} $out";
            distPhase = "true";
          };
        buildExeSquirrel = arch:
          pkgs.mkYarnPackage rec {
            name = package.name;
            version = package.version;
            src = pkgs.nix-gitignore.gitignoreSource [ ".git" ] ./.;
            electron_zip_dir = electronZipDir;
            ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
            extraBuildInputs =
              [ pkgs.wineWowPackages.full pkgs.mono pkgs.fontconfig pkgs.zip ];
            # DEBUG = "*";
            preConfigure = ''
              # substituteInPlace package.json --replace "electron-forge make" "yarn exec electron-forge -- make --arch ${arch} --platform win32 --targets @electron-forge/maker-squirrel"
            '';
            buildPhase = ''
              # electron-forge needs 'home' with a skip check file
              mkdir home
              touch home/.skip-forge-system-check
              ## squirrel is upset with symlink './deps/name/name -> .deps/name'
              #rm ./deps/${name}/${name} 
              ## squirrel needs write access to node_modules
              #rm ./deps/${name}/node_modules
              #rm ./node_modules/${name}
              #cp -r ./node_modules ./deps/${name}/node_modules
              #chmod -R 755 ./deps/${name}/node_modules
              ## squirrel needs fontconfig
              ## squirrel tries to start a GUI app and fails
              # DISPLAY=:0 HOME="$(realpath home)" FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf FONTCONFIG_PATH=${pkgs.fontconfig.out}/etc/fonts/ yarn run build:electron
            '';
            installPhase =
              "cp -r ./deps/${name}/out/make/squirrel.windows/${arch} $out";
            distPhase = "true";
          };
        buildExe = arch:
          pkgs.mkYarnPackage rec {
            name = package.name;
            version = package.version;
            src = pkgs.nix-gitignore.gitignoreSource [ ".git" ] ./.;
            electron_zip_dir = electronZipDir;
            ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
            extraBuildInputs =
              [ pkgs.wineWowPackages.full pkgs.mono pkgs.fontconfig pkgs.zip ];
            # DEBUG = "*";
            preConfigure = ''
              substituteInPlace package.json --replace "electron-forge make" "yarn exec electron-forge -- make --platform win32 --arch ${arch} --targets @electron-forge/maker-zip"
            '';
            buildPhase = ''
              # electron-forge needs 'home' with a skip check file
              mkdir home
              touch home/.skip-forge-system-check
              HOME="$(realpath home)" yarn run build:electron
            '';
            installPhase =
              "cp -r ./deps/appname/out/make/zip/win32/${arch} $out";
            distPhase = "true";
          };
        buildRpm = arch:
          let
            builtRpm = pkgs.vmTools.runInLinuxVM (pkgs.mkYarnPackage rec {
              memSize = 4096; # 4 GiB for the VM
              name = package.name;
              version = package.version;
              src = pkgs.nix-gitignore.gitignoreSource [ ".git" ] ./.;
              electron_zip_dir = electronZipDir;
              ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
              extraBuildInputs = [ pkgs.rpm ];
              # DEBUG = "*";
              preConfigure = ''
                substituteInPlace package.json --replace "electron-forge make" "yarn exec electron-forge -- make --arch ${arch} --platform linux --targets @electron-forge/maker-rpm"
              '';
              buildPhase = ''
                mkdir home
                touch home/.skip-forge-system-check
                rm ./deps/${name}/${name}
                HOME="$(realpath home)" yarn run build:electron
              '';
              installPhase = "cp -r ./deps/${name}/out/make/rpm/${arch} $out";
              distPhase = "true";
              dontFixup = true;
            });
          in pkgs.runCommand builtRpm.name { version = builtRpm.version; } ''
            cp -r ${builtRpm}/* $out
          '';
        buildDeb = arch:
          pkgs.mkYarnPackage rec {
            name = package.name;
            version = package.version;
            src = pkgs.nix-gitignore.gitignoreSource [ ".git" ] ./.;
            electron_zip_dir = electronZipDir;
            ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
            extraBuildInputs = [ pkgs.dpkg pkgs.fakeroot ];
            # DEBUG = "*"; 
            preConfigure = ''
              substituteInPlace package.json --replace "electron-forge make" "yarn exec electron-forge -- make --arch ${arch} --platform linux --targets @electron-forge/maker-deb"
            '';
            buildPhase = ''
              mkdir home
              touch home/.skip-forge-system-check
              rm ./deps/${name}/${name} 
              HOME="$(realpath home)" yarn run build:electron
            '';
            installPhase = "cp -r ./deps/${name}/out/make/deb/${arch} $out";
            distPhase = "true";
          };
      in rec {
        packages = {
          inherit webapp server;
          linux = {
            x64 = {
              deb = buildDeb "x64";
              rpm = buildRpm "x64";
            };
          };
          windows = { x64 = { exe = buildExe "x64"; }; };
          macos = {
            x64 = { zip = buildZip "x64"; };
            arm64 = { zip = buildZip "arm64"; };
          };
          all = pkgs.linkFarm "electron-appname" [
            {
              name = "linux-x64-deb";
              path = packages.linux.x64.deb;
            }
            {
              name = "linux-x64-rpm";
              path = packages.linux.x64.rpm;
            }
            {
              name = "windows-x64-exe";
              path = packages.windows.x64.exe;
            }
            {
              name = "macos-arm64-zip";
              path = packages.macos.arm64.zip;
            }
            {
              name = "macos-x64-zip";
              path = packages.macos.x64.zip;
            }
          ];
        };
        defaultPackage = packages.webapp;
        defaultApp = server;
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            nodejs
            yarn
            (if system == "x86_64-linux" then [
              # debian builds
              dpkg
              fakeroot
              # rpm builds
              rpm
              # exe builds
              wineWowPackages.full
              mono
              # zip builds
              zip
              # github releases
              gitAndTools.gh
            ] else
              [ ])
          ];
          # prevent electron download from electron in package.json
          ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
          # use the electron builds from here
          electron_zip_dir = electronZipDir;
        };
      });
}
