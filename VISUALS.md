# Visuals

This page contains animated GIFs demonstrating many of the core VimTeX editing
features listed in `:help vimtex-features` and documented in `:help
vimtex-mappings`. Hopefully the animations can give you a clearer mental image
of what these mappings do and how you might use them.

You may want to scroll through this page while simultaneously looking
through `:help vimtex-features`---the animations should nicely complement the
plain-text documentation.

## Table of contents
<!-- vim-markdown-toc GFM -->

* [Motion commands](#motion-commands)
  * [Navigating sections](#navigating-sections)
  * [Navigating environments](#navigating-environments)
  * [Navigating math zones](#navigating-math-zones)
  * [Navigating frames](#navigating-frames)
  * [Navigating matching delimiters](#navigating-matching-delimiters)
* [Text objects](#text-objects)
  * [The delimiter and environment objects](#the-delimiter-and-environment-objects)
* [Deleting surrounding LaTeX content](#deleting-surrounding-latex-content)
  * [Delete surrounding commands](#delete-surrounding-commands)
  * [Delete surrounding environments](#delete-surrounding-environments)
  * [Delete surrounding math zones](#delete-surrounding-math-zones)
  * [Delete surrounding delimiters](#delete-surrounding-delimiters)
* [Changing surrounding LaTeX content](#changing-surrounding-latex-content)
  * [Change surrounding commands](#change-surrounding-commands)
  * [Change surrounding environments](#change-surrounding-environments)
  * [Change surrounding math zones](#change-surrounding-math-zones)
  * [Change surrounding delimiters](#change-surrounding-delimiters)
* [Toggling commands](#toggling-commands)
  * [Toggling starred commands and environments](#toggling-starred-commands-and-environments)
  * [Toggling delimiter modifiers](#toggling-delimiter-modifiers)
  * [Toggling fractions](#toggling-fractions)

<!-- vim-markdown-toc -->

## Motion commands

### Navigating sections

Use `]]` to jump to the beginning of the next `\section`, `\subsection` or
`\subsubsection`, whichever comes first. Use `[[` to jump backward through
sections, and see the similar shortcuts `][` and `[]` in the VimTeX
documentation at `:help <Plug>(vimtex-][)` and `:help <Plug>(vimtex-[])`.

![Navigating sections](https://github.com/ejmastnak/vimtex-media/blob/main/move/move-section.gif)

### Navigating environments

Use `]m` and `[m` to jump to the next or previous environment `\begin{}`
command. See the VimTeX documentation for the similar shortcuts `]M` and `[M`,
described in `:help <Plug>(vimtex-]M)` and `:help <Plug>(vimtex-[M)`.

![Navigating environments](https://github.com/ejmastnak/vimtex-media/blob/main/move/move-environment.gif)

### Navigating math zones

Use `]n` and `[n` to jump to the beginning of the next or previous math zone.
See the VimTeX documentation for the similar shortcuts `]N` and `[N`,
described in `:help <Plug>(vimtex-]N)` and `:help <Plug>(vimtex-[N)`.

![Navigating math zones](https://github.com/ejmastnak/vimtex-media/blob/main/move/move-math.gif)

### Navigating frames

Use `]r` and `[r` to jump to the beginning of the next or previous Beamer
`frame` environment. See the VimTeX documentation for the similar shortcuts
`]R` and `[R`, described in `:help <Plug>(vimtex-]R)` and `:help
<Plug>(vimtex-[R)`.

![Navigating frames](https://github.com/ejmastnak/vimtex-media/blob/main/move/move-frame.gif)

### Navigating matching delimiters

Use `%` to move between matching delimiters, inline-math `$` delimiters, and LaTeX environments.

![Navigating matching delimiters](https://github.com/ejmastnak/vimtex-media/blob/main/move/move-matching.gif)

## Text objects

VimTeX provides text objects for commands, delimiters, environments, math zones,
sections, and items. Currently only delimiters and environments have a GIF.

### The delimiter and environment objects

The following GIF uses Vim's visual mode to show highlight the scope of the
`id`, `ad`, `ie`, and `ae` text objects.

![Delimiter and environment objects](https://github.com/ejmastnak/vimtex-media/blob/main/text-objects/text-objects.gif)

## Deleting surrounding LaTeX content

### Delete surrounding commands

Use `dsc` to delete a LaTeX command while preserving the command's argument(s);
the `dsc` mapping also recognizes and correctly deletes parameters inside square
brackets.

![`dsc`](https://github.com/ejmastnak/vimtex-media/blob/main/change-delete/dsc.gif)

### Delete surrounding environments

Use `dse` to delete the `\begin{}` and `\end{}` declaration surrounding a LaTeX
environment without changing the environment contents.

![`dse`](https://github.com/ejmastnak/vimtex-media/blob/main/change-delete/dse.gif)

### Delete surrounding math zones

Use `ds$` to delete surrounding math zones (display math, standard environments,
and inline math) without changing the math contents.

![`ds$`](https://github.com/ejmastnak/vimtex-media/blob/main/change-delete/dsm.gif)

### Delete surrounding delimiters

Use `dsd` to delete delimiters (e.g. `()`, `[]`, `{}`, *and* any of their `\left
\right`, `\big \big` variants) without changing the enclosed content.

![`dsd`](https://github.com/ejmastnak/vimtex-media/blob/main/change-delete/dsd.gif)


## Changing surrounding LaTeX content

### Change surrounding commands

Use `csc` to change a LaTeX command while preserving the command's argument(s).

![`csc`](https://github.com/ejmastnak/vimtex-media/blob/main/change-delete/csc.gif)

### Change surrounding environments

Use `cse` to change the type of a LaTeX environment without changing the
environment contents.

![`cse`](https://github.com/ejmastnak/vimtex-media/blob/main/change-delete/cse.gif)

### Change surrounding math zones

Use `cs$` to change the type of surrounding math zone without changing the math
contents. You can switch between display math, standard environments, and inline
math.

![`cs$`](https://github.com/ejmastnak/vimtex-media/blob/main/change-delete/csm.gif)

### Change surrounding delimiters

Use `csd` to change delimiters (e.g. `()`, `[]`, `{}`, and any of their `\left
\right`, `\big \big` variants) without changing the enclosed content; the `csd`
command is "smart" and correctly recognizes and preserves `\left \right`-style
modifiers.

![`csd`](https://github.com/ejmastnak/vimtex-media/blob/main/change-delete/csd.gif)

## Toggling commands

### Toggling starred commands and environments

Use `tsc` and `tse` to toggle between starred and un-starred versions of
commands and environments, respectively.

![`tsc` and `tse`](https://github.com/ejmastnak/vimtex-media/blob/main/toggle/tsc-tse.gif)

### Toggling delimiter modifiers

Use `tsd` to change between plain and `\left`/`\right` versions of delimiters.
Use the `g:vimtex_delim_toggle_mod_list` variable to add more modifiers  to the
delimiter toggle list. (e.g. `\big` as in the GIF below)

![`tsd`](https://github.com/ejmastnak/vimtex-media/blob/main/toggle/tsd.gif)

### Toggling fractions

Use `tsf` to toggle between inline and `\frac{}{}` versions of fractions.

![`tsf`](https://github.com/ejmastnak/vimtex-media/blob/main/toggle/tsf.gif)

