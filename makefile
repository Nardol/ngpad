EXENAME=NGPad
COMMON_DEFINES=$(options) _UNICODE WXUSINGDLL NOPCH
COMMON_STRING_DEFINES=EXT_DLL=\"$(EXT_DLL)\"

HOST_LUA?=lua
VERSION_MAJOR=$(shell $(HOST_LUA) -e "print(os.date('%Y')+0)" 2>/dev/null || date +%Y)
VERSION_MINOR=$(shell $(HOST_LUA) -e "print(os.date('%m')+0)" 2>/dev/null || date +%-m)
VERSION_BUILD_MAJOR=$(shell $(HOST_LUA) -e "print(os.date('%d')+0)" 2>/dev/null || date +%-d)
VERSION_BUILD_MINOR=$(shell $(HOST_LUA) -e "print(os.date('%H')+0)" 2>/dev/null || date +%-H)
VERSION_STRING=$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_BUILD_MAJOR)
VERSION_DEFINES=VERSION_MAJOR=$(VERSION_MAJOR) VERSION_MINOR=$(VERSION_MINOR) VERSION_BUILD_MAJOR=$(VERSION_BUILD_MAJOR) VERSION_BUILD_MINOR=$(VERSION_BUILD_MINOR) VERSION_STRING=\"$(VERSION_STRING)\"

ifeq ($(OS),Windows_NT)
PLATFORM=windows
EXT_EXE=.exe
EXT_DLL=.dll
DEFINES=$(COMMON_DEFINES) HAVE_W32API_H __WXMSW__
CXX=g++
WINDRES=windres
MKDIR_P=mkdir.exe -p
WINDRESFLAGS=-c 65001 $(addprefix -D,$(DEFINES)) $(addprefix -D,$(VERSION_DEFINES)) -I"$(CPATH)"
CXXFLAGS=-std=gnu++17 -Wextra $(addprefix -D,$(DEFINES)) $(addprefix -D,$(COMMON_STRING_DEFINES)) $(addprefix -D,$(VERSION_DEFINES)) -mthreads
LDFLAGS=-L. -lpcre2-8 -lpcre2-16 -lwxbase33u$(NAME_SUFFIX) -lwxmsw33u$(NAME_SUFFIX)_core -lwxmsw33u$(NAME_SUFFIX)_aui -lwxbase33u$(NAME_SUFFIX)_xml -lwxbase33u$(NAME_SUFFIX)_net -lwxmsw33u$(NAME_SUFFIX)_webview -lwxmsw33u$(NAME_SUFFIX)_stc -lfmt -lole32 -loleaut32 -loleacc -llua -ltidy -mthreads -mwindows -Wl,--allow-multiple-definition
RCSRCS=$(wildcard src/app/*.rc)
else
PLATFORM=linux
EXT_EXE=
EXT_DLL=.so
DEFINES=$(COMMON_DEFINES)
CXX?=g++
WX_CONFIG?=wx-config
PKG_CONFIG?=pkg-config
MKDIR_P=mkdir -p
WX_COMPONENTS=std,aui,xml,net,webview,stc
PCRE2_CFLAGS=$(shell $(PKG_CONFIG) --cflags libpcre2-8 2>/dev/null) $(shell $(PKG_CONFIG) --cflags libpcre2-16 2>/dev/null)
PCRE2_LIBS?=$(shell $(PKG_CONFIG) --libs libpcre2-8 2>/dev/null || echo -lpcre2-8) $(shell $(PKG_CONFIG) --libs libpcre2-16 2>/dev/null || echo -lpcre2-16)
LUA_CFLAGS?=$(shell $(PKG_CONFIG) --cflags lua5.4 2>/dev/null)
LUA_LIBS?=$(shell $(PKG_CONFIG) --libs lua5.4 2>/dev/null || echo -llua5.4)
FMT_CFLAGS?=$(shell $(PKG_CONFIG) --cflags fmt 2>/dev/null)
FMT_LIBS?=-lfmt
TIDY_CFLAGS?=$(shell $(PKG_CONFIG) --cflags tidy 2>/dev/null)
TIDY_LIBS?=-ltidy
NLOHMANN_CFLAGS?=$(shell $(PKG_CONFIG) --cflags nlohmann_json 2>/dev/null)
CXXFLAGS=-std=gnu++17 -Wextra $(addprefix -D,$(DEFINES)) $(addprefix -D,$(COMMON_STRING_DEFINES)) $(addprefix -D,$(VERSION_DEFINES)) $(shell $(WX_CONFIG) --cxxflags) $(PCRE2_CFLAGS) $(LUA_CFLAGS) $(FMT_CFLAGS) $(TIDY_CFLAGS) $(NLOHMANN_CFLAGS)
LDFLAGS=$(shell $(WX_CONFIG) --libs $(WX_COMPONENTS)) $(PCRE2_LIBS) $(LUA_LIBS) $(FMT_LIBS) $(TIDY_LIBS) -ldl -Wl,--export-dynamic
RCSRCS=
endif
EXTRA_EXCLUDED_SRCS?=

ifeq ($(mode),release)
NAME_SUFFIX=
DEFINES += RELEASE
CXXOPTFLAGS=-s -O3
else
NAME_SUFFIX=d
DEFINES += DEBUG
CXXOPTFLAGS=-g
endif

EXECUTABLE=$(EXENAME)$(NAME_SUFFIX)$(EXT_EXE)
OBJDIR=obj$(NAME_SUFFIX)-$(PLATFORM)/

SRCS=$(filter-out $(EXTRA_EXCLUDED_SRCS),$(wildcard src/common/*.cpp) $(wildcard src/app/*.cpp) $(wildcard src/console/*.cpp) $(wildcard src/text/*.cpp) $(wildcard src/lua/binding/*.cpp) $(wildcard src/lua/app/*.cpp))
MDSRCS=$(wildcard doc/*.md)
OBJS=$(addprefix $(OBJDIR),$(SRCS:.cpp=.o))
RCOBJS=$(addprefix $(OBJDIR)rsrc/,$(RCSRCS:.rc=.o))
MDOBJS=$(MDSRCS:.md=.html)
PERCENT=%

all: $(EXECUTABLE)

.PHONY: $(EXECUTABLE) clean distclean

clean:
	rm -rf $(OBJDIR)

distclean:
	rm -rf obj-linux/ objd-linux/ obj-windows/ objd-windows/ $(EXENAME) $(EXENAME)d $(EXENAME).exe $(EXENAME)d.exe

doc: $(MDOBJS) doc/scripting-reference.md

$(EXECUTABLE): $(RCOBJS) $(OBJS)
	$(CXX) $(CXXFLAGS) $(CXXOPTFLAGS) -o $@ $^ $(LDFLAGS)

$(OBJDIR)%.o: %.cpp $(wildcard %.hpp)
	$(MKDIR_P) $(dir $@)
	$(CXX) $(CXXFLAGS) $(CXXOPTFLAGS) -c -o $@ $<

$(OBJDIR)rsrc/%.o: %.rc
	$(MKDIR_P) $(dir $@)
	$(WINDRES) $(WINDRESFLAGS) -o $@ $<

doc/scripting-reference.md: gendoc.lua doc/scripting-reference.mdg $(SRCS)
	lua gendoc.lua $^ $@

doc/%.html: doc/%.md
	pandoc -t html5 -f gfm --standalone -o $@ $<
