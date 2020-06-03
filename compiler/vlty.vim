"
"   vlty: a "compiler" for vimtex,
"         invokes LanguageTool with YaLafi as LaTeX filter
"

if exists("current_compiler")
    finish
endif
let current_compiler = "vlty"

" older Vim always used :setlocal
if exists(':CompilerSet') != 2
    command -nargs=* CompilerSet setlocal <args>
endif

let s:cpo_save = &cpo
set cpo&vim


"   set default values
"
let s:pref = 'In order to use the vlty compiler, please '
if !exists('g:vimtex_vlty')
    let g:vimtex_lty = {}
elseif type(g:vimtex_vlty) != type({})
    echoerr s:pref . 'initialise g:vimtex_vlty with a dictionary.'
    finish
endif
let s:vlty = g:vimtex_vlty

if !has_key(s:vlty, 'ltdirectory')
    let s:vlty['ltdirectory'] = '~/lib/LanguageTool'
endif
if !has_key(s:vlty, 'server')
    let s:vlty['server'] = ''
endif
if !has_key(s:vlty, 'disable')
    let s:vlty['disable'] = 'WHITESPACE_RULE'
endif
if !has_key(s:vlty, 'enable')
    let s:vlty['enable'] = ''
endif
if !has_key(s:vlty, 'disablecategories')
    let s:vlty['disablecategories'] = ''
endif
if !has_key(s:vlty, 'enablecategories')
    let s:vlty['enablecategories'] = ''
endif
if !has_key(s:vlty, 'shell_options')
    let s:vlty['shell_options'] = ''
endif
if !has_key(s:vlty, 'show_suggestions')
    let s:vlty['show_suggestions'] = 0
endif


"   check installation components
"
if !executable('python')
    echoerr s:pref . 'install Python.'
    finish
endif
call system('python -c "import yalafi"')
if v:shell_error != 0
    echoerr s:pref . 'install the Python module YaLafi.'
    finish
endif
if s:vlty['server'] != 'lt'
    if !executable('java')
        echoerr s:pref . 'install Java.'
        finish
    endif
    if !filereadable(fnamemodify(s:vlty['ltdirectory']
                            \ . '/languagetool-commandline.jar', ':p'))
        echoerr s:pref . "set g:vimtex_vlty['ltdirectory'] to the"
                    \ . ' path of LanguageTool.'
        finish
    endif
endif


let s:vimtex = getbufvar(bufnr(), 'vimtex',
                        \ {'documentclass': '', 'packages': {}})
let s:documentclass = s:vimtex['documentclass']
let s:packages = join(keys(s:vimtex['packages']), ',')
let s:language = matchstr(&spelllang, '\v^\a\a([-_]\a\a)?')
let s:language = substitute(s:language, '_', '-', '')

let &l:makeprg =
    \ 'python -m yalafi.shell'
    \ . ' --lt-directory ' . s:vlty['ltdirectory']
    \ . (s:vlty['server'] == '' ?  '' : ' --server ' . s:vlty['server'])
    \ . ' --language ' . s:language
    \ . ' --disable "' . s:vlty['disable'] . '"'
    \ . ' --enable "' . s:vlty['enable'] . '"'
    \ . ' --disablecategories "' . s:vlty['disablecategories'] . '"'
    \ . ' --enablecategories "' . s:vlty['enablecategories'] . '"'
    \ . ' --documentclass "' . s:documentclass . '"'
    \ . ' --packages "' . s:packages . '"'
    \ . ' ' . s:vlty['shell_options']
    \ . ' %:S'

let &l:errorformat = '%A%*\d.) Line %l\, column %v\, Rule ID:%.%#,'
if s:vlty['show_suggestions'] == 0
    let &l:errorformat .= '%ZMessage: %m,%-G%.%#'
else
    let &l:errorformat .= '%CMessage: %m,%Z%m,%-G%.%#'
endif

silent CompilerSet makeprg
silent CompilerSet errorformat

let &cpo = s:cpo_save
unlet s:cpo_save

