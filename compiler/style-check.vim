if exists('current_compiler') | finish | endif
let current_compiler = 'style-check'

let s:cpo_save = &cpo
set cpo&vim

CompilerSet makeprg=style-check.rb\ %:S

setlocal errorformat=
setlocal errorformat+=%f:%l:%c:\ %m
setlocal errorformat+=%-G%.%#
silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save
