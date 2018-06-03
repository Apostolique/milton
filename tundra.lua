

Build {
    Env = {
        CPPPATH = { "third_party",
            "third_party/imgui",
            {"third_party/SDL2-2.0.3/include"; Config = { "win*", "macos" }},
            "src"
        },
        CXXOPTS = { }
    },

    Units = function()
        require "tundra.syntax.files"

        local shadergen = Program {
            Name = "shadergen",
            Sources = { "src/shadergen.cc" },
            Pass = "CodeGeneration",
        },
        DefRule {
            Name = "ShaderGen",
            Command = "$(SHADERGEN_BIN)",
            ImplicitInputs = { "$(SHADERGEN_BIN)",
                "src/common.glsl" ,
                "src/exporter_rect.f.glsl" ,
                "src/layer_blend.v.glsl" ,
                "src/layer_blend.f.glsl" ,
                "src/outline.v.glsl",
                "src/outline.f.glsl",
                "src/picker.v.glsl",
                "src/picker.f.glsl",
                "src/quad.v.glsl",
                "src/quad.f.glsl",
                "src/simple.v.glsl",
                "src/simple.f.glsl",
                "src/stroke_raster.v.glsl",
                "src/stroke_raster.f.glsl",
                "src/texture_fill.v.glsl" ,
                "src/texture_fill.f.glsl" ,
                "src/postproc.f.glsl" ,
                "src/blur.f.glsl" ,
                "third_party/Fxaa3_11.f.glsl"
            },

            Pass = "CodeGeneration",
            Blueprint = {
                Input = { Type = "string", Required = true },
            },
            ConfigInvariant = true,
            Setup = function(env, data)
                return {
                    InputFiles = { data.Input },
                    OutputFiles = { "src/shaders.gen.h" }
                }
            end,
        },
        DefRule {
            Name = "ResourceFile",
            Command = "$(RC) $(OBJECTROOT)$(SEP)$(BUILD_ID)$(SEP)Milton.rc ",
            ImplicitInputs = "$(OBJECTROOT)$(SEP)$(BUILD_ID)$(SEP)Milton.rc",
            Blueprint = {
                Input = { Type = "string", Required = true },
            },
            Setup = function(env, data)
                return {
                    InputFiles = { data.Input },
                    OutputFiles = { "$(OBJECTROOT)$(SEP)$(BUILD_ID)$(SEP)Milton.res" }
                }
            end,
        }
        local copyRC = CopyFile { Source="Milton.rc", Target="$(OBJECTROOT)$(SEP)$(BUILD_ID)$(SEP)/Milton.rc" }

        local milton = Program {
            Name = "Milton",
            Sources = {
                "src/StrokeList.cc",
                "src/canvas.cc",
                "src/color.cc",
                "src/gl_helpers.cc",
                "src/gui.cc",
                "src/localization.cc",
                "src/memory.cc",
                "src/milton.cc",
                "src/persist.cc",
                "src/profiler.cc",
                "src/renderer.cc",
                "src/sdl_milton.cc",
                "src/utils.cc",
                "src/vector.cc",
                {"src/platform_windows.cc"; Config = { "win*" }},
                {"src/platform_unix.cc"; Config = { "linux-*", "macos" }},
                {"src/platform_linux.cc"; Config = { "linux-*" }},
                {"src/platform_mac.cc"; Config = { "macos" }},
                {"src/platform_mac_gui.mm"; Config = { "macos" }},
                "src/third_party_libs.cc",

                { ResourceFile { Input="Milton.rc" }; Config="win*" },
                ShaderGen { Input = "src/shadergen.cc" },
            },
            Libs = {
                { "kernel32.lib"; Config = { "win*-*-*" } },
                { "OpenGL32.lib"; Config = { "win*" } },
                { "User32.lib"; Config = { "win*" } },
                { "gdi32.lib"; Config = { "win*" } },
                { "shell32.lib"; Config = { "win*" } },
                { "comdlg32.lib"; Config = { "win*" } },
                { "ole32.lib"; Config = { "win*" } },
                { "oleAut32.lib"; Config = { "win*" } },
                { "third_party/bin/SDL2.lib"; Config = { "win*" } },
                { "SDL2"; Config = "macos" },
                { "GL"; Config = "linux-*-*"},
                --, "Xi", "m", "c"
                { "m"; Config = "linux-*-*"},
                { "Xi"; Config = "linux-*-*"},
                { "stdc++"; Config = "linux-*-*"},
                { "c++"; Config = "macos"},
            },
            LibPaths = {
                { "third_party/build"; Config = "macos" },
            },
            Frameworks = {
                "Carbon",
                "Cocoa",
                "ForceFeedback",
                "IOKit",
                "OpenGL",
            },
            Depends = { copyRC }
        }

        local copyIcon = CopyFile { Source="milton_icon.ico", Target="$(OBJECTROOT)$(SEP)$(BUILD_ID)$(SEP)/milton_icon.ico" }
        local copyFont = CopyFile { Source="third_party/Carlito.ttf", Target="$(OBJECTROOT)$(SEP)$(BUILD_ID)$(SEP)/Carlito.ttf" }
        local copyFontLicense= CopyFile { Source="third_party/Carlito.LICENSE", Target="$(OBJECTROOT)$(SEP)$(BUILD_ID)$(SEP)/Carlito.LICENSE" }

        Default(copyRC)
        Default(copyIcon)
        Default(copyFont)
        Default(copyFontLicense)
        Default(milton)
    end,
    Passes = {
        CodeGeneration = { Name="Generate Code", BuildOrder=1 }
    },
    Configs = {
        Config {
            Name = "win64-msvc",
            DefaultOnHost = "windows",
            Tools = { {"msvc-vs2015"; TargetArch = "x64"} },
            Config = { "Debug" },
            Env = {
                CPPDEFS = "_CRT_SECURE_NO_WARNINGS",
                CXXOPTS = { "/Wall", "/EHsc", "/Zi", "/Oi", "/Od", "/WX", "/Gm-", "/GR-",
                    -- Define
                    -- Comment for cleanup
                    "/wd4100", "/wd4189", "/wd4800", "/wd4127", "/wd4239", "/wd4987",
                    -- Disabled warnings
                    "/wd4305", "/wd4820", "/wd4255", "/wd4710", "/wd4711", "/wd4201", "/wd4204", "/wd4191", "/wd5027", "/wd4514", "/wd4242", "/wd4244", "/wd4738", "/wd4619", "/wd4505", "/wd4365"
                },
                SHADERGEN_BIN = "$(OBJECTROOT)$(SEP)$(BUILD_ID)$(SEP)shadergen.exe",
                PROGOPTS = "/DEBUG /SAFESEH:NO",
            },
            ReplaceEnv = {
                OBJECTROOT = "build",
            },
        },
        Config {
            Name = "linux-clang",
            DefaultOnHost = "linux",
            Tools = { "clang" },
            Env = {
                CXXOPTS = {
                    "-std=c++11",
                    "`pkg-config --cflags sdl2 gtk+-2.0`",
                    "-Wno-missing-braces",
                    "-Wno-unused-function",
                    "-Wno-unused-variable",
                    "-Wno-unused-result",
                    "-Wno-write-strings",
                    "-Wno-c++11-compat-deprecated-writable-strings",
                    "-Wno-null-dereference",
                    "-Wno-format",
                    "-fno-strict-aliasing",
                    "-fno-omit-frame-pointer",
                    "-Werror",
                    "-O0",
                    "-g",
                },
                PROGOPTS = {
                    "`pkg-config --libs sdl2 gtk+-2.0`",
                },
                SHADERGEN_BIN = "./$(OBJECTROOT)$(SEP)$(BUILD_ID)$(SEP)shadergen",
            },
            ReplaceEnv = {
                OBJECTROOT = "build",
            },
        },
        Config {
            Name = "macos-clang",
            DefaultOnHost = "macosx",
            Tools = { "clang-osx" },
            Env = {
                CXXOPTS = {
                    "-std=c++11",
                    "-Wno-missing-braces",
                    "-Wno-unused-function",
                    "-Wno-unused-variable",
                    "-Wno-unused-result",
                    "-Wno-write-strings",
                    "-Wno-c++11-compat-deprecated-writable-strings",
                    "-Wno-null-dereference",
                    "-Wno-format",
                    "-fno-strict-aliasing",
                    "-fno-omit-frame-pointer",
                    "-Wno-extern-c-compat",
                    "-Werror",
                    "-O0",
                    "-g",
                    "-fobjc-arc"
                },
                SHADERGEN_BIN = "./$(OBJECTROOT)$(SEP)$(BUILD_ID)$(SEP)shadergen",
            },
            ReplaceEnv = {
                OBJECTROOT = "build",
            },
        }
    },
}
