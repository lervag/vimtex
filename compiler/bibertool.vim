if exists("current_compiler") | finish | endif
let current_compiler = "bibertool"

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim

CompilerSet makeprg=biber\ --tool\ --validate-datamodel\ %:S

let &l:errorformat ="%-PINFO - Globbing data source '%f',"
let &l:errorformat.="%EERROR - %*[^\\,]\\, line %l\\, %m,"
setlocal errorformat+=%WWARN\ -\ Datamodel:\ %m
setlocal errorformat+=%-G%.%#
silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save
