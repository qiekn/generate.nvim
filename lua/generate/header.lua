local ts = vim.treesitter
local ts_util = require('generate.treesitter')

local M = {}

local function get_node_name(node)
  local identifier = ts_util.first_child_with_type('type_identifier', node)
  if identifier == nil then
    identifier = ts_util.first_child_with_type('namespace_identifier', node)
  end
  if identifier == nil then
    identifier = ts_util.first_child_with_type('identifier', node)
  end
  if identifier == nil then
    return nil
  end
  return ts.get_node_text(identifier, 0, {})
end

local function in_range(node, line1, line2)
  if line1 == nil then
    return true
  end
  local start_row = node:start()
  local end_row = node:end_()
  -- treesitter rows are 0-based, command range is 1-based
  return start_row <= line2 - 1 and end_row >= line1 - 1
end

local function collect_declarations(node, namespaces, class_prefix, result, line1, line2)
  local node_type = node:type()

  if node_type == 'class_specifier' or node_type == 'struct_specifier' then
    local name = get_node_name(node)
    if name == nil then
      return
    end
    local qualified = class_prefix ~= '' and (class_prefix .. '::' .. name) or name
    local fields = ts_util.first_child_with_type('field_declaration_list', node)
    if fields == nil then
      return
    end
    local declarations = {}
    for child in fields:iter_children() do
      if ts_util.is_function_declaration(child) and in_range(child, line1, line2) then
        table.insert(declarations, child)
      elseif child:type() == 'class_specifier' or child:type() == 'struct_specifier' then
        collect_declarations(child, namespaces, qualified, result, line1, line2)
      end
    end
    if #declarations > 0 then
      table.insert(result, { namespaces = namespaces, name = qualified, declarations = declarations })
    end

  elseif node_type == 'namespace_definition' then
    local name = get_node_name(node)
    local child_namespaces = vim.list_extend({}, namespaces)
    if name then
      table.insert(child_namespaces, name)
    end
    local body = ts_util.first_child_with_type('declaration_list', node)
    if body == nil then
      return
    end
    local declarations = {}
    for child in body:iter_children() do
      local child_type = child:type()
      if child_type == 'namespace_definition'
        or child_type == 'class_specifier'
        or child_type == 'struct_specifier' then
        collect_declarations(child, child_namespaces, class_prefix, result, line1, line2)
      elseif ts_util.is_function_declaration(child) and in_range(child, line1, line2) then
        table.insert(declarations, child)
      end
    end
    if #declarations > 0 then
      table.insert(result, { namespaces = child_namespaces, name = '', declarations = declarations })
    end

  elseif node_type == 'translation_unit' then
    for child in node:iter_children() do
      local child_type = child:type()
      if child_type == 'namespace_definition'
        or child_type == 'class_specifier'
        or child_type == 'struct_specifier' then
        collect_declarations(child, namespaces, class_prefix, result, line1, line2)
      end
    end
  end
end

function M.get_declarations(root, line1, line2)
  local result = {}
  collect_declarations(root, {}, '', result, line1, line2)
  return result
end

return M
