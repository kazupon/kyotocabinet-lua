kc = require("kyotocabinet")

-- create the database object
db = kc.DB:new()

-- open the database
if not db:open("casket.kch", kc.DB.OREADER) then
   print("open error: " .. tostring(db:error()))
end

-- define the visitor
VisitorImpl = {}
function VisitorImpl:new()
   local obj = {}
   function obj:visit_full(key, value)
      print(key .. ":" .. value)
      return kc.Visitor.NOP
   end
   function obj:visit_empty(key)
      print(key .. " is missing")
      return kc.Visitor.NOP
   end
   local base = kc.Visitor:new()
   setmetatable(obj, { __index = base})
   return obj
end
visitor = VisitorImpl:new()

-- retrieve a record with visitor
if not db:accept("foo", visitor, false) or
   not db:accept("dummy", visitor, false) then
   print("accept error: " .. tostring(db:error()))
end

-- traverse records with visitor
if not db:iterate(visitor, false) then
   print("iterate error: " .. tostring(db:error()))
end

-- close the database
if not db:close() then
   print("close error: " .. tostring(db:error()))
end
