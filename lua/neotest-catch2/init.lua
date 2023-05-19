local utils = require("neotest-catch2.utils")
local lib = require("neotest.lib")
local xml = require("neotest.lib.xml")
local async = require("neotest.async")
local Path = require("plenary.path").path

---@class neotest.Adapter
---@field name string
local Adapter = { name = "neotest-catch2" }

local get_args = function()
    return {}
end

local is_callable = function(obj)
    return type(obj) == "function" or (type(obj) == "table" and obj.__call)
end

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function Adapter.root(dir)
    local root = lib.files.match_root_pattern(
        get_args().buildPrefixes
    )(dir)
    return root
end

---@async
---@param file_path string
---@return boolean
function Adapter.is_test_file(file_path)
    return utils.is_test_file(file_path, get_args().testSuffixes)
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function Adapter.discover_positions(file_path)
    local parsed = lib.treesitter.parse_positions(file_path, utils.query, {
        require_namespaces = false,
        position_id = function(position, _)
            return position.name
        end,
        build_position = utils.build_positions_tree
    })
    -- print(vim.inspect(parsed))
    return parsed
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function Adapter.build_spec(args)
    local tree = args.tree
    local path = tree:data().path
    local root = Adapter.root(path)
    local filters = utils.positions2filter(tree)
    -- print("filters: ", vim.inspect(filters))

    if #filters == 0 then
        error("Did not run tests: no tests selected to run")
    end

    local buildPrefix = (get_args().buildPrefixes) or { "build" }

    local runner = get_args().runner or utils.get_runner(path, buildPrefix)
    runner = (get_args().runnerPrefix or "") .. runner
    if (not runner) then
        error("I couldn't find any test executable runner!")
    end
    local target = vim.split(runner, Path.sep, {})
    target = target[#target]
    local temp_dir = get_args().tempDir or (async.fn.tempname() .. "/")
    local results_path = temp_dir .. "test_result.xml"
    local buildCommand = ""
    if get_args().buildCommandFn ~= nil then
        buildCommand = string.format("cd %s && %s && cd - && ", root, (get_args().buildCommandFn(target, root)))
    end
    local test_args = {
        "-r", "xml",
        "-o", results_path, filters
    }
    local command = table.concat(vim.tbl_flatten({
        buildCommand,
        runner,
        test_args,
        vim.list_extend(get_args(), args.extra_args or {}, 1, #get_args())
    }), " ")
    -- print("running command:", command)
    -- print("current strategy: ", args.strategy)
    local strategy_config = utils.get_strategy_config(args.strategy, test_args, runner, get_args().strategyConfig, "lldb")
    return { command = command,
        context = { results_path = results_path }, cwd = root, strategy = strategy_config }
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param _ neotest.Tree
---@return table<string, neotest.Result>
function Adapter.results(spec, result, _)
    local success, data = pcall(lib.files.read, spec.context.results_path)
    if not success then
        error("the runner command(" .. spec.command .. ") failed!")
        return {}
    end
    local results = {}
    local section_results = {}

    local handler = xml.parse(data)
    local testcases = utils.into_iter(handler.Catch.Group.TestCase)
    for _, testcase in ipairs(testcases) do
        if testcase.Section ~= nil then
            section_results = utils.extract_results(spec, result, utils.into_iter(testcase.Section),
                utils.unescape_special_chars(testcase._attr.name))
        else
            results = utils.extract_results(spec, result, utils.into_iter(testcase))
        end
        results = utils.merge_tables(results, section_results)
    end
    -- print("results: ", vim.inspect(results))
    return results
end

setmetatable(Adapter, {
    __call = function(_, opts)
        if is_callable(opts.args) then
            get_args = opts.args
        elseif opts.args then
            get_args = function()
                return opts.args
            end
        end
        return Adapter
    end,
})

return Adapter
