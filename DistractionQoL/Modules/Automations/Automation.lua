-- Automation.lua
-- Central delegator for Automations modules
-- Maintains backward compatibility while delegating to specialized atomic modules

local addonName, DQ = ...

DQ.Automation = {}

function DQ.Automation:Init()
    if DQ.Vendor and DQ.Vendor.Init then
        DQ.Vendor:Init()
    end
    if DQ.FastLoot and DQ.FastLoot.Init then
        DQ.FastLoot:Init()
    end
    if DQ.Cinematics and DQ.Cinematics.Init then
        DQ.Cinematics:Init()
    end
    if DQ.SafeResurrect and DQ.SafeResurrect.Init then
        DQ.SafeResurrect:Init()
    end
end
