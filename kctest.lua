#! /usr/bin/lua

--------------------------------------------------------------------------------------------------
-- The test cases of the Lua binding
--                                                               Copyright (C) 2009-2010 FAL Labs
-- This file is part of Kyoto Cabinet.
-- This program is free software: you can redistribute it and/or modify it under the terms of
-- the GNU General Public License as published by the Free Software Foundation, either version
-- 3 of the License, or any later version.
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-- See the GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License along with this program.
-- If not, see <http://www.gnu.org/licenses/>.
--------------------------------------------------------------------------------------------------


kc = require("kyotocabinet")


-- main routine
function main()
   if #arg < 1 then usage() end
   local rv
   if arg[1] == "order" then
      rv = runorder()
   elseif arg[1] == "wicked" then
      rv = runwicked()
   elseif arg[1] == "misc" then
      rv = runmisc()
   else
      usage()
   end
   collectgarbage("collect")
   return rv
end


-- print the usage and exit
function usage()
   printf("%s: test cases of the Lua binding\n", progname)
   printf("\n")
   printf("usage:\n")
   printf("  %s order [-rnd] [-etc] path rnum\n", progname)
   printf("  %s wicked [-it num] path rnum\n", progname)
   printf("  %s misc path\n", progname)
   printf("\n")
   os.exit(1)
end


-- perform formatted output
function printf(format, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p)
   if type(a) ~= "number" then a = tostring(a) end
   if type(b) ~= "number" then b = tostring(b) end
   if type(c) ~= "number" then c = tostring(c) end
   if type(d) ~= "number" then d = tostring(d) end
   if type(e) ~= "number" then e = tostring(e) end
   if type(f) ~= "number" then f = tostring(f) end
   if type(g) ~= "number" then g = tostring(g) end
   if type(h) ~= "number" then h = tostring(h) end
   if type(i) ~= "number" then i = tostring(i) end
   if type(j) ~= "number" then j = tostring(j) end
   if type(k) ~= "number" then k = tostring(k) end
   if type(l) ~= "number" then l = tostring(l) end
   if type(m) ~= "number" then m = tostring(m) end
   if type(n) ~= "number" then n = tostring(n) end
   if type(o) ~= "number" then o = tostring(o) end
   if type(p) ~= "number" then p = tostring(p) end
   io.stdout:write(string.format(format, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o, p))
end


-- print the error message of the database
function dberrprint(db, func)
   local err = db:error()
   printf("%s: %s: %s: %s: %s\n", progname, func, err:code(), err:name(), err:message())
end


-- print members of a database
function dbmetaprint(db, verbose)
   if verbose then
      local status = db:status()
      if status then
         for key, value in pairs(status) do
            printf("%s: %s\n", key, value)
         end
      end
   else
      printf("count: %d\n", db:count())
      printf("size: %d\n", db:size())
   end
end


-- parse arguments of order command
function runorder()
   local path = nil
   local rnum = nil
   local rnd = false
   local etc = false
   local i = 2
   while i <= #arg do
      if not path and string.match(arg[i], "^-") then
         if arg[i] == "-rnd" then
            rnd = true
         elseif arg[i] == "-etc" then
            etc = true
         else
            usage()
         end
      elseif not path then
         path = arg[i]
      elseif not rnum then
         rnum = tonumber(arg[i])
      else
         usage()
      end
      i = i + 1
   end
   if not path or not rnum or rnum < 1 then usage() end
   local rv = procorder(path, rnum, rnd, etc)
   return rv
end


-- parse arguments of wicked command
function runwicked()
   local path = nil
   local rnum = nil
   local itnum = 1
   local i = 2
   while i <= #arg do
      if not path and string.match(arg[i], "^-") then
         if arg[i] == "-it" then
            i = i + 1
            if i > #arg then usage() end
            itnum = tonumber(arg[i])
         else
            usage()
         end
      elseif not path then
         path = arg[i]
      elseif not rnum then
         rnum = tonumber(arg[i])
      else
         usage()
      end
      i = i + 1
   end
   if not path or not rnum or rnum < 1 or not itnum or itnum < 1 then usage() end
   local rv = procwicked(path, rnum, itnum)
   return rv
end


-- parse arguments of misc command
function runmisc()
   local path = nil
   local i = 2
   while i <= #arg do
      if not path and string.match(arg[i], "^-") then
         if arg[i] == "-it" then
            i = i + 1
            if i > #arg then usage() end
            itnum = tonumber(arg[i])
         else
            usage()
         end
      elseif not path then
         path = arg[i]
      else
         usage()
      end
      i = i + 1
   end
   if not path then usage() end
   local rv = procmisc(path)
   return rv
end


-- perform write command
function procorder(path, rnum, rnd, etc)
   printf("<In-order Test>\n  path=%s  rnum=%d  rnd=%s  etc=%s\n\n", path, rnum, rnd, etc)
   local err = false
   local db = kc.DB:new()
   printf("opening the database:\n")
   local stime = kc.time()
   if not db:open(path, kc.DB.OWRITER + kc.DB.OCREATE + kc.DB.OTRUNCATE) then
      dberrprint(db, "DB::open")
      err = true
   end
   local etime = kc.time()
   printf("time: %.3f\n", etime - stime)
   printf("setting records:\n")
   stime = kc.time()
   for i = 1, rnum do
      if err then break end
      local key = string.format("%08d", rnd and math.random(rnum) or i)
      if not db:set(key, key) then
         dberrprint(db, "DB::set")
         err = true
      end
      if rnum > 250 and i % (rnum / 250) == 0 then
         printf(".")
         if i == rnum or i % (rnum / 10) == 0 then
            printf(" (%08d)\n", i)
         end
      end
   end
   etime = kc.time()
   dbmetaprint(db, false)
   printf("time: %.3f\n", etime - stime)
   if etc then
      printf("adding records:\n")
      stime = kc.time()
      for i = 1, rnum do
         if err then break end
         local key = string.format("%08d", rnd and math.random(rnum) or i)
         if not db:add(key, key) and db:error():code() ~= kc.Error.DUPREC then
            dberrprint(db, "DB::add")
            err = true
         end
         if rnum > 250 and i % (rnum / 250) == 0 then
            printf(".")
            if i == rnum or i % (rnum / 10) == 0 then
               printf(" (%08d)\n", i)
            end
         end
      end
      etime = kc.time()
      dbmetaprint(db, false)
      printf("time: %.3f\n", etime - stime)
   end
   if etc then
      printf("appending records:\n")
      stime = kc.time()
      for i = 1, rnum do
         if err then break end
         local key = string.format("%08d", rnd and math.random(rnum) or i)
         if not db:append(key, key) then
            dberrprint(db, "DB::append")
            err = true
         end
         if rnum > 250 and i % (rnum / 250) == 0 then
            printf(".")
            if i == rnum or i % (rnum / 10) == 0 then
               printf(" (%08d)\n", i)
            end
         end
      end
      etime = kc.time()
      dbmetaprint(db, false)
      printf("time: %.3f\n", etime - stime)
   end
   if etc then
      printf("accepting visitors:\n")
      stime = kc.time()
      local cnt = 0
      local function visit(key, value)
         cnt = cnt + 1
         local rv = kc.Visitor.NOP
         if rnd then
            local num = math.random(7)
            if num == 1 then
               rv = tostring(cnt)
            elseif num == 2 then
               rv = kc.Visitor.REMOVE
            end
         end
         return rv
      end
      for i = 1, rnum do
         if err then break end
         local key = string.format("%08d", rnd and math.random(rnum) or i)
         if not db:accept(key, visit, rnd) then
            dberrprint(db, "DB::append")
            err = true
         end
         if rnum > 250 and i % (rnum / 250) == 0 then
            printf(".")
            if i == rnum or i % (rnum / 10) == 0 then
               printf(" (%08d)\n", i)
            end
         end
      end
      etime = kc.time()
      dbmetaprint(db, false)
      printf("time: %.3f\n", etime - stime)
   end
   printf("getting records:\n")
   stime = kc.time()
   for i = 1, rnum do
      if err then break end
      local key = string.format("%08d", rnd and math.random(rnum) or i)
      if not db:get(key) and db:error():code() ~= kc.Error.NOREC then
         dberrprint(db, "DB::get")
         err = true
      end
      if rnum > 250 and i % (rnum / 250) == 0 then
         printf(".")
         if i == rnum or i % (rnum / 10) == 0 then
            printf(" (%08d)\n", i)
         end
      end
   end
   etime = kc.time()
   dbmetaprint(db, false)
   printf("time: %.3f\n", etime - stime)
   if etc then
      printf("traversing the database by the inner iterator:\n")
      stime = kc.time()
      local cnt = 0
      local function visit(key, value)
         cnt = cnt + 1
         local rv = kc.Visitor.NOP
         if rnd then
            local num = math.random(7)
            if num == 1 then
               rv = tostring(cnt) .. tostring(cnt)
            elseif num == 2 then
               rv = kc.Visitor.REMOVE
            end
         end
         if rnum > 250 and cnt % (rnum / 250) == 0 then
            printf(".")
            if cnt == rnum or cnt % (rnum / 10) == 0 then
               printf(" (%08d)\n", cnt)
            end
         end
         return rv
      end
      if not db:iterate(visit, rnd) then
         dberrprint(db, "DB::iterate")
         err = true
      end
      if rnd then printf(" (end)\n") end
      etime = kc.time()
      dbmetaprint(db, false)
      printf("time: %.3f\n", etime - stime)
   end
   if etc then
      printf("traversing the database by the outer cursor:\n")
      stime = kc.time()
      local cnt = 0
      local function visit(key, value)
         cnt = cnt + 1
         local rv = kc.Visitor.NOP
         if rnd then
            local num = math.random(7)
            if num == 1 then
               rv = tostring(cnt) .. tostring(cnt)
            elseif num == 2 then
               rv = kc.Visitor.REMOVE
            end
         end
         if rnum > 250 and cnt % (rnum / 250) == 0 then
            printf(".")
            if cnt == rnum or cnt % (rnum / 10) == 0 then
               printf(" (%08d)\n", cnt)
            end
         end
         return rv
      end
      local cur = db:cursor()
      if not cur:jump() and db:error():code() ~= kc.Error.NOREC then
         dberrprint(db, "Cursor::jump")
         err = true
      end
      while cur:accept(visit, rnd, false) do
         if not cur:step() and db:error():code() ~= kc.Error.NOREC then
            dberrprint(db, "Cursor::step")
            err = true
         end
      end
      if db:error():code() ~= kc.Error.NOREC then
         dberrprint(db, "Cursor::accept")
         err = true
      end
      if not rnd or math.random(2) == 1 then cur:disable() end
      if rnd then printf(" (end)\n") end
      etime = kc.time()
      dbmetaprint(db, false)
      printf("time: %.3f\n", etime - stime)
   end
   printf("removing records:\n")
   stime = kc.time()
   for i = 1, rnum do
      if err then break end
      local key = string.format("%08d", rnd and math.random(rnum) or i)
      if not db:remove(key) and db:error():code() ~= kc.Error.NOREC then
         dberrprint(db, "DB::remove")
         err = true
      end
      if rnum > 250 and i % (rnum / 250) == 0 then
         printf(".")
         if i == rnum or i % (rnum / 10) == 0 then
            printf(" (%08d)\n", i)
         end
      end
   end
   etime = kc.time()
   dbmetaprint(db, true)
   printf("time: %.3f\n", etime - stime)
   printf("closing the database:\n")
   stime = kc.time()
   if not db:close() then
      dberrprint(db, "DB::close")
      err = true
   end
   etime = kc.time()
   printf("time: %.3f\n", etime - stime)
   printf("%s\n\n", err and "error" or "ok")
   return err and 1 or 0
end


-- perform wicked command
function procwicked(path, rnum, itnum)
   printf("<Wicked Test>\n  path=%s  rnum=%d  itnum=%d\n\n", path, rnum, itnum)
   local VisitorImpl = {}
   function VisitorImpl:new(rnd)
      local obj = {}
      obj.cnt = 0
      obj.rnd = rnd
      function obj:visit_full(key, value)
         self.cnt = self.cnt + 1
         local rv = kc.Visitor.NOP
         if self.rnd then
            local num = math.random(7)
            if num == 1 then
               rv = self.cnt
            elseif num == 2 then
               rv = kc.Visitor.REMOVE
            end
         end
         return rv
      end
      function obj:visit_empty(key)
         return self:visit_full(key, key)
      end
      local base = kc.Visitor:new()
      setmetatable(obj, { __index = base })
      return obj
   end
   local err = false
   local db = kc.DB:new()
   for itcnt = 1, itnum do
      if itnum > 1 then printf("iteration %d:\n", itcnt) end
      local stime = kc.time()
      local mode = kc.DB.OWRITER + kc.DB.OCREATE
      if itcnt == 1 then mode = mode + kc.DB.OTRUNCATE end
      if not db:open(path, mode) then
         dberrprint(db, "DB::open")
         err = true
      end
      local cur = db:cursor()
      for i = 1, rnum do
         if err then break end
         local tran = math.random(100) == 1
         if tran and not db:begin_transaction(math.random(rnum) == 1) then
            dberrprint(db, "DB::begin_transaction")
            tran = false
            err = true
         end
         local key = string.format("%08d", math.random(rnum))
         local cmd = math.random(12)
         if cmd == 1 then
            if not db:set(key, key) then
               dberrprint(db, "DB::set")
               err = true
            end
         elseif cmd == 2 then
            if not db:add(key, key) and db:error():code() ~= kc.Error.DUPREC then
               dberrprint(db, "DB::add")
               err = true
            end
         elseif cmd == 3 then
            if not db:replace(key, key) and db:error():code() ~= kc.Error.NOREC then
               dberrprint(db, "DB::replace")
               err = true
            end
         elseif cmd == 4 then
            if not db:append(key, key) then
               dberrprint(db, "DB::append")
               err = true
            end
         elseif cmd == 5 then
            if math.random(2) == 1 then
               local num = math.random(10)
               if not db:increment(key, num) and db:error():code() ~= kc.Error.LOGIC then
                  dberrprint(db, "DB::increment")
                  err = true
               end
            else
               local num = math.random() * 10
               if not db:increment_double(key, num) and db:error():code() ~= kc.Error.LOGIC then
                  dberrprint(db, "DB::increment_double")
                  err = true
               end
            end
         elseif cmd == 6 then
            if not db:cas(key, key, key) and db:error():code() ~= kc.Error.LOGIC then
               dberrprint(db, "DB::cas")
               err = true
            end
         elseif cmd == 7 then
            if not db:remove(key) and db:error():code() ~= kc.Error.NOREC then
               dberrprint(db, "DB::remove")
               err = true
            end
         elseif cmd == 8 then
            local visitor = VisitorImpl:new(1)
            if not db:accept(key, visitor, true) then
               dberrprint(db, "DB::accept")
               err = true
            end
         elseif cmd == 9 then
            if math.random(10) == 1 then
               if math.random(4) == 1 then
                  if not cur:jump_back() and db:error():code() ~= kc.Error.NOIMPL and
                  db:error():code() ~= kc.Error.NOREC then
                     dberrprint(db, "Cursor::jump_back")
                     err = true
                  end
               else
                  if not cur:jump() and db:error():code() ~= kc.Error.NOREC then
                     dberrprint(db, "Cursor::jump")
                     err = true
                  end
               end
            else
               cmd = math.random(6)
               if cmd == 1 then
                  if not cur:get_key() and db:error():code() ~= kc.Error.NOREC then
                     dberrprint(db, "Cursor::get_key")
                     err = true
                  end
               elseif cmd == 2 then
                  if not cur:get_value() and db:error():code() ~= kc.Error.NOREC then
                     dberrprint(db, "Cursor::get_value")
                     err = true
                  end
               elseif cmd == 3 then
                  if not cur:get() and db:error():code() ~= kc.Error.NOREC then
                     dberrprint(db, "Cursor::get")
                     err = true
                  end
               elseif cmd == 4 then
                  if not cur:remove() and db:error():code() ~= kc.Error.NOREC then
                     dberrprint(db, "Cursor::remove")
                     err = true
                  end
               else
                  local visitor = VisitorImpl:new(1)
                  if not cur:accept(visitor, true, math.random(2) == 1) and
                  db:error():code() ~= kc.Error.NOREC then
                     dberrprint(db, "Cursor::accept")
                     err = true
                  end
               end
            end
            if math.random(2) == 1 then
               if not cur:step() and db:error():code() ~= kc.Error.NOREC then
                  dberrprint(db, "Cursor::step")
                  err = true
               end
            end
            if math.random(rnum / 50 + 1) == 1 then
               prefix = string.sub(key, 1, -2)
               if not db:match_prefix(prefix, math.random(10)) then
                  dberrprint(db, "DB::match_prefix")
                  err = true
               end
            end
            if math.random(rnum / 50 + 1) == 1 then
               regex = string.sub(key, 1, -2)
               if not db:match_regex(regex, math.random(10)) and
               db:error():code() ~= kc.Error.LOGIC then
                  dberrprint(db, "DB::match_regex")
                  err = true
               end
            end
            if math.random(rnum / 50 + 1) == 1 then
               origin = string.sub(key, 1, -2)
               if not db:match_similar(origin, 3, math.random(2) == 0, math.random(10)) then
                  dberrprint(db, "DB::match_similar")
                  err = true
               end
            end
         else
            if not db:get(key) and db:error():code() ~= kc.Error.NOREC then
               dberrprint(db, "DB::get")
               err = true
            end
         end
         if tran and not db:end_transaction(math.random(10) > 1) then
            dberrprint(db, "DB::end_transaction")
            err = true
         end
         if rnum > 250 and i % (rnum / 250) == 0 then
            printf(".")
            if i == rnum or i % (rnum / 10) == 0 then
               printf(" (%08d)\n", i)
            end
         end
      end
      cur:disable()
      dbmetaprint(db, itcnt == itnum)
      if not db:close() then
         dberrprint(db, "DB::close")
         err = true
      end
      local etime = kc.time()
      printf("time: %.3f\n", etime - stime)
   end
   printf("%s\n\n", err and "error" or "ok")
   return err and 1 or 0
end


-- perform misc command
function procmisc(path)
   printf("<Miscellaneous Test>\n  path=%s\n\n", path)
   local err = false
   printf("calling utility functions:\n")
   kc.atoi("123.456mikio")
   kc.atoix("123.456mikio")
   kc.atof("123.456mikio")
   kc.hash_murmur(path)
   kc.hash_fnv(path)
   kc.levdist(path, "casket")
   kc.time()
   kc.sleep()
   local str = kc.pack("cCsSiIlLfdnNMi*", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15)
   local ary = kc.unpack("cCsSiIlLfdnNMi*", str)
   if #ary ~= 15 then
      printf("%s: unpack: error\n", progname)
      err = true
   end
   ary = kc.split("hop,step,jump", ",")
   if #ary ~= 3 then
      printf("%s: split: error\n", progname)
      err = true
   end
   kc.codec("url", kc.codec("~url", "%e5%b9%b3%e6%9e%97%e5%b9%b9%e9%9b%84"))
   kc.codec("base", kc.codec("~base", "5bmz5p6X5bm56ZuE"))
   kc.bit("and", 1, 2)
   kc.bit("or", 1, 2)
   kc.strstr("abrakadabra", "abra")
   kc.strstr("abrakadabra", "abra", "XX")
   kc.strfwm("abrakadabra", "abra")
   kc.strbwm("abrakadabra", "abra")
   kc.regex("abrakadabra", "(.)b(.)(a)")
   kc.regex("abrakadabra", "(.)b(.)(a)", "[$1$2$3$4$0]")
   local oary = { "first", "second", 3, 4.4, "five", nil, "six", 777777.0 }
   local astr = kc.arraydump(oary)
   local nary = kc.arrayload(astr)
   local omap = { ["tako"] = "ika", ["uni"] = "kani", ["ebi"] = 3, ["ikura"] = 4.4 }
   local mstr = kc.mapdump(omap)
   local nmap = kc.mapload(mstr)
   local dcurs = {}
   printf("opening the database with functor:\n")
   local function myproc(db)
      tostring(db)
      local rnum = 10000
      printf("setting records:\n")
      for i = 1, rnum do
         db[i] = i
      end
      if db:count() ~= rnum then
         dberrprint(db, "DB::count")
         err = true
      end
      printf("deploying cursors:\n")
      for i = 1, 100 do
         local cur = db:cursor()
         if not cur:jump(i) then
            dberrprint(db, "Cursor::jump")
            err = true
         end
         local num = i % 3
         if num == 0 then
            table.insert(dcurs, cur)
         elseif num == 1 then
            cur:disable()
         end
         tostring(cur)
      end
      printf("getting records:\n")
      for i = 1, #dcurs do
         if not dcurs[i].get_key then
            dberrprint(db, "Cursor::get_key")
            err = true
         end
      end
      printf("accepting visitor:\n")
      local function visitfunc(key, value)
         local rv = kc.Visitor.NOP
         local num = tonumber(key) % 3
         if num == 0 then
            if value then
               rv = "empty:" .. key
            else
               rv = "full:" .. key
            end
         elseif num == 1 then
            rv = kc.Visitor.REMOVE
         end
         return rv
      end
      for i = 0, rnum * 2 do
         if not db:accept(i, visitfunc, true) then
            dberrprint(db, "DB::access")
            err = true
         end
      end
      printf("accepting visitor by iterator:\n")
      if not db:iterate(function (key, value) return nil end, false) then
         dberrprint(db, "DB::iterate")
         err = true
      end
      if not db:iterate(function (key, value) return string.upper(value) end, true) then
         dberrprint(db, "DB::iterate")
         err = true
      end
      printf("accepting visitor with a cursor:\n")
      local cur = db:cursor()
      function curvisitfunc(key, value)
         local rv = kc.Visitor.NOP
         local num = tonumber(key) % 7
         if num == 0 then
            rv = "cur:full:" .. key
         elseif num == 1 then
            rv = kc.Visitor.REMOVE
         end
         return rv
      end
      if cur:jump_back() then
         while cur:accept(curvisitfunc, true) do
            cur:step_back()
         end
      elseif cur:jump() then
         while cur:accept(curvisitfunc, true) do
            cur:step()
         end
      else
         dberrprint(db, "Cursor::jump")
         err = true
      end
      printf("accepting visitor in bulk:\n")
      keys = {}
      for i = 1, 10 do
         table.insert(keys, i)
      end
      if not db:accept_bulk(keys, visitfunc, true) then
         dberrprint(db, "DB::accept_bulk")
         err = true
      end
      recs = {}
      for i = 1, 10 do
         recs[i] = string.format("[%d]", i)
      end
      if db:set_bulk(recs) < 0 then
         dberrprint(db, "DB::set_bulk")
         err = true
      end
      if not db:get_bulk(keys) then
         dberrprint(db, "DB::get_bulk")
         err = true
      end
      if db:remove_bulk(keys) < 0 then
         dberrprint(db, "DB::remove_bulk")
         err = true
      end
      printf("synchronizing the database:\n")
      local FileProcessorImpl = {}
      function FileProcessorImpl:new()
         local obj = {}
         function obj:process(path, count, size)
            return true
         end
         local base = kc.FileProcessor:new()
         setmetatable(obj, { __index = base })
         return obj
      end
      local fproc = FileProcessorImpl:new()
      if not db:synchronize(false, fproc) then
         dberrprint(db, "DB::synchronize")
         err = true
      end
      if not db:synchronize(false, function (path, count, size) return true end) then
         dberrprint(db, "DB::synchronize")
         err = false
      end
      if not db:occupy(false, fproc) then
         dberrprint(db, "DB::occupy")
         err = true
      end
      if not db:occupy(false, function (path, count, size) return true end) then
         dberrprint(db, "DB::occupy")
         err = false
      end
      printf("performing transaction:\n")
      local function commitfunc()
         db["tako"] = "ika"
         return true
      end
      if not db:transaction(commitfunc, false) then
         dberrprint(db, "DB::transaction")
         err = true
      end
      if db["tako"] ~= "ika" then
         dberrprint(db, "DB::transaction")
         err = true
      end
      db["tako"] = nil
      local cnt = db:count()
      local function abortfunc()
         db["tako"] = "ika"
         db["kani"] = "ebi"
         return false
      end
      if not db:transaction(abortfunc, false) then
         dberrprint(db, "DB::transaction")
         err = true
      end
      if db["tako"] or db["kani"] or db:count() ~= cnt then
         dberrprint(db, "DB::transaction")
         err = true
      end
      printf("closing the database:\n")
   end
   local dberr = kc.DB:process(myproc, path, kc.DB.OWRITER + kc.DB.OCREATE + kc.DB.OTRUNCATE)
   if dberr then
      printf("%s: DB::process: %s\n", progname, dberr)
      err = true
   end
   printf("accessing dead cursors:\n")
   for i = 1, #dcurs do
      dcurs[i]:get_key()
   end
   printf("re-opening the database as a reader:\n")
   local db = kc.DB:new()
   if not db:open(path, kc.DB.OREADER) then
      dberrprint(db, "DB::open")
      err = true
   end
   printf("traversing records by iterator:\n")
   local keys = {}
   for key, value in db:pairs() do
      table.insert(keys, key)
   end
   if db:count() ~= #keys then
      dberrprint(db, "DB::count")
      err = true
   end
   printf("checking records:\n")
   for i = 1, #keys do
      if not db:get(keys[i]) then
         dberrprint(db, "DB::get")
         err = true
      end
   end
   printf("closing the database:\n")
   if not db:close() then
      dberrprint(db, "DB::close")
      err = true
   end
   printf("re-opening the database as a writer:\n")
   if not db:open(path, kc.DB.OWRITER) then
      dberrprint(db, "DB::open")
      err = true
   end
   if not db:set("tako", "ika") then
      dberrprint(db, "DB::set")
      err = true
   end
   printf("removing records by cursor:\n")
   local cur = db:cursor()
   if not cur:jump() then
      dberrprint(db, "Cursor::jump")
      err = true
   end
   local cnt = 0
   while true do
      local key = cur:get_key(true)
      if not key then break end
      if cnt % 10 ~= 0 then
         if not db:remove(key) then
            dberrprint(db, "DB::remove")
            err = true
         end
         cnt = cnt + 1
      end
   end
   if db:error():code() ~= kc.Error.NOREC then
      dberrprint(db, "Cursor::get_key")
      err = true
   end
   cur:disable()
   printf("processing a cursor by callback:\n")
   local function curprocfunc(cur)
      if not cur:jump() then
         dberrprint(db, "Cursor::jump")
         err = true
      end
      local value = string.format("[%s]", cur:get_value())
      if not cur:set_value(value) then
         dberrprint(db, "Cursor::set_value")
         err = true
      end
      if cur:get_value() ~= value then
         dberrprint(db, "Cursor::get_value")
         err = true
      end
   end
   db:cursor_process(curprocfunc)
   printf("dumping records into snapshot:\n")
   local snappath = db:path()
   if string.match(snappath, ".*\.kc[ht]$") then
      snappath = snappath .. ".kcss"
   else
      snappath = "kctest.kcss"
   end
   if not db:dump_snapshot(snappath) then
      dberrprint(db, "DB::dump_snapshot")
      err = true
   end
   local cnt = db:count()
   printf("clearing the database:\n")
   if not db:clear() then
      dberrprint(db, "DB::clear")
      err = true
   end
   printf("loading records from snapshot:\n")
   if not db:load_snapshot(snappath) then
      dberrprint(db, "DB::load_snapshot")
      err = true
   end
   if db:count() ~= cnt then
      dberrprint(db, "DB::load_snapshot")
      err = true
   end
   os.remove(snappath)
   local copypath = db:path()
   local suffix = nil
   if string.match(copypath, ".*\.kch$") then
      suffix = ".kch"
   elseif string.match(copypath, ".*\.kct$") then
      suffix = ".kct"
   end
   if suffix then
      printf("performing copy and merge:\n")
      local copypaths = {}
      for i = 1, 2 do
         table.insert(copypaths, string.format("%s.%d%s", copypath, i, suffix))
      end
      local srcary = {}
      for i = 1, #copypaths do
         if not db:copy(copypaths[i]) then
            dberrprint(db, "DB::copy")
            err = true
         end
         local srcdb = kc.DB:new()
         if not srcdb:open(copypaths[i], kc.DB.OREADER) then
            dberrprint(srcdb, "DB::open")
            err = true
         end
         table.insert(srcary, srcdb)
      end
      if not db:merge(srcary, kc.DB.MAPPEND) then
         dberrprint(db, "DB::merge")
         err = true
      end
      for i = 1, #srcary do
         if not srcary[i]:close() then
            dberrprint(srcary[i], "DB::close")
            err = true
         end
      end
      for i = 1, #copypaths do
         os.remove(copypaths[i])
      end
   end
   printf("executing a mapreduce process:\n")
   function map(key, value, emit)
      value = kc.regex(value, "[a-zA-Z][a-zA-Z]*:*", " ")
      values = kc.split(value, " ")
      for i = 1, #values do
         value = values[i]
         if #value > 0 then
            if not emit(value, key) then return false end
         end
      end
      return true
   end
   function reduce(key, iter)
      while true do
         local value = iter()
         if not value then break end
      end
      return true
   end
   local proccnt = 0
   function proc(emit)
      proccnt = proccnt + 1
      if emit then
         return emit("proc", proccnt)
      end
      return true
   end
   if not db:mapreduce(map, reduce, nil, nil, nil, nil, nil, nil, proc) then
      dberrprint(db, "DB::mapreduce")
      err = true
   end
   if proccnt ~= 3 then
      dberrprint(db, "DB::mapreduce")
      err = true
   end
   printf("closing the database:\n")
   if not db:close() then
      dberrprint(db, "DB::close")
      err = true
   end
   tostring(db)
   printf("processing database pointer:\n")
   local ptr = kc.DB:new_ptr()
   if ptr then
      kc.DB:delete_ptr(ptr)
   else
      printf("%s: DB::new_ptr: failed\n", progname)
      err = true
   end
   printf("%s\n\n", err and "error" or "ok")
   return err and 1 or 0
end


-- execute main
io.stdout:setvbuf("no")
progname = string.gsub(arg[0], ".*/", "")
math.randomseed(kc.time() * 1000)
os.exit(main())



-- END OF FILE
