" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#init() " {{{1
  call s:check_version()

  call s:init_options()
  call s:init_highlights()
  call s:init_state()
  call s:init_buffer()
  call s:init_default_mappings()

  if exists('#User#VimtexEventInitPost')
    doautocmd User VimtexEventInitPost
  endif
endfunction

" }}}1

function! s:check_version() " {{{1
  if get(g:, 'vimtex_disable_version_warning', 0)
    return
  endif

  if v:version <= 703 && !has('patch544')
    echoerr 'vimtex error: Please use Vim version 7.3.544 or newer!'
  endif
endfunction

" }}}1

function! s:init_options() " {{{1
  call s:init_option('vimtex_compiler_enabled', 1)
  call s:init_option('vimtex_compiler_method', 'latexmk')
  call s:init_option('vimtex_compiler_progname',
        \ get(v:, 'progpath', get(v:, 'progname')))
  call s:init_option('vimtex_compiler_callback_hooks', [])

  call s:init_option('vimtex_complete_enabled', 1)
  call s:init_option('vimtex_complete_close_braces', 0)
  call s:init_option('vimtex_complete_recursive_bib', 0)

  call s:init_option('vimtex_echo_ignore_wait', 0)

  call s:init_option('vimtex_fold_enabled', 0)
  if &diff
    let g:vimtex_fold_manual = 0
  else
    call s:init_option('vimtex_fold_manual', 0)
  endif
  call s:init_option('vimtex_fold_comments', 0)
  call s:init_option('vimtex_fold_levelmarker', '*')
  call s:init_option('vimtex_fold_preamble', 1)
  call s:init_option('vimtex_fold_envs', 1)
  call s:init_option('vimtex_fold_markers', 1)
  call s:init_option('vimtex_fold_parts',
        \ [
        \   'part',
        \   'appendix',
        \   'frontmatter',
        \   'mainmatter',
        \   'backmatter',
        \ ])
  call s:init_option('vimtex_fold_sections',
        \ [
        \   'chapter',
        \   'section',
        \   'subsection',
        \   'subsubsection',
        \ ])
  call s:init_option('vimtex_fold_commands_default', {
        \ 'hypersetup' : 'single',
        \ 'tikzset' : 'single',
        \ 'usepackage' : 'single_opt',
        \ 'includepdf' : 'single_opt',
        \ '%(re)?new%(command|environment)' : 'multi',
        \ 'providecommand' : 'multi',
        \ 'presetkeys' : 'multi',
        \ 'Declare%(Multi|Auto)?CiteCommand' : 'multi',
        \ 'Declare%(Index)?%(Field|List|Name)%(Format|Alias)' : 'multi',
        \})

  call s:init_option('vimtex_format_enabled', 0)

  call s:init_option('vimtex_imaps_enabled', 1)
  call s:init_option('vimtex_imaps_leader', '`')
  call s:init_option('vimtex_imaps_disabled', [])
  call s:init_option('vimtex_imaps_list', [
        \ { 'lhs' : '0',  'rhs' : '\emptyset' },
        \ { 'lhs' : '6',  'rhs' : '\partial' },
        \ { 'lhs' : '8',  'rhs' : '\infty' },
        \ { 'lhs' : '=',  'rhs' : '\equiv' },
        \ { 'lhs' : '\',  'rhs' : '\setminus' },
        \ { 'lhs' : '.',  'rhs' : '\cdot' },
        \ { 'lhs' : '*',  'rhs' : '\times' },
        \ { 'lhs' : '<',  'rhs' : '\langle' },
        \ { 'lhs' : '>',  'rhs' : '\rangle' },
        \ { 'lhs' : '<=', 'rhs' : '\leq' },
        \ { 'lhs' : '>=', 'rhs' : '\geq' },
        \ { 'lhs' : '[',  'rhs' : '\subseteq' },
        \ { 'lhs' : ']',  'rhs' : '\supseteq' },
        \ { 'lhs' : '(',  'rhs' : '\subset' },
        \ { 'lhs' : ')',  'rhs' : '\supset' },
        \ { 'lhs' : 'A',  'rhs' : '\forall' },
        \ { 'lhs' : 'E',  'rhs' : '\exists' },
        \ { 'lhs' : 'qj', 'rhs' : '\downarrow' },
        \ { 'lhs' : 'qJ', 'rhs' : '\Downarrow' },
        \ { 'lhs' : 'qk', 'rhs' : '\uparrow' },
        \ { 'lhs' : 'qK', 'rhs' : '\Uparrow' },
        \ { 'lhs' : 'qh', 'rhs' : '\leftarrow' },
        \ { 'lhs' : 'qH', 'rhs' : '\Leftarrow' },
        \ { 'lhs' : 'ql', 'rhs' : '\rightarrow' },
        \ { 'lhs' : 'qL', 'rhs' : '\Rightarrow' },
        \ { 'lhs' : 'a',  'rhs' : '\alpha' },
        \ { 'lhs' : 'b',  'rhs' : '\beta' },
        \ { 'lhs' : 'c',  'rhs' : '\chi' },
        \ { 'lhs' : 'd',  'rhs' : '\delta' },
        \ { 'lhs' : 'e',  'rhs' : '\epsilon' },
        \ { 'lhs' : 'f',  'rhs' : '\phi' },
        \ { 'lhs' : 'g',  'rhs' : '\gamma' },
        \ { 'lhs' : 'h',  'rhs' : '\eta' },
        \ { 'lhs' : 'i',  'rhs' : '\iota' },
        \ { 'lhs' : 'k',  'rhs' : '\kappa' },
        \ { 'lhs' : 'l',  'rhs' : '\lambda' },
        \ { 'lhs' : 'm',  'rhs' : '\mu' },
        \ { 'lhs' : 'n',  'rhs' : '\nu' },
        \ { 'lhs' : 'p',  'rhs' : '\pi' },
        \ { 'lhs' : 'q',  'rhs' : '\theta' },
        \ { 'lhs' : 'r',  'rhs' : '\rho' },
        \ { 'lhs' : 's',  'rhs' : '\sigma' },
        \ { 'lhs' : 't',  'rhs' : '\tau' },
        \ { 'lhs' : 'y',  'rhs' : '\psi' },
        \ { 'lhs' : 'u',  'rhs' : '\upsilon' },
        \ { 'lhs' : 'w',  'rhs' : '\omega' },
        \ { 'lhs' : 'z',  'rhs' : '\zeta' },
        \ { 'lhs' : 'x',  'rhs' : '\xi' },
        \ { 'lhs' : 'G',  'rhs' : '\Gamma' },
        \ { 'lhs' : 'D',  'rhs' : '\Delta' },
        \ { 'lhs' : 'F',  'rhs' : '\Phi' },
        \ { 'lhs' : 'G',  'rhs' : '\Gamma' },
        \ { 'lhs' : 'L',  'rhs' : '\Lambda' },
        \ { 'lhs' : 'P',  'rhs' : '\Pi' },
        \ { 'lhs' : 'Q',  'rhs' : '\Theta' },
        \ { 'lhs' : 'S',  'rhs' : '\Sigma' },
        \ { 'lhs' : 'U',  'rhs' : '\Upsilon' },
        \ { 'lhs' : 'W',  'rhs' : '\Omega' },
        \ { 'lhs' : 'X',  'rhs' : '\Xi' },
        \ { 'lhs' : 'Y',  'rhs' : '\Psi' },
        \ { 'lhs' : 've', 'rhs' : '\varepsilon' },
        \ { 'lhs' : 'vf', 'rhs' : '\varphi' },
        \ { 'lhs' : 'vk', 'rhs' : '\varkappa' },
        \ { 'lhs' : 'vq', 'rhs' : '\vartheta' },
        \ { 'lhs' : 'vr', 'rhs' : '\varrho' },
        \])

  call s:init_option('vimtex_index_hide_line_numbers', 1)
  call s:init_option('vimtex_index_resize', 0)
  call s:init_option('vimtex_index_show_help', 1)
  call s:init_option('vimtex_index_split_pos', 'vert leftabove')
  call s:init_option('vimtex_index_split_width', 30)

  call s:init_option('vimtex_matchparen_enabled', 1)
  call s:init_option('vimtex_motion_enabled', 1)

  call s:init_option('vimtex_labels_enabled', 1)

  call s:init_option('vimtex_quickfix_method', 'latexlog')
  call s:init_option('vimtex_quickfix_autojump', '0')
  call s:init_option('vimtex_quickfix_mode', '2')
  call s:init_option('vimtex_quickfix_open_on_warning', '1')

  call s:init_option('vimtex_text_obj_enabled', 1)
  call s:init_option('vimtex_text_obj_linewise_operators', ['d', 'y'])

  call s:init_option('vimtex_toc_enabled', 1)
  call s:init_option('vimtex_toc_fold', 0)
  call s:init_option('vimtex_toc_fold_levels', 10)
  call s:init_option('vimtex_toc_number_width', 0)
  call s:init_option('vimtex_toc_secnumdepth', 3)
  call s:init_option('vimtex_toc_show_numbers', 1)
  call s:init_option('vimtex_toc_show_preamble', 1)

  call s:init_option('vimtex_view_enabled', 1)
  call s:init_option('vimtex_view_automatic', 1)
  call s:init_option('vimtex_view_method', 'general')
  call s:init_option('vimtex_view_use_temp_files', 0)
  call s:init_option('vimtex_view_general_viewer', get({
        \ 'linux' : 'xdg-open',
        \ 'mac'   : 'open',
        \}, vimtex#util#get_os(), ''))
  call s:init_option('vimtex_view_general_options', '@pdf')
  call s:init_option('vimtex_view_general_options_latexmk', '')
  call s:init_option('vimtex_view_mupdf_options', '')
  call s:init_option('vimtex_view_mupdf_send_keys', '')
  call s:init_option('vimtex_view_zathura_options', '')
endfunction

" }}}1
function! s:init_option(option, default) " {{{1
  let l:option = 'g:' . a:option
  if !exists(l:option)
    let {l:option} = a:default
  endif
endfunction

" }}}1
function! s:init_highlights() " {{{1
  for [l:name, l:target] in [
        \ ['VimtexImapsArrow', 'Comment'],
        \ ['VimtexImapsLhs', 'ModeMsg'],
        \ ['VimtexImapsRhs', 'ModeMsg'],
        \ ['VimtexImapsWrapper', 'Type'],
        \ ['VimtexIndexHelp', 'helpVim'],
        \ ['VimtexIndexLine', 'ModeMsg'],
        \ ['VimtexInfo', 'Question'],
        \ ['VimtexLabelsChap', 'PreProc'],
        \ ['VimtexLabelsEq', 'Statement'],
        \ ['VimtexLabelsFig', 'Identifier'],
        \ ['VimtexLabelsHelp', 'helpVim'],
        \ ['VimtexLabelsLine', 'Todo'],
        \ ['VimtexLabelsSec', 'Type'],
        \ ['VimtexLabelsTab', 'String'],
        \ ['VimtexMsg', 'ModeMsg'],
        \ ['VimtexSuccess', 'Statement'],
        \ ['VimtexTocHelp', 'helpVim'],
        \ ['VimtexTocNum', 'Number'],
        \ ['VimtexTocSec0', 'Title'],
        \ ['VimtexTocSec1', 'Normal'],
        \ ['VimtexTocSec2', 'helpVim'],
        \ ['VimtexTocSec3', 'NonText'],
        \ ['VimtexTocSec4', 'Comment'],
        \ ['VimtexTocTag', 'Directory'],
        \ ['VimtexWarning', 'WarningMsg'],
        \]
    if !hlexists(l:name)
      silent execute 'highlight default link' l:name l:target
    endif
  endfor
endfunction

" }}}1
function! s:init_state() " {{{1
  call vimtex#state#init()
  call vimtex#state#init_local()
endfunction

" }}}1
function! s:init_buffer() " {{{1
  " Set Vim options
  for l:suf in [
        \ '.sty',
        \ '.cls',
        \ '.log',
        \ '.aux',
        \ '.bbl',
        \ '.out',
        \ '.blg',
        \ '.brf',
        \ '.cb',
        \ '.dvi',
        \ '.fdb_latexmk',
        \ '.fls',
        \ '.idx',
        \ '.ilg',
        \ '.ind',
        \ '.inx',
        \ '.pdf',
        \ '.synctex.gz',
        \ '.toc',
        \ ]
    execute 'set suffixes+=' . l:suf
  endfor
  setlocal suffixesadd=.tex,.sty,.cls
  setlocal comments=sO:%\ -,mO:%\ \ ,eO:%%,:%
  setlocal commentstring=%%s
  setlocal includeexpr=vimtex#include#expr()
  let &l:include = '\v\\%(input|include)\{'
  let &l:define  = '\\\([egx]\|char\|mathchar\|count\|dimen\|muskip\|skip'
  let &l:define .= '\|toks\)\=def\|\\font\|\\\(future\)\=let'
  let &l:define .= '\|\\new\(count\|dimen\|skip'
  let &l:define .= '\|muskip\|box\|toks\|read\|write\|fam\|insert\)'
  let &l:define .= '\|\\\(re\)\=new\(boolean\|command\|counter\|environment'
  let &l:define .= '\|font\|if\|length\|savebox'
  let &l:define .= '\|theorem\(style\)\=\)\s*\*\=\s*{\='
  let &l:define .= '\|DeclareMathOperator\s*{\=\s*'

  " Define autocommands
  augroup vimtex_buffers
    au BufFilePre  <buffer> call s:filename_changed_pre()
    au BufFilePost <buffer> call s:filename_changed_post()
    au BufLeave    <buffer> call s:buffer_left()
    au BufDelete   <buffer> call s:buffer_deleted()
    au QuitPre     <buffer> call s:buffer_deleted(b:vimtex_id)
  augroup END

  " Initialize buffer settings for sub modules
  for l:mod in s:modules
    if index(get(b:vimtex, 'disabled_modules', []), l:mod) >= 0 | continue | endif

    try
      call vimtex#{l:mod}#init_buffer()
    catch /E117.*#init_/
    endtry
  endfor
endfunction

" }}}1
function! s:init_default_mappings() " {{{1
  if !get(g:,'vimtex_mappings_enabled', 1) | return | endif

  function! s:map(mode, lhs, rhs, ...)
    if (a:0 > 0) || (maparg(a:lhs, a:mode) ==# '')
      silent execute a:mode . 'map <silent><buffer>' a:lhs a:rhs
    endif
  endfunction

  call s:map('n', '<localleader>li', '<plug>(vimtex-info)')
  call s:map('n', '<localleader>lI', '<plug>(vimtex-info-full)')
  call s:map('n', '<localleader>lx', '<plug>(vimtex-reload)')
  call s:map('n', '<localleader>ls', '<plug>(vimtex-toggle-main)')

  call s:map('n', 'ds$', '<plug>(vimtex-env-delete-math)')
  call s:map('n', 'cs$', '<plug>(vimtex-env-change-math)')
  call s:map('n', 'dse', '<plug>(vimtex-env-delete)')
  call s:map('n', 'cse', '<plug>(vimtex-env-change)')
  call s:map('n', 'tse', '<plug>(vimtex-env-toggle-star)')

  call s:map('n', 'dsc',  '<plug>(vimtex-cmd-delete)')
  call s:map('n', 'csc',  '<plug>(vimtex-cmd-change)')
  call s:map('n', 'tsc',  '<plug>(vimtex-cmd-toggle-star)')
  call s:map('i', '<F7>', '<plug>(vimtex-cmd-create)')
  call s:map('n', '<F7>', '<plug>(vimtex-cmd-create)')
  call s:map('x', '<F7>', '<plug>(vimtex-cmd-create)')

  call s:map('n', 'dsd', '<plug>(vimtex-delim-delete)')
  call s:map('n', 'csd', '<plug>(vimtex-delim-change-math)')
  call s:map('n', 'tsd', '<plug>(vimtex-delim-toggle-modifier)')
  call s:map('x', 'tsd', '<plug>(vimtex-delim-toggle-modifier)')
  call s:map('i', ']]',  '<plug>(vimtex-delim-close)')

  if get(g:, 'vimtex_compiler_enabled', 0)
    call s:map('n', '<localleader>ll', '<plug>(vimtex-compile)')
    call s:map('n', '<localleader>lo', '<plug>(vimtex-compile-output)')
    call s:map('n', '<localleader>lL', '<plug>(vimtex-compile-selected)')
    call s:map('x', '<localleader>lL', '<plug>(vimtex-compile-selected)')
    call s:map('n', '<localleader>lk', '<plug>(vimtex-stop)')
    call s:map('n', '<localleader>lK', '<plug>(vimtex-stop-all)')
    call s:map('n', '<localleader>le', '<plug>(vimtex-errors)')
    call s:map('n', '<localleader>lc', '<plug>(vimtex-clean)')
    call s:map('n', '<localleader>lC', '<plug>(vimtex-clean-full)')
    call s:map('n', '<localleader>lg', '<plug>(vimtex-status)')
    call s:map('n', '<localleader>lG', '<plug>(vimtex-status-all)')
  endif

  if get(g:, 'vimtex_motion_enabled', 0)
    call s:map('n', ']]', '<plug>(vimtex-]])')
    call s:map('n', '][', '<plug>(vimtex-][)')
    call s:map('n', '[]', '<plug>(vimtex-[])')
    call s:map('n', '[[', '<plug>(vimtex-[[)')
    call s:map('x', ']]', '<plug>(vimtex-]])')
    call s:map('x', '][', '<plug>(vimtex-][)')
    call s:map('x', '[]', '<plug>(vimtex-[])')
    call s:map('x', '[[', '<plug>(vimtex-[[)')
    call s:map('o', ']]', '<plug>(vimtex-]])')
    call s:map('o', '][', '<plug>(vimtex-][)')
    call s:map('o', '[]', '<plug>(vimtex-[])')
    call s:map('o', '[[', '<plug>(vimtex-[[)')

    " These are forced in order to overwrite matchit mappings
    call s:map('n', '%', '<plug>(vimtex-%)', 1)
    call s:map('x', '%', '<plug>(vimtex-%)', 1)
    call s:map('o', '%', '<plug>(vimtex-%)', 1)
  endif

  if get(g:, 'vimtex_text_obj_enabled', 0)
    call s:map('x', 'ic', '<plug>(vimtex-ic)')
    call s:map('x', 'ac', '<plug>(vimtex-ac)')
    call s:map('o', 'ic', '<plug>(vimtex-ic)')
    call s:map('o', 'ac', '<plug>(vimtex-ac)')
    call s:map('x', 'id', '<plug>(vimtex-id)')
    call s:map('x', 'ad', '<plug>(vimtex-ad)')
    call s:map('o', 'id', '<plug>(vimtex-id)')
    call s:map('o', 'ad', '<plug>(vimtex-ad)')
    call s:map('x', 'ie', '<plug>(vimtex-ie)')
    call s:map('x', 'ae', '<plug>(vimtex-ae)')
    call s:map('o', 'ie', '<plug>(vimtex-ie)')
    call s:map('o', 'ae', '<plug>(vimtex-ae)')
    call s:map('x', 'i$', '<plug>(vimtex-i$)')
    call s:map('x', 'a$', '<plug>(vimtex-a$)')
    call s:map('o', 'i$', '<plug>(vimtex-i$)')
    call s:map('o', 'a$', '<plug>(vimtex-a$)')
    call s:map('x', 'iP', '<plug>(vimtex-iP)')
    call s:map('x', 'aP', '<plug>(vimtex-aP)')
    call s:map('o', 'iP', '<plug>(vimtex-iP)')
    call s:map('o', 'aP', '<plug>(vimtex-aP)')
  endif

  if get(g:, 'vimtex_toc_enabled', 0)
    call s:map('n', '<localleader>lt', '<plug>(vimtex-toc-open)')
    call s:map('n', '<localleader>lT', '<plug>(vimtex-toc-toggle)')
  endif

  if get(g:, 'vimtex_labels_enabled', 0)
    call s:map('n', '<localleader>ly', '<plug>(vimtex-labels-open)')
    call s:map('n', '<localleader>lY', '<plug>(vimtex-labels-toggle)')
  endif

  if has_key(b:vimtex, 'viewer')
    call s:map('n', '<localleader>lv', '<plug>(vimtex-view)')
    if has_key(b:vimtex.viewer, 'reverse_search')
      call s:map('n', '<localleader>lr', '<plug>(vimtex-reverse-search)')
    endif
  endif

  if get(g:, 'vimtex_imaps_enabled', 0)
    call s:map('n', '<localleader>lm', '<plug>(vimtex-imaps-list)')
  endif
endfunction

" }}}1

function! s:filename_changed_pre() " {{{1
  let thisfile = fnamemodify(expand('%'), ':p')
  let s:filename_changed = thisfile ==# b:vimtex.tex
  let s:filename_old = b:vimtex.base
endfunction

" }}}1
function! s:filename_changed_post() " {{{1
  if s:filename_changed
    let b:vimtex.tex = fnamemodify(expand('%'), ':p')
    let b:vimtex.base = fnamemodify(b:vimtex.tex, ':t')
    let b:vimtex.name = fnamemodify(b:vimtex.tex, ':t:r')
    let message = ['vimtex: ',
          \ ['VimtexWarning', 'Filename change detected!'],
          \ "\n  Old filename: ", ['VimtexInfo', s:filename_old],
          \ "\n  New filename: ", ['VimtexInfo', b:vimtex.base]]

    if has_key(b:vimtex, 'compiler')
          \ && b:vimtex.compiler.is_running()
      let message += ["\n  latexmk process: ",
            \ ['VimtexInfo', b:vimtex.pid],
            \ ['VimtexWarning', ' killed!']]
      call vimtex#compiler#stop()
    endif

    " Update viewer output file names
    if exists('b:vimtex.viewer.out')
      call vimtex#view#common#use_temp_files_p(b:vimtex.viewer)
    endif

    call vimtex#echo#status(message)
  endif
endfunction

" }}}1
function! s:buffer_left() " {{{1
  let s:vimtex_id = b:vimtex_id
endfunction

" }}}1
function! s:buffer_deleted(...) " {{{1
  "
  " Get the relevant blob id
  "
  let l:vimtex_id = a:0 > 0 ? a:1 : get(s:, 'vimtex_id', -1)
  if exists('s:vimtex_id') | unlet s:vimtex_id | endif
  if !vimtex#state#exists(l:vimtex_id) | return | endif

  "
  " Count the number of open buffers for the given blob
  "
  let l:buffers = filter(range(1, bufnr('$')), 'buflisted(v:val)')
  let l:vimtex_ids = map(l:buffers, 'getbufvar(v:val, ''vimtex_id'', -1)')
  let l:count = count(l:vimtex_ids, l:vimtex_id)

  "
  " Check if the deleted buffer was the last remaining buffer of an opened
  " latex project
  "
  if l:count <= 1
    call vimtex#state#cleanup(l:vimtex_id)
  endif
endfunction

" }}}1


" {{{1 Initialize module

let s:modules = map(
      \ glob(fnamemodify(expand('<sfile>'), ':r') . '/*.vim', 0, 1),
      \ 'fnamemodify(v:val, '':t:r'')')

" }}}1

" vim: fdm=marker sw=2
