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

  " Apply a simple hack to allow texCmd in lua blocks.
  " Note: The hack depends on which version of Lua syntax is used. The
  "       following is tested with the standard builtin Lua support, as well as
  "       the "tbastos/vim-lua" plugin.
  if s:lua_is_builtin()
    syntax match texCmd nextgroup=texOpt,texArg skipwhite skipnl "\\[a-zA-Z@]\+" contained containedin=luaFunctionBlock
  else
    syntax cluster luaStat add=texCmd
  endif

  highlight def link texCmdLua texCmd
endfunction

" }}}1

function! s:lua_is_builtin() abort " {{{1
  let l:path = globpath(&runtimepath, 'syntax/lua.vim', 0, 1)[0]

  return has('nvim')
        \ ? stridx(l:path, 'runtime/syntax') > 0
        \ : l:path =~# 'vim\d\+/syntax'
endfunction

" }}}1
