kc = require("kyotocabinet")

-- define the functor
function dbproc(db)

   -- store records
   db["foo"] = "hop"
   db["bar"] = "step"
   db[3] = "jump"

   -- update records in transaction
   function tranproc()
      db["foo"] = 2.71828
      return true
   end
   db:transaction(tranproc)

   -- multiply a record value
   function mulproc(key, value)
      return tonumber(value) * 2
   end
   db:accept("foo", mulproc)

   -- traverse records by iterator
   for key, value in db:pairs() do
      print(key .. ":" .. value)
   end

   -- upcase values by iterator
   function upproc(key, value)
      return string.upper(value)
   end
   db:iterate(upproc)

   -- traverse records by cursor
   function curproc(cur)
      cur:jump()
      function printproc(key, value)
         print(key .. ":" .. value)
         return Visitor.NOP
      end
      while cur:accept(printproc) do
         cur:step()
      end
   end
   db:cursor_process(curproc)

end

-- process the database by the functor
kc.DB:process(dbproc, "casket.kch")
