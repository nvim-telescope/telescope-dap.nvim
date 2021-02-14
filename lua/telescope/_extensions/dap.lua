local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

local has_dap, dap = pcall(require, 'dap')
if not has_dap then
  error('This plugins requires mfussenegger/nvim-dap')
end

local actions    = require'telescope.actions'
local builtin    = require'telescope.builtin'
local finders    = require'telescope.finders'
local pickers    = require'telescope.pickers'
local sorters    = require'telescope.sorters'
local previewers = require'telescope.previewers'

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
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_bufnr)
      actions.goto_file_selection_edit:replace(function()
        local selection = actions.get_selected_entry(prompt_bufnr)
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
    sorter = sorters.get_generic_fuzzy_sorter(),
    attach_mappings = function(prompt_bufnr)
      actions.goto_file_selection_edit:replace(function()
        local selection = actions.get_selected_entry(prompt_bufnr)
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
            variables[name].lnum = lnum + 1 -- Its wrong if we don't do + 1. But i don't understand why
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
          display = string.format('%s(%s) = %s', entry.name, entry.type, entry.value),
          filename = frame.source.path,
          lnum = entry.lnum or 1,
          col = entry.col or 0,
        }
      end
    },
    sorter = sorters.get_generic_fuzzy_sorter(),
    previewer = previewers.vimgrep.new(opts),
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
        sorter = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function(prompt_bufnr)
          actions.goto_file_selection_edit:replace(function()
            local selection = actions.get_selected_entry(prompt_bufnr)
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
  }
}
