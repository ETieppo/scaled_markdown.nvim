

local VISUAL_MODES =
{ v = true, V = true, ['\22'] = true }

local reveal_range = {}


local function add_rows(
   revealed_rows,
   first_row,
   last_row)

   for row = math.min(first_row, last_row), math.max(first_row, last_row) do
      revealed_rows[row] = true
   end
end

function reveal_range.collect_revealed_rows(
   win,
   reveal_config)

   local revealed_rows = {}
   local cursor_row = vim.api.nvim_win_get_cursor(win)[1] - 1
   if reveal_config.cursor_line then revealed_rows[cursor_row] = true end
   local is_current_window = vim.api.nvim_get_current_win() == win
   local current_mode = vim.api.nvim_get_mode().mode:sub(1, 1)
   if
reveal_config.visual_selection and
      is_current_window and
      VISUAL_MODES[current_mode] then

      add_rows(revealed_rows, vim.fn.line('v') - 1, cursor_row)
   end
   return revealed_rows
end

return reveal_range
