" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#pgfplots#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'pgfplots') | return | endif
  let b:vimtex_syntax.pgfplots = 1

  " Load Tikz first
  call vimtex#syntax#p#tikz#load()

  " Add texAxisStatement to Tikz cluster
  syntax cluster texTikz add=texAxisStatement

  " Match pgfplotsset and axis environments
  syntax match texTikzSet /\\pgfplotsset\>/
        \ contains=texStatement skipwhite nextgroup=texTikzOptsCurly
  syntax match texTikzEnv /\v\\begin\{%(log)*axis}/
        \ contains=texBeginEnd nextgroup=texTikzOpts skipwhite
  syntax match texTikzEnv /\v\\begin\{groupplot}/
        \ contains=texBeginEnd nextgroup=texTikzOpts skipwhite

  " Match some custom pgfplots macros
  syntax match texAxisStatement /\\addplot3\>/
        \ contained skipwhite nextgroup=texTikzOpts
  syntax match texAxisStatement /\\nextgroupplot\>/
        \ contained skipwhite nextgroup=texTikzOpts

  highlight def link texAxisStatement texStatement
endfunction

" }}}1
