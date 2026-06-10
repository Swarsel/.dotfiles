{
  flake.modules.homeManager.emacs-init = _:
    let
      devdocsHook = mode: docs:
        ''(${mode} . (lambda () (setq-local devdocs-current-docs '(${docs}))))'';
      pythonDocs = ''"python~3.12" "numpy~1.23" "matplotlib~3.7" "pandas~1"'';
    in
    {
      config.programs.emacs.init.usePackage.devdocs = {
        enable = true;
        hook = [
          (devdocsHook "python-mode" pythonDocs)
          (devdocsHook "python-ts-mode" pythonDocs)
          (devdocsHook "c-mode" ''"c"'')
          (devdocsHook "c-ts-mode" ''"c"'')
          (devdocsHook "c++-mode" ''"cpp"'')
          (devdocsHook "c++-ts-mode" ''"cpp"'')
        ];
      };
    };
}
