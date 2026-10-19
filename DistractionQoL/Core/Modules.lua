-- Modules.lua
-- Centralized lifecycle and module registry manager for DistractionQoL
-- Allows self-contained modules to register their initialization and event hooks safely.
-- Isolated execution with pcall to prevent one broken module from breaking the entire suite.

local addonName, DQ = ...

DQ.Modules = {}
local registeredModules = {}
local isInitialized = false

-- Registers a feature or system module
-- name: string identifier
-- moduleTable: table containing an optional :Init() method
-- priority: integer (lower numbers initialize earlier, default 100)
function DQ:RegisterModule(name, moduleTable, priority)
    if not name then return end
    moduleTable = moduleTable or {}
    priority = priority or 100

    registeredModules[name] = {
        name = name,
        instance = moduleTable,
        priority = priority,
        initialized = false,
    }
    DQ.Modules[name] = moduleTable
    return moduleTable
end

-- Safely retrieves a registered module
function DQ:GetModule(name)
    return DQ.Modules[name]
end

-- Initializes all registered modules ordered by priority
function DQ:InitializeModules()
    if isInitialized then return end
    isInitialized = true

    -- Gather list of modules
    local list = {}
    for _, mod in pairs(registeredModules) do
        table.insert(list, mod)
    end

    -- Sort ascending by priority
    table.sort(list, function(a, b)
        return a.priority < b.priority
    end)

    -- Execute Init() safely on each module
    for _, mod in ipairs(list) do
        if not mod.initialized and mod.instance and type(mod.instance.Init) == "function" then
            local ok, err = pcall(mod.instance.Init, mod.instance)
            if not ok then
                if DQ.Print then
                    DQ:Print(string.format("|cffff4444Error initializing [%s]: %s|r", mod.name, tostring(err)))
                else
                    print(string.format("[DistractionQoL] Error initializing [%s]: %s", mod.name, tostring(err)))
                end
            else
                mod.initialized = true
            end
        end
    end
end
