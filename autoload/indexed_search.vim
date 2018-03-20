function! s:echohl(hl, msg)
    exec 'echohl' a:hl
    echo a:msg
    echohl None
endfunction

function! s:search(force)
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

    call winrestview(winview)
    return [index, total, is_on_match, first_match_lnum, last_match_lnum]
endfunction

function! s:index_message(index, total, is_on_match, first_match_lnum, last_match_lnum, force)
    let hl = 'Directory'
    let msg = ''

    let matches = a:total
    if !a:force && a:total > g:indexed_search_max_hits
        let matches = '> '. g:indexed_search_max_hits
        if !a:is_on_match
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

function! s:echo_index(force)
    if @/ == '' || (!a:force && line('$') >= g:indexed_search_max_lines)
        return
    endif

    let results = s:search(a:force)
    let [hl, msg] = call('s:index_message', results + [a:force])
    call s:echohl(g:indexed_search_colors ? hl : 'None', msg)
endfunction


function! indexed_search#show_index(force)
    if exists('s:save_ut') | return | endif
    let s:save_ut = &ut

    " autocmds run in the context of the script.  So this function's arguments
    " aren't in scope, we need to use script variables.
    let s:force = a:force

    let &ut = 200
    augroup indexed_search_delayed
        autocmd CursorHold *
            \ let &ut = s:save_ut         |
            \ unlet s:save_ut             |
            \ call s:echo_index(s:force)  |
            \ autocmd! indexed_search_delayed
    augroup END
endfunction
