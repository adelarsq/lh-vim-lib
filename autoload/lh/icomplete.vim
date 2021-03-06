"=============================================================================
" File:         autoload/lh/icomplete.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/lh-vim-lib/License.md>
" Version:	3.5.0
let s:version = '3.5.0'
" Created:      03rd Jan 2011
" Last Update:  16th Nov 2015
"------------------------------------------------------------------------
" Description:
"       Helpers functions to build |ins-completion-menu|
"
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/autoload/lh
"       Requires Vim7+
" History:
"       v3.5.0 : Smarter completion function added
"       v3.3.10: Fix conflict with lh-brackets
"       v3.0.0 : GPLv3
" 	v2.2.4 : first version
" TODO:
" 	- We are not able to detect the end of the completion mode. As a
" 	consequence we can't prevent c/for<space> to trigger an abbreviation
" 	instead of the right template file.
" 	In an ideal world, there would exist an event post |complete()|
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#icomplete#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = 0
if !exists('s:logger')
  let s:logger = lh#log#none()
endif
function! lh#icomplete#verbose(...)
  if a:0 > 0
    let s:verbose = a:1
    let s:logger = lh#log#new('vert', 'loc')
  else
    let s:logger = lh#log#none()
  endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#icomplete#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#icomplete#run(startcol, matches, Hook) {{{2
function! lh#icomplete#run(startcol, matches, Hook)
  call lh#icomplete#_register_hook(a:Hook)
  call complete(a:startcol, a:matches)
  return ''
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#icomplete#_clear_key_bindings() {{{2
function! lh#icomplete#_clear_key_bindings()
  iunmap <buffer> <cr>
  iunmap <buffer> <c-y>
  iunmap <buffer> <esc>
  " iunmap <space>
  " iunmap <tab>
endfunction

" Function: lh#icomplete#_restore_key_bindings() {{{2
function! lh#icomplete#_restore_key_bindings(previous_mappings)
  call s:Verbose('Restore keybindings after completion')
  if has_key(a:previous_mappings, 'cr') && has_key(a:previous_mappings.cr, 'buffer') && a:previous_mappings.cr.buffer
    let cmd = lh#mapping#define(a:previous_mappings.cr)
  else
    iunmap <buffer> <cr>
  endif
  if has_key(a:previous_mappings, 'c_y') && has_key(a:previous_mappings.c_y, 'buffer') && a:previous_mappings.c_y.buffer
    let cmd = lh#mapping#define(a:previous_mappings.c_y)
  else
    iunmap <buffer> <c-y>
  endif
  if has_key(a:previous_mappings, 'esc') && has_key(a:previous_mappings.esc, 'buffer') && a:previous_mappings.esc.buffer
    let cmd = lh#mapping#define(a:previous_mappings.esc)
  else
    iunmap <buffer> <esc>
  endif
  " iunmap <space>
  " iunmap <tab>
endfunction

" Function: lh#icomplete#_register_hook(Hook) {{{2
function! lh#icomplete#_register_hook(Hook)
  " call s:Verbose('Register hook on completion')
  let old_keybindings = {}
  let old_keybindings.cr = maparg('<cr>', 'i', 0, 1)
  let old_keybindings.c_y = maparg('<c-y>', 'i', 0, 1)
  let old_keybindings.esc = maparg('<esc>', 'i', 0, 1)
  exe 'inoremap <buffer> <silent> <cr> <c-y><c-\><c-n>:call' .a:Hook . '()<cr>'
  exe 'inoremap <buffer> <silent> <c-y> <c-y><c-\><c-n>:call' .a:Hook . '()<cr>'
  " <c-o><Nop> doesn't work as expected...
  " To stay in INSERT-mode:
  " inoremap <silent> <esc> <c-e><c-o>:<cr>
  " To return into NORMAL-mode:
  inoremap <buffer> <silent> <esc> <c-e><esc>

  call lh#event#register_for_one_execution_at('InsertLeave',
	\ ':call lh#icomplete#_restore_key_bindings('.string(old_keybindings).')', 'CompleteGroup')
        " \ ':call lh#icomplete#_clear_key_bindings()', 'CompleteGroup')
endfunction

" Why is it triggered even before entering the completion ?
function! lh#icomplete#_register_hook2(Hook)
  " call lh#event#register_for_one_execution_at('InsertLeave',
  call lh#event#register_for_one_execution_at('CompleteDone',
	\ ':debug call'.a:Hook.'()<cr>', 'CompleteGroup')
        " \ ':call lh#icomplete#_clear_key_bindings()', 'CompleteGroup')
endfunction

"------------------------------------------------------------------------
" ## Smart completion {{{2
" Function: lh#icomplete#new(startcol, matches, hook) {{{3
function! lh#icomplete#new(startcol, matches, hook) abort
  silent! unlet b:complete_data
  let augroup = 'IComplete'.bufnr('%').'Done'
  let b:complete_data = lh#on#exit()
        \.restore('&completefunc')
        \.restore('&complete')
        \.restore('&omnifunc')
        \.restore('&completeopt')
        \.register('au! '.augroup)
        \.register('call self.logger.log("finalized! (".getline(".").")")')
  set complete=
  " TODO: actually, remove most options but preview
  set completeopt-=menu
  set completeopt-=longest
  set completeopt+=menuone
  let b:complete_data.startcol        = a:startcol
  let b:complete_data.all_matches     = map(copy(a:matches), 'type(v:val)==type({}) ? v:val : {"word": v:val}')
  let b:complete_data.matches         = {'words': [], 'refresh': 'always'}
  let b:complete_data.hook            = a:hook
  let b:complete_data.cursor_pos      = []
  let b:complete_data.last_content    = [line('.'), getline('.')]
  let b:complete_data.no_more_matches = 0
  let b:complete_data.logger          = s:logger.reset()

  " keybindings {{{4
  call b:complete_data
        \.restore_buffer_mapping('<cr>', 'i')
        \.restore_buffer_mapping('<c-y>', 'i')
        \.restore_buffer_mapping('<esc>', 'i')
        \.restore_buffer_mapping('<tab>', 'i')
  inoremap <buffer> <silent> <cr>  <c-y><c-\><c-n>:call b:complete_data.conclude()<cr>
  inoremap <buffer> <silent> <c-y> <c-y><c-\><c-n>:call b:complete_data.conclude()<cr>
  " Unlike usual <tab> behaviour, this time, <tab> inserts the next match
  inoremap <buffer> <silent> <tab> <down><c-y><c-\><c-n>:call b:complete_data.conclude()<cr>
  " <c-o><Nop> doesn't work as expected...
  " To stay in INSERT-mode:
  " inoremap <silent> <esc> <c-e><c-o>:<cr>
  " To return into NORMAL-mode:
  inoremap <buffer> <silent> <esc> <c-e><esc>
  " TODO: see to have <Left>, <Right>, <Home>, <End> abort

  " Group {{{4
  exe 'augroup '.augroup
    au!
    " Emulate InsertCharPost
    " au CompleteDone <buffer> call b:complete_data.logger.log("Completion done")
    au InsertLeave  <buffer> call b:complete_data.finalize()
    au CursorMovedI <buffer> call b:complete_data.cursor_moved()
  augroup END

  function! s:cursor_moved() abort dict "{{{4
    if self.no_more_matches
      call self.finalize()
      return
    endif
    if !self.has_text_changed_since_last_move()
      call s:logger.log(lh#fmt#printf("cursor %1 just moved (text hasn't changed)", string(getpos('.'))))
      return
    endif
    call s:logger.log(lh#fmt#printf('cursor moved %1 and text has changed -> relaunch completion', string(getpos('.'))))
    call feedkeys( "\<C-X>\<C-O>\<C-P>", 'n' )
  endfunction
  let b:complete_data.cursor_moved = function('s:cursor_moved')

  function! s:has_text_changed_since_last_move() abort dict "{{{4
    let l = line('.')
    let line = getline('.')
    try
      if l != self.last_content[0]  " moved vertically
        let self.no_more_matches = 1
        call s:logger.log("Vertical move => stop")
        return 0
        " We shall leave complete mode now!
      endif
      call s:logger.log(lh#fmt#printf("line was: %1, and becomes: %2; has_changed?%3", self.last_content[1], line, line != self.last_content[1]))
      return line != self.last_content[1] " text changed
    finally
      let self.last_content = [l, line]
    endtry
  endfunction
  let b:complete_data.has_text_changed_since_last_move = function('s:has_text_changed_since_last_move')

  function! s:complete(findstart, base) abort dict "{{{4
    call s:logger.log(lh#fmt#printf('findstart?%1 -> %2', a:findstart, a:base))
    if a:findstart
      if self.no_more_matches
        call s:logger.log("no more matches -> -3")
        return -3
        call self.finalize()
      endif
      if self.cursor_pos == getcurpos()
        call s:logger.log("cursor hasn't moved -> -2")
        return -2
      endif
      let self.cursor_pos = getcurpos()
      return self.startcol
    else
      return self.get_completions(a:base)
    endif
  endfunction
  let b:complete_data.complete = function('s:complete')

  function! s:get_completions(base) abort dict "{{{4
    let matching = filter(copy(self.all_matches), 'v:val.word =~ join(split(a:base, ".\\zs"), ".*")')
    let self.matches.words = matching
    call s:logger.log(lh#fmt#printf("'%1' matches: %2", a:base, string(self.matches)))
    if empty(self.matches.words)
      call s:logger.log("No more matches...")
      let self.no_more_matches = 1
    endif
    return self.matches
  endfunction
  let b:complete_data.get_completions = function('s:get_completions')

  function! s:conclude() abort dict " {{{4
    let selection = getline('.')[self.startcol : col('.')-1]
    call s:logger.log("Successful selection of <".selection.">")
    if !empty(self.hook)
      call lh#function#execute(self.hook, selection)
    endif
    " call self.hook()
    call self.finalize()
  endfunction
  let b:complete_data.conclude = function('s:conclude')

  " Register {{{4
  " call b:complete_data
        " \.restore('b:complete_data')
  " set completefunc=lh#icomplete#func
  set omnifunc=lh#icomplete#func
endfunction

" Function: lh#icomplete#new_on(pattern, matches, hook) {{{3
function! lh#icomplete#new_on(pattern, matches, hook) abort
  let l = getline('.')
  let startcol = match(l[0:col('.')-1], '\v'.a:pattern.'+$')
  if startcol == -1
    let startcol = col('.')-1
  endif
  call lh#icomplete#new(startcol, a:matches, a:hook)
endfunction

" Function: lh#icomplete#func(startcol, base) {{{3
function! lh#icomplete#func(findstart, base) abort
  return b:complete_data.complete(a:findstart, a:base)
endfunction

if 1
  let entries = [
	\ {'word': 'un', 'menu': 1, 'kind': 's', 'info': ' '},
	\ {'word': 'deux', 'menu': 2, 'kind': 's', 'info': 'takes a parameter'},
	\ {'word': 'trois', 'menu': 3, 'info': ''},
	\ {'word': 'trentre-deux', 'menu': 32, 'info': ''},
	\ 'unité'
	\ ]
  inoremap <silent> <buffer> µ <c-o>:call lh#icomplete#new_on('\w', entries, 'lh#common#warning_msg("nominal: ".v:val)')<cr><c-x><c-O><c-p>
endif

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
