{
  description = "React Native devenv template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    android = {
      url = "github:tadfisher/android-nixpkgs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        devshell.follows = "devshell";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      devshell,
      flake-utils,
      android,
    }:
    {
      overlay = final: _prev: { inherit (self.packages.${final.system}) android-sdk; };
    }
    //
      flake-utils.lib.eachSystem
        [
          "aarch64-darwin"
          "x86_64-darwin"
          "x86_64-linux"
        ]
        (
          system:
          let
            inherit (nixpkgs.lib) optionals;
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = true;
              overlays = [
                devshell.overlays.default
                self.overlay
              ];
            };
            enbale-system-android-images = true;
            enable-other-useful-dev-pks = true;
          in
          {
            packages = {
              android-sdk = android.sdk.${system} (
                sdkPkgs:
                with sdkPkgs;
                [
                  build-tools-34-0-0
                  cmdline-tools-latest
                  emulator
                  platform-tools
                  platforms-android-34
                ]
                ++ optionals (enbale-system-android-images && system == "aarch64-darwin") [
                  system-images-android-34-google-apis-arm64-v8a
                  system-images-android-34-google-apis-playstore-arm64-v8a
                ]
                ++
                  optionals (enbale-system-android-images && (system == "x86_64-darwin" || system == "x86_64-linux"))
                    [
                      system-images-android-34-google-apis-x86-64
                      system-images-android-34-google-apis-playstore-x86-64
                    ]
                # Other useful packages for a development environment.
                ++ optionals enable-other-useful-dev-pks [
                  ndk-26-1-10909125
                  skiaparser-3
                  sources-android-34
                ]
              );
            };

            devShell = pkgs.devshell.mkShell {
              # Documentation: https://github.com/numtide/devshell
              name = "React Native project";

              packages = with pkgs; [
                git
                android-sdk
                jdk
                nodejs_22
                yarn-berry
                watchman
              ];

              env =
                let
                  inherit (pkgs) android-sdk jdk;
                  androidHome = "${android-sdk}/share/android-sdk";
                in
                [
                  {
                    name = "ANDROID_HOME";
                    value = androidHome;
                  }
                  {
                    name = "ANDROID_SDK_ROOT";
                    value = androidHome;
                  }
                  {
                    name = "ANDROID_NDK_ROOT";
                    value = "${androidHome}/ndk-bundle";
                  }
                  {
                    name = "JAVA_HOME";
                    value = jdk.home;
                  }
                  {
                    name = "GRADLE_OPTS";
                    value = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidHome}/build-tools/34.0.0/aapt2";
                  }
                  {
                    name = "PATH";
                    prefix = "${androidHome}/emulator";
                  }
                  {
                    name = "PATH";
                    prefix = "${androidHome}/platform-tools";
                  }
                ];
            };
          }
        );
}
