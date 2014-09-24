" File:         IndexedSearch.vim
" Author:       Yakov Lerner <iler.ml@gmail.com>
" URL:          http://www.vim.org/scripts/script.php?script_id=1682
" Last change:  2006-11-21
"
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


" before 061119, it worked only vim7 not on vim6 (we use winrestview())
" after  061119, works only on vim6 (we avoid winrestview on vim6)


"if version < 700 | finish | endif " we need vim7 at least. Won't work for vim6

"if &cp | echo "warning: IndexedSearch.vim need nocp" | finish | endif " we need &nocp mode

if exists("g:loaded_indexed_search")
    finish
endif
let g:loaded_indexed_search = 1

let s:save_cpo = &cpo
set cpo&vim


"  Performance tuning limits
if !exists('g:indexed_search_max_lines')
    " Max filesize (in lines) up to where current_index() works
    let g:indexed_search_max_lines = 30000
endif

if !exists("g:indexed_search_max_hits")
    let g:indexed_search_max_hits = 1000
endif

" Appearance
if !exists('g:indexed_search_colors')
    " 1 or undefined - use colors for messages,
    " 0              - no colors
    let g:indexed_search_colors = 1
endif

if !exists('g:indexed_search_shortmess')
    " 1              - shorter messages;
    " 0 or undefined - longer messages.
    let g:indexed_search_shortmess = 0
endif

" Mappings
if !exists("g:indexed_search_show_index_mappings")
    let g:indexed_search_show_index_mappings = 1
endif


command! -bang ShowSearchIndex :call indexed_search#search_index(<bang>0)

" before 061120,  I had cmapping for <cr> which was very intrusive. Didn't work
"                 with supertab iInde<c-x><c-p>(resulted in something like recursive <c-r>=
" after  061120,  I remap [/?] instead of remapping <cr>. Works in vim6, too
nnoremap /  :ShowSearchIndex<CR>
nnoremap ?  :ShowSearchIndex<CR>

" before 061114  we had op invocation inside the function but this
"                did not properly keep @/ and direction (func.return restores @/ and direction)
" after  061114  invoking op inside the function does not work because
"                @/ and direction is restored at return from function
"                We must have op invocation at the toplevel of mapping even though this
"                makes mappings longer.
nnoremap <silent>n  :silent! norm! n<CR>:ShowSearchIndex<CR>
nnoremap <silent>N  :silent! norm! N<CR>:ShowSearchIndex<CR>
nnoremap <silent>*  :silent! norm! *<CR>:ShowSearchIndex<CR>
nnoremap <silent>#  :silent! norm! #<CR>:ShowSearchIndex<CR>


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
