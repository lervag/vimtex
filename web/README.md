# VimTeX documentation website

This directory builds a web-published version of the VimTeX help (`doc/vimtex.txt`).
It is deployed to GitHub Pages by `.github/workflows/docs.yml`.

The published site consists of:

- `/`          landing page (built from the repo `README.md`)
- `/docs/`     the VimTeX help, rendered with neovim's `gen_help_html.lua`

## Build locally

```sh
mise run web-host

# to rebuild the page
mise run web-build
```

