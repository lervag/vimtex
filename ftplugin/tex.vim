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

" Set default options
" {{{1 Completion
call latex#util#set_default('g:latex_complete_enabled', 1)
call latex#util#set_default('g:latex_complete_close_braces', 0)
call latex#util#set_default('g:latex_complete_patterns', {
      \ 'ref' : '\C\\v\?\(eq\|page\|[cC]\)\?ref\*\?\_\s*{[^{}]*',
      \ 'bib' : '\C\\\a*cite\a*\*\?\(\[[^\]]*\]\)*\_\s*{[^{}]*',
      \ })

" {{{1 Folding
call latex#util#set_default('g:latex_fold_enabled', 1)
call latex#util#set_default('g:latex_fold_preamble', 1)
call latex#util#set_default('g:latex_fold_envs', 1)
call latex#util#set_default('g:latex_fold_parts',
      \ [
        \ "appendix",
        \ "frontmatter",
        \ "mainmatter",
        \ "backmatter",
      \ ])
call latex#util#set_default('g:latex_fold_sections',
      \ [
        \ "part",
        \ "chapter",
        \ "section",
        \ "subsection",
        \ "subsubsection",
      \ ])

" {{{1 Latexmk
call latex#util#set_default('g:latex_latexmk_enabled', 1)
call latex#util#set_default('g:latex_latexmk_options', '')
call latex#util#set_default('g:latex_latexmk_output', 'pdf')
call latex#util#set_default('g:latex_latexmk_autojump', '0')

" {{{1 Miscelleneous
call latex#util#set_default('g:latex_default_mappings', 1)
call latex#util#set_default('g:latex_viewer', 'xdg-open')
call latex#util#set_default('g:latex_build_dir', '.')
call latex#util#set_default('g:latex_main_tex_candidates',
      \ [
        \ 'main',
        \ 'memo',
        \ 'note',
        \ 'report',
        \ 'thesis',
      \])
call latex#util#set_default('g:latex_errorformat_show_warnings', 1)
call latex#util#set_default('g:latex_errorformat_ignore_warnings',
      \ [
        \ 'Underfull',
        \ 'Overfull',
        \ 'specifier changed to',
      \ ])

" {{{1 Motion
call latex#util#set_default('g:latex_motion_enabled', 1)
call latex#util#set_default('g:latex_motion_matchparen', 1)

" {{{1 Toc
call latex#util#set_default('g:latex_toc_enabled', 1)
call latex#util#set_default('g:latex_toc_width', 30)
call latex#util#set_default('g:latex_toc_split_side', 'leftabove')
call latex#util#set_default('g:latex_toc_resize', 1)
call latex#util#set_default('g:latex_toc_hide_help', 0)
call latex#util#set_default('g:latex_toc_fold', 0)
call latex#util#set_default('g:latex_toc_fold_levels', 0)
" }}}1

call latex#init()

" vim:fdm=marker:ff=unix
