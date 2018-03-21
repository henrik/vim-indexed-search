# IndexedSearch.vim

Requires vim7.4

Originally by [Yakov Lerner](http://www.vim.org/account/profile.php?user_id=2342) and put on GitHub by [Henrik Nyh](https://github.com/henrik) to have it there in a [Pathogen](http://www.vim.org/scripts/script.php?script_id=2332)-friendly format.  Majorly rewritten by [Otto Modinos](https://github.com/otommod).

[See the original plugin page at vim.org.](http://www.vim.org/scripts/script.php?script_id=1682)

```
This plugin redefines 6 search commands (/,?,n,N,*,#). At every 
search command, it automatically prints>
       "At match #N out of M matches". 
>
-- the total number of matches (M) and the number(index) of current 
match (N). This helps to get oriented when searching forward and 
backward. 

There are no new commands and no new behavior to learn. 
Just watch the bottom line when you do /,?,n,N,*,#. 
```

[See full help file.](https://github.com/henrik/vim-indexed-search/blob/master/doc/indexed-search.txt)

## Alternatives

Is this plugin too slow for you?  Do you want more (or less) features?  Here're some other plugins that do (or can do) the same thing:

  * [google/vim-searchindex](https://github.com/google/vim-searchindex); very fast and unobtrusive
  * [osyo-manga/vim-anzu](https://github.com/osyo-manga/vim-anzu); tons of features
  * [romainl/vim-cool](https://github.com/romainl/vim-cool); initally just for disabling the highlighting of matches after a seach, now also show an index
  * [lacygoill/vim-search](https://github.com/lacygoill/vim-search); meant for [personal use](https://github.com/junegunn/vim-slash/issues/7) but can be used by everyone
