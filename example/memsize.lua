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
rnum = 1000000;
if #arg > 0 then
   rnum = tonumber(arg[1])
end

if #arg > 1 then
   hash = kc.DB:new()
   if not hash:open(arg[2], kc.DB.OWRITER + kc.DB.OCREATE + kc.DB.OTRUNCATE) then
      error("open failed")
   end
else
   hash = {}
end

stime = kc.time()
for i = 1, rnum do
  local key = string.format("%08d", i)
  local value = string.format("%08d", i)
  hash[key] = value
end
etime = kc.time()

print(string.format("Time: %.3f sec.", etime - stime))
print(string.format("Usage: %.3f MB", memoryusage() - musage))
