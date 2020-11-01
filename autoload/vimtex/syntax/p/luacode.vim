" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#luacode#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'luacode') | return | endif
  let b:vimtex_syntax.luacode = 1

  call vimtex#syntax#nested#include('lua')
  syntax region texRegionLua
        \ start='\\begin{luacode\*\?}'
        \ end='\\end{luacode\*\?}'
        \ keepend
        \ transparent
        \ contains=texCmdEnv,@vimtex_nested_lua
  syntax match texCmd '\\\(directlua\|luadirect\)' nextgroup=texRegionLuaArg
  syntax region texRegionLuaArg matchgroup=Delimiter
        \ start='{'
        \ end='}'
        \ contained
        \ contains=@vimtex_nested_lua
endfunction

" }}}1
