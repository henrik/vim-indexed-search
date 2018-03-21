function! s:echohl(hl, msg)
    exec 'echohl' a:hl
    echo a:msg
    echohl None
endfunction

function! s:old_search(force)
    let winview = winsaveview()
    let line = winview["lnum"]
    let col = winview["col"] + 1
    let [index, total, is_on_match, first_match_lnum, last_match_lnum] = [0, 0, 0, 0, 0]

    call cursor(1, 1)
    let [matchline, matchcol] = searchpos(@/, 'Wc')
    let first_match_lnum = matchline
    while matchline && (total <= g:indexed_search_max_hits || a:force)
        let total += 1
        let last_match_lnum = matchline
        if matchline < line || (matchline == line && matchcol <= col)
            let index = total
            let is_on_match = matchline == line && matchcol == col
        endif
        let [matchline, matchcol] = searchpos(@/, 'W')
    endwhile
    let out_of_time = (!a:force && total > g:indexed_search_max_hits)
                \ + (!a:force && index > g:indexed_search_max_hits)

    call winrestview(winview)
    return [index, total, is_on_match, out_of_time, first_match_lnum, last_match_lnum]
endfunction

function! s:search(force)
    let [before, after, is_on_match, first_match_lnum, last_match_lnum] = [0, 0, 1, 0, 0]

    let now = reltime()
    let winview = winsaveview()
    let [save_ws, save_fen] = [&wrapscan, &foldenable]
    set nowrapscan nofoldenable

    " If we're at the last line and the file contains no EOL there,
    " `line2byte()` seems (to me) to give a wrong result.
    let eolbug = line('.') == line('$') && !&eol && (&bin || !&fixeol)

    " We need to find out whether the cursor is currently on a match or not
    " since that'll affect our numbering.  Naturally, there's no easy way to
    " get such information.  The hard way is to wiggle the cursor a bit and
    " try to search back and check if we ended up where we started.  There are
    " two edge cases though.
    let curpos = getpos('.')
    if line2byte(line('$') + 1) <= 3
        " The buffer is empty or has only one character.
        " In this case, we can't wiggle the cursor, so we just search and
        " check for the 'E486 Pattern not found' error.
        set wrapscan
        try
            silent keepjumps normal! n
        catch /^Vim[^)]\+):E486\D/
            let is_on_match = 0
        endtry
        set nowrapscan
    elseif line2byte('.') + col('.') - 1 <= 1
        " We're at the very start of the buffer.
        " We move the cursor forwards.
        silent! keepjumps goto 2
        silent! exec 'keepjumps normal!' (v:searchforward ? 'N' : 'n')
    else
        " In every other case, we move the cursor backwards.  This works even
        " if we're at the very edge of the buffer which is nice because I
        " couldn't find any surefire way to check for that.
        silent! exec 'keepjumps goto' (line2byte('.') + col('.') - (eolbug ? 0 : 2))
        silent! exec 'keepjumps normal!' (v:searchforward ? 'n' : 'N')
    endif
    if getpos('.') != curpos | let is_on_match = 0 | endif
    call winrestview(winview)

    " This is the algorithm itself; we first count all the matches before the
    " cursor and then all the ones after it.  To count these, we first try
    " moving in tens; running '10n' is (mostly) the same as running 'n' 10
    " times but it's faster since it runs in C.  If however there are only,
    " say, 9 matches, Vim will internally run 'n' 9 times before announcing
    " that the 10th found no match but with no way to see how many matched;
    " other than counting them one-by-one.  While this wastes some searches as
    " a whole it ends up being far faster than doing it all one-by-one.
    try
        while before <= g:indexed_search_max_hits || a:force
            " if reltimefloat(reltime(now)) > 0.1 | break | endif
            try
                silent keepjumps normal! 10N
                let before += 10
            catch /^Vim[^)]\+):E38[45]\D/
                try
                    silent keepjumps normal! N
                    let before += 1
                catch /^Vim[^)]\+):E38[45]\D/
                    let first_match_lnum = line('.')
                    break
                endtry
            endtry
        endwhile
        call winrestview(winview)
        while before + after <= g:indexed_search_max_hits || a:force
            " if reltimefloat(reltime(now)) > 0.1 | break | endif
            try
                silent keepjumps normal! 10n
                let after += 10
            catch /^Vim[^)]\+):E38[45]\D/
                try
                    silent keepjumps normal! n
                    let after += 1
                catch /^Vim[^)]\+):E38[45]\D/
                    let last_match_lnum = line('.')
                    break
                endtry
            endtry
        endwhile
    finally
        let [&wrapscan, &foldenable] = [save_ws, save_fen]
        call winrestview(winview)
    endtry
    if !v:searchforward
        let [after, before] = [before, after]
        let [first_match_lnum, last_match_lnum] = [last_match_lnum, first_match_lnum]
    end

    let out_of_time = (!a:force && before > g:indexed_search_max_hits)
                \ + (!a:force && after + before > g:indexed_search_max_hits)

    let index = before + is_on_match
    let total = before + after + is_on_match
    return [index, total, is_on_match, out_of_time, first_match_lnum, last_match_lnum]
endfunction

function! s:index_message(index, total, is_on_match, out_of_time, first_match_lnum, last_match_lnum)
    let hl = 'Directory'
    let msg = ''

    let matches = a:total
    if a:out_of_time
        let matches = '> '. a:total
        if !a:is_on_match || a:out_of_time > 1
            return [hl, matches .' matches']
        endif
    endif

    let line_info = ""
    if g:indexed_search_line_info
        let line_info = ' (FM:'. a:first_match_lnum .', LM:'. a:last_match_lnum .')'
    endif
    let shortmatch = matches . line_info . (g:indexed_search_shortmess ? '' : ' matches')

    if a:total == 0
        let hl = 'Error'
        let msg = 'No matches'

    elseif !a:is_on_match && a:index == 0
        let hl = 'WarningMsg'
        let msg = 'Before first match, of '. shortmatch
        if a:total == 1 | let msg = 'Before single match' | endif
    elseif !a:is_on_match && a:index == a:total
        let hl = 'WarningMsg'
        let msg = 'After last match of '. shortmatch
        if a:total == 1 | let msg = 'After single match' | endif
    elseif !a:is_on_match
        " hl remains default
        let msg = 'Between matches '. a:index .'-'. (a:index+1) .' of '. matches . line_info

    elseif !g:indexed_search_numbered_only && a:index == 1 && a:total == 1
        let hl = 'Search'
        let msg = 'Single match'
    elseif !g:indexed_search_numbered_only && a:index == 1
        let hl = 'Search'
        let msg = 'First of '. shortmatch
    elseif !g:indexed_search_numbered_only && a:index == a:total
        let hl = 'LineNr'
        let msg = 'Last of '. shortmatch
    else
        " hl remains default
        let msg = (g:indexed_search_shortmess ? '' : 'Match '). a:index .' of '. matches . line_info
    endif

    return [hl, msg.'  /'.@/.'/']
endfunction


function! indexed_search#show_index(force)
    if @/ == '' || (!a:force && line('$') >= g:indexed_search_max_lines)
        return
    endif

    let results = s:search(a:force)
    let [hl, msg] = call('s:index_message', results)
    call s:echohl(g:indexed_search_colors ? hl : 'None', msg)
endfunction
