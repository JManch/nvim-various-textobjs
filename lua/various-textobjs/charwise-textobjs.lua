local M = {}
local fn = vim.fn
local u = require("various-textobjs.utils")

---@return boolean
local function isVisualMode()
	local modeWithV = vim.fn.mode():find("v")
	return modeWithV ~= nil
end

---sets the selection for the textobj (characterwise)
---@class pos number[]
---@param startpos pos
---@param endpos pos
local function setSelection(startpos, endpos)
	u.setCursor(0, startpos)
	if isVisualMode() then
		u.normal("o")
	else
		u.normal("v")
	end
	u.setCursor(0, endpos)
end

---Seek and select characterwise text object based on pattern.
---@param pattern string lua pattern. REQUIRED two capture groups marking the two additions for the outer variant of the textobj. Use an empty capture group when there is no difference between inner and outer on that side. (Essentially, the two capture groups work as lookbehind and lookahead.)
---@param inner boolean true = inner textobj
---@param lookForwL integer number of lines to look forward for the textobj
---@return boolean whether textobj search was successful
local function searchTextobj(pattern, inner, lookForwL)
	local cursorRow, cursorCol = unpack(u.getCursor(0))
	local lineContent = u.getline(cursorRow)
	local lastLine = fn.line("$")
	local beginCol = 0
	local endCol, captureG1, captureG2, noneInStartingLine

	-- first line: check if standing on or in front of textobj
	repeat
		beginCol = beginCol + 1
		beginCol, endCol, captureG1, captureG2 = lineContent:find(pattern, beginCol)
		noneInStartingLine = not beginCol
		local standingOnOrInFront = endCol and endCol > cursorCol
	until standingOnOrInFront or noneInStartingLine

	-- subsequent lines: search full line for first occurrence
	local i = 0
	if noneInStartingLine then
		while true do
			i = i + 1
			if i > lookForwL or cursorRow + i > lastLine then
				u.notFoundMsg(lookForwL)
				return false
			end
			lineContent = u.getline(cursorRow + i)

			beginCol, endCol, captureG1, captureG2 = lineContent:find(pattern)
			if beginCol then break end
		end
	end

	-- capture groups determine the inner/outer difference
	-- INFO :find() returns integers of the position if the capture group is empty
	if inner then
		local frontOuterLen = type(captureG1) ~= "number" and #captureG1 or 0
		local backOuterLen = type(captureG2) ~= "number" and #captureG2 or 0
		beginCol = beginCol + frontOuterLen
		endCol = endCol - backOuterLen
	end

	setSelection({ cursorRow + i, beginCol - 1 }, { cursorRow + i, endCol - 1 })
	return true
end

---Subword
---@param inner boolean outer includes trailing -_
function M.subword(inner)
	local pattern = "()%w[%l%d]+([ _-]?)"

	-- adjust pattern when word under cursor is all uppercase to handle
	-- subwords of SCREAMING_SNAKE_CASE variables
	local upperCaseWord = fn.expand("<cword>") == fn.expand("<cword>"):upper()
	if upperCaseWord then pattern = "()[%u%d]+([ _-]?)" end

	-- forward looking results in unexpected behavior for subword
	searchTextobj(pattern, inner, 0)
end

---number textobj
---@param inner boolean inner number consists purely of digits, outer number factors in decimal points and includes minus sign
---@param lookForwL integer number of lines to look forward for the textobj
function M.number(inner, lookForwL)
	-- here two different patterns make more sense, so the inner number can match
	-- before and after the decimal dot. enforcing digital after dot so outer
	-- excludes enumrations.
	local pattern = inner and "%d+" or "%-?%d*%.?%d+"
	searchTextobj(pattern, false, lookForwL)
end

return M
