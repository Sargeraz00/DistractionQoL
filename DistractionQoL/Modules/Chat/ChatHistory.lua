-- ChatHistory.lua
-- Dedicated command and chat history recall module with Arrow Up / Arrow Down
-- Fast, event-driven, zero polling, zero continuous OnUpdate
-- Persists command history (/m, /reload, macros, trade ads) across sessions and reloads

local addonName, DQ = ...

DQ.ChatHistory = {}

local MAX_HISTORY_DEFAULT = 30
local hookedBoxes = {}

local function GetHistoryTable()
    if not DistractionQoLDB then
        DistractionQoLDB = {}
    end
    if not DistractionQoLDB.chatHistory then
        DistractionQoLDB.chatHistory = {}
    end
    return DistractionQoLDB.chatHistory
end

-- Adds a new entry to the front of the circular history buffer
function DQ.ChatHistory:AddEntry(text)
    if not text or type(text) ~= "string" then return end
    -- Trim whitespace
    local trimmed = text:match("^%s*(.-)%s*$")
    if not trimmed or trimmed == "" then return end

    local history = GetHistoryTable()
    local maxEntries = (DQ.Config and DQ.Config:Get("chat", "historySize")) or MAX_HISTORY_DEFAULT

    -- Prevent duplicate consecutive entries
    if history[1] == trimmed then
        return
    end

    -- If entry already exists further in history, remove it to push to top
    for i = 2, math.min(#history, 15) do
        if history[i] == trimmed then
            table.remove(history, i)
            break
        end
    end

    table.insert(history, 1, trimmed)

    -- Trim buffer to max capacity
    while #history > maxEntries do
        table.remove(history)
    end
end

-- Retrieves next or previous history entry based on delta (+1 for older, -1 for newer)
function DQ.ChatHistory:GetNext(editBox, delta)
    local history = GetHistoryTable()
    if #history == 0 then return nil end

    local currentIdx = editBox._DQHistoryIndex or 0

    if currentIdx == 0 and delta > 0 then
        -- Save what the user had currently typed before cycling
        editBox._DQSavedText = editBox:GetText() or ""
    end

    local newIdx = currentIdx + delta
    if newIdx > #history then
        newIdx = #history
    end

    if newIdx < 1 then
        editBox._DQHistoryIndex = 0
        return nil
    end

    editBox._DQHistoryIndex = newIdx
    return history[newIdx]
end

-- Hooks a chat edit box safely
function DQ.ChatHistory:HookEditBox(editBox)
    if not editBox or hookedBoxes[editBox] then return end
    hookedBoxes[editBox] = true

    editBox._DQHistoryIndex = 0

    editBox:HookScript("OnKeyDown", function(self, key)
        if key == "ENTER" or key == "NUMPADENTER" then
            local text = self:GetText()
            if text and text:match("%S") then
                DQ.ChatHistory:AddEntry(text)
            end
            self._DQHistoryIndex = 0
            self._DQSavedText = nil
            return
        end

        if key == "ESCAPE" then
            self._DQHistoryIndex = 0
            self._DQSavedText = nil
            return
        end

        if key ~= "UP" and key ~= "DOWN" then return end
        if IsAltKeyDown() or IsControlKeyDown() or IsShiftKeyDown() then return end

        local text = self:GetText() or ""
        local cursorPos = (self.GetCursorPosition and self:GetCursorPosition()) or 0

        if key == "UP" then
            -- Trigger if box is empty, or already cycling history, or cursor is at beginning
            if text == "" or (self._DQHistoryIndex and self._DQHistoryIndex > 0) or cursorPos == 0 then
                local entry = DQ.ChatHistory:GetNext(self, 1)
                if entry then
                    self:SetText(entry)
                    if self.SetCursorPosition then
                        self:SetCursorPosition(#entry)
                    end
                end
            end
        elseif key == "DOWN" then
            if self._DQHistoryIndex and self._DQHistoryIndex > 0 then
                local entry = DQ.ChatHistory:GetNext(self, -1)
                if entry then
                    self:SetText(entry)
                    if self.SetCursorPosition then
                        self:SetCursorPosition(#entry)
                    end
                else
                    self:SetText(self._DQSavedText or "")
                    if self.SetCursorPosition then
                        self:SetCursorPosition(#(self._DQSavedText or ""))
                    end
                    self._DQHistoryIndex = 0
                end
            end
        end
    end)

    editBox:HookScript("OnEditFocusLost", function(self)
        self._DQHistoryIndex = 0
    end)
end

-- Initializes hooks across all active and future chat edit boxes
function DQ.ChatHistory:Init()
    -- Hook standard Blizzard Chat Frame EditBoxes (1 to 10)
    for i = 1, 10 do
        local eb = _G["ChatFrame" .. i .. "EditBox"]
        if eb then
            self:HookEditBox(eb)
        end
    end

    -- Hook active edit box if opened later
    hooksecurefunc("ChatEdit_GetActiveWindow", function()
        local active = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
        if active then
            DQ.ChatHistory:HookEditBox(active)
        end
    end)
end
