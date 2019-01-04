{ lib, pkgs, ... }:
with pkgs;

{
  nixpkgs.overlays = [
    (self: super: {
      inherit (import ../../pkgs { inherit pkgs; }) nixcloud;
      #lxc = super.lxc.overrideAttrs (drv: rec {
      #  version = "2.1.1";
      #  name = "lxc-${version}";
      #  src = /etc/nixos/pkgs/lxc;
      #  patches = [  ];
      #});
      phabricator = super.phabricator.overrideAttrs(drv: rec {
        name = "phabricator-${version}";
        version = "2019-01-04";
        srcLibphutil = pkgs.fetchgit {
          url = git://github.com/facebook/libphutil.git;
          rev = "cad1985726c99e1225b95abf8a2bd1601a267fe4";
          sha256 = "1qlvr4js1r9lmn7v15idifh5jq2mjbkbx36rlvfiffvkgibanfia";
        };
        srcArcanist = pkgs.fetchgit {
          url = git://github.com/facebook/arcanist.git;
          rev = "25c2381959ac94d9249ae4023c5f9ea36436b81c";
          sha256 = "1zxlyp4yr5ya0k18m52ff43xzs48jpchc2ysff9m3g88a2grrsmg";
        };
        srcPhabricator = pkgs.fetchgit {
          url = git://github.com/phacility/phabricator.git;
          rev = "3963c86ad5e52536cdf11983037d173ce7bb12f7";
          sha256 = "1gmgy15c4q5rv9f688dn7smzyn84qaqv63hc9r4y738lqgwjm4qa";
        };
      });
    })
  ];
}
