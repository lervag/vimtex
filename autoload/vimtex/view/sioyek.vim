" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#sioyek#new() abort " {{{1
  return s:viewer.init()
endfunction

" }}}1


let s:viewer = vimtex#view#_template#new({
      \ 'name': 'sioyek',
      \})

function! s:viewer._check() dict abort " {{{1
  " Check if sioyek is executable
  if !executable(g:vimtex_view_sioyek_exe)
    call vimtex#log#error('sioyek is not executable!')
    return v:false
  endif

  return v:true
endfunction

" }}}1
function! s:viewer._start(outfile) dict abort " {{{1
  " Update file path for Windows+cygwin
  let l:file = executable('cygpath')
        \ ? join(vimtex#jobs#capture('cygpath -aw "' . a:outfile . '"'), '')
        \ : a:outfile

  let l:cmd  = g:vimtex_view_sioyek_exe
        \ . ' --reuse-instance'
        \ . ' --inverse-search "' . s:inverse_search_cmd
        \ .   ' -c \"VimtexInverseSearch %2 ''%1''\""'
        \ . ' --forward-search-file ' . vimtex#util#shellescape(expand('%:p'))
        \ . ' --forward-search-line ' . line('.')
        \ . ' ' . vimtex#util#shellescape(l:file)

  " Start the view process
  " NB: Use vimtex#jobs#start to ensure it runs in the background
  let self.job = vimtex#jobs#start(l:cmd, {'detached': v:true})
  let self.cmd_start = l:cmd
endfunction

" }}}1


let s:inverse_search_cmd = get(g:, 'vimtex_callback_progpath',
      \                        get(v:, 'progpath', get(v:, 'progname', '')))
      \ . (has('nvim')
      \   ? ' --headless'
      \   : ' -T dumb --not-a-term -n')
