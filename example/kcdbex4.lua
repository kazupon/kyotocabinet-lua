kc = require("kyotocabinet")

-- create the database object
db = kc.DB:new()

-- open the database
if not db:open() then
   print("open error: " .. tostring(db:error()))
end

-- store records
db["1"] = "this is a pen"
db["2"] = "what a beautiful pen this is"
db["3"] = "she is beautiful"

-- define the papper
function map(key, value, emit)
   local values = kc.split(value, " ")
   for i = 1, #values do
      if not emit(values[i], "") then
         return false
      end
   end
   return true
end

-- define the reducer
function reduce(key, iter)
   local count = 0
   while true do
      local value = iter()
      if not value then
         break
      end
      count = count + 1
   end
   print(key .. ": " .. count)
   return true
end

-- execute the MapReduce process
if not db:mapreduce(map, reduce) then
   print("mapreduce error: " .. tostring(db:error()))
end

-- close the database
if not db:close() then
   print("close error: " .. tostring(db:error()))
end
