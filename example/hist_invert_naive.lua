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

srcdb = kc.DB:new()
srcdbname = string.format("hist_src.kch#msiz=0")
srcdb:open(srcdbname, kc.DB.OREADER)
rnum = srcdb:count()

destdb = kc.DB:new()
destdbname = string.format("hist_dest_naive.kch#apow=0#opts=sl#bnum=%d#msiz=0", rnum)
destdb:open(destdbname, kc.DB.OWRITER + kc.DB.OCREATE + kc.DB.OTRUNCATE)

count = 0
cache = {}
csiz = 0
function visit(key, value)
   count = count + 1
   local id = kc.unpack("N", key)[1]
   local stamps = kc.unpack("N*", value)
   for i = 1, #stamps do
      local pkey = kc.pack("N", stamps[i])
      local old = cache[pkey]
      if not old then old = "" end
      local value = old .. key
      cache[pkey] = value
   end
   if count % 10000 == 0 then
      print(string.format("[read]  count=%d  mem=%.3f  time=%.3f",
                          count, memoryusage() - musage, kc.time() - ctime))
   end
   return kc.Visitor.NOP
end

srcdb:iterate(visit, false)

for key, value in pairs(cache) do
   destdb:append(key, value)
end
print(string.format("[end]  mem=%.3f  time=%.3f",
                    memoryusage() - musage, kc.time() - ctime))

srcdb:close()
