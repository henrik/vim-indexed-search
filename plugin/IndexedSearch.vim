" File:         IndexedSearch.vim
" Author:       Yakov Lerner <iler.ml@gmail.com>
" URL:          http://www.vim.org/scripts/script.php?script_id=1682
" Last change:  2014-10-10

" This script redefines 6 search commands (/,?,n,N,*,#). At each search,
" it shows at which match number you are, and the total number
" of matches, like this: "At Nth match out of M". This is printed
" at the bottom line at every n,N,/,?,*,# search command, automatically.
"
" To try out the plugin, source it and play with N,n,*,#,/,? commands.
" At the bottom line, you'll see wha it shows. There are no new
" commands and no new behavior to learn. Just additional info
" on the bottom line, whenever you perform search.
"
" Works on vim6 and vim7. On very large files, won't cause slowdown
" because it checks the file size.
" Don't use if you're sensitive to one of its components :-)
"
" I am posting this plugin because I find it useful.
" -----------------------------------------------------
" Checking Where You Are with respect to Search Matches
" .....................................................
" You can press \\ or \/ (that's backslach then slash),
" or :ShowSearchIndex to show at which match index you are,
" without moving cursor.
"
" If cursor is exactly on the match, the message is:
"     At Nth match of M
" If cursor is between matches, following messages are displayed:
"     Betwen matches 189-190 of 300
"     Before first match, of 300
"     After last match, of 300
" ------------------------------------------------------
" To disable colors for messages, set 'let g:indexed_search_colors=0'.
" ------------------------------------------------------
" Performance. Plugin bypasses match counting when it would take
" too much time (too many matches, too large file). You can
" tune performance limits below, after comment "Performance tuning limits"
" ------------------------------------------------------
" In case of bugs and wishes, please email: iler.ml at gmail.com
" ------------------------------------------------------

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
    " 1 or null - use colors for messages,
    " 0         - no colors
    let g:indexed_search_colors = 1
endif

if !exists('g:indexed_search_shortmess')
    " 1         - shorter messages;
    " 0 or null - longer messages.
    let g:indexed_search_shortmess = 0
endif

if !exists('g:indexed_search_numbered_only')
    " 1         - numbered only count
    " 0         - first and last spelled out
    let g:indexed_search_numbered_only = 0
endif

" Mappings
if !exists('g:indexed_search_mappings')
    let g:indexed_search_mappings = 1
endif

if !exists('g:indexed_search_dont_move')
    let g:indexed_search_dont_move = 0
endif

if !exists('g:indexed_search_unfold')
    let g:indexed_search_unfold = 1
endif

command! -bang ShowSearchIndex :call indexed_search#show_index(<bang>0)

noremap <Plug>(indexed-search-/)  :ShowSearchIndex<CR>/
noremap <Plug>(indexed-search-?)  :ShowSearchIndex<CR>?

noremap <silent> <Plug>(indexed-search-*)  *:ShowSearchIndex<CR>
noremap <silent> <Plug>(indexed-search-#)  #:ShowSearchIndex<CR>

noremap <silent> <Plug>(indexed-search-n)  n:ShowSearchIndex<CR>
noremap <silent> <Plug>(indexed-search-N)  N:ShowSearchIndex<CR>

if g:indexed_search_mappings
    nmap / <Plug>(indexed-search-/)
    nmap ? <Plug>(indexed-search-?)

    if g:indexed_search_dont_move
        " These can't be implemented using the <Plug> mappings because the
        " 'N' needs to happen after the '*' (or '#') and before the
        " :ShowSearchIndex
        nnoremap <silent>* *N:ShowSearchIndex<CR>
        nnoremap <silent># #N:ShowSearchIndex<CR>
    else
        nmap * <Plug>(indexed-search-*)
        nmap # <Plug>(indexed-search-#)
    endif

    if g:indexed_search_unfold
        nmap n <Plug>(indexed-search-n)zv
        nmap N <Plug>(indexed-search-N)zv
    else
        nmap n <Plug>(indexed-search-n)
        nmap N <Plug>(indexed-search-N)
    endif
endif


let &cpo = s:save_cpo

" Last changes
" 2006-10-20 added limitation by # of matches
" 061021 lerner fixed problem with cmap <enter> that screwed maps
" 061021 colors added
" 061022 fixed g/ when too many matches
" 061106 got message to work with check for largefile right
" 061110 addition of DelayedEcho(ScheduledEcho) fixes and simplifies things
" 061110 mapping for nN*# greately simplifified by switching to ScheduledEcho
" 061110 fixed problem with i<c-o>/pat<cr> and c/PATTERN<CR> Markus Braun
" 061110 fixed bug in / and ?, Counting moved to Delayd
" 061110 fixed bug extra line+enter prompt in [/?] by addinf redraw
" 061110 fixed overwriting builtin errmsg with ">1000 matches"
" 061111 fixed bug with gg & 'set nosol' (gg->gg0)
" 061113 fixed mysterious eschewing of @/ wfte *,#
" 061113 fixed counting of match at the very beginning of file
" 061113 added msgs "Before single match", "After single match"
" 061113 fixed bug with &ut not always restored. This could happen if
"        ScheduleEcho() was called twice in a row.
" 061114 fixed problem with **#n. Direction of the last n is incorrect (must be backward
"              but was incorrectly forward)
" 061114 fixed disappearrance of "Hit BOTTOM" native msg when file<max and numhits>max
" 061116 changed hlgroup os "At last match" from DiffChange to LineNr. Looks more natural.
" 061120 shortened text messages.
" 061120 made to work on vim6
" 061120 bugfix for vim6 (virtcol() not col())
" 061120 another bug with virtcol() vs col()
" 061120 fixed [/?] on vim6 (vim6 doesn't have getcmdtype())
" 061121 fixed mapping in <cr> with supertab.vim. Switched to [/?] mapping, removed <cr> mapping.
"        also shortened code considerably, made vim6 and vim7 work same way, removed need
"        for getcmdtype().
" 061121 fixed handling of g:indexed_search_colors (Markus Braun)


" Wishlist
" -  using high-precision timer of vim7, count number of millisec
"    to run the counters, and base auto-disabling on time it takes.
"    very complex regexes can be terribly slow even of files like 'man bash'
"    which is mere 5k lines long. Also when there are >10k matches in the file
"    set limit to 200 millisec
" - implement CursorHold bg counting to which too_slow will resort
" - even on large files, we can show "At last match", "After last match"
" - define global vars for all highlights, with defaults
