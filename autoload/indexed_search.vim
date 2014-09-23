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
    let hl = "Directory"
    let msg = ""

    if !a:force && a:total > g:indexed_search_max_hits
        let matches = "> ". g:indexed_search_max_hits
        if a:exact < 0
            return [hl, matches ." matches"]
        endif
    else
        let matches = a:total
    endif
    let shortmatch = matches . (g:indexed_search_shortmess ? "" : " matches")

    if a:total == 0
        let hl = "Error"
        let msg = "No matches"
    elseif a:exact == 1 && a:total == 1
        " hl remains default
        let msg = "Single match"
    elseif a:exact == 1
        let hl = "Search"
        let msg = "First of ". shortmatch
    elseif a:exact == a:total
        let hl = "LineNr"
        let msg = "Last of ". shortmatch
    elseif a:exact >= 0
        let msg = (g:indexed_search_shortmess ? "" : "Match ")
                 \. a:exact ." of ". matches
    elseif a:after == 0
        let hl = "MoreMsg"
        let msg = "Before first match, of ". shortmatch
        if a:total == 1 | let msg = "Before single match" | endif
    elseif a:after == a:total
        let hl = "WarningMsg"
        let msg = "After last match of ". shortmatch
        if a:total == 1 | let msg = "After single match" | endif
    else
        let msg = "Between matches ". a:after ."-". (a:after+1) ." of ". matches
    endif

    return [hl, msg."  /".@/."/"]
endfunction

function! s:CountCurrentSearchIndex(force, cmd)
    if @/ == '' || (!a:force && line('$') >= g:indexed_search_max_lines)
        let s:Msg = ''
        let s:Highlight = ''
        return ""
    endif

    let [total, exact, after] = s:search(@/, a:force)
    let [s:Highlight, s:Msg] s:index_message(total, exact, after)
    return ""
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
