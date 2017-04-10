" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#skim#new() " {{{1
  " Check if the viewer is executable
  if !executable(s:skim.path)
    call vimtex#echo#warning('Skim is not executable!')
    call vimtex#echo#echo('- vimtex viewer will not work!')
    call vimtex#echo#wait()
    return {}
  endif

  return vimtex#view#common#apply_common_template(deepcopy(s:skim))
endfunction

" }}}1

let s:skim = {
      \ 'name' : 'Skim',
      \ 'path' : '/Applications/Skim.app/Contents/SharedSupport/displayline',
      \}

function! s:skim.view(file) dict " {{{1
  if empty(a:file)
    let outfile = self.out()

    " Only copy files if they don't exist
    if g:vimtex_view_use_temp_files
          \ && vimtex#view#common#not_readable(outfile)
      call self.copy_files()
    endif
  else
    let outfile = a:file
  endif
  if vimtex#view#common#not_readable(outfile) | return | endif

  let l:cmd = join([
        \ self.path,
        \ '-r',
        \ '-b',
        \ line('.'),
        \ vimtex#util#shellescape(outfile),
        \ vimtex#util#shellescape(expand('%:p'))
        \])

  let self.process = vimtex#process#start(l:cmd)

  if has_key(self, 'hook_view')
    call self.hook_view()
  endif
endfunction

" }}}1
function! s:skim.compiler_callback(status) dict " {{{1
  if !a:status | return | endif

  if g:vimtex_view_use_temp_files
    call self.copy_files()
  endif

  let l:cmd = join([
        \ self.path,
        \ '-r',
        \ '-b' . (!empty(system('pgrep Skim')) ? ' -g' : ''),
        \ line('.'),
        \ vimtex#util#shellescape(self.out()),
        \ vimtex#util#shellescape(expand('%:p'))
        \])

  if has('nvim')
    let self.process = jobstart(l:cmd)
  elseif has('job')
    let self.process = job_start(l:cmd)
  else
    let self.process = vimtex#process#start(join(l:cmd))
  endif
endfunction

" }}}1
function! s:skim.latexmk_append_argument() dict " {{{1
  if g:vimtex_view_use_temp_files
    return ' -view=none'
  else
    return vimtex#compiler#latexmk#wrap_option('pdf_previewer', self.path)
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
