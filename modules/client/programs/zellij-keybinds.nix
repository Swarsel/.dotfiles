{
  flake.modules.homeManager.zellij-keybinds =
    { lib, ... }:
    let
      bind = keys: actions: {
        bind = {
          _args = lib.toList keys;
          _children = lib.toList actions;
        };
      };
      switchTo = mode: { SwitchToMode._args = [ mode ]; };
      directional =
        action:
        lib.mapAttrsToList (direction: keys: bind keys (action direction)) {
          down = [
            "j"
            "down"
          ];
          left = [
            "h"
            "left"
          ];
          right = [
            "l"
            "right"
          ];
          up = [
            "k"
            "up"
          ];
        };
    in
    {
      config.programs.zellij.settings.keybinds = {
        _props.clear-defaults = true;
        entersearch._children = [
          (bind [ "Ctrl c" "esc" ] (switchTo "scroll"))
          (bind "enter" (switchTo "search"))
        ];
        locked._children = [ (bind "Ctrl g" (switchTo "normal")) ];
        pane._children = [
          (bind "Ctrl p" (switchTo "normal"))
          (bind "d" [
            { NewPane._args = [ "down" ]; }
            (switchTo "normal")
          ])
          (bind "e" [
            { TogglePaneEmbedOrFloating = { }; }
            (switchTo "normal")
          ])
          (bind "f" [
            { ToggleFocusFullscreen = { }; }
            (switchTo "normal")
          ])
          (bind "n" [
            { NewPane = { }; }
            (switchTo "normal")
          ])
          (bind "p" { SwitchFocus = { }; })
          (bind "f12" [
            { ToggleFloatingPanes = { }; }
            (switchTo "normal")
          ])
          (bind "x" [
            { CloseFocus = { }; }
            (switchTo "normal")
          ])
        ]
        ++ directional (direction: {
          MoveFocus._args = [ direction ];
        });
        renametab._children = [
          (bind "esc" [
            { UndoRenameTab = { }; }
            (switchTo "tab")
          ])
          (bind "Ctrl c" (switchTo "normal"))
        ];
        resize._children = [
          (bind "Ctrl n" (switchTo "normal"))
          (bind "+" { Resize._args = [ "Increase" ]; })
          (bind "-" { Resize._args = [ "Decrease" ]; })
          (bind "H" { Resize._args = [ "Decrease left" ]; })
          (bind "J" { Resize._args = [ "Decrease down" ]; })
          (bind "K" { Resize._args = [ "Decrease up" ]; })
          (bind "L" { Resize._args = [ "Decrease right" ]; })
        ]
        ++ directional (direction: {
          Resize._args = [ "Increase ${direction}" ];
        });
        scroll._children = [
          (bind "e" [
            { EditScrollback = { }; }
            (switchTo "normal")
          ])
          (bind "s" [
            (switchTo "entersearch")
            { SearchInput._args = [ 0 ]; }
          ])
        ];
        search._children = [
          (bind "c" { SearchToggleOption._args = [ "CaseSensitivity" ]; })
          (bind "n" { Search._args = [ "down" ]; })
          (bind "o" { SearchToggleOption._args = [ "WholeWord" ]; })
          (bind "p" { Search._args = [ "up" ]; })
          (bind "w" { SearchToggleOption._args = [ "Wrap" ]; })
        ];
        session._children = [
          (bind "Ctrl o" (switchTo "normal"))
          (bind "w" [
            {
              LaunchOrFocusPlugin = {
                _args = [ "session-manager" ];
                _children = [
                  { floating._args = [ true ]; }
                  { move_to_focused_tab._args = [ true ]; }
                ];
              };
            }
            (switchTo "normal")
          ])
          (bind "d" { Detach = { }; })
        ];
        "shared_among \"scroll\" \"search\""._children = [
          (bind [ "PageDown" "right" "l" "Ctrl f" ] { PageScrollDown = { }; })
          (bind [ "PageUp" "left" "h" "Ctrl b" ] { PageScrollUp = { }; })
          (bind [ "down" "j" ] { ScrollDown = { }; })
          (bind [ "up" "k" ] { ScrollUp = { }; })
          (bind "d" { HalfPageScrollDown = { }; })
          (bind "u" { HalfPageScrollUp = { }; })
          (bind "Ctrl c" [
            { ScrollToBottom = { }; }
            (switchTo "normal")
          ])
          (bind "Ctrl s" (switchTo "normal"))
        ];
        "shared_except \"locked\""._children = [
          (bind [ "Alt h" "Alt left" ] { MoveFocusOrTab._args = [ "left" ]; })
          (bind "Alt right" { MoveFocusOrTab._args = [ "right" ]; })
          (bind [ "Alt j" "Alt down" ] { MoveFocus._args = [ "down" ]; })
          (bind [ "Alt k" "Alt up" ] { MoveFocus._args = [ "up" ]; })
          (bind "Alt +" { Resize._args = [ "Increase" ]; })
          (bind "Alt -" { Resize._args = [ "Decrease" ]; })
          (bind "Alt r" { WriteChars._args = [ "cdr\n" ]; })
          (bind "Alt w" { WriteChars._args = [ "cdw\n" ]; })
          (bind "Alt b" { WriteChars._args = [ "cdb\n" ]; })
          (bind "Alt f" { ToggleFloatingPanes = { }; })
          (bind "Alt i" { MoveTab._args = [ "left" ]; })
          (bind "Alt p" { NewPane = { }; })
          (bind "Alt n" { NewTab = { }; })
          (bind "Ctrl g" (switchTo "locked"))
        ];
        "shared_except \"locked\" \"pane\""._children = [ (bind "Ctrl p" (switchTo "pane")) ];
        "shared_except \"locked\" \"resize\""._children = [ (bind "Ctrl n" (switchTo "resize")) ];
        "shared_except \"locked\" \"scroll\" \"search\""._children = [
          (bind "Ctrl s" (switchTo "scroll"))
        ];
        "shared_except \"locked\" \"session\""._children = [ (bind "Ctrl o" (switchTo "session")) ];
        "shared_except \"locked\" \"tab\""._children = [ (bind "Ctrl t" (switchTo "tab")) ];
        "shared_except \"normal\" \"locked\" \"entersearch\""._children = [
          (bind "enter" (switchTo "normal"))
        ];
        "shared_except \"normal\" \"locked\" \"entersearch\" \"renametab\""._children = [
          (bind "esc" (switchTo "normal"))
        ];
        tab._children = [
          (bind "Ctrl t" (switchTo "normal"))
          (bind [ "h" "k" "left" "up" ] { GoToPreviousTab = { }; })
          (bind [ "j" "l" "down" "right" ] { GoToNextTab = { }; })
          (bind "n" [
            { NewTab = { }; }
            (switchTo "normal")
          ])
          (bind "r" [
            (switchTo "renametab")
            { TabNameInput._args = [ 0 ]; }
          ])
          (bind "s" [
            { ToggleActiveSyncTab = { }; }
            (switchTo "normal")
          ])
          (bind "x" [
            { CloseTab = { }; }
            (switchTo "normal")
          ])
        ]
        ++ map (
          n:
          bind (toString n) [
            { GoToTab._args = [ n ]; }
            (switchTo "normal")
          ]
        ) (lib.range 1 9);
      };
    };
}
