" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#p#todonotes#load(cfg) abort " {{{1
  syntax match texCmdTodo '\\todo\>' nextgroup=texTodoOpt,texTodoArg

  call vimtex#syntax#core#new_opt('texTodoOpt', {'next': 'texTodoArg'})
  call vimtex#syntax#core#new_arg('texTodoArg', {'contains': 'TOP,@Spell'})

  highlight def link texTodoOpt texOpt
endfunction

" }}}1
