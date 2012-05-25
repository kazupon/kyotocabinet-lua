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


-- preamble
db = kc.DB:new(_db_ptr)
io.stdout:setvbuf("no")
min = _id * _rnum + 1
max = min + _rnum - 1
range = _rnum * _thnum


-- print the error message of the database
function errprint(func)
   local err = db:error()
   print(string.format("%s: %s: %d: %s: %s",
                       _progname, func, err:code(), err:name(), err:message()))
end


-- set records
function procset()
   local err = false
   for i = min, max do
      local key = string.format("%08d", _rnd and math.random(range) or i)
      if not db:set(key, key) then
         errprint("DB::set")
         err = true
         break
      end
      if _id == 0 and max > 250 and i % (max / 250) == 0 then
         io.write(".")
         if i % (max / 10) == 0 then
            print(string.format(" (%08d)", i))
         end
      end
   end
   return not err
end


-- add records
function procadd()
   local err = false
   for i = min, max do
      local key = string.format("%08d", _rnd and math.random(range) or i)
      if not db:add(key, key) and db:error():code() ~= kc.Error.DUPREC then
         errprint("DB::add")
         err = true
         break
      end
      if _id == 0 and max > 250 and i % (max / 250) == 0 then
         io.write(".")
         if i % (max / 10) == 0 then
            print(string.format(" (%08d)", i))
         end
      end
   end
   return not err
end


-- append records
function procappend()
   local err = false
   for i = min, max do
      local key = string.format("%08d", _rnd and math.random(range) or i)
      if not db:append(key, key) then
         errprint("DB::append")
         err = true
         break
      end
      if _id == 0 and max > 250 and i % (max / 250) == 0 then
         io.write(".")
         if i % (max / 10) == 0 then
            print(string.format(" (%08d)", i))
         end
      end
   end
   return not err
end


-- accept visitors
function procaccept()
   local err = false
   local cnt = 0
   local function visit(key, value)
      cnt = cnt + 1
      local rv = kc.Visitor.NOP
      if _rnd then
         local num = math.random(7)
         if num == 1 then
            rv = tostring(cnt)
         elseif num == 2 then
            rv = kc.Visitor.REMOVE
         end
      end
      return rv
   end
   for i = min, max do
      local key = string.format("%08d", _rnd and math.random(range) or i)
      if not db:accept(key, visit, _rnd) then
         errprint("DB::append")
         err = true
         break
      end
      if _id == 0 and max > 250 and i % (max / 250) == 0 then
         io.write(".")
         if i % (max / 10) == 0 then
            print(string.format(" (%08d)", i))
         end
      end
   end
   return not err
end


-- get records
function procget()
   local err = false
   for i = min, max do
      local key = string.format("%08d", _rnd and math.random(range) or i)
      if not db:get(key) and db:error():code() ~= kc.Error.NOREC then
         errprint("DB::get")
         err = true
         break
      end
      if _id == 0 and max > 250 and i % (max / 250) == 0 then
         io.write(".")
         if i % (max / 10) == 0 then
            print(string.format(" (%08d)", i))
         end
      end
   end
   return not err
end


-- traverse the database by the inner iterator
function prociter()
   local err = false
   local cnt = 0
   local function visit(key, value)
      cnt = cnt + 1
      local rv = kc.Visitor.NOP
      if _rnd then
         local num = math.random(7)
         if num == 1 then
            rv = tostring(cnt) .. tostring(cnt)
         elseif num == 2 then
            rv = kc.Visitor.REMOVE
         end
      end
      if _id == 0 and max > 250 and cnt % (max / 250) == 0 then
         io.write(".")
         if cnt % (max / 10) == 0 then
            print(string.format(" (%08d)", cnt))
         end
      end
      return rv
   end
   if not db:iterate(visit, _rnd) then
      errprint(db, "DB::iterate")
      err = true
   end
   if _id == 0 and _rnd then print(" (end)") end
   return not err
end


-- traverse the database by the outer cursor
function proccur()
   local err = false
   local cnt = 0
   local function visit(key, value)
      cnt = cnt + 1
      local rv = kc.Visitor.NOP
      if _rnd then
         local num = math.random(7)
         if num == 1 then
            rv = tostring(cnt) .. tostring(cnt)
         elseif num == 2 then
            rv = kc.Visitor.REMOVE
         end
      end
      if _id == 0 and max > 250 and cnt % (max / 250) == 0 then
         io.write(".")
         if cnt % (max / 10) == 0 then
            print(string.format(" (%08d)", cnt))
         end
      end
      return rv
   end
   local cur = db:cursor()
   if not cur:jump() and db:error():code() ~= kc.Error.NOREC then
      errprint("Cursor::jump")
      err = true
   end
   while cur:accept(visit, _rnd, false) do
      if not cur:step() and db:error():code() ~= kc.Error.NOREC then
         dberrprint(db, "Cursor::step")
         err = true
      end
   end
   if db:error():code() ~= kc.Error.NOREC then
      dberrprint(db, "Cursor::accept")
      err = true
   end
   if not _rnd or math.random(2) == 1 then cur:disable() end
   if _id == 0 and _rnd then print(" (end)") end
   return not err
end


-- remove records
function procremove()
   local err = false
   for i = min, max do
      local key = string.format("%08d", _rnd and math.random(range) or i)
      if not db:remove(key) and db:error():code() ~= kc.Error.NOREC then
         errprint("DB::get")
         err = true
         break
      end
      if _id == 0 and max > 250 and i % (max / 250) == 0 then
         io.write(".")
         if i % (max / 10) == 0 then
            print(string.format(" (%08d)", i))
         end
      end
   end
   return not err
end



-- END OF FILE
