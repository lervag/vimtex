" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('g:latex_enabled') && !g:latex_enabled
  finish
endif
if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

set suffixesadd+=.tex

" {{{1 Options

call latex#util#set_default('g:latex_build_dir', '.')
call latex#util#set_default('g:latex_complete_enabled', 1)
call latex#util#set_default('g:latex_complete_close_braces', 0)
call latex#util#set_default('g:latex_complete_recursive_bib', 0)
call latex#util#set_default('g:latex_complete_patterns',
      \ {
      \ 'ref' : '\C\\v\?\(eq\|page\|[cC]\|labelc\)\?ref\*\?\_\s*{[^{}]*',
      \ 'bib' : '\C\\\a*cite\a*\*\?\(\[[^\]]*\]\)*\_\s*{[^{}]*',
      \ })
call latex#util#set_default('g:latex_errorformat_show_warnings', 1)
call latex#util#set_default('g:latex_errorformat_ignore_warnings',
      \ [
      \ 'Underfull',
      \ 'Overfull',
      \ 'specifier changed to',
      \ ])
call latex#util#set_default('g:latex_fold_enabled', 1)
call latex#util#set_default('g:latex_fold_preamble', 1)
call latex#util#set_default('g:latex_fold_envs', 1)
call latex#util#set_default('g:latex_fold_parts',
      \ [
      \   "part",
      \   "appendix",
      \   "frontmatter",
      \   "mainmatter",
      \   "backmatter",
      \ ])
call latex#util#set_default('g:latex_fold_sections',
      \ [
      \   "chapter",
      \   "section",
      \   "subsection",
      \   "subsubsection",
      \ ])
call latex#util#set_default('g:latex_indent_enabled', 1)
call latex#util#set_default('g:latex_latexmk_enabled', 1)
call latex#util#set_default('g:latex_latexmk_callback', 1)
call latex#util#set_default('g:latex_latexmk_options', '')
call latex#util#set_default('g:latex_latexmk_output', 'pdf')
call latex#util#set_default('g:latex_latexmk_autojump', '0')
call latex#util#set_default('g:latex_latexmk_quickfix', '2')
call latex#util#set_default('g:latex_mappings_enabled', 1)
call latex#util#set_default('g:latex_motion_enabled', 1)
call latex#util#set_default('g:latex_motion_matchparen', 1)
call latex#util#set_default('g:latex_toc_enabled', 1)
call latex#util#set_default('g:latex_toc_width', 30)
call latex#util#set_default('g:latex_toc_split_side', 'leftabove')
call latex#util#set_default('g:latex_toc_resize', 1)
call latex#util#set_default('g:latex_toc_hide_help', 0)
call latex#util#set_default('g:latex_toc_fold', 0)
call latex#util#set_default('g:latex_toc_fold_levels', 0)
call latex#util#set_default('g:latex_viewer', 'xdg-open')

" }}}1

call latex#init()

" vim: fdm=marker
