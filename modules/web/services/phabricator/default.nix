{ config, lib, pkgs, apache, ... }:

with lib;

{
  # TODO:
  # - pygment-based syntax highlighting
  # - SSH/git
  # - svn/hg support
  # - isolation of PHP context, e.g. through a DynamicUser=-based PHP-FPM?
  options = {
  };

  config = let
    phabricatorRoot = pkgs.phabricator;
  in rec {
    webserver.variant = "apache";
    webserver.systemPackages = [pkgs.php];
    webserver.apache.enablePHP = true;
    webserver.apache.extraConfig = ''
      <Directory "${phabricatorRoot}/phabricator/webroot">
        Require all granted
      </Directory>
      DocumentRoot ${phabricatorRoot}/phabricator/webroot
      RewriteEngine on
      RewriteRule ^(.*)$ /index.php?__path__=$1 [B,L,QSA]
    '';

    database.phabricator.user = config.webserver.user;
    database.phabricator.postCreate = "${phabricatorRoot}/phabricator/bin/storage upgrade --force --user ${config.webserver.user}";
  };

  meta = {
    description = "A collection of web applications which help software companies build better software";
    maintainers = with maintainers; [ eliasp ];
    license = licenses.asl20;
    homepage = https://www.phacility.com/phabricator/;
  };
}
