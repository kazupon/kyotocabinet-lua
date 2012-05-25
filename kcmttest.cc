/*************************************************************************************************
 * The test cases of the Lua binding
 *                                                               Copyright (C) 2009-2010 FAL Labs
 * This file is part of Kyoto Cabinet.
 * This program is free software: you can redistribute it and/or modify it under the terms of
 * the GNU General Public License as published by the Free Software Foundation, either version
 * 3 of the License, or any later version.
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with this program.
 * If not, see <http://www.gnu.org/licenses/>.
 *************************************************************************************************/


#include <kcpolydb.h>

namespace kc = kyotocabinet;

extern "C" {

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

const int32_t THREADMAX = 128;


// global variables
const char* g_progname;                  // program name
uint32_t g_randseed;                     // random seed


// function prototypes
int main(int argc, char** argv);
static void usage();
static void eprintf(const char* format, ...);
static void dbmetaprint(kc::PolyDB* db);
static int32_t runorder(int argc, char** argv);
static int32_t procorder(const char* path, const char* script,
                         int64_t rnum, int32_t thnum, bool rnd, bool etc);


// main routine
int main(int argc, char** argv) {
  g_progname = argv[0];
  const char* ebuf = kc::getenv("KCRNDSEED");
  g_randseed = ebuf ? (uint32_t)kc::atoi(ebuf) : (uint32_t)(kc::time() * 1000);
  std::srand(g_randseed);
  if (argc < 2) usage();
  int32_t rv = 0;
  if (!std::strcmp(argv[1], "order")) {
    rv = runorder(argc, argv);
  } else {
    usage();
  }
  if (rv != 0) {
    std::printf("FAILED: KCRNDSEED=%u PID=%ld", g_randseed, (long)kc::getpid());
    for (int32_t i = 0; i < argc; i++) {
      std::printf(" %s", argv[i]);
    }
    std::printf("\n\n");
  }
  return rv;
}


// print the usage and exit
static void usage() {
  std::printf("%s: multi-thread test of the Lua binding\n", g_progname);
  std::printf("\n");
  std::printf("  %s order [-th num] [-rnd] [-etc] path script rnum\n", g_progname);
  std::printf("\n");
  std::exit(1);
}


// print formatted error string and flush the buffer
static void eprintf(const char* format, ...) {
  std::string msg;
  va_list ap;
  va_start(ap, format);
  kc::strprintf(&msg, "%s: ", g_progname);
  kc::strprintf(&msg, format, ap);
  kc::strprintf(&msg, "\n");
  va_end(ap);
  std::cerr << msg;
  std::cerr.flush();
}


// print members of a database
static void dbmetaprint(kc::PolyDB* db) {
  std::printf("count: %lld\n", (long long)db->count());
  std::printf("size: %lld\n", (long long)db->size());
}


// parse arguments of order command
static int32_t runorder(int argc, char** argv) {
  const char* path = NULL;
  const char* script = NULL;
  const char* rstr = NULL;
  int32_t thnum = 1;
  bool rnd = false;
  bool etc = false;
  for (int32_t i = 2; i < argc; i++) {
    if (!path && argv[i][0] == '-') {
      if (!std::strcmp(argv[i], "-th")) {
        if (++i >= argc) usage();
        thnum = kc::atoix(argv[i]);
      } else if (!std::strcmp(argv[i], "-rnd")) {
        rnd = true;
      } else if (!std::strcmp(argv[i], "-etc")) {
        etc = true;
      } else {
        usage();
      }
    } else if (!path) {
      path = argv[i];
    } else if (!script) {
      script = argv[i];
    } else if (!rstr) {
      rstr = argv[i];
    } else {
      usage();
    }
  }
  if (!path || !script || !rstr) usage();
  int64_t rnum = kc::atoix(rstr);
  if (rnum < 1 || thnum < 1) usage();
  if (thnum > THREADMAX) thnum = THREADMAX;
  int32_t rv = procorder(path, script, rnum, thnum, rnd, etc);
  return rv;
}


// perform order command
static int32_t procorder(const char* path, const char* script,
                         int64_t rnum, int32_t thnum, bool rnd, bool etc) {
  std::printf("<In-order Test>\n  seed=%u  path=%s  script=%s"
              "  rnum=%lld  thnum=%d  rnd=%d  etc=%d\n\n",
              g_randseed, path, script, (long long)rnum, thnum, rnd, etc);
  bool err = false;
  kc::PolyDB db;
  std::printf("opening the database:\n");
  double stime = kc::time();
  if (!db.open(path, kc::PolyDB::OWRITER | kc::PolyDB::OCREATE | kc::PolyDB::OTRUNCATE)) {
    kc::PolyDB::Error e = db.error();
    eprintf("open error: %d: %s: %s", e.code(), e.name(), e.message());
    err = true;
  }
  double etime = kc::time();
  dbmetaprint(&db);
  std::printf("time: %.3f\n", etime - stime);
  class ThreadImpl : public kc::Thread {
  public:
    ThreadImpl() :
      id_(0), script_(NULL), db_(NULL), rnum_(0), thnum_(0),
      rnd_(false), etc_(false), func_(NULL), err_(false) {}
    void setparams(int32_t id, const char* script, kc::PolyDB* db, int64_t rnum, int32_t thnum,
                   bool rnd, bool etc, const char* func) {
      id_ = id;
      script_ = script;
      db_ = db;
      rnum_ = rnum;
      thnum_ = thnum;
      rnd_ = rnd;
      etc_ = etc;
      func_ = func;
    }
    bool error() {
      return err_;
    }
    void run() {
      lua_State* lua = luaL_newstate();
      if (lua) {
        luaL_openlibs(lua);
        lua_pushstring(lua, g_progname);
        lua_setglobal(lua, "_progname");
        lua_pushinteger(lua, id_);
        lua_setglobal(lua, "_id");
        lua_pushlightuserdata(lua, db_);
        lua_setglobal(lua, "_db_ptr");
        lua_pushnumber(lua, rnum_);
        lua_setglobal(lua, "_rnum");
        lua_pushinteger(lua, thnum_);
        lua_setglobal(lua, "_thnum");
        lua_pushboolean(lua, rnd_);
        lua_setglobal(lua, "_rnd");
        lua_pushboolean(lua, etc_);
        lua_setglobal(lua, "_etc");
        int32_t luaerr = luaL_loadfile(lua, script_);
        if (luaerr == 0) {
          if (lua_pcall(lua, 0, 0, 0) == 0) {
            lua_settop(lua, 0);
            lua_getglobal(lua, func_);
            if (lua_pcall(lua, 0, 0, 0) != 0) {
              const char* msg = lua_tostring(lua, -1);
              eprintf("Lua error: %s", msg ? msg : "(nil)");
              err_ = true;
            }
          } else {
            const char* msg = lua_tostring(lua, -1);
            eprintf("Lua error: %s", msg ? msg : "(nil)");
            err_ = true;
          }
        } else if (luaerr == LUA_ERRFILE) {
          eprintf("opening the script file failed");
          err_ = true;
        }
      } else {
        eprintf("loading the Lua processor failed");
        err_ = true;
      }
      lua_close(lua);
    }
    int32_t id_;
    const char* script_;
    kc::PolyDB* db_;
    int64_t rnum_;
    int32_t thnum_;
    bool rnd_;
    bool etc_;
    const char* func_;
    bool err_;
  };
  ThreadImpl threads[THREADMAX];
  std::printf("setting records:\n");
  stime = kc::time();
  for (int32_t i = 0; i < thnum; i++) {
    threads[i].setparams(i, script, &db, rnum, thnum, rnd, etc, "procset");
    threads[i].start();
  }
  for (int32_t i = 0; i < thnum; i++) {
    threads[i].join();
    if (threads[i].error()) err = true;
  }
  etime = kc::time();
  dbmetaprint(&db);
  std::printf("time: %.3f\n", etime - stime);
  if (etc) {
    std::printf("adding records:\n");
    stime = kc::time();
    for (int32_t i = 0; i < thnum; i++) {
      threads[i].setparams(i, script, &db, rnum, thnum, rnd, etc, "procadd");
      threads[i].start();
    }
    for (int32_t i = 0; i < thnum; i++) {
      threads[i].join();
      if (threads[i].error()) err = true;
    }
    etime = kc::time();
    dbmetaprint(&db);
    std::printf("time: %.3f\n", etime - stime);
  }
  if (etc) {
    std::printf("appending records:\n");
    stime = kc::time();
    for (int32_t i = 0; i < thnum; i++) {
      threads[i].setparams(i, script, &db, rnum, thnum, rnd, etc, "procappend");
      threads[i].start();
    }
    for (int32_t i = 0; i < thnum; i++) {
      threads[i].join();
      if (threads[i].error()) err = true;
    }
    etime = kc::time();
    dbmetaprint(&db);
    std::printf("time: %.3f\n", etime - stime);
  }
  if (etc) {
    std::printf("accepting visitors:\n");
    stime = kc::time();
    for (int32_t i = 0; i < thnum; i++) {
      threads[i].setparams(i, script, &db, rnum, thnum, rnd, etc, "procaccept");
      threads[i].start();
    }
    for (int32_t i = 0; i < thnum; i++) {
      threads[i].join();
      if (threads[i].error()) err = true;
    }
    etime = kc::time();
    dbmetaprint(&db);
    std::printf("time: %.3f\n", etime - stime);
  }
  std::printf("getting records:\n");
  stime = kc::time();
  for (int32_t i = 0; i < thnum; i++) {
    threads[i].setparams(i, script, &db, rnum, thnum, rnd, etc, "procget");
    threads[i].start();
  }
  for (int32_t i = 0; i < thnum; i++) {
    threads[i].join();
    if (threads[i].error()) err = true;
  }
  etime = kc::time();
  dbmetaprint(&db);
  std::printf("time: %.3f\n", etime - stime);
  if (etc) {
    std::printf("traversing the database by the inner iterator:\n");
    stime = kc::time();
    for (int32_t i = 0; i < thnum; i++) {
      threads[i].setparams(i, script, &db, rnum, thnum, rnd, etc, "prociter");
      threads[i].start();
    }
    for (int32_t i = 0; i < thnum; i++) {
      threads[i].join();
      if (threads[i].error()) err = true;
    }
    etime = kc::time();
    dbmetaprint(&db);
    std::printf("time: %.3f\n", etime - stime);
  }
  if (etc) {
    std::printf("traversing the database by the outer cursor:\n");
    stime = kc::time();
    for (int32_t i = 0; i < thnum; i++) {
      threads[i].setparams(i, script, &db, rnum, thnum, rnd, etc, "proccur");
      threads[i].start();
    }
    for (int32_t i = 0; i < thnum; i++) {
      threads[i].join();
      if (threads[i].error()) err = true;
    }
    etime = kc::time();
    dbmetaprint(&db);
    std::printf("time: %.3f\n", etime - stime);
  }
  std::printf("removing records:\n");
  stime = kc::time();
  for (int32_t i = 0; i < thnum; i++) {
    threads[i].setparams(i, script, &db, rnum, thnum, rnd, etc, "procremove");
    threads[i].start();
  }
  for (int32_t i = 0; i < thnum; i++) {
    threads[i].join();
    if (threads[i].error()) err = true;
  }
  etime = kc::time();
  dbmetaprint(&db);
  std::printf("time: %.3f\n", etime - stime);
  if (!db.close()) {
    kc::PolyDB::Error e = db.error();
    eprintf("close error: %d: %s: %s", e.code(), e.name(), e.message());
    err = true;
  }
  std::printf("%s\n\n", err ? "error" : "ok");
  return err ? 1 : 0;
}


}


// END OF FILE
