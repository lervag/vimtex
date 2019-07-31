" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#moreverb#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'moreverb') | return | endif
  let b:vimtex_syntax.moreverb = 1

  if exists('g:tex_verbspell')
    syntax region texZone start="\\begin{verbatimtab}"   end="\\end{verbatimtab}\|%stopzone\>"   contains=@Spell
    syntax region texZone start="\\begin{verbatimwrite}" end="\\end{verbatimwrite}\|%stopzone\>" contains=@Spell
    syntax region texZone start="\\begin{boxedverbatim}" end="\\end{boxedverbatim}\|%stopzone\>" contains=@Spell
  else
    syntax region texZone start="\\begin{verbatimtab}"   end="\\end{verbatimtab}\|%stopzone\>"
    syntax region texZone start="\\begin{verbatimwrite}" end="\\end{verbatimwrite}\|%stopzone\>"
    syntax region texZone start="\\begin{boxedverbatim}" end="\\end{boxedverbatim}\|%stopzone\>"
  endif
endfunction

" }}}1
