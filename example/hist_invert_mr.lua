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
destdbname = string.format("hist_dest_mr.kch#apow=0#opts=sl#bnum=%d#msiz=0", rnum)
destdb:open(destdbname, kc.DB.OWRITER + kc.DB.OCREATE + kc.DB.OTRUNCATE)

mapcount = 0
function map(key, value, emit)
   mapcount = mapcount + 1
   local id = kc.unpack("N", key)[1]
   local stamps = kc.unpack("N*", value)
   for i = 1, #stamps do
      local pkey = kc.pack("N", stamps[i])
      emit(pkey, key)
   end
   if mapcount % 10000 == 0 then
      print(string.format("[map]  count=%d  mem=%.3f  time=%.3f",
                          mapcount, memoryusage() - musage, kc.time() - ctime))
   end
   return true
end

redcount = 0
function reduce(key, iter)
   redcount = redcount + 1
   local id = kc.unpack("N", key)[1]
   local stamps = {}
   while true do
      local value = iter()
      if not value then break end
      table.insert(stamps, kc.unpack("N", value)[1])
   end
   local value = kc.pack("N*", stamps)
   destdb:set(key, value)
   if redcount % 10000 == 0 then
      print(string.format("[reduce]  count=%d  mem=%.3f  time=%.3f",
                          redcount, memoryusage() - musage, kc.time() - ctime))
   end
   return true
end

function log(name, message)
   print(string.format("[%s]  %s", name, message))
   return true
end

srcdb:mapreduce(map, reduce, ".", kc.DB.XNOLOCK, 8, 64 * 1024 * 1024, -1, log)
print(string.format("[end]  mem=%.3f  time=%.3f",
                    memoryusage() - musage, kc.time() - ctime))

destdb:close()
srcdb:close()
