@echo off
echo Building Odin - Freya

setlocal
cd %~dp0
odin build . -out:target/freya.exe --debug

echo Build Done