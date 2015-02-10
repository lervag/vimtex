if exists("current_compiler") | finish | endif
let current_compiler = "lacheck"

CompilerSet makeprg=lacheck\ %
CompilerSet errorformat="%f",\ line\ %l:\ %m
