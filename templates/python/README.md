# Python template using uv2nix

This template flake provides a python environment that is being managed by `uv` while still keeping the store managed by `nix`.

## Setup

1) Enter project directory
2) `project python`
3) Edit Python version in `flake.nix` and Python version + dependencies in `pyproject.toml`
4) `uv lock`
5) `direnv reload`

## Usage



### Testing

- run `nix flake check`

###### Note for Emacs users

It can happen that Emacs will not immediately pick up on the new environment after you have made your changes. In that case, perform the following steps in Emacs (this is for a setup using `envrc.el` and `eglot`):

1) `(envrc-reload)`
2) `(eglot)`
