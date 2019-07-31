" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#luacode#load() abort " {{{1
  if has_key(b:vimtex_syntax, 'luacode') | return | endif
  let b:vimtex_syntax.luacode = 1

  unlet b:current_syntax
  syntax include @LUA syntax/lua.vim
  let b:current_syntax = 'tex'

  call vimtex#syntax#add_to_clusters('texZoneLua')
  syntax region texZoneLua
        \ start='\\begin{luacode\*\?}'rs=s
        \ end='\\end{luacode\*\?}'re=e
        \ keepend
        \ transparent
        \ contains=texBeginEnd,@LUA
  syntax match texStatement '\\\(directlua\|luadirect\)' nextgroup=texZoneLuaArg
  syntax region texZoneLuaArg matchgroup=Delimiter
        \ start='{'
        \ end='}'
        \ contained
        \ contains=@LUA
endfunction

" }}}1
