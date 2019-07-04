" Author:       Yakov Lerner <iler.ml@gmail.com>
" URL:          http://www.vim.org/scripts/script.php?script_id=1682
" Last change:  2018-03-21

" This script redefines 6 search commands (/,?,n,N,*,#). At each search, it
" shows at which match number you are, and the total number of matches, like
" this: "At nth match out of N". This is printed at the bottom line at every
" n,N,/,?,*,# search command, automatically.
"
" I am posting this plugin because I find it useful.

" :ShowSearchIndex - Checking your match index
" -----------------------------------------------------
" At any time, you can use :ShowSearchIndex to show at which match index you
" are without moving the cursor.
"
" If cursor is exactly on the match, the message is:
"     At Nth match of M
" If cursor is between matches, following messages are displayed:
"     Betwen matches 189-190 of 300
"     Before first match, of 300
"     After last match, of 300

" To disable colors for messages, set g:indexed_search_colors to 0.
"
" Performance
" ------------------------------------------------------
" Plugin bypasses match counting when it would take too much time, i.e. too
" many matches or too large a file.  You can change these limits with
" g:indexed_search_max_lines and g:indexed_search_max_hits.


if exists("g:loaded_indexed_search") || &cp || v:version < 700
    finish
endif
let g:loaded_indexed_search = 1

let s:save_cpo = &cpo
set cpo&vim


" Performance tuning limits
if !exists('g:indexed_search_max_lines')
    " Max filesize (in lines) up to where the plugin works
    let g:indexed_search_max_lines = 30000
endif

if !exists("g:indexed_search_max_hits")
    " Max number of matches up to where the plugin stops counting
    let g:indexed_search_max_hits = 1000
endif

" Appearance settings
if !exists('g:indexed_search_colors')
    " Whether to use colors for messages
    let g:indexed_search_colors = 1
endif

if !exists('g:indexed_search_shortmess')
    " Make messages shorter
    let g:indexed_search_shortmess = 0
endif

if !exists('g:indexed_search_numbered_only')
    " Only show index number, no extra words
    let g:indexed_search_numbered_only = 0
endif

if !exists('g:indexed_search_line_info')
    let g:indexed_search_line_info = 0
endif

" Mappings
if !exists('g:indexed_search_mappings')
    let g:indexed_search_mappings = 1
endif

if !exists('g:indexed_search_dont_move')
    let g:indexed_search_dont_move = 0
endif

if !exists('g:indexed_search_center')
    let g:indexed_search_center = 0
endif

if !exists('g:indexed_search_n_always_searches_forward')
    let g:indexed_search_n_always_searches_forward = 0
endif


command! -bang ShowSearchIndex :call indexed_search#show_index(<bang>0)


function! s:should_unfold()
    return has('folding') && &fdo =~ 'search\|all'
endfunction

function! s:has_mapping(name)
    return !empty(maparg(a:name, mode()))
endfunction

function! s:restview()
    call winrestview(s:winview)
endfunction

function! s:star(seq)
    if g:indexed_search_dont_move
        let s:winview = winsaveview()
        return a:seq . "\<Plug>(indexed-search-restview)"
    endif
    return a:seq
endfunction

function! s:n(seq)
    if g:indexed_search_n_always_searches_forward && !v:searchforward
        return ["\<Plug>(indexed-search-n)", "\<Plug>(indexed-search-N)"][a:seq ==# 'n']
    endif
    return a:seq
endfunction

function! s:after()
    return (s:should_unfold() ? 'zv' : '')
                \ .(g:indexed_search_center ? 'zz' : '')
                \ .(s:has_mapping('<Plug>(indexed-search-custom)') ? "\<Plug>(indexed-search-custom)" : '')
                \ ."\<Plug>(indexed-search-index)"
endfunction


if g:indexed_search_mappings
    noremap  <Plug>(indexed-search-index)  <Nop>
    nnoremap <Plug>(indexed-search-index)  :ShowSearchIndex<CR>
    xnoremap <Plug>(indexed-search-index)  :<C-u>ShowSearchIndex<CR>gv

    noremap  <Plug>(indexed-search-n)  n
    noremap  <Plug>(indexed-search-N)  N

    noremap  <Plug>(indexed-search-restview)  :call <SID>restview()<CR>
    xnoremap <Plug>(indexed-search-restview)  :<C-u>call <SID>restview()<CR>gv

    map  <expr> <Plug>(indexed-search-after)  <SID>after()
    imap        <Plug>(indexed-search-after)  <Nop>

    cmap <expr> <CR> "\<CR>" . (getcmdtype() =~ '[/?]' ? "\<Plug>(indexed-search-after)" : '')
    " map  <expr> gd   'gd'    . "\<Plug>(indexed-search-after)"
    " map  <expr> gD   'gD'    . "\<Plug>(indexed-search-after)"
    map  <expr> *    <SID>star('*')  . "\<Plug>(indexed-search-after)"
    map  <expr> #    <SID>star('#')  . "\<Plug>(indexed-search-after)"
    map  <expr> g*   <SID>star('g*') . "\<Plug>(indexed-search-after)"
    map  <expr> g#   <SID>star('g#') . "\<Plug>(indexed-search-after)"
    map  <expr> n    <SID>n('n')     . "\<Plug>(indexed-search-after)"
    map  <expr> N    <SID>n('N')     . "\<Plug>(indexed-search-after)"
endif


let &cpo = s:save_cpo

" Wishlist
" -  using high-precision timer of vim7, count number of millisec
"    to run the counters, and base auto-disabling on time it takes.
"    very complex regexes can be terribly slow even of files like 'man bash'
"    which is mere 5k lines long. Also when there are >10k matches in the file
"    set limit to 200 millisec
" - implement CursorHold bg counting to which too_slow will resort
" - even on large files, we can show "At last match", "After last match"
" - define global vars for all highlights, with defaults
