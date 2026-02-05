{ self, inputs, config, pkgs, lib, confLib, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];
  config = {
    systemd.user = {
      targets = {
        noctalia-shell.Unit = {
          After = [ "graphical-session.target" ];
          Wants = [
            "tray.target"
            "noctalia-tray-pre.target"
          ];
        };
        tray = {
          Unit = {
            After = [ "noctalia-tray-pre.target" ];
            PartOf = [ "noctalia-shell.service" ];
          };
          Install.WantedBy = [ "noctalia-shell.target" ];
        };
        noctalia-tray-pre = {
          Unit = {
            After = [
              "noctalia-init.service"
            ];
          };
          Install.WantedBy = [ "noctalia-shell.target" ];
        };
      };
      services = {
        noctalia-shell = confLib.overrideTarget "noctalia-shell.target";
        noctalia-init = {
          Unit = {
            PartOf = [ "noctalia-tray-pre.target" ];
          };

          Service = {
            Type = "oneshot";
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
            ExecStart = "-${pkgs.busybox}/bin/pkill mako";
            RemainAfterExit = true;
          };

          Install = {
            WantedBy = [ "noctalia-tray-pre.target" ];
          };
        };
      };
    };

    programs = {
      fastfetch.enable = true;
      noctalia-shell = {
        enable = true;
        package = pkgs.noctalia-shell.override { calendarSupport = true; };
        systemd.enable = true;
        settings = {
          bar = {
            barType = "simple";
            position = "top";
            monitors = [ ];
            density = "default";
            showCapsule = false;
            showOutline = false;
            capsuleOpacity = lib.mkForce 1;
            backgroundOpacity = lib.mkForce 0.5;
            useSeparateOpacity = true;
            floating = false;
            marginVertical = 4;
            marginHorizontal = 0;
            frameThickness = 8;
            frameRadius = 12;
            outerCorners = true;
            hideOnOverview = false;
            displayMode = "auto_hide";
            autoHideDelay = 100;
            autoShowDelay = 300;
            screenOverrides = [ ];
            widgets = {
              left = [
                {
                  characterCount = 2;
                  colorizeIcons = false;
                  emptyColor = "primary";
                  enableScrollWheel = false;
                  focusedColor = "secondary";
                  followFocusedScreen = false;
                  groupedBorderOpacity = 1;
                  hideUnoccupied = true;
                  iconScale = 0.5;
                  id = "Workspace";
                  labelMode = "none";
                  occupiedColor = "primary";
                  pillSize = 0.4;
                  reverseScroll = false;
                  showApplications = true;
                  showBadge = true;
                  showLabelsOnlyWhenOccupied = true;
                  unfocusedIconsOpacity = 0.25;
                }
              ];
              center = [
                {
                  colorizeIcons = false;
                  hideMode = "hidden";
                  id = "ActiveWindow";
                  maxWidth = 145;
                  scrollingMode = "hover";
                  showIcon = true;
                  useFixedWidth = false;
                }
                {
                  id = "plugin:privacy-indicator";
                }
                {
                  id = "plugin:screen-recorder";
                }
              ];
              right = [
                {
                  blacklist = [
                    "bluetooth*"
                  ];
                  colorizeIcons = false;
                  drawerEnabled = true;
                  hidePassive = true;
                  id = "Tray";
                  pinned = [ ];
                }
                {
                  displayMode = "alwaysShow";
                  id = "Volume";
                  middleClickCommand = "pavucontrol";
                }
                {
                  displayMode = "onhover";
                  id = "Network";
                }
                {
                  displayMode = "onhover";
                  id = "Bluetooth";
                }
                {
                  displayMode = "onhover";
                  id = "VPN";
                }
                {
                  deviceNativePath = "__default__";
                  hideIfIdle = true;
                  hideIfNotDetected = true;
                  id = "Battery";
                  showNoctaliaPerformance = false;
                  showPowerProfiles = true;
                }
                {
                  id = "plugin:ba7043:github-feed";
                }
                {
                  id = "plugin:clipper";
                }
                {
                  colorName = "primary";
                  id = "SessionMenu";
                }
                {
                  customFont = "FiraCode Nerd Font Mono";
                  formatHorizontal = "ddd dd. MMM HH:mm:ss";
                  formatVertical = "";
                  id = "Clock";
                  tooltipFormat = "ddd dd. MMM HH:mm:ss";
                  useCustomFont = true;
                  usePrimaryColor = true;
                }
                {
                  colorizeDistroLogo = false;
                  colorizeSystemIcon = "primary";
                  customIconPath = "";
                  enableColorization = true;
                  icon = "noctalia";
                  id = "ControlCenter";
                  useDistroLogo = true;
                }
              ];
            };
          };
          general = {
            avatarImage = "${self}/files/wallpaper/swarsel.png";
            dimmerOpacity = 0.2;
            showScreenCorners = false;
            forceBlackScreenCorners = false;
            scaleRatio = 1;
            radiusRatio = 0.2;
            iRadiusRatio = 1;
            boxRadiusRatio = 1;
            screenRadiusRatio = 1;
            animationSpeed = 1;
            animationDisabled = false;
            compactLockScreen = true;
            lockOnSuspend = true;
            showSessionButtonsOnLockScreen = true;
            showHibernateOnLockScreen = false;
            enableShadows = true;
            shadowDirection = "bottom_right";
            shadowOffsetX = 2;
            shadowOffsetY = 3;
            language = "";
            allowPanelsOnScreenWithoutBar = true;
            showChangelogOnStartup = true;
            telemetryEnabled = false;
            enableLockScreenCountdown = true;
            lockScreenCountdownDuration = 10000;
            autoStartAuth = true;
            allowPasswordWithFprintd = true;
          };
          ui = {
            fontDefaultScale = 1;
            fontFixedScale = 1;
            tooltipsEnabled = true;
            panelBackgroundOpacity = lib.mkForce 1;
            panelsAttachedToBar = true;
            settingsPanelMode = "centered";
            wifiDetailsViewMode = "grid";
            bluetoothDetailsViewMode = "grid";
            networkPanelView = "wifi";
            bluetoothHideUnnamedDevices = false;
            boxBorderEnabled = false;
          };
          location = {
            name = confLib.getConfig.repo.secrets.common.location.timezoneSpecific;
            weatherEnabled = true;
            weatherShowEffects = false;
            useFahrenheit = false;
            use12hourFormat = false;
            showWeekNumberInCalendar = true;
            showCalendarEvents = true;
            showCalendarWeather = true;
            analogClockInCalendar = false;
            firstDayOfWeek = 1;
            hideWeatherTimezone = false;
            hideWeatherCityName = false;
          };
          calendar = {
            cards = [
              {
                enabled = true;
                id = "calendar-header-card";
              }
              {
                enabled = true;
                id = "calendar-month-card";
              }
              {
                enabled = true;
                id = "weather-card";
              }
            ];
          };
          wallpaper = {
            enabled = true;
            overviewEnabled = true;
            directory = "${self}/files/wallpaper";
            monitorDirectories = [ ];
            enableMultiMonitorDirectories = true;
            showHiddenFiles = false;
            viewMode = "single";
            setWallpaperOnAllMonitors = true;
            fillMode = "crop";
            fillColor = "#000000";
            useSolidColor = false;
            solidColor = "#1a1a2e";
            automationEnabled = false;
            wallpaperChangeMode = "random";
            randomIntervalSec = 300;
            transitionDuration = 500;
            transitionType = "random";
            transitionEdgeSmoothness = 0.05;
            panelPosition = "follow_bar";
            hideWallpaperFilenames = false;
            useWallhaven = false;
            wallhavenQuery = "";
            wallhavenSorting = "relevance";
            wallhavenOrder = "desc";
            wallhavenCategories = "111";
            wallhavenPurity = "100";
            wallhavenRatios = "";
            wallhavenApiKey = "";
            wallhavenResolutionMode = "atleast";
            wallhavenResolutionWidth = "";
            wallhavenResolutionHeight = "";
            sortOrder = "name";
          };
          appLauncher = {
            enableClipboardHistory = false;
            autoPasteClipboard = false;
            enableClipPreview = true;
            clipboardWrapText = true;
            clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
            clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
            position = "center";
            pinnedApps = [ ];
            useApp2Unit = false;
            sortByMostUsed = true;
            terminalCommand = "kitty -e";
            customLaunchPrefixEnabled = false;
            customLaunchPrefix = "";
            viewMode = "list";
            showCategories = false;
            iconMode = "native";
            showIconBackground = false;
            enableSettingsSearch = false;
            enableWindowsSearch = false;
            ignoreMouseInput = true;
            screenshotAnnotationTool = "";
          };
          controlCenter = {
            position = "close_to_bar_button";
            diskPath = "/";
            shortcuts = {
              left = [
                {
                  id = "Network";
                }
                {
                  id = "Bluetooth";
                }
              ];
              right = [
                {
                  id = "Notifications";
                }
                {
                  id = "PowerProfile";
                }
                {
                  id = "KeepAwake";
                }
                {
                  id = "plugin:screen-recorder";
                }
              ];
            };
            cards = [
              {
                enabled = true;
                id = "profile-card";
              }
              {
                enabled = true;
                id = "shortcuts-card";
              }
              {
                enabled = true;
                id = "audio-card";
              }
              {
                enabled = true;
                id = "brightness-card";
              }
              {
                enabled = true;
                id = "weather-card";
              }
              {
                enabled = true;
                id = "media-sysmon-card";
              }
            ];
          };
          systemMonitor = {
            cpuWarningThreshold = 80;
            cpuCriticalThreshold = 90;
            tempWarningThreshold = 80;
            tempCriticalThreshold = 90;
            gpuWarningThreshold = 80;
            gpuCriticalThreshold = 90;
            memWarningThreshold = 80;
            memCriticalThreshold = 90;
            swapWarningThreshold = 80;
            swapCriticalThreshold = 90;
            diskWarningThreshold = 80;
            diskCriticalThreshold = 90;
            diskAvailWarningThreshold = 20;
            diskAvailCriticalThreshold = 10;
            cpuPollingInterval = 1000;
            gpuPollingInterval = 3000;
            enableDgpuMonitoring = false;
            memPollingInterval = 1000;
            diskPollingInterval = 30000;
            networkPollingInterval = 1000;
            loadAvgPollingInterval = 3000;
            useCustomColors = true;
            warningColor = "#5ec4ff";
            criticalColor = "#d95468";
            externalMonitor = "btm";
          };
          dock = {
            enabled = false;
          };
          network = {
            wifiEnabled = true;
            bluetoothRssiPollingEnabled = false;
            bluetoothRssiPollIntervalMs = 10000;
            wifiDetailsViewMode = "grid";
            bluetoothDetailsViewMode = "grid";
            bluetoothHideUnnamedDevices = false;
          };
          sessionMenu = {
            enableCountdown = true;
            countdownDuration = 3000;
            position = "center";
            showHeader = true;
            largeButtonsStyle = true;
            largeButtonsLayout = "grid";
            showNumberLabels = true;
            powerOptions = [
              {
                action = "lock";
                command = "";
                countdownEnabled = true;
                enabled = true;
              }
              {
                action = "suspend";
                command = "";
                countdownEnabled = true;
                enabled = true;
              }
              {
                action = "hibernate";
                command = "";
                countdownEnabled = true;
                enabled = true;
              }
              {
                action = "reboot";
                command = "";
                countdownEnabled = true;
                enabled = true;
              }
              {
                action = "logout";
                command = "";
                countdownEnabled = true;
                enabled = true;
              }
              {
                action = "shutdown";
                command = "";
                countdownEnabled = true;
                enabled = true;
              }
            ];
          };
          notifications = {
            enabled = true;
            monitors = [ ];
            location = "top_right";
            overlayLayer = true;
            backgroundOpacity = 0.5;
            respectExpireTimeout = true;
            lowUrgencyDuration = 3;
            normalUrgencyDuration = 8;
            criticalUrgencyDuration = 15;
            enableMediaToast = false;
            enableKeyboardLayoutToast = true;
            batteryWarningThreshold = 20;
            batteryCriticalThreshold = 5;
            saveToHistory = {
              low = true;
              normal = true;
              critical = true;
            };
            sounds.enabled = false;
          };
          osd = {
            enabled = true;
            location = "right";
            autoHideMs = 2000;
            overlayLayer = true;
            backgroundOpacity = 0.5;
            monitors = [ ];
            enabledTypes = [ 0 1 2 3 ];
          };
          audio = {
            volumeStep = 5;
            volumeOverdrive = false;
            cavaFrameRate = 30;
            visualizerType = "linear";
            mprisBlacklist = [ ];
            preferredPlayer = "";
            volumeFeedback = false;
          };
          brightness = {
            brightnessStep = 5;
            enforceMinimum = true;
            enableDdcSupport = false;
          };
          nightLight = {
            enabled = true;
            autoSchedule = true;
            nightTemp = "3700";
            dayTemp = "5500";
            manualSunrise = "06:30";
            manualSunset = "18:30";
          };
          hooks.enabled = false;
          desktopWidgets.enabled = false;

          plugins = {
            sources = [
              {
                enabled = true;
                name = "Official Noctalia Plugins";
                url = "https://github.com/noctalia-dev/noctalia-plugins";
              }
              {
                enabled = true;
                name = "Dev";
                url = "https://github.com/Swarsel/noctalia-plugins";
              }
            ];
            states = lib.listToAttrs
              (map
                (plugin:
                  lib.nameValuePair plugin {
                    enabled = true;
                    sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
                  })
                [
                  "clipper"
                  "github-feed"
                  "privacy-indicator"
                  "kaomoji-provider"
                  "unicode-picker"
                  "screen-recorder"
                ]) // {
              github-feed = {
                enabled = true;
                sourceUrl = "https://github.com/Swarsel/noctalia-plugins";
              };
            };
          };
          pluginSettings = {
            clipper = {
              enableTodoIntegration = false;
            };

            privacy-indicator = {
              hideInactive = true;
              iconSpacing = 4;
              removeMargins = true;
            };

            screen-recorder = {
              hideInactive = true;
              directory = "";
              filenamePattern = "recording_yyyyMMdd_HHmmss";
              frameRate = "60";
              audioCodec = "opus";
              videoCodec = "h264";
              quality = "very_high";
              colorRange = "limited";
              showCursor = true;
              copyToClipboard = true;
              audioSource = "default_output";
              videoSource = "portal";
              resolution = "original";
            };

            github-feed = {
              username = lib.toUpper config.swarselsystems.mainUser;
              token = confLib.getConfig.repo.secrets.common.noctaliaGithubToken;
              refreshInterval = 300;
              maxEvents = 50;
              showStars = false;
              showForks = false;
              showPRs = false;
              showRepoCreations = false;
              showMyRepoStars = true;
              showMyRepoForks = true;
              openInBrowser = true;
              # my fork:
              showNotificationBadge = true;
              colorizationEnabled = true;
              colorizationIcon = "Primary";
              colorizationBadge = "Tertiary";
              colorizationBadgeText = "Primary";
              defaultTab = 1;
              enableSystemNotifications = true;
              notifyGitHubNotifications = true;
              notifyStars = true;
              notifyForks = true;
              notifyPRs = true;
              notifyRepoCreations = true;
              notifyMyRepoStars = true;
              notifyMyRepoForks = true;
            };
          };
        };
      };
    };
  };
}
