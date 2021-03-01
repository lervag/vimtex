" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#luacode#load(cfg) abort " {{{1
  call vimtex#syntax#nested#include('lua')

  call vimtex#syntax#core#new_region_env('texLuaZone', 'luacode\*\?',
        \ {'contains': '@vimtex_nested_lua,texCmd'})

  syntax match texCmdLua "\\\%(directlua\|luadirect\)\>"
        \ nextgroup=texLuaArg skipwhite skipnl
  call vimtex#syntax#core#new_arg('texLuaArg', {
        \ 'contains': '@vimtex_nested_lua,texCmd',
        \})

  highlight def link texCmdLua texCmd
endfunction

" }}}1
