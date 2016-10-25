" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#general#new() " {{{1
  "
  " Set default options
  "
  call vimtex#util#set_default_os_specific('g:vimtex_view_general_viewer',
        \ {
        \   'linux' : 'xdg-open',
        \   'mac'   : 'open',
        \ })
  call vimtex#util#set_default('g:vimtex_view_general_options', '@pdf')
  call vimtex#util#set_default('g:vimtex_view_general_options_latexmk', '')

  "
  " Check if the viewer is executable
  "
  if !executable(g:vimtex_view_general_viewer)
    call vimtex#echo#warning('viewer "'
          \ . g:vimtex_view_general_viewer . '" is not executable!')
    call vimtex#echo#echo('- Please see :h g:vimtex_view_general_viewer')
    call vimtex#echo#wait()
    return {}
  endif

  "
  " Start from standard template
  "
  let l:viewer = vimtex#view#common#use_temp_files_p(deepcopy(s:general))

  "
  " Add callback hook
  "
  if exists('g:vimtex_view_general_callback')
    let l:viewer.latexmk_callback = function(g:vimtex_view_general_callback)
  endif

  return l:viewer
endfunction

" }}}1

let s:general = {}

function! s:general.view(file) dict " {{{1
  if empty(a:file)
    let outfile = self.out

    " Only copy files if they don't exist
    if g:vimtex_view_use_temp_files
          \ && vimtex#view#common#not_readable(outfile)
      call self.copy_files()
    endif
  else
    let outfile = a:file
  endif
  if vimtex#view#common#not_readable(outfile) | return | endif

  " Parse options
  let opts = g:vimtex_view_general_options
  let opts = substitute(opts, '@line', line('.'), 'g')
  let opts = substitute(opts, '@col', col('.'), 'g')
  let opts = substitute(opts, '@tex',
        \ vimtex#util#shellescape(expand('%:p')), 'g')
  let opts = substitute(opts, '@pdf', vimtex#util#shellescape(outfile), 'g')

  " Construct the command
  let exe = {}
  let exe.cmd = g:vimtex_view_general_viewer . ' ' . opts
  call vimtex#util#execute(exe)
  let self.cmd_view = exe.cmd

  if has_key(self, 'hook_view')
    call self.hook_view()
  endif
endfunction

" }}}1
function! s:general.latexmk_append_argument() dict " {{{1
  if g:vimtex_view_use_temp_files
    return ' -view=none'
  else
    let l:option = g:vimtex_view_general_viewer
    if !empty(g:vimtex_view_general_options_latexmk)
      let l:option .= ' '
      let l:option .= substitute(g:vimtex_view_general_options_latexmk,
            \                    '@line', line('.'), 'g')
    endif
    return vimtex#latexmk#add_option('pdf_previewer', l:option)
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
