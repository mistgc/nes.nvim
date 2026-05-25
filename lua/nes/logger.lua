---@class nes.Logger
---@field logfile string
local Logger = {}

local uv = vim.uv

local log_level_names = {
  [vim.log.levels.ERROR] = 'ERROR', --4
  [vim.log.levels.WARN] = 'WARN', --3
  [vim.log.levels.INFO] = 'INFO', --2
  [vim.log.levels.DEBUG] = 'DEBUG', --1
  [vim.log.levels.TRACE] = 'TRACE', --0
}

function Logger.setup()
  local log_dir = vim.fs.normalize(vim.fn.stdpath('log'))
  vim.fn.mkdir(log_dir, 'p')
  Logger.logfile = log_dir .. '/nes.nvim.log'
end

function Logger.write_log(filepath, msg)
  local log_msg = msg
  if not log_msg:match('\n$') then
    log_msg = log_msg .. '\n'
  end
  uv.fs_open(filepath, 'a', tonumber('644', 8), function(err, fd)
    if err or not fd then
      vim.notify('Failed to open log file ' .. err)
      return
    end
    uv.fs_write(fd, log_msg, -1, function(write_err)
      if write_err then
        vim.notify('Failed to write to log file ' .. write_err)
      end
      uv.fs_close(fd)
    end)
  end)
end

function Logger.log(level, msg)
  local level_name = log_level_names[level]
  local secs = os.time()
  local msecs = math.floor((os.clock() % 1) * 1000)
  local timestamp = string.format('%s.%03d', os.date('%Y-%m-%d %H:%M:%S', secs), msecs)
  local log_msg = string.format('%s [%s]: %s', timestamp, level_name, msg)
  Logger.write_log(Logger.logfile, log_msg)
end

function Logger.error(msg)
  vim.notify(msg, vim.log.levels.ERROR)
  Logger.log(vim.log.levels.ERROR, msg)
end

function Logger.warn(msg)
  vim.notify(msg, vim.log.levels.WARN)
  Logger.log(vim.log.levels.WARN, msg)
end

function Logger.info(msg)
  Logger.log(vim.log.levels.INFO, msg)
end

function Logger.debug(msg)
  Logger.log(vim.log.levels.DEBUG, msg)
end

function Logger.trace(msg)
  Logger.log(vim.log.levels.TRACE, msg)
end

return Logger
