"=============================================================================
" File:         autoload/lh/dict.vim                              {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/lh-vim-lib>
" Version:      3.3.20.
let s:k_version = '3320'
" Created:      26th Nov 2015
" Last Update:  02nd Dec 2015
"------------------------------------------------------------------------
" Description:
"       |Dict| helper functions
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#dict#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#dict#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#dict#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Dictionary modification {{{2
" Function: lh#dict#add_new(dst, src) {{{3
function! lh#dict#add_new(dst, src) abort
  return extend(a:dst, a:src, 'keep')
  " for [k,v] in items(a:src)
    " if !has_key(a:dst, k)
      " let a:dst[k] = v
    " endif
  " endfor
  " return a:dst
endfunction

" # Dictionary in read-only {{{2

" Function: lh#dict#key(one_key_dict) {{{3
function! lh#dict#key(one_key_dict) abort
  let it = items(a:one_key_dict)
  if len(it) != 1
    throw "[expect] The dictionary hasn't one key exactly (".string(a:one_key_dict).")"
  endif
  return it[0]
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
