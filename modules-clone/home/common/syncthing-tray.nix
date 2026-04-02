{ lib, config, pkgs, ... }:
{
  options.swarselmodules.syncthing-tray = lib.mkEnableOption "enable syncthing applet for tray";
  config = lib.mkIf config.swarselmodules.syncthing-tray {

    home.activation.setupSyncthingIni =
      let
        syncthingApiEnvVarName = "SYNCTHING_API_KEY";
        syncthingIni = {
          file = "${config.home.homeDirectory}/.config/syncthingtray.ini";
          content = ''
            [General]
            v=2.0.2

            [qt]
            customfont=false
            customicontheme=false
            customlocale=false
            custompalette=false
            customstylesheet=false
            customwidgetstyle=false
            font="Cantarell,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
            icontheme=hicolor
            iconthemepath=
            locale=en_US
            palette="@Variant(\0\0\0\x44\x1\x1\xff\xff\xa0\xa0\xb3\xb3\xc5\xc5\0\0\x1\x1\xff\xff  jj\x86\x86\0\0\x1\x1\xff\xff\0\0::ff\0\0\x1\x1\xff\xff\0\0::ff\0\0\x1\x1\xff\xff\x1d\x1d%%,,\0\0\x1\x1\xff\xff\x1d\x1d%%,,\0\0\x1\x1\xff\xff\xa0\xa0\xb3\xb3\xc5\xc5\0\0\x1\x1\xff\xff\xff\xff\xff\xff\xff\xff\0\0\x1\x1\xff\xff\xa0\xa0\xb3\xb3\xc5\xc5\0\0\x1\x1\xff\xff\x1d\x1d%%,,\0\0\x1\x1\xff\xff\x17\x17\x1d\x1d##\0\0\x1\x1\xff\xff\0\0\0\0\0\0\0\0\x1\x1\xff\xff\0\0::ff\0\0\x1\x1\xff\xff\xa0\xa0\xb3\xb3\xc5\xc5\0\0\x1\x1\xff\xff^^\xc4\xc4\xff\xff\0\0\x1\x1\xff\xff\xc0\xc0nn\xce\xce\0\0\x1\x1\xff\xff\x17\x17\x1d\x1d##\0\0\x1\x1\xff\xff^^\xc4\xc4\xff\xff\0\0\x1\x1\xff\xff  jj\x86\x86\0\0\x1\x1\xff\xff\0\0::ff\0\0\x1\x1\xff\xff\0\0::ff\0\0\x1\x1\xff\xff\x1d\x1d%%,,\0\0\x1\x1\xff\xff\x1d\x1d%%,,\0\0\x1\x1\xff\xff^^\xc4\xc4\xff\xff\0\0\x1\x1\xff\xff\xff\xff\xff\xff\xff\xff\0\0\x1\x1\xff\xff^^\xc4\xc4\xff\xff\0\0\x1\x1\xff\xff\x1d\x1d%%,,\0\0\x1\x1\xff\xff\x17\x17\x1d\x1d##\0\0\x1\x1\xff\xff\0\0\0\0\0\0\0\0\x1\x1\xff\xff\0\0::ff\0\0\x1\x1\x66\x66\xa0\xa0\xb3\xb3\xc5\xc5\0\0\x1\x1\xff\xff^^\xc4\xc4\xff\xff\0\0\x1\x1\xff\xff\xc0\xc0nn\xce\xce\0\0\x1\x1\xff\xff\x17\x17\x1d\x1d##\0\0\x1\x1\xff\xff\xa0\xa0\xb3\xb3\xc5\xc5\0\0\x1\x1\xff\xff  jj\x86\x86\0\0\x1\x1\xff\xff\0\0::ff\0\0\x1\x1\xff\xff\0\0::ff\0\0\x1\x1\xff\xff\x1d\x1d%%,,\0\0\x1\x1\xff\xff\x1d\x1d%%,,\0\0\x1\x1\xff\xff\xa0\xa0\xb3\xb3\xc5\xc5\0\0\x1\x1\xff\xff\xff\xff\xff\xff\xff\xff\0\0\x1\x1\xff\xff\xa0\xa0\xb3\xb3\xc5\xc5\0\0\x1\x1\xff\xff\x1d\x1d%%,,\0\0\x1\x1\xff\xff\x17\x17\x1d\x1d##\0\0\x1\x1\xff\xff\0\0\0\0\0\0\0\0\x1\x2\xff\xffP\x14\xff\xff\x65\x65\0\0\x1\x1\xff\xff\xa0\xa0\xb3\xb3\xc5\xc5\0\0\x1\x1\xff\xff^^\xc4\xc4\xff\xff\0\0\x1\x1\xff\xff\xc0\xc0nn\xce\xce\0\0\x1\x1\xff\xff\x17\x17\x1d\x1d##\0\0)"
            plugindir=
            stylesheetpath=
            trpath=
            widgetstyle=

            [startup]
            considerForReconnect=false
            considerLauncherForReconnect=false
            showButton=false
            showLauncherButton=false
            stopOnMetered=false
            stopServiceOnMetered=false
            syncthingArgs="serve --no-browser --logflags=3"
            syncthingAutostart=false
            syncthingPath=syncthing
            syncthingUnit=syncthing.service
            systemUnit=false
            useLibSyncthing=false

            [tray]
            connections\1\apiKey=@ByteArray(''$${syncthingApiEnvVarName})
            connections\1\authEnabled=falsex
            connections\1\autoConnect=true
            connections\1\devStatsPollInterval=60000
            connections\1\diskEventLimit=200
            connections\1\errorsPollInterval=30000
            connections\1\httpsCertPath=${config.home.homeDirectory}/.config/syncthing/https-cert.pem
            connections\1\label=Primary instance
            connections\1\localPath=
            connections\1\longPollingTimeout=0
            connections\1\password=
            connections\1\pauseOnMetered=false
            connections\1\reconnectInterval=30000
            connections\1\requestTimeout=0
            connections\1\statusComputionFlags=123
            connections\1\syncthingUrl=http://${config.services.syncthing.guiAddress}
            connections\1\trafficPollInterval=5000
            connections\1\userName=
            connections\size=1
            dbusNotifications=true
            distinguishTrayIcons=false
            frameStyle=16
            ignoreInavailabilityAfterStart=15
            notifyOnDisconnect=true
            notifyOnErrors=true
            notifyOnLauncherErrors=true
            notifyOnLocalSyncComplete=false
            notifyOnNewDeviceConnects=false
            notifyOnNewDirectoryShared=false
            notifyOnRemoteSyncComplete=false
            positioning\assumedIconPos=@Point(0 0)
            positioning\useAssumedIconPosition=false
            positioning\useCursorPos=true
            preferIconsFromTheme=false
            showDownloads=false
            showSyncthingNotifications=true
            showTabTexts=true
            showTraffic=true
            statusIcons="#ff26b6db,#ff0882c8,#ffffffff;#ffdb3c26,#ffc80828,#ffffffff;#ffc9ce3b,#ffebb83b,#ffffffff;#ff2d9d69,#ff2d9d69,#ffffffff;#ff26b6db,#ff0882c8,#ffffffff;#ff26b6db,#ff0882c8,#ffffffff;#ffa9a9a9,#ff58656c,#ffffffff;#ffa9a9a9,#ff58656c,#ffffffff;#ffa9a9a9,#ff58656c,#ffffffff"
            statusIconsRenderSize=@Size(32 32)
            statusIconsStrokeWidth=0
            tabPos=1
            trayIcons="#ff26b6db,#ff0882c8,#ffffffff;#ffdb3c26,#ffc80828,#ffffffff;#ffc9ce3b,#ffebb83b,#ffffffff;#ff2d9d69,#ff2d9d69,#ffffffff;#ff26b6db,#ff0882c8,#ffffffff;#ff26b6db,#ff0882c8,#ffffffff;#ffa9a9a9,#ff58656c,#ffffffff;#ffa9a9a9,#ff58656c,#ffffffff;#ffa9a9a9,#ff58656c,#ffffffff"
            trayIconsRenderSize=@Size(32 32)
            trayIconsStrokeWidth=0
            trayMenuSize=@Size(575 475)
            usePaletteForStatusIcons=false
            usePaletteForTrayIcons=false
            windowType=0

            [webview]
            customCommand=
            disabled=false
            mode=0

          '';
        };
      in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -eu

        if [ ! -f ${syncthingIni.file} ]; then
        cat >${syncthingIni.file} <<'EOF'
        ${syncthingIni.content}
        EOF
        export ${syncthingApiEnvVarName}=$(cat /run/syncthing-init/api_key)
        ${lib.getExe pkgs.envsubst} -i ${syncthingIni.file} -o ${syncthingIni.file}
        unset ${syncthingApiEnvVarName}
        fi
      '';

  };

}
