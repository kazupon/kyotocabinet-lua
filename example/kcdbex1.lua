kc = require("kyotocabinet")

-- create the database object
db = kc.DB:new()

-- open the database
if not db:open("casket.kch", kc.DB.OWRITER + kc.DB.OCREATE) then
   print("open error: " .. tostring(db:error()))
end

-- store records
if not db:set("foo", "hop") or
   not db:set("bar", "step") or
   not db:set("baz", "jump") then
   print("set error: " .. tostring(db:error()))
end

-- retrieve records
value = db:get("foo")
if value then
   print(value)
else
   print("get error: " .. tostring(db:error()))
end

-- traverse records
cur = db:cursor()
cur:jump()
while true do
   local key, value = cur:get(true)
   if not key then break end
   print(key .. ":" .. value)
end
cur:disable()

-- close the database
if not db:close() then
   print("close error: " .. tostring(db:error()))
end
