local M = {}

local unchecked_pattern = '%- %[ %]'
local checked_pattern = '%- %[x%]'

local box_state = function(line)
  local checked_pos = line:find(checked_pattern)
  local unchecked_pos = line:find(unchecked_pattern)

  if unchecked_pos then
	return { is_checked = false, col = unchecked_pos }
  elseif checked_pos then
	return { is_checked = true, col = checked_pos }
  end
end

local replace_box = function(lines, toggled)
  for i, line in ipairs(lines) do
	if line:find(unchecked_pattern) and toggled then
	  lines[i] = line:gsub(unchecked_pattern, '- [x]')
	elseif line:find(checked_pattern) and not toggled then
	  lines[i] = line:gsub(checked_pattern, '- [ ]')
	end
  end
  return lines
end

M.toggle_cursor = function()
  local line = vim.api.nvim_get_current_line()
  local curs = vim.api.nvim_win_get_cursor(0)
  local box = box_state(line)

  if not box then return end

  line = replace_box({line}, not box.is_checked)
  vim.api.nvim_buf_set_lines(0, curs[1] - 1, curs[1], false, line)
end

local multi_line_toggle = function(lines, range)
	local checked, unchecked = false, false

	for _, line in ipairs(lines) do
	  local box = box_state(line)

	  if not box then goto skip end

	  if box.is_checked then checked = true
	  elseif not box.is_checked then unchecked = true end
	  ::skip::
	end

	lines = replace_box(lines, not checked or unchecked)
	vim.api.nvim_buf_set_lines(0, range['start'] - 1, range['end'], false, lines)
end

M.toggle_parent = function()
  local parent_line = vim.api.nvim_get_current_line()
  local parent_pos = vim.api.nvim_win_get_cursor(0)[1]
  local parent_start = parent_pos
  local parent_box = box_state(parent_line)

  local lines = vim.api.nvim_buf_get_lines(0, parent_pos, parent_pos + 1, false)
  if lines and #lines > 0 then
    local child_line = lines[1]

    if parent_box then
      while box_state(child_line) and box_state(child_line).col > parent_box.col do
        parent_pos = parent_pos + 1
        lines = vim.api.nvim_buf_get_lines(0, parent_pos, parent_pos + 1, false)

        if lines and #lines > 0 then
          child_line = lines[1]
        else
          break
        end
      end
    end
	lines = vim.api.nvim_buf_get_lines(0, parent_start - 1, parent_pos, false)
	multi_line_toggle(lines, {['start'] = parent_start, ['end'] = parent_pos})
  end
end

local visual_mode_ops = function(callback)
  -- return to normal mode; required due to how ..getpos("'< & '>") works
  vim.api.nvim_feedkeys(
	vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true
  )

  -- finish the current work in event loop queue 
  vim.schedule(function()
	callback({
	  start = vim.fn.getpos("'<")[2],
	  ['end'] = vim.fn.getpos("'>")[2]
	})
  end)
end

M.visual_toggle = function()
  visual_mode_ops(function(v_pos)
	multi_line_toggle(
	vim.api.nvim_buf_get_lines(0, v_pos['start'] - 1, v_pos['end'], false), v_pos)
  end)
end

M.setup = function(opts)
  local user_maps = opts.mappings

  if user_maps then M.mappings = user_maps else
	M.mappings = {
	  cursor = '<leader>tt',
	  parent = '<leader>tp'
	}
  end
  M.apply_mappings()
end

M.apply_mappings = function()
  vim.keymap.set('n', M.mappings.cursor, M.toggle_cursor, {silent = true})
  vim.keymap.set('n', M.mappings.parent, M.toggle_parent, {silent = true})
  vim.keymap.set('x', M.mappings.cursor, M.visual_toggle, {silent = true})
end

return M
