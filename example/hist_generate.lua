kc = require("kyotocabinet")

function memoryusage()
   local fh = io.open("/proc/self/status")
   if fh then
      for line in fh:lines() do
         if string.find(line, "VmRSS:") == 1 then
            local num = string.gsub(line, "%w+:%s*(%d+).*", "%1")
            return tonumber(num) / 1024
         end
      end
      fh:close()
   end
end
musage = memoryusage()
ctime = kc.time()

rnum = 1000000
hnum = 100
db = kc.DB:new()
dbname = string.format("hist_src.kch#apow=0#fpow=0#opts=sl#bnum=%d#msiz=1g", rnum)
db:open(dbname, kc.DB.OWRITER + kc.DB.OCREATE + kc.DB.OTRUNCATE)

for id = 1, rnum do
   local stamps = {}
   for i = 1, hnum do
      local stamp = math.floor(math.random() * rnum / (math.random() + 1))
      table.insert(stamps, stamp)
   end
   local key = kc.pack("N", id)
   local value = kc.pack("N*", stamps)
   db:set(key, value)
   if id % 10000 == 0 then
      print(string.format("[write]  count=%d  mem=%.3f  time=%.3f",
                          id, memoryusage() - musage, kc.time() - ctime))
   end
end
print(string.format("[end]  mem=%.3f  time=%.3f",
                    memoryusage() - musage, kc.time() - ctime))

db:close()
