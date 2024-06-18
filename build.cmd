@echo off
setlocal enabledelayedexpansion

where /Q cl.exe || (
  set __VSCMD_ARG_NO_LOGO=1
  for /f "tokens=*" %%i in ('"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -property installationPath') do set VS=%%i
  if "!VS!" equ "" (
    echo ERROR: Visual Studio installation not found
    exit /b 1
  )  
  call "!VS!\VC\Auxiliary\Build\vcvarsall.bat" amd64 || exit /b 1
)

if "%VSCMD_ARG_TGT_ARCH%" neq "x64" (
  echo ERROR: please run this from MSVC x64 native tools command prompt, 32-bit target is not supported!
  exit /b 1
)

if "%1" equ "debug" (
  set CL=/MTd /Od /Zi /D_DEBUG /RTC1 /Fdwcap.pdb /fsanitize=address
  set LINK=/DEBUG
) else (
  set CL=/GL /O1 /DNDEBUG /GS-
  set LINK=/LTCG /OPT:REF /OPT:ICF ucrt.lib libvcruntime.lib
)

call :fxc Resize
call :fxc ConvertSimple
call :fxc ConvertPass1
call :fxc ConvertPass2
call :fxc PrepareLookup8
call :fxc PrepareLookup16

rc.exe /nologo wcap.rc
cl.exe /nologo /W3 /WX /MP *.c /Fewcap.exe wcap.res /link /INCREMENTAL:NO /MANIFEST:EMBED /MANIFESTINPUT:wcap.manifest /SUBSYSTEM:WINDOWS /FIXED /merge:_RDATA=.rdata
del *.obj *.res >nul

goto :eof

:fxc
set FXC=/O3 /WX /Qstrip_reflect /Qstrip_debug /Qstrip_priv
fxc.exe /nologo %FXC% /T cs_5_0 /E %1 /Fo wcap_shader_%1.dxbc /Fc wcap_shader_%1.asm wcap_shaders.hlsl
fxc.exe /nologo /compress /Vn %1ShaderBytes /Fo wcap_shader_%1.dcs /Fh wcap_shader_%1.h wcap_shader_%1.dxbc
goto :eof
