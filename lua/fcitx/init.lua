local dbus = require 'fcitx.dbus'

local M = { dbus = dbus }
local defaults = {
  enable_cmdline = false,
}

local function guard(fn)
  return function()
    if vim.fn.reg_executing() == '' then
      fn()
    end
  end
end

local function create_autocmds(opts)
  local group = vim.api.nvim_create_augroup('FcitxToggle', { clear = true })
  local leave_event = vim.fn.exists('##InsertLeavePre') == 1 and 'InsertLeavePre' or 'InsertLeave'

  vim.api.nvim_create_autocmd(leave_event, {
    group = group,
    callback = guard(dbus.fcitx2en),
  })
  vim.api.nvim_create_autocmd('InsertEnter', {
    group = group,
    callback = guard(dbus.fcitx2zh),
  })

  if opts.enable_cmdline then
    vim.api.nvim_create_autocmd('CmdlineEnter', {
      group = group,
      pattern = { '/', '?' },
      callback = guard(dbus.fcitx2zh),
    })
    vim.api.nvim_create_autocmd('CmdlineLeave', {
      group = group,
      pattern = { '/', '?' },
      callback = guard(dbus.fcitx2en),
    })
  end

  return group
end

function M.setup(opts)
  opts = vim.tbl_extend('force', defaults, opts or {})
  if not dbus.loaded then
    return
  end

  if M._group then
    pcall(vim.api.nvim_del_augroup_by_id, M._group)
  end
  M._group = create_autocmds(opts)
end

return M
