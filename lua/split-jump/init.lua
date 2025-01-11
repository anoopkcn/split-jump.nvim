---@class SplitJumpConfig
---@field mappings boolean
---@field disable_when_zoomed boolean
---@field save_on_switch integer
---@field preserve_zoom boolean
---@field no_wrap boolean
---@field disable_netrw_workaround boolean

---@class split_jump
local M = {}

local tmux_is_last_pane = false

-- Configuration defaults
local default_config = {
  mappings = true,
  disable_when_zoomed = false,
  save_on_switch = 0, -- 0: no save, 1: save current buffer, 2: save all buffers
  preserve_zoom = false,
  no_wrap = false,
  disable_netrw_workaround = true
}

local function vim_navigate(direction)
  local success, _ = pcall(vim.cmd, 'wincmd ' .. direction)
  if not success then
    vim.notify('E11: Invalid in command-line window; <CR> executes, CTRL-C quits: wincmd ' .. direction, vim.log.levels.WARN)
  end
end

local function tmux_socket()
  return vim.split(vim.env.TMUX, ',')[1]
end

local function tmux_command(args)
  local tmux_exe = string.find(vim.env.TMUX or '', 'tmate') and 'tmate' or 'tmux'
  local cmd = string.format('%s -S %s %s', tmux_exe, tmux_socket(), args)
  return vim.fn.system(cmd)
end

local function tmux_vim_pane_is_zoomed()
  return tonumber(tmux_command("display-message -p '#{window_zoomed_flag}'")) == 1
end

local function should_forward_navigation(tmux_last_pane, at_tab_page_edge)
  if M.config.disable_when_zoomed and tmux_vim_pane_is_zoomed() then
    return false
  end
  return tmux_last_pane or at_tab_page_edge
end

local pane_position_from_direction = {
  h = 'left',
  j = 'bottom',
  k = 'top',
  l = 'right'
}

local function tmux_aware_navigate(direction)
  local nr = vim.fn.winnr()
  local tmux_last_pane = (direction == 'p' and tmux_is_last_pane)

  if not tmux_last_pane then
    vim_navigate(direction)
  end

  local at_tab_page_edge = (nr == vim.fn.winnr())

  if should_forward_navigation(tmux_last_pane, at_tab_page_edge) then
    if M.config.save_on_switch == 1 then
      pcall(vim.cmd, 'update')
    elseif M.config.save_on_switch == 2 then
      pcall(vim.cmd, 'wall')
    end

    local dir_tr = {p = 'l', h = 'L', j = 'D', k = 'U', l = 'R'}
    local args = string.format('select-pane -t %s -%s', vim.fn.shellescape(vim.env.TMUX_PANE), dir_tr[direction])

    if M.config.preserve_zoom then
      args = args .. ' -Z'
    end

    if M.config.no_wrap then
      args = string.format('if -F "#{pane_at_%s}" "" "%s"',
        pane_position_from_direction[direction],
        args)
    end

    tmux_command(args)
    tmux_is_last_pane = true
  else
    tmux_is_last_pane = false
  end
end

---@param user_config? SplitJumpConfig
function M.setup(user_config)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend('force', default_config, user_config or {})

  -- Only set up if not in tmux
  if not vim.env.TMUX then
    vim.api.nvim_create_user_command('SplitJumpLeft', function() vim_navigate('h') end, {})
    vim.api.nvim_create_user_command('SplitJumpDown', function() vim_navigate('j') end, {})
    vim.api.nvim_create_user_command('SplitJumpUp', function() vim_navigate('k') end, {})
    vim.api.nvim_create_user_command('SplitJumpRight', function() vim_navigate('l') end, {})
    vim.api.nvim_create_user_command('SplitJumpPrevious', function() vim_navigate('p') end, {})
    return
  end

  -- Create commands
  vim.api.nvim_create_user_command('SplitJumpLeft', function() tmux_aware_navigate('h') end, {})
  vim.api.nvim_create_user_command('SplitJumpDown', function() tmux_aware_navigate('j') end, {})
  vim.api.nvim_create_user_command('SplitJumpUp', function() tmux_aware_navigate('k') end, {})
  vim.api.nvim_create_user_command('SplitJumpRight', function() tmux_aware_navigate('l') end, {})
  vim.api.nvim_create_user_command('SplitJumpPrevious', function() tmux_aware_navigate('p') end, {})

  -- Set up autocommand to reset tmux_is_last_pane
  vim.api.nvim_create_autocmd('WinEnter', {
    group = vim.api.nvim_create_augroup('split_jump', { clear = true }),
    callback = function() tmux_is_last_pane = false end
  })

  -- Set up default mappings unless disabled
  if M.config.mappings then
    local opts = { noremap = true, silent = true }
    vim.keymap.set('n', '<C-h>', ':SplitJumpLeft<CR>', opts)
    vim.keymap.set('n', '<C-j>', ':SplitJumpDown<CR>', opts)
    vim.keymap.set('n', '<C-k>', ':SplitJumpUp<CR>', opts)
    vim.keymap.set('n', '<C-l>', ':SplitJumpRight<CR>', opts)
    vim.keymap.set('n', '<C-\\>', ':SplitJumpPrevious<CR>', opts)

    -- Handle netrw mapping conflict
    if not M.config.disable_netrw_workaround then
      if not vim.g.Netrw_UserMaps then
        vim.g.Netrw_UserMaps = {{'<C-l>', '<C-U>SplitJumpRight<cr>'}}
      else
        vim.notify(
          'split_jump conflicts with netrw <C-l> mapping. ' ..
          'set disable_netrw_workaround = true in setup() to suppress this warning.', vim.log.levels.WARN
        )
      end
    end
  end
end

M.setup()

return setmetatable(M, {
  __index = function(_, k)
    return M[k]
  end,
})
