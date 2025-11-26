local M = { loaded = false }
_G.fcitx_loaded = false

local function warn(msg)
  if vim and vim.notify then
    vim.schedule(function()
      vim.notify(msg, vim.log.levels.WARN)
    end)
  else
    print(msg)
  end
end

local ok, ldbus = pcall(require, 'ldbus')
if not ok then
  warn('fcitx.nvim unavailable: ' .. tostring(ldbus))
  return M
end

local controller = {
  bus_name = 'org.fcitx.Fcitx5',
  path = '/controller',
  interface = 'org.fcitx.Fcitx.Controller1',
}

local function set_loaded(flag)
  flag = not not flag
  M.loaded = flag
  _G.fcitx_loaded = flag
end

local function connect()
  local conn, err = ldbus.bus.get 'session'
  if not conn then
    return nil, err or 'failed to connect to the DBus session bus'
  end
  return conn
end

local bus, initial_err = connect()
if not bus then
  warn('fcitx.nvim unavailable: ' .. initial_err)
  set_loaded(false)
  return M
end
set_loaded(true)

local function send(method)
  local function attempt()
    local msg, msg_err = ldbus.message.new_method_call(
      controller.bus_name,
      controller.path,
      controller.interface,
      method
    )
    if not msg then
      return nil, msg_err or ('failed to build DBus message: ' .. method)
    end
    local reply, call_err = bus:send_with_reply_and_block(msg)
    if not reply then
      return nil, call_err or ('DBus call failed: ' .. method)
    end
    return reply
  end

  local reply, err = attempt()
  if reply then
    return reply
  end

  local conn, conn_err = connect()
  if not conn then
    set_loaded(false)
    return nil, conn_err or err
  end

  bus = conn
  set_loaded(true)
  reply, err = attempt()
  if not reply then
    return nil, err
  end
  return reply
end

local function send_value(method)
  local reply, err = send(method)
  if not reply then
    warn('fcitx.nvim call failed: ' .. (err or method))
    return nil
  end
  local iter = reply:iter_init()
  return iter and iter:get_basic() or nil
end

local function call(method)
  local reply, err = send(method)
  if not reply then
    warn('fcitx.nvim call failed: ' .. (err or method))
    return false
  end
  return true
end

function M.is_active()
  if not M.loaded then
    return false
  end
  local state = tonumber(send_value('State')) or 0
  return state == 2
end

function M.fcitx2en()
  if not M.loaded then
    return
  end
  if M.is_active() then
    vim.b.inputtoggle = 1
    call('Deactivate')
  end
end

function M.fcitx2zh()
  if not M.loaded then
    return
  end
  local toggle = vim.b.inputtoggle
  if toggle == 1 then
    call('Activate')
    vim.b.inputtoggle = 0
  elseif toggle == nil then
    vim.b.inputtoggle = 0
  end
end

function M.current()
  if not M.loaded then
    return ''
  end
  return send_value('CurrentInputMethod') or ''
end

return M
