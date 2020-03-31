NATIVECC ?= cc
NATIVECXX ?= c++
WINDRES ?= windres
PKGCONFIG ?= pkg-config

ASSETS_DIRECTORY = assets

# Default options
FIX_BUGS = 1
BACKEND_RENDERER = SDLTexture
BACKEND_AUDIO = SDL2

ALL_CFLAGS = $(CFLAGS)
ALL_CXXFLAGS = $(CXXFLAGS)
ALL_LDFLAGS = $(LDFLAGS)
ALL_LIBS = $(LIBS)

ifeq ($(WINDOWS), 1)
  EXE_EXTENSION = .exe
endif

ifeq ($(RELEASE), 1)
  ALL_CFLAGS += -O3 -DNDEBUG
  ALL_CXXFLAGS += -O3 -DNDEBUG
  ALL_LDFLAGS += -s
  FILENAME_DEF = CSE2$(EXE_EXTENSION)
else
  ALL_CFLAGS += -Og -ggdb3
  ALL_CXXFLAGS += -Og -ggdb3
  FILENAME_DEF = CSE2_debug$(EXE_EXTENSION)
endif

ifeq ($(JAPANESE), 1)
  BUILD_DIRECTORY = game_japanese

  DEFINES += -DJAPANESE
else
  BUILD_DIRECTORY = game_english
endif

FILENAME ?= $(FILENAME_DEF)

ifeq ($(FIX_BUGS), 1)
  DEFINES += -DFIX_BUGS
endif

ifeq ($(DEBUG_SAVE), 1)
  DEFINES += -DDEBUG_SAVE
endif

ALL_CFLAGS += -std=c99 -MMD -MP -MF $@.d
CSE2_CFLAGS += $(shell $(PKGCONFIG) sdl2 --cflags) $(shell $(PKGCONFIG) freetype2 --cflags)

ALL_CXXFLAGS += -std=c++11 -MMD -MP -MF $@.d
CSE2_CXXFLAGS += $(shell $(PKGCONFIG) sdl2 --cflags) $(shell $(PKGCONFIG) freetype2 --cflags)

ifeq ($(STATIC), 1)
  ALL_LDFLAGS += -static
  CSE2_LIBS += $(shell $(PKGCONFIG) sdl2 --libs --static) $(shell $(PKGCONFIG) freetype2 --libs --static) -lfreetype
else
  CSE2_LIBS += $(shell $(PKGCONFIG) sdl2 --libs) $(shell $(PKGCONFIG) freetype2 --libs)
endif

SOURCES = \
  src/ArmsItem.cpp \
  src/Back.cpp \
  src/Bitmap.cpp \
  src/Boss.cpp \
  src/BossAlmo1.cpp \
  src/BossAlmo2.cpp \
  src/BossBallos.cpp \
  src/BossFrog.cpp \
  src/BossIronH.cpp \
  src/BossLife.cpp \
  src/BossOhm.cpp \
  src/BossPress.cpp \
  src/BossTwinD.cpp \
  src/BossX.cpp \
  src/BulHit.cpp \
  src/Bullet.cpp \
  src/Caret.cpp \
  src/Config.cpp \
  src/Draw.cpp \
  src/Ending.cpp \
  src/Escape.cpp \
  src/Fade.cpp \
  src/File.cpp \
  src/Flags.cpp \
  src/Flash.cpp \
  src/Font.cpp \
  src/Frame.cpp \
  src/Game.cpp \
  src/Generic.cpp \
  src/GenericLoad.cpp \
  src/Input.cpp \
  src/KeyControl.cpp \
  src/Main.cpp \
  src/Map.cpp \
  src/MapName.cpp \
  src/MiniMap.cpp \
  src/MyChar.cpp \
  src/MycHit.cpp \
  src/MycParam.cpp \
  src/NpcAct000.cpp \
  src/NpcAct020.cpp \
  src/NpcAct040.cpp \
  src/NpcAct060.cpp \
  src/NpcAct080.cpp \
  src/NpcAct100.cpp \
  src/NpcAct120.cpp \
  src/NpcAct140.cpp \
  src/NpcAct160.cpp \
  src/NpcAct180.cpp \
  src/NpcAct200.cpp \
  src/NpcAct220.cpp \
  src/NpcAct240.cpp \
  src/NpcAct260.cpp \
  src/NpcAct280.cpp \
  src/NpcAct300.cpp \
  src/NpcAct320.cpp \
  src/NpcAct340.cpp \
  src/NpcAct360.cpp \
  src/NpcAct380.cpp \
  src/NpChar.cpp \
  src/NpcHit.cpp \
  src/NpcTbl.cpp \
  src/Organya.cpp \
  src/Pause.cpp \
  src/PixTone.cpp \
  src/Profile.cpp \
  src/Random.cpp \
  src/Resource.cpp \
  src/SelStage.cpp \
  src/Shoot.cpp \
  src/Sound.cpp \
  src/Stage.cpp \
  src/Star.cpp \
  src/TextScr.cpp \
  src/Triangle.cpp \
  src/ValueView.cpp

ifneq (,$(filter 1,$(AUDIO_OGG)$(AUDIO_FLAC) $(AUDIO_TRACKER) $(AUDIO_PXTONE)))
  SOURCES += \
    src/ExtraSoundFormats.cpp \
    external/clownaudio/src/miniaudio.cpp \
    external/clownaudio/src/mixer.cpp \
    external/clownaudio/src/decoding/decoder_selector.cpp \
    external/clownaudio/src/decoding/predecoder.cpp \
    external/clownaudio/src/decoding/resampled_decoder.cpp \
    external/clownaudio/src/decoding/split_decoder.cpp \
    external/clownaudio/src/decoding/decoders/memory_stream.cpp

  DEFINES += -DEXTRA_SOUND_FORMATS -DCLOWNAUDIO_EXPORT= -DCLOWNAUDIO_NO_EXPORT=

  ALL_CFLAGS += -Iexternal/clownaudio/include
  ALL_CXXFLAGS += -Iexternal/clownaudio/include
endif

ifeq ($(AUDIO_OGG), 1)
  SOURCES += \
    external/clownaudio/src/decoding/decoders/stb_vorbis.cpp

  DEFINES += -DUSE_STB_VORBIS
endif

ifeq ($(AUDIO_FLAC), 1)
  SOURCES += \
    external/clownaudio/src/decoding/decoders/dr_flac.cpp

  DEFINES += -DUSE_DR_FLAC
endif

ifeq ($(AUDIO_TRACKER), 1)
  SOURCES += \
    external/clownaudio/src/decoding/decoders/libxmp-lite.cpp \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/control.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/dataio.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/effects.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/filter.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/format.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/hio.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/lfo.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/load.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/load_helpers.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/memio.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/mix_all.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/mixer.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/period.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/player.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/read_event.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/scan.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/smix.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/virtual.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/loaders/common.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/loaders/it_load.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/loaders/itsex.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/loaders/mod_load.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/loaders/s3m_load.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/loaders/sample.c \
    external/clownaudio/src/decoding/decoders/libs/libxmp-lite/src/loaders/xm_load.c

  DEFINES += -DUSE_LIBXMPLITE -DLIBXMP_CORE_PLAYER=1

  ALL_CFLAGS += -Iexternal/clownaudio/src/decoding/decoders/libs/libxmp-lite/include/libxmp-lite
  ALL_CXXFLAGS += -Iexternal/clownaudio/src/decoding/decoders/libs/libxmp-lite/include/libxmp-lite
endif

ifeq ($(AUDIO_PXTONE), 1)
  SOURCES += \
    external/clownaudio/src/decoding/decoders/pxtone.cpp \
    external/clownaudio/src/decoding/decoders/pxtone_noise.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnDelay.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnDescriptor.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnError.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnEvelist.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnMaster.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnMem.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnOverDrive.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnPulse_Frequency.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnPulse_Noise.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnPulse_NoiseBuilder.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnPulse_Oggv.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnPulse_Oscillator.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnPulse_PCM.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnService.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnService_moo.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnText.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnUnit.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnWoice.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnWoice_io.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtnWoicePTV.cpp \
    external/clownaudio/src/decoding/decoders/libs/pxtone/pxtoneNoise.cpp

  DEFINES += -DUSE_PXTONE
endif

RESOURCES = 

ifneq ($(WINDOWS), 1)
  RESOURCES += ICON/ICON_MINI.png
endif

ifeq ($(BACKEND_RENDERER), OpenGL3)
  SOURCES += src/Backends/Rendering/OpenGL3.cpp external/glad/src/glad.c

  ifeq ($(WINDOWS), 1)
    CSE2_LIBS += -lopengl32
  else
    CSE2_LIBS += -lGL -ldl
  endif
else ifeq ($(BACKEND_RENDERER), OpenGLES2)
  SOURCES += src/Backends/Rendering/OpenGLES2.cpp
  CSE2_CFLAGS += $(shell $(PKGCONFIG) --cflags glesv2)
  CSE2_CXXFLAGS += $(shell $(PKGCONFIG) --cflags glesv2)
  CSE2_LIBS += $(shell $(PKGCONFIG) --libs glesv2)
else ifeq ($(BACKEND_RENDERER), SDLTexture)
  SOURCES += src/Backends/Rendering/SDLTexture.cpp
else ifeq ($(BACKEND_RENDERER), Software)
  SOURCES += src/Backends/Rendering/Software.cpp
else
  $(error Invalid BACKEND_RENDERER selected)
endif

ifeq ($(BACKEND_AUDIO), SDL2)
  SOURCES += src/Backends/Audio/SDL2.cpp src/Backends/Audio/SoftwareMixer.cpp
else ifeq ($(BACKEND_AUDIO), miniaudio)
  SOURCES += src/Backends/Audio/miniaudio.cpp src/Backends/Audio/SoftwareMixer.cpp
  CSE2_LIBS += -lm -lpthread

  ifneq ($(WINDOWS), 1)
    CSE2_LIBS += -ldl
  endif
else
  $(error Invalid BACKEND_AUDIO selected)
endif

OBJECTS = $(addprefix obj/$(FILENAME)/, $(addsuffix .o, $(SOURCES)))
DEPENDENCIES = $(addprefix obj/$(FILENAME)/, $(addsuffix .o.d, $(SOURCES)))

ifeq ($(WINDOWS), 1)
  OBJECTS += obj/$(FILENAME)/windows_resources.o
endif

all: $(BUILD_DIRECTORY)/$(FILENAME)
	$(info Finished)

$(BUILD_DIRECTORY)/$(FILENAME): $(OBJECTS)
	@mkdir -p $(@D)
	$(info Linking $@)
	@$(CXX) $(ALL_CXXFLAGS) $(CSE2_CXXFLAGS) $(ALL_LDFLAGS) $^ -o $@ $(ALL_LIBS) $(CSE2_LIBS)

obj/$(FILENAME)/%.c.o: %.c
	@mkdir -p $(@D)
	$(info Compiling $<)
	@$(CC) $(ALL_CFLAGS) $(CSE2_CFLAGS) $(DEFINES) $< -o $@ -c

obj/$(FILENAME)/%.cpp.o: %.cpp
	@mkdir -p $(@D)
	$(info Compiling $<)
	@$(CXX) $(ALL_CXXFLAGS) $(CSE2_CXXFLAGS) $(DEFINES) $< -o $@ -c

obj/$(FILENAME)/src/Resource.cpp.o: src/Resource.cpp $(addprefix src/Resource/, $(addsuffix .h, $(RESOURCES)))
	@mkdir -p $(@D)
	$(info Compiling $<)
	@$(CXX) $(ALL_CXXFLAGS) $(CSE2_CXXFLAGS) $(DEFINES) $< -o $@ -c

src/Resource/%.h: $(ASSETS_DIRECTORY)/resources/% obj/bin2h
	@mkdir -p $(@D)
	$(info Converting $<)
	@obj/bin2h $< $@

obj/bin2h: bin2h/bin2h.c
	@mkdir -p $(@D)
	$(info Compiling $^)
	@$(NATIVECC) -O3 -s -std=c90 -Wall -Wextra -pedantic $^ -o $@

include $(wildcard $(DEPENDENCIES))

obj/$(FILENAME)/windows_resources.o: $(ASSETS_DIRECTORY)/resources/CSE2.rc $(ASSETS_DIRECTORY)/resources/resource1.h $(ASSETS_DIRECTORY)/resources/afxres.h $(ASSETS_DIRECTORY)/resources/ICON/0.ico
	@mkdir -p $(@D)
	$(info Compiling Windows resource file $<)
	@$(WINDRES) $< $@

# TODO
clean:
	@rm -rf obj
