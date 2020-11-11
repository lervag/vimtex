" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#luacode#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'luacode') | return | endif
  let b:vimtex_syntax.luacode = 1

  call vimtex#syntax#nested#include('lua')

  call vimtex#syntax#core#new_region_env('texLuaRegion', 'luacode\*\?', '@vimtex_nested_lua')

  syntax match texCmdLua "\\\%(directlua\|luadirect\)\>" nextgroup=texLuaArg skipwhite skipnl
  call vimtex#syntax#core#new_arg('texLuaArg', {
        \ 'contains': '@vimtex_nested_lua',
        \ 'opts': 'contained keepend',
        \})

  highlight def link texCmdLua texCmd
endfunction

" }}}1
