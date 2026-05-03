" =============================================================================
"  SHEOL // sheol.vim
"  Neovim colorscheme calibrated to the Tarnished Reliquary palette.
"  Drop into ~/.config/nvim/colors/sheol.vim and `:colorscheme sheol`
" =============================================================================

set background=dark
hi clear
if exists('syntax_on') | syntax reset | endif
let g:colors_name = 'sheol'
set termguicolors

" ---- Palette ----------------------------------------------------------------
let s:abyss     = '#050507'
let s:crypt     = '#0c0a10'
let s:sepulcher = '#14111a'
let s:shroud    = '#1f1a26'
let s:ash       = '#2a2530'
let s:linen     = '#6b6470'
let s:bone      = '#b8aea0'
let s:relic     = '#d4c8b0'
let s:pallor    = '#e8dfd0'
let s:tarnish   = '#4a3a1f'
let s:oxide     = '#6b5530'
let s:gilt      = '#a08240'
let s:leaf      = '#c9a651'
let s:halo      = '#e8c870'
let s:sanctus   = '#5a1a1a'
let s:viaticum  = '#2d1a3a'

" ---- Helper ------------------------------------------------------------------
function! s:hi(group, fg, bg, attr) abort
    let l:cmd = 'hi ' . a:group
    if a:fg !=# '' | let l:cmd .= ' guifg=' . a:fg | endif
    if a:bg !=# '' | let l:cmd .= ' guibg=' . a:bg | endif
    if a:attr !=# '' | let l:cmd .= ' gui=' . a:attr | endif
    execute l:cmd
endfunction

" ---- Editor UI ---------------------------------------------------------------
call s:hi('Normal',          s:bone,    s:abyss,    '')
call s:hi('NormalFloat',     s:bone,    s:crypt,    '')
call s:hi('FloatBorder',     s:gilt,    s:crypt,    '')
call s:hi('NormalNC',        s:linen,   s:abyss,    '')
call s:hi('Cursor',          s:abyss,   s:halo,     '')
call s:hi('CursorLine',      '',        s:crypt,    'NONE')
call s:hi('CursorLineNr',    s:halo,    s:crypt,    'bold')
call s:hi('LineNr',          s:tarnish, s:abyss,    '')
call s:hi('SignColumn',      s:gilt,    s:abyss,    '')
call s:hi('VertSplit',       s:ash,     s:abyss,    '')
call s:hi('WinSeparator',    s:ash,     s:abyss,    '')
call s:hi('StatusLine',      s:relic,   s:crypt,    '')
call s:hi('StatusLineNC',    s:linen,   s:crypt,    '')
call s:hi('TabLine',         s:linen,   s:crypt,    '')
call s:hi('TabLineFill',     s:linen,   s:abyss,    '')
call s:hi('TabLineSel',      s:halo,    s:abyss,    'bold')
call s:hi('Pmenu',           s:bone,    s:crypt,    '')
call s:hi('PmenuSel',        s:halo,    s:sepulcher,'bold')
call s:hi('PmenuSbar',       '',        s:ash,      '')
call s:hi('PmenuThumb',      '',        s:gilt,     '')
call s:hi('Visual',          '',        s:sepulcher,'')
call s:hi('Search',          s:abyss,   s:gilt,     '')
call s:hi('IncSearch',       s:abyss,   s:halo,     'bold')
call s:hi('CurSearch',       s:abyss,   s:halo,     'bold')
call s:hi('MatchParen',      s:halo,    s:tarnish,  'bold')
call s:hi('NonText',         s:tarnish, '',         '')
call s:hi('Whitespace',      s:tarnish, '',         '')
call s:hi('SpecialKey',      s:tarnish, '',         '')
call s:hi('Folded',          s:linen,   s:crypt,    'italic')
call s:hi('FoldColumn',      s:gilt,    s:abyss,    '')
call s:hi('ColorColumn',     '',        s:crypt,    '')
call s:hi('Conceal',         s:linen,   '',         '')
call s:hi('Directory',       s:gilt,    '',         'bold')
call s:hi('Title',           s:halo,    '',         'bold')
call s:hi('Question',        s:relic,   '',         '')
call s:hi('ModeMsg',         s:gilt,    '',         'bold')
call s:hi('MoreMsg',         s:gilt,    '',         '')
call s:hi('WildMenu',        s:halo,    s:sepulcher,'bold')

" ---- Diagnostics -------------------------------------------------------------
call s:hi('DiagnosticError', s:sanctus, '',         '')
call s:hi('DiagnosticWarn',  s:leaf,    '',         '')
call s:hi('DiagnosticInfo',  s:bone,    '',         '')
call s:hi('DiagnosticHint',  s:linen,   '',         '')
call s:hi('Error',           s:sanctus, '',         'bold')
call s:hi('ErrorMsg',        s:sanctus, '',         'bold')
call s:hi('WarningMsg',      s:leaf,    '',         '')

" ---- Diff --------------------------------------------------------------------
call s:hi('DiffAdd',         s:oxide,   s:crypt,    '')
call s:hi('DiffChange',      s:gilt,    s:crypt,    '')
call s:hi('DiffDelete',      s:sanctus, s:crypt,    '')
call s:hi('DiffText',        s:halo,    s:sepulcher,'bold')

" ---- Syntax (legacy + treesitter shared) ------------------------------------
call s:hi('Comment',         s:tarnish, '',         'italic')
call s:hi('String',          s:bone,    '',         '')
call s:hi('Character',       s:bone,    '',         '')
call s:hi('Number',          s:leaf,    '',         '')
call s:hi('Float',           s:leaf,    '',         '')
call s:hi('Boolean',         s:leaf,    '',         'bold')
call s:hi('Constant',        s:leaf,    '',         '')

call s:hi('Identifier',      s:relic,   '',         '')
call s:hi('Function',        s:halo,    '',         '')

call s:hi('Statement',       s:gilt,    '',         'bold')
call s:hi('Conditional',     s:gilt,    '',         'bold')
call s:hi('Repeat',          s:gilt,    '',         'bold')
call s:hi('Label',           s:gilt,    '',         '')
call s:hi('Operator',        s:oxide,   '',         '')
call s:hi('Keyword',         s:gilt,    '',         'bold')
call s:hi('Exception',       s:sanctus, '',         'bold')

call s:hi('PreProc',         s:oxide,   '',         '')
call s:hi('Include',         s:oxide,   '',         'italic')
call s:hi('Define',          s:oxide,   '',         '')
call s:hi('Macro',           s:oxide,   '',         '')
call s:hi('PreCondit',       s:oxide,   '',         '')

call s:hi('Type',            s:leaf,    '',         '')
call s:hi('StorageClass',    s:gilt,    '',         'bold')
call s:hi('Structure',       s:leaf,    '',         '')
call s:hi('Typedef',         s:leaf,    '',         '')

call s:hi('Special',         s:halo,    '',         '')
call s:hi('SpecialChar',     s:halo,    '',         '')
call s:hi('Tag',             s:gilt,    '',         '')
call s:hi('Delimiter',       s:linen,   '',         '')
call s:hi('SpecialComment',  s:gilt,    '',         'italic')
call s:hi('Debug',           s:sanctus, '',         '')
call s:hi('Underlined',      s:gilt,    '',         'underline')
call s:hi('Ignore',          s:linen,   '',         '')
call s:hi('Todo',            s:halo,    s:tarnish,  'bold')

" ---- Treesitter --------------------------------------------------------------
call s:hi('@variable',           s:bone,    '',     '')
call s:hi('@variable.builtin',   s:leaf,    '',     'italic')
call s:hi('@parameter',          s:relic,   '',     'italic')
call s:hi('@field',              s:relic,   '',     '')
call s:hi('@property',           s:relic,   '',     '')
call s:hi('@function',           s:halo,    '',     '')
call s:hi('@function.builtin',   s:halo,    '',     'italic')
call s:hi('@function.macro',     s:oxide,   '',     '')
call s:hi('@method',             s:halo,    '',     '')
call s:hi('@constructor',        s:leaf,    '',     'bold')
call s:hi('@keyword',            s:gilt,    '',     'bold')
call s:hi('@keyword.return',     s:sanctus, '',     'bold')
call s:hi('@keyword.operator',   s:gilt,    '',     'bold')
call s:hi('@conditional',        s:gilt,    '',     'bold')
call s:hi('@repeat',             s:gilt,    '',     'bold')
call s:hi('@string',             s:bone,    '',     '')
call s:hi('@string.escape',      s:halo,    '',     '')
call s:hi('@string.special',     s:halo,    '',     '')
call s:hi('@number',             s:leaf,    '',     '')
call s:hi('@boolean',            s:leaf,    '',     'bold')
call s:hi('@type',               s:leaf,    '',     '')
call s:hi('@type.builtin',       s:leaf,    '',     'italic')
call s:hi('@namespace',          s:oxide,   '',     '')
call s:hi('@punctuation',        s:linen,   '',     '')
call s:hi('@punctuation.bracket',s:linen,   '',     '')
call s:hi('@punctuation.delimiter', s:linen,'',     '')
call s:hi('@operator',           s:oxide,   '',     '')
call s:hi('@comment',            s:tarnish, '',     'italic')
call s:hi('@tag',                s:gilt,    '',     '')
call s:hi('@tag.attribute',      s:relic,   '',     '')
call s:hi('@tag.delimiter',      s:linen,   '',     '')
call s:hi('@text.title',         s:halo,    '',     'bold')
call s:hi('@text.literal',       s:bone,    s:crypt,'')
call s:hi('@text.uri',           s:gilt,    '',     'underline')
call s:hi('@text.todo',          s:halo,    s:tarnish, 'bold')

" ---- LSP (modern semantic tokens) -------------------------------------------
hi! link @lsp.type.namespace      @namespace
hi! link @lsp.type.type           @type
hi! link @lsp.type.class          @type
hi! link @lsp.type.enum           @type
hi! link @lsp.type.interface      @type
hi! link @lsp.type.struct         @type
hi! link @lsp.type.parameter      @parameter
hi! link @lsp.type.variable       @variable
hi! link @lsp.type.property       @property
hi! link @lsp.type.enumMember     Constant
hi! link @lsp.type.function       @function
hi! link @lsp.type.method         @method
hi! link @lsp.type.macro          @function.macro
hi! link @lsp.type.decorator      @function

" ---- Plugins (telescope, nvim-tree, indent-blankline) -----------------------
call s:hi('TelescopeNormal',          s:bone,  s:crypt, '')
call s:hi('TelescopeBorder',          s:gilt,  s:crypt, '')
call s:hi('TelescopeTitle',           s:halo,  s:crypt, 'bold')
call s:hi('TelescopePromptNormal',    s:relic, s:sepulcher, '')
call s:hi('TelescopePromptBorder',    s:gilt,  s:sepulcher, '')
call s:hi('TelescopeSelection',       s:halo,  s:sepulcher, 'bold')
call s:hi('TelescopeMatching',        s:halo,  '',     'bold')

call s:hi('NvimTreeNormal',           s:bone,  s:abyss, '')
call s:hi('NvimTreeFolderName',       s:gilt,  '',      '')
call s:hi('NvimTreeOpenedFolderName', s:halo,  '',      'bold')
call s:hi('NvimTreeRootFolder',       s:halo,  '',      'bold')
call s:hi('NvimTreeGitDirty',         s:sanctus, '',    '')
call s:hi('NvimTreeGitNew',           s:oxide, '',      '')

call s:hi('IndentBlanklineChar',      s:ash,   '',      '')
call s:hi('IblIndent',                s:ash,   '',      '')
call s:hi('IblScope',                 s:tarnish, '',    '')

" ---- Git (gitsigns, fugitive) -----------------------------------------------
call s:hi('GitSignsAdd',     s:oxide,   '', '')
call s:hi('GitSignsChange',  s:gilt,    '', '')
call s:hi('GitSignsDelete',  s:sanctus, '', '')
call s:hi('gitcommitSummary', s:relic,  '', 'bold')
call s:hi('diffAdded',       s:oxide,   '', '')
call s:hi('diffRemoved',     s:sanctus, '', '')
call s:hi('diffChanged',     s:gilt,    '', '')
