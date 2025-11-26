if vim.g.fcitx_nvim_disable_auto_setup then
  return
end

local ok, fcitx = pcall(require, 'fcitx')
if not ok then
  vim.schedule(function()
    vim.notify('fcitx.nvim: ' .. tostring(fcitx), vim.log.levels.WARN)
  end)
  return
end

fcitx.setup()
