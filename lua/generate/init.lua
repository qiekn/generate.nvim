local M = {}

function M.setup(opts)
  if opts then
    require('generate.config').setup(opts)
  end

  local api = vim.api
  local ts = vim.treesitter

  api.nvim_create_user_command('Generate', function(params)
    local header = require('generate.header')
    local source = require('generate.source')

    local path = api.nvim_buf_get_name(0)
    local parser = ts.get_parser()
    local root = parser:parse()[1]:root()

    local arg = params.fargs[1]
    if arg == 'implementations' then
      local line1, line2
      if params.range == 2 then
        line1 = params.line1
        line2 = params.line2
      end
      local namespaces = header.get_declarations(root, line1, line2)
      source.insert_header(path)
      source.implement_methods(namespaces)
    end
  end, {
    bang = false,
    bar = false,
    nargs = 1,
    range = true,
    complete = function()
      return { 'implementations' }
    end,
  })
end

return M
