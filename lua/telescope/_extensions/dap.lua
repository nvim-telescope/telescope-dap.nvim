local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

local has_dap, dap = pcall(require, 'dap')
if not has_dap then
  error('This plugins requires mfussenegger/nvim-dap')
end

local actions      = require'telescope.actions'
local action_state = require'telescope.actions.state'
local builtin      = require'telescope.builtin'
local finders      = require'telescope.finders'
local pickers      = require'telescope.pickers'
local previewers   = require'telescope.previewers'
local conf = require('telescope.config').values

local function get_url_buf(url)
  local buf = -1
  if url then
    local scheme = url:match('^([a-z]+)://.*')
    if scheme then
      buf = vim.uri_to_bufnr(url)
    else
      buf = vim.uri_to_bufnr(vim.uri_from_fname(url))
    end
    vim.fn.bufload(buf)
  end
  return buf
end

local commands = function(opts)
  opts = opts or {}

  local results = {}
  for k, v in pairs(dap) do
    if type(v) == "function" then
      table.insert(results, k)
    end
  end

  pickers.new(opts, {
    prompt_title = 'Dap Commands',
    finder    = finders.new_table {
      results = results
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        dap[selection.value]()
      end)

      return true
    end
  }):find()
end

local configurations = function(opts)
  opts = opts or {}

  local results = {}
  for _, lang in pairs(dap.configurations) do
    for _, config in ipairs(lang) do
      table.insert(results, config)
    end
  end

  if vim.tbl_isempty(results) then
    return
  end

  pickers.new(opts, {
    prompt_title = 'Dap Configurations',
    finder    = finders.new_table {
      results = results,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.type .. ': ' .. entry.name,
          ordinal = entry.type .. ': ' .. entry.name,
          preview_command = function(entry, bufnr)
            local output = vim.split(vim.inspect(entry.value), '\n')
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, output)
          end
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        dap.run(selection.value)
      end)

      return true
    end,
    previewer = previewers.display_content.new(opts)
  }):find()
end

local list_breakpoints = function(opts)
  opts = opts or {}
  opts.prompt_title = 'Dap Breakpoints'

  dap.list_breakpoints(false)
  builtin.quickfix(opts)
end

local variables = function(opts)
  opts = opts or {}

  local frame = dap.session().current_frame

  local variables = {}
  for _, s in pairs(frame.scopes or {}) do
    if s.variables then
      for _, v in pairs(s.variables) do
        if v.type ~= '' and v.value ~= '' then
          variables[v.name] = { name = v.name, value = v.value, type = v.type }
        end
      end
    end
  end

  local buf = get_url_buf(frame and frame.source and frame.source.path)

  local require_ok, locals = pcall(require, "nvim-treesitter.locals")
  local _, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
  local _, utils = pcall(require, "nvim-treesitter.utils")
  local _, parsers = pcall(require, "nvim-treesitter.parsers")
  local _, queries = pcall(require, "nvim-treesitter.query")

  if require_ok then
    if buf ~= -1 then
      local lang =  parsers.get_buf_lang(buf)
      if not parsers.has_parser(lang) or not queries.has_locals(lang) then return end
      local definition_nodes = locals.get_definitions(buf)
      for _, d in pairs(definition_nodes) do
        local node = utils.get_at_path(d, 'var.node') or utils.get_at_path(d, 'parameter.node')
        if node then
          local name = ts_utils.get_node_text(node, buf)[1]

          if variables[name] then
            local lnum, col = node:start()
            variables[name].lnum = lnum + 1 -- Treesitter lines start at 0!
            variables[name].col = col
          end
        end
      end
    end
  end

  local results = {}
  for _, v in pairs(variables) do
    table.insert(results, v)
  end

  pickers.new(opts, {
    prompt_title = 'Dap Variables',
    finder    = finders.new_table {
      results = results,
      entry_maker = function(entry)
        return {
          value = entry,
          ordinal = string.format('%s(%s) = %s', entry.name, entry.type, entry.value),
          display = string.format('%s(%s) = %s', entry.name, entry.type, entry.value:gsub('\n', '')),
          filename = frame.source.path,
          lnum = entry.lnum or 1,
          col = entry.col or 0,
        }
      end
    },
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
  }):find()
end


local frames = function(opts)
  opts = opts or {}
  local session = require'dap'.session()

  if not session or not session.stopped_thread_id then
    print('Cannot move frame if not stopped')
    return
  end
  local frames = session.threads[session.stopped_thread_id].frames

  pickers.new(opts, {
    prompt_title = 'Jump to frame',
    finder    = finders.new_table {
      results = frames,
      entry_maker = function(frame)
        return {
          value = frame,
          display = frame.name,
          ordinal = frame.name,
          filename = frame.source and frame.source.path or '',
          lnum = frame.line or 1,
          col = frame.column or 0,
        }
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        session:_frame_set(selection.value)
      end)

      return true
    end,
    previewer = conf.grep_previewer(opts),
  }):find()
end

return telescope.register_extension {
  setup = function()
    require('dap.ui').pick_one = function(items, prompt, label_fn, cb)
      local opts = {}
      pickers.new(opts, {
        prompt_title = prompt,
        finder    = finders.new_table {
          results = items,
          entry_maker = function(entry)
            return {
              value = entry,
              display = label_fn(entry),
              ordinal = label_fn(entry),
            }
          end,
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)

            cb(selection.value)
          end)

          return true
        end,
      }):find()
    end
  end,
  exports = {
    commands = commands,
    configurations = configurations,
    list_breakpoints = list_breakpoints,
    variables = variables,
    frames = frames,
  }
}
