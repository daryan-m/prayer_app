{ pkgs }: {
  channel = "stable-24.05";

  packages = [
    pkgs.flutter
    pkgs.jdk17
    pkgs.unzip
    pkgs.chromium
  ];

  idx.extensions = [
    "Dart-Code.dart"
    "Dart-Code.flutter"
  ];

  idx.previews = {
    previews = {
      web = {
        command = [
          "flutter"
          "run"
          "--machine"
          "-d"
          "web-server"
          "--web-hostname"
          "0.0.0.0"
          "--web-port"
          "$PORT"
        ];
        manager = "flutter";
      };
    };
  };
}