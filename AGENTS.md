# CLAUDE.md

This file provides guidance to AI code agents when working with code in this repository.

## What this is

VimTeX is a filetype plugin for Vim/Neovim providing LaTeX (and BibTeX) support:
compilation, PDF viewing, completion, syntax, folding, motions, text objects,
TOC, quickfix parsing. Bulk of the code is Vimscript under `autoload/`; a small
and growing part is Lua under `lua/vimtex/`.

Requires recent Vim / Neovim (see README "Requirements" for specific version
requirements); CI tests both.

## Working agreements

- **Never commit unless asked.** Leave changes in the working tree; the
  maintainer writes the commits. The same goes for pushing, tagging, and
  opening pull requests.
- **Never reply to GitHub issues, discussions, or pull request threads unless
  asked.** Reading them for context is fine; posting is not.
- **Write tests early, but run them late.** Writing the test first is usually
  the right first step: for a bug, a failing test that reproduces it; for
  a feature, a test that exercises the intended API, since that is the best way
  to see how the code will feel to use in practice. What should _not_ happen is
  running the suite after every individual change — that interrupts the flow of
  thought. Work through the design and implementation, then run the tests as
  a final stage.

## Tests

Tests are Makefile-driven Vim scripts. They live in `test/test-*/` and are plain
`.vim` files run with a clean editor via `-u`.

```sh
make                                 # run everything (as CI does, with -j1)
make test-toc                        # run one test directory
make test/test-toc/test-general      # run one test file (test-general.vim)
MYVIM="vim -T dumb --not-a-term -n" make   # run with vanilla vim instead of nvim
```

- The root `Makefile` is a thin wrapper that forwards to `test/Makefile`; the
  same targets work from within `test/` (`cd test && make test-toc`) and via
  `make -C test ...`.
- `MYVIM` defaults to `nvim --clean --headless`.
- The subdirectory Makefiles export `INMAKE=1`. Most test scripts contain
  `if empty($INMAKE) | finish | endif` so that running `nvim -u test-foo.vim`
  by hand drops you into an interactive session with the fixture loaded, while
  `make` runs the assertions.
- Assertions use Vim's `assert_*` functions plus helpers in
  `autoload/vimtex/test.vim` (`vimtex#test#finished()` — must be the last call,
  it prints `v:errors` and `cquit`s on failure; also `#completion()`, `#keys()`,
  `#main()`).
- Test scripts start with `set nocompatible` / `let &rtp = '../..,' . &rtp` /
  `filetype plugin on` to load the working tree copy of VimTeX.
- Some tests need `latexmk`/TeX Live, `wget`, and `chronic` (moreutils).
  `docker/Dockerfile` reproduces the CI environment.
- `test/example-*` are manual playground setups, `test/issues/NNNN` are
  issue-specific reproductions, `test/perf-*` and `*-speed`/`*-timing` are
  benchmarks (the timing ones are ordered last by `test/Makefile`).

## Docs site

`mise run web-build` / `mise run web-host` build and serve the site (Hugo
landing page from README.md + `doc/vimtex.txt` rendered by Neovim's
`gen_help_html.lua`); see `web/scripts/build.sh`.

## Architecture

**Entry points.** `ftplugin/tex.vim` and `ftplugin/bib.vim` call
`vimtex#init()`. `syntax/tex.vim` and `indent/tex.vim` are separate entry points
(they are not loaded via `vimtex#init()`). `after/ftplugin/tex.vim` checks for
conflicts with other plugins. `plugin/vimtex.vim` defines only what must be
global (notably `:VimtexInverseSearch`) — this is why VimTeX must not be lazy
loaded by a plugin manager.

**Module auto-discovery.** `autoload/vimtex.vim` globs `autoload/vimtex/*.vim`
into `s:modules` and calls `vimtex#<mod>#init_buffer()` for each, ignoring
`E117` when the function doesn't exist. So a new submodule is wired up simply by
creating the file and optionally defining:

- `vimtex#<mod>#init_buffer()` — buffer-local mappings, commands, autocommands
- `vimtex#<mod>#init_state(state)` — add data to the project state

**State.** `autoload/vimtex/state.vim` maps a buffer to a project state object
(`b:vimtex`, id in `b:vimtex_id`), created by
`vimtex#state#class#new()` in `state/class.vim`. One state per LaTeX project
(main file), shared across all buffers of a multi-file project; sub-files may
additionally get a "local" state (`vimtex#state#init_local()`). Cleanup happens
on `BufWipeout` and `VimLeave`.

**Backend dispatch.** Several subsystems pick an implementation by option and
call into a per-backend file with a uniform interface:

| Subsystem | Dispatcher | Backends |
|---|---|---|
| compile | `compiler.vim` | `compiler/{latexmk,tectonic,arara,latexrun,texpresso,generic}.vim` (`#init()` returns a state object; `_template.vim` is the base) |
| view | `view.vim` | `view/{zathura,mupdf,sioyek,skim,general,...}.vim` (`#new()` returns an object with `.view()`) |
| quickfix | `qf.vim` | `qf/{latexlog,pulp,bibtex,biblatex,pplatex}.vim` |
| fold | `fold.vim` | `fold/*.vim`, one file per fold type |
| completion | `complete.vim` | context-dependent completers; `complete/<pkg>` are keyword lists, `complete/tools` maps commands to unicode |
| context menu | `context.vim` | `context/*.vim` |
| text objects | `text_obj.vim` | `text_obj/{targets,cmdtargets,envtargets}.vim` |
| jobs / ui | `jobs.vim`, `ui.vim` | `jobs/{vim,neovim}.vim`, `ui/{vim,nvim,legacy}.vim` (editor abstraction) |
| parsing | `parser.vim` | `parser/{tex,bib,toc,fls,auxiliary,fixme}.vim` |

When adding a backend, copy the `_template.vim` where one exists and keep the
interface identical — the dispatcher calls it by constructed function name
(e.g. `vimtex#view#{g:vimtex_view_method}#new()`).

**Options.** All `g:vimtex_*` defaults are declared in one place,
`autoload/vimtex/options.vim`, via `s:init_option()`; that file also holds
deprecation checks and default highlight groups. A new option must be added
there and documented in `doc/vimtex.txt`.

**Syntax.** `syntax/tex.vim` is thin; rules live in
`autoload/vimtex/syntax/core.vim` with package-specific rules in
`autoload/vimtex/syntax/p/<package>.vim` (loaded on demand via
`syntax/packages.vim`) and `syntax/nested.vim` for embedded languages.
`autoload/vimtex/syntax.vim` is the *query* API used by the rest of the code
(e.g. `vimtex#syntax#in_mathzone()`) — not the rules themselves.

**Other cross-cutting APIs** used widely: `delim.vim`
(`vimtex#delim#get_surrounding()`), `cmd.vim` (`vimtex#cmd#get_current()`),
`cache.vim` (`vimtex#cache#open/close`, persistent under `$XDG_CACHE_HOME/vimtex`),
`log.vim`, `pos.vim`, `util.vim`, `debug.vim`.

`DOCUMENTATION.md` is the maintained high-level tour of this structure — update
it when the structure changes.

## Conventions

**Vimscript style** (see CONTRIBUTING.md): `shiftwidth=2`, no tabs, max 80
columns, single-quoted strings, `abort` on functions, `l:` prefix on locals,
`s:` for script-local. Functions are folded with markers: each function ends
with a trailing `" }}}1` line and the header ends with `" {{{1`. Keep related
functions grouped so the folded file reads as an outline.

**Lua style**: `.stylua.toml` — 80 columns, 2 spaces, double quotes preferred,
no parentheses on single-argument calls.

**Vimscript linting**: `.vintrc.yaml` configures `vint`.

**Documentation**: `doc/vimtex.txt` follows Vim help syntax — max 80 columns,
section separators of `=`, subsection separators of `-`, tags right-aligned at
column 79, and every section listed in the table of contents. Cross-reference
with help tags (`|vimtex-foo|`) rather than backticks; a `|Foo|` link resolves
even when the tag is defined as `*:Foo*`. Regenerate `doc/tags` with
`:helptags doc` when tags change.

**Commits**: conventional commits, parsed by `cliff.toml` for the changelog —
`feat`, `fix`, `doc`, `perf`, `merge` appear in the changelog; `test` and
`chore` are skipped. Scopes are used freely (e.g. `feat(view): ...`).
Development happens on `master`.
