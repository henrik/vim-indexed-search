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

function! s:colored_echo(msg, hl)
    execute "echohl ". a:hl
    redraw
    echo a:msg
    echohl None
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

function! s:index_message(total, exact, after, force)
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
    elseif a:exact == 1 && a:total == 1 && g:indexed_search_numbered_only != 1
        " hl remains default
        let msg = "Single match"
    elseif a:exact == 1 && g:indexed_search_numbered_only != 1
        let hl = "Search"
        let msg = "First of ". shortmatch
    elseif a:exact == a:total && g:indexed_search_numbered_only != 1
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

function! s:current_index(force)
    if @/ == '' || (!a:force && line('$') >= g:indexed_search_max_lines)
        return ['', '']
    endif

    let [total, exact, after] = s:search(@/, a:force)
    return s:index_message(total, exact, after, a:force)
endfunction

function! s:echo_index(force)
    let [hl, msg] = s:current_index(a:force)
    if msg != ''
        call s:colored_echo(msg, (g:indexed_search_colors ? hl : "None"))
    endif
endfunction


function! indexed_search#show_index(force)
    let s:save_ut = &ut
    let s:force = a:force

    if &ut > 200 | let &ut = 200 | endif
    augroup IndexedSearchAutoCmds
        autocmd CursorHold *
            \ let &ut = s:save_ut         |
            \ call s:echo_index(s:force)  |
            \ autocmd! IndexedSearchAutoCmds
    augroup END
endfunction
