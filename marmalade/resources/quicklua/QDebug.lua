--------------------------------------------------------------------------------
-- Debug functions
--------------------------------------------------------------------------------

-- From http://lua-users.org/wiki/OptimisationCodingTips
function clAssert(condition, ...)
   if not condition then
      if next({...}) then
         local s,r = pcall(function (...) return(string.format(...)) end, ...)
         if s then
            error("assertion failed!: " .. r, 2)
         end
      end
      error("assertion failed!", 2)
   end
end

