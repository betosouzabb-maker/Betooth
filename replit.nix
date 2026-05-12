{ pkgs }:

{
  deps = [
    pkgs.nodejs_20
    pkgs.nodePackages.npm
    pkgs.postgresql
    pkgs.redis
    pkgs.openssl
    pkgs.libuuid
  ];

  env = {
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.libuuid
      pkgs.openssl
    ];
  };
}
