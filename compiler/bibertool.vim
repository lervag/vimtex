if exists('current_compiler') | finish | endif
let current_compiler = 'bibertool'

let s:cpo_save = &cpo
set cpo&vim

CompilerSet makeprg=biber\ --nodieonerror\ --noconf\ --nolog\ --output-file=-\ --validate-datamodel\ --tool\ %:S

let &l:errorformat = "%-PINFO - Globbing data source '%f',"
let &l:errorformat .= '%EERROR - %*[^\,]\, line %l\, %m,'
let &l:errorformat .= "%WWARN - Datamodel: Entry '%s' (%f): %m,"
let &l:errorformat .= '%WWARN - Datamodel: %m,'
let &l:errorformat .= '%-G%.%#'
silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save
