" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#circuitikz#load(cfg) abort " {{{1
  call vimtex#syntax#packages#load('tikz')

  syntax match texTikzEnvBgn "\\begin{circuitikz}"
        \ nextgroup=texTikzOpt skipwhite skipnl
        \ contains=texCmdEnv
  call vimtex#syntax#core#new_region_env('texTikzZone', 'circuitikz', {
        \ 'contains': '@texClusterTikz',
        \ 'transparent': 1,
        \})
endfunction

" }}}1

