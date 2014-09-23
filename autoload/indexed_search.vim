let s:ScheduledEcho = ''
let s:DelaySearchIndex = 0
let g:IndSearchUT = &ut


function! s:milli_since(start)
    " Use it like this:
    "   :let s = reltime()
    "   :sleep 100m
    "   :let time_passed = s:milli_since(s)
    " This would result in a Float which represents the milliseconds passed.

    let rel_time = reltimestr(reltime(a:start))
    let [sec, milli] = map(split(rel_time, '\ze\.'), 'str2float(v:val)')
    return (sec + milli) * 1000
endfunction


function! s:ScheduleEcho(msg,highlight)

    "if &ut > 50 | let g:IndSearchUT=&ut | let &ut=50 | endif
    "if &ut > 100 | let g:IndSearchUT=&ut | let &ut=100 | endif
    if &ut > 200 | let g:IndSearchUT=&ut | let &ut=200 | endif
    " 061116 &ut is sometimes not restored and drops permanently to 50. But how ?

    let s:ScheduledEcho      = a:msg
    let use_colors = !exists('g:indexed_search_colors') || g:indexed_search_colors
    let s:ScheduledHighlight = ( use_colors ? a:highlight : "None" )

    aug IndSearchEcho

    au CursorHold *
      \ exe 'set ut='.g:IndSearchUT |
      \ if s:DelaySearchIndex | call indexed_search#ShowCurrentSearchIndex(0,'') |
      \    let s:ScheduledEcho = s:Msg | let s:ScheduledHighlight = s:Highlight |
      \    let s:DelaySearchIndex = 0 | endif |
      \ if s:ScheduledEcho != ""
      \ | exe "echohl ".s:ScheduledHighlight | echo s:ScheduledEcho | echohl None
      \ | let s:ScheduledEcho='' |
      \ endif |
      \ aug IndSearchEcho | exe 'au!' | aug END | aug! IndSearchEcho
    " how about moving contents of this au into function

    aug END
endfunction

function! s:search(query, force)
    let winview = winsaveview()
    let line = winview["lnum"]
    let col = winview["col"] + 1
    let [total, exact, after] = [0, -1, 0]

    call cursor(1, 1)
    let [matchline, matchcol] = searchpos(a:query, 'Wc')
    while matchline && (total <= g:indexed_search_max_hits || a:force)
        let total += 1
        if (matchline == line && matchcol == col)
            let exact = total
        elseif matchline < line || (matchline == line && matchcol < col)
            let after = total
        endif
        let [matchline, matchcol] = searchpos(a:query, 'W')
    endwhile

    call winrestview(winview)
    return [total, exact, after]
endfunction

function! s:index_message(total, a:exact, a:after, force)
    if !a:force && a:total > g:search_index_maxhit
        if a:exact >= 0
            let too_slow=1 "  if too_slow, we'll want to switch the work over to CursorHold
            let a:total=">".(a:total-1)
        else
            let s:Msg = ">".(a:total-1)." matches"
            if v:errmsg != ""
                let s:Msg = ""  " avoid overwriting builtin errmsg with our ">1000 matches"
            endif
            return ""
        endif
    endif

    "           Messages Summary
    "
    " Short Message            Long Message
    " -------------------------------------------
    " %d of %d matches         Match %d of %d
    " Last of %d matches       <-same
    " First of %d matches      <-same
    " No matchess              <-same
    " -------------------------------------------
    let s:Highlight = "Directory"
    if a:total == "0"
        let s:Highlight = "Error"
        let prefix = "No matches "
    elseif a:exact == 1 && a:total==1
        " s:Highlight remains default
        let prefix = "Single match"
    elseif a:exact == 1
        let s:Highlight = "Search"
        let prefix = "First of " . a:total . " matches "
    elseif a:exact == a:total
        let s:Highlight = "LineNr"
        let prefix = "Last of " . a:total . " matches "
    elseif a:exact >= 0
        if exists('g:indexed_search_shortmess') && g:indexed_search_shortmess
            let prefix = a:exact." of " . a:total . " matches "
        else
            let prefix = "Match ".a:exact." of " . a:total
        endif
    elseif a:after == 0
        let s:Highlight = "MoreMsg"
        let prefix = "Before first match, of ".a:total." matches "
        if a:total == 1
            let prefix = "Before single match"
        endif
    elseif a:after == a:total
        let s:Highlight = "WarningMsg"
        let prefix = "a:after last match of ".a:total." matches "
        if a:total == 1
            let prefix = "a:after single match"
        endif
    else
        let prefix = "Between matches ".a:after."-".(a:after+1)." of ".a:total
    endif
    let s:Msg = prefix . "  /".@/ . "/"
    return ""
endfunction

function! s:CountCurrentSearchIndex(force, cmd)
" sets globals -> s:Msg , s:Highlight
    let s:Msg = '' | let s:Highlight = ''
    let builtin_errmsg = ""

    " echo "" | " make sure old msg is erased
    if a:cmd == '!'
        " if cmd is '!', we do not execute any command but report
        " last errmsg
        if v:errmsg != ""
            echohl Error
            echomsg v:errmsg
            echohl None
        endif
    elseif a:cmd != ''
        let v:errmsg = ""

        silent! exe "norm! ".a:cmd

        if v:errmsg != ""
            echohl Error
            echomsg v:errmsg
            echohl None
        endif

        if line('$') >= g:search_index_max
            " for large files, preserve original error messages and add nothing
            return ""
        endif
    else
    endif

    if !a:force && line('$') >= g:search_index_max
        let too_slow=1
        " when too_slow, we'll want to switch the work over to CursorHold
        return ""
    endif
    if @/ == '' | return "" | endif
    let [num, exact, after] = s:search(@/, a:force)
    return s:index_message(num, exact, after)
endfunction


function! indexed_search#DelaySearchIndex(force,cmd)
    let s:DelaySearchIndex = 1
    call s:ScheduleEcho('','')
endfunction

function! indexed_search#ShowCurrentSearchIndex(force, cmd)
    " NB: function saves and restores @/ and direction
    " this used to cause me many troubles

    call s:CountCurrentSearchIndex(a:force, a:cmd) " -> s:Msg, s:Highlight

    if s:Msg != ""
        call s:ScheduleEcho(s:Msg, s:Highlight )
    endif
endfunction
