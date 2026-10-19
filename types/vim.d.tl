global record vim
  type VirtualChunkProps = {string, string}
  type ValidatorProps = function(any): boolean
  type OptionValueProps = string | integer | boolean

  record HighlightProps
    fg: string | integer
    bg: string | integer
    bold: boolean
    italic: boolean
    strikethrough: boolean
    link: string
    default: boolean
  end

  record HighlightInfoProps
    fg: integer
    bg: integer
    bold: boolean
    italic: boolean
    strikethrough: boolean
  end

  record GetHighlightOptionsProps
    name: string
    link: boolean
  end

  record ExtmarkOptionsProps
    end_row: integer
    end_col: integer
    conceal: string
    conceal_lines: string
    hl_group: string
    virt_text: {VirtualChunkProps}
    virt_text_pos: string
    virt_text_win_col: integer
    virt_lines: {{VirtualChunkProps}}
    virt_lines_above: boolean
    virt_lines_leftcol: boolean
    strict: boolean
    details: boolean
  end

  type ExtmarkProps = {integer, integer, integer, ExtmarkOptionsProps}

  record AutocmdEventProps
    buf: integer
    event: string
  end

  record AutocmdOptionsProps
    group: integer
    pattern: string | {string}
    buffer: integer
    callback: function(AutocmdEventProps)
  end

  record AugroupOptionsProps
    clear: boolean
  end

  record UserCommandEventProps
    fargs: {string}
  end

  record UserCommandOptionsProps
    nargs: string
    complete: function(string, string, integer): {string}
    desc: string
  end

  record OptionValueOptionsProps
    scope: string
    win: integer
    buf: integer
  end

  record ModeProps
    mode: string
  end

  record WinInfoProps
    textoff: integer
  end

  record SplitOptionsProps
    plain: boolean
    trimempty: boolean
  end

  record SystemOptionsProps
    stdin: string
    text: boolean
    timeout: integer
    cwd: string
  end

  record SystemCompletedProps
    code: integer
    stdout: string
    stderr: string
  end

  record SystemObjectProps
    wait: function(SystemObjectProps, ? integer): SystemCompletedProps
  end

  record TimerProps
    start: function(TimerProps, integer, integer, function()): integer
    stop: function(TimerProps): integer
    close: function(TimerProps)
    is_closing: function(TimerProps): boolean
  end

  record TSNodeProps
    iter_children: function(TSNodeProps): function(): TSNodeProps
    type: function(TSNodeProps): string
    range: function(TSNodeProps): integer, integer, integer, integer
    field: function(TSNodeProps, string): {TSNodeProps}
    parent: function(TSNodeProps): TSNodeProps
  end

  record TSTreeProps
    root: function(TSTreeProps): TSNodeProps
  end

  record LanguageTreeProps
    parse: function(
      LanguageTreeProps,
      ? {integer, integer} | boolean
    ): {TSTreeProps}
    for_each_tree: function(
      LanguageTreeProps,
      function(TSTreeProps, LanguageTreeProps)
    )
    lang: function(LanguageTreeProps): string
  end

  record QueryProps
    captures: {string}
    iter_captures: function(
      QueryProps,
      TSNodeProps,
      integer,
      ? integer,
      ? integer
    ): function(): integer, TSNodeProps
  end

  record GetParserOptionsProps
    error: boolean
  end

  record BufferOptionsProps
    filetype: string
    buftype: string
    modified: boolean
  end

  record WindowOptionsProps
    conceallevel: integer
    concealcursor: string
    number: boolean
    numberwidth: integer

    metamethod __index: function(WindowOptionsProps, integer): WindowOptionsProps
  end

  record AutocmdQueryProps
    group: string | integer
    event: string
  end

  record ExecAutocmdsOptionsProps
    buffer: integer
  end

  record BufferDeleteOptionsProps
    force: boolean
  end

  record FindOptionsProps
    path: string
    type: string
    limit: number
  end

  record DebugInfoProps
    source: string
  end

  record CpuInfoProps
    model: string
  end

  record GlobalOptionsProps
    termguicolors: boolean
  end

  record api
    nvim_buf_clear_namespace: function(integer, integer, integer, integer)
    nvim_buf_delete: function(integer, BufferDeleteOptionsProps)
    nvim_buf_set_lines: function(integer, integer, integer, boolean, {string})
    nvim_exec_autocmds: function(string, ExecAutocmdsOptionsProps)
    nvim_get_autocmds: function(AutocmdQueryProps): {any}
    nvim_get_commands: function({string: any}): {string: any}
    nvim_win_set_width: function(integer, integer)
    nvim_buf_get_extmarks: function(
      integer,
      integer,
      integer | {integer, integer},
      integer | {integer, integer},
      ExtmarkOptionsProps
    ): {ExtmarkProps}
    nvim_buf_get_lines: function(integer, integer, integer, boolean): {string}
    nvim_buf_is_loaded: function(integer): boolean
    nvim_buf_is_valid: function(integer): boolean
    nvim_buf_line_count: function(integer): integer
    nvim_buf_set_extmark: function(
      integer,
      integer,
      integer,
      integer,
      ExtmarkOptionsProps
    ): integer
    nvim_create_augroup: function(string, AugroupOptionsProps): integer
    nvim_create_autocmd: function(
      string | {string},
      AutocmdOptionsProps
    ): integer
    nvim_create_namespace: function(string): integer
    nvim_create_user_command: function(
      string,
      function(UserCommandEventProps),
      UserCommandOptionsProps
    )
    nvim_del_augroup_by_name: function(string)
    nvim_get_current_buf: function(): integer
    nvim_get_current_win: function(): integer
    nvim_get_hl: function(integer, GetHighlightOptionsProps): HighlightInfoProps
    nvim_get_mode: function(): ModeProps
    nvim_get_option_value: function(
      string,
      OptionValueOptionsProps
    ): OptionValueProps
    nvim_list_bufs: function(): {integer}
    nvim_list_uis: function(): {any}
    nvim_set_hl: function(integer, string, HighlightProps)
    nvim_set_option_value: function(
      string,
      OptionValueProps,
      OptionValueOptionsProps
    )
    nvim_ui_send: function(string)
    nvim_win_call: function<A, B>(integer, function(): (A, B)): A, B
    nvim_win_get_cursor: function(integer): {integer, integer}
    nvim_win_get_width: function(integer): integer
    nvim_win_is_valid: function(integer): boolean
    nvim_win_set_cursor: function(integer, {integer, integer})
  end

  record fn
    bufwinid: function(integer): integer
    delete: function(string, ? string): integer
    executable: function(string): integer
    getcompletion: function(string, string): {string}
    stdpath: function(string): string
    getpid: function(): integer
    getwininfo: function(integer): {WinInfoProps}
    line: function(string): integer
    nr2char: function(integer): string
    split: function(string, string): {string}
    strdisplaywidth: function(string): integer
    tempname: function(): string
    win_findbuf: function(integer): {integer}
  end

  record uv
    new_timer: function(): TimerProps
    fs_stat: function(string): table
    hrtime: function(): integer
    cpu_info: function(): {CpuInfoProps}
  end

  record json
    encode: function(any): string
    decode: function(string): any
  end

  record fs
    find: function(function(string): (boolean), FindOptionsProps): {string}
  end

  record v
    progpath: string
    argv: {string}
  end

  record treesitter
    record language
      add: function(string): boolean
    end

    record query
      parse: function(string, string): QueryProps
    end

    get_node_text: function(TSNodeProps, integer): string
    get_parser: function(
      integer,
      string,
      ? GetParserOptionsProps
    ): LanguageTreeProps
  end

  record health
    start: function(string)
    ok: function(string)
    info: function(string)
    warn: function(string)
    error: function(string)
  end

  record base64
    encode: function(string): string
  end

  record log
    record levels
      DEBUG: integer
      INFO: integer
      WARN: integer
      ERROR: integer
    end
  end

  record cmd
    metamethod __call: function(cmd, string)
    edit: function(string)
    enew: function()
    vsplit: function()
    close: function()
  end

  bo: {integer: BufferOptionsProps}
  wo: WindowOptionsProps
  o: GlobalOptionsProps
  env: {string: string}

  deep_equal: function(any, any): boolean
  deepcopy: function<T>(T): T
  endswith: function(string, string): boolean
  inspect: function(any): string
  list_extend: function<T>({T}, {T}): {T}
  list_slice: function<T>({T}, ? integer, ? integer): {T}
  notify: function(string, ? integer)
  schedule: function(function())
  split: function(string, string, ? SplitOptionsProps): {string}
  startswith: function(string, string): boolean
  system: function(
    {string},
    ? SystemOptionsProps,
    ? function(SystemCompletedProps)
  ): SystemObjectProps
  tbl_contains: function<T>({T}, T): boolean
  tbl_deep_extend: function<T>(string, T, T, ...: T): T
  tbl_extend: function<T>(string, T, T, ...: T): T
  tbl_filter: function<T>(function(T): (boolean), {T}): {T}
  tbl_keys: function<K, V>({K: V}): {K}
  tbl_map: function<T, U>(function(T): (U), {T}): {U}
  tbl_values: function<K, V>({K: V}): {V}
  trim: function(string): string
  validate: function(
    string,
    any,
    string | {string} | ValidatorProps,
    ? boolean | string,
    ? string
  )
  wait: function(integer, function(): boolean): boolean
end

global unpack: function<T>({T}, ? integer, ? integer): T...
