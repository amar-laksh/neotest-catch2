local Path = require("plenary.path")
local lib = require("neotest.lib")
local bit = require('bit')
local M = {}

---- Helper functions start
function M.is_executable(file)
    if bit.band(bit.tobit(100), bit.tobit(file:_st_mode())) == 100 then
        return true
    end
    return false
end

function M.replace(str, what, with)
    what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") -- escape pattern
    with = string.gsub(with, "[%%]", "%%%%") -- escape replacement
    return string.gsub(str, what, with)
end

function M.escape_special_chars(str)
    str = str:gsub(",", "\\%1")
    str = str:gsub("%[", "\\[")
    return str
end

function M.unescape_special_chars(str)
    str = M.escape_special_chars(str)
    str = str:gsub("\"", "\\%1")
    return str
end

function M.into_iter(table)
    local iterable = {}
    if #table == 0 then
        iterable = { table }
    else
        iterable = table
    end
    return iterable
end

function M.contains(table, key)
    for _, element in ipairs(table) do
        if element[key] ~= nil then
            return true
        end
    end
    return false
end

function M.merge_tables(t1, t2)
    -- We merge the two tables and overwrite duplicate elements
    for k, v in pairs(t1) do t2[k] = v end
    return t2
end

local function add_catch2_prefixes(kind, name)
    if (kind == "SCENARIO") then
        name = "Scenario: " .. name
    elseif (kind == "GIVEN") then
        name = "Given: " .. name
    elseif (kind == "WHEN") then
        name = "When: " .. name
    elseif (kind == "THEN") then
        name = "Then: " .. name
    end
    return name
end

function M.concat_tables(t1, t2)
    if #t1 == 0 then
        return t2
    end
    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1
end

---- Helper functions ends

M.test_extensions = {
    ["cpp"] = true,
    ["cc"] = true,
    ["cxx"] = true,
    ["c++"] = true,
}

M.query = [[ 
(
 (
  expression_statement
  (
   call_expression
   function: (identifier) @test.kind
   arguments: (
               argument_list
               . (string_literal) @test.name
               . (string_literal)? @test.tag
               )
   (#any-of? @test.kind "TEST_CASE"  "SCENARIO" "TEMPLATE_TEST_CASE")
   )
  )
 . (compound_statement) @test.definition
)
]]


function M.get_match_type(captured_nodes)
    if captured_nodes["test.name"] then
        return "test"
    end
    if captured_nodes["namespace.name"] then
        return "namespace"
    end
end

--- Provides a list of files/directories in the root path
---@param path string
---@param root string | nil
---@param build_prefixes Table
---@return string[]
function M.get_runners(path, root, build_prefixes)
    local runners = {}
    if (root ~= nil) then
        -- print("path: ", path)
        -- print("root: ", root)
        local buildPrefix = ""
        for _, prefix in pairs(build_prefixes) do
            if lib.files.exists(root .. prefix) then
                buildPrefix = prefix
            end
        end
        local build_dir = root .. buildPrefix
        -- print("build_dir: ", build_dir)
        local test_runner_dir = Path:new(build_dir .. M.replace(path, root .. Path.path.sep, "")):parent()
        for name, type in vim.fs.dir(tostring(test_runner_dir)) do
            if type == "file" then
                local name_path = Path:new(tostring(test_runner_dir) .. Path.path.sep .. name)
                if M.is_executable(name_path) then
                    runners[#runners + 1] = name_path:absolute()
                end
            end
        end
    end
    return runners
end

--- Provides the runner for the unit test
---@param path string
---@param build_prefixes any
---@return string
function M.get_runner(path, build_prefixes)
    -- TODO: apply some criteria to select the correct runner, maybe CMAKE?
    local runners = M.get_runners(path, lib.files.match_root_pattern(
        build_prefixes
    )(path), build_prefixes
    ) or error("Cannot find runners", 0)
    return runners[1]
end

---@async
---@param file_path string
---@param test_suffixes table
---@return boolean
function M.is_test_file(file_path, test_suffixes)
    local elems = vim.split(file_path, Path.path.sep, { plain = true })
    local filename = elems[#elems]
    if filename == "" then -- directory
        return true
    end
    local extsplit = vim.split(filename, ".", { plain = true })
    local extension = extsplit[#extsplit]
    local fname_last_part = extsplit[#extsplit - 1]
    local result = false
    for i, _ in pairs(test_suffixes) do
        if (M.test_extensions[extension]
            and vim.endswith(fname_last_part, test_suffixes[i])) then
            result = true
        end
    end
    return result
end

--- Provides filter names from the test using the test tree
---@param tree neotest.Tree
---@return string
function M.positions2filter(tree)
    local data = tree:data()
    local type = data.type
    -- print("data: ", vim.inspect(data.description))
    if type == "test" then
        return string.format('"%s"', data.name)
    elseif type == "file" then
        local filters = {}
        for _, test in ipairs(tree:children()) do
            -- print("test:", vim.inspect(test))
            filters[#filters + 1] = M.positions2filter(test)
        end
        local fs = table.concat(filters, ",")
        return fs:sub(1, -1)
    else
        error("unknown position type " .. type)
    end
end

--- Callback function to build test tree by parsing catch2 structures
---@param file_path string
---@param source any
---@param captured_nodes any
---@return table
function M.build_positions_tree(file_path, source, captured_nodes)
    local tree = {}
    local match_type = M.get_match_type(captured_nodes)
    if match_type then
        local name = vim.treesitter.get_node_text(captured_nodes[match_type .. ".name"], source)
        local definition = captured_nodes[match_type .. ".definition"]
        local tag = vim.treesitter.get_node_text(captured_nodes[match_type .. ".tag"], source)
        local kind = vim.treesitter.get_node_text(captured_nodes[match_type .. ".kind"], source)
        -- Cleaning up quotes at the beginning and end
        if name:sub(1, 1) == "\"" and name:sub(#name, #name) == "\"" then
            name = name:sub(2, #name - 1)
        end
        if tag:sub(1, 1) == "\"" and tag:sub(#tag, #tag) == "\"" then
            tag = tag:sub(2, #tag - 1)
        end

        name = M.escape_special_chars(add_catch2_prefixes(kind, name))
        tree = {
            type = match_type,
            path = file_path,
            name = name,
            range = { definition:range() },
            tag = tag,
            kind = kind
        }
    end
    return tree
end

--- Extracts results from the test results
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param testcases Table
---@param main_filter Table
---@return Table
function M.extract_results(spec, result, testcases, main_filter)
    local results = {}
    local last = {}
    for _, testcase in ipairs(testcases) do
        local filter = main_filter or M.unescape_special_chars(testcase._attr.name)
        local current = M.fill_result(testcase, filter, spec, result)
        results = M.concat_tables(results, current)
    end
    return results
end

function M.fill_result(testcase, filter, spec, result)
    local results = {}
    local errors = {}
    if testcase.Expression ~= nil then
        local expressions = M.into_iter(testcase.Expression)
        for idx, expression in ipairs(expressions) do
            local line = tonumber(expression._attr.line)
            local message = "\nOriginal: " ..
                expression.Original .. "\nExpanded: " .. expression.Expanded
            errors[idx] = { message = message, line = line - 1 }
            results[filter] = {
                status = "failed",
                short = message,
                output = spec.context.results_path,
            }
        end
    else
        results[filter] = {
            status = "passed",
            output = result.output
        }
    end
    results[filter].errors = errors
    return results
end

--- Provides appropriate strategy according to user choice
---@param strategy string
---@param path string
---@param test_args Table
---@param args neotest.RunArgs
---@param dap_adapter string
function M.get_strategy_config(strategy, test_args, path, args, dap_adapter)
    local config = {
        dap = function()
            local status_ok, _ = pcall(require, 'dap')
            if not status_ok then
                return
            end
            local c = {
                type = dap_adapter,
                name = 'Neotest Debugger',
                request = 'launch',
                program = path,
                stopOnEntry = false,
                args = test_args,
            }
            local conf = M.merge_tables(c, args or {})
            return conf
        end,
    }
    if config[strategy] then
        return config[strategy]()
    end
end

return M
