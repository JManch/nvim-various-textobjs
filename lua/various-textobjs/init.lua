local M = {}

local charwise = require("various-textobjs.charwise-textobjs")

local lookForwardSmall = 5

---Subword
---@param inner boolean outer includes trailing -_
function M.subword(inner) charwise.subword(inner) end

---number textobj
---@param inner boolean inner number consists purely of digits, outer number factors in decimal points and includes minus sign
function M.number(inner) charwise.number(inner, lookForwardSmall) end

return M
