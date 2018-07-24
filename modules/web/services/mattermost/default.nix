{ config, pkgs, lib, mkUniqueUser, mkUniqueGroup, ... }:
with lib;
{
  options = {
    siteName = mkOption {
      default = "Mattermost";
      description = "Name of the Mattermost instance";
    };
    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Addtional configuration options as Nix attribute set in config.json schema.
      '';
    };
  };

  meta = {
    #description = "";
    #homepage = "";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ qknight ];
    meta.platforms = lib.platforms.linux;
  };
  config =     let
      defaultConfig = builtins.fromJSON (readFile "${pkgs.mattermost}/config/config.json");

      path = builtins.toPath "/${config.proxyOptions.domain}/${config.proxyOptions.path}";
      siteUrl = "${if (config.proxyOptions.https.mode == "on") then "https" else "http"}:/${path}";

      mattermostConf = foldl recursiveUpdate defaultConfig
        [ { ServiceSettings.SiteURL = "${siteUrl}"; # "https://chat.example.com";
            ServiceSettings.ListenAddress = config.proxyOptions.port;
            TeamSettings.SiteName = config.siteName;
            SqlSettings.DriverName = "postgres";
            SqlSettings.DataSource = "postgres:///mattermost?host=${config.database.mattermost.socketPath}";
          }
          config.extraConfig
        ];
      mattermostConfJSON = pkgs.writeText "mattermost-config-raw.json" (builtins.toJSON mattermostConf);
    in

    lib.mkIf config.enable {

    # inject the leaps websocket for cooperative document opening/editing into proxyOptions
    #proxyOptions.websockets = {
    #  ws = {
    #    subpath = "/leaps/ws";
    #  };
    #};

    #directories.www.postCreate = ''
    #  cat > README.md <<EOF
    #  # No files to edit other than this one?
    #  You can add more files into \`${config.stateDir}/www\` to edit them
    #  collaberatively via your Leaps instance.
    #  EOF
    #'';

    users.mattermost = {
      description = "Mattermost server user";
      home        = "${config.stateDir}/www";
      createHome  = true;
      group       = "mattermost";
    };
    groups.mattermost = {};

    database.mattermost.user = "mattermost-m1";
    database.hydra.owners = [ "mattermost-m1" ];

    database.mattermost.type = "postgresql";

    systemd.services.mattermost = {
     description = "${config.uniqueName} main service (mattermost)";

      wantedBy      = [ "multi-user.target" ];
      after         = [ "network.target" ];

      # FIXME: refactor into an environment
      preStart = ''
        mkdir -p ${config.stateDir}/www/{data,config,logs}
        ln -sf ${pkgs.mattermost}/{bin,fonts,i18n,templates,client} ${config.stateDir}/www
        ln -sf ${mattermostConfJSON} ${config.stateDir}/www/config/config.json
      '';
      #   + lib.optionalString cfg.localDatabaseCreate ''
      #  if ! test -e "${config.stateDir}/.db-created"; then
      #    ${pkgs.sudo}/bin/sudo -u ${config.services.postgresql.superUser} \
      #      ${config.services.postgresql.package}/bin/psql postgres -c \
      #        "CREATE ROLE ${cfg.localDatabaseUser} WITH LOGIN NOCREATEDB NOCREATEROLE ENCRYPTED PASSWORD '${cfg.localDatabasePassword}'"
      #    ${pkgs.sudo}/bin/sudo -u ${config.services.postgresql.superUser} \
      #      ${config.services.postgresql.package}/bin/createdb \
      #        --owner ${cfg.localDatabaseUser} ${cfg.localDatabaseName}
      #    touch ${config.stateDir}/.db-created
      #  fi
      #'' + ''
      #  chown ${cfg.user}:${cfg.group} -R ${config.stateDir}
      #  chmod u+rw,g+r,o-rwx -R ${config.stateDir}
      #'';

      serviceConfig = {
        User = "mattermost";
        Group = "mattermost";
        Restart = "on-failure";
        WorkingDirectory = "${config.stateDir}/www";
        PrivateTmp = true;
        #ExecStart = "${pkgs.mattermost}/bin/mattermost";
        ExecStart = "${pkgs.mattermost}/bin/mattermost-platform";
        LimitNOFILE = "49152";
      };
    };

    #tests.wanted = [ ./test.nix ];
  };
}
