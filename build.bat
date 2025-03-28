@echo off
echo Creating build directory...
if not exist build mkdir build
if not exist build\win mkdir build\win

echo Creating game.love...
if exist build\game.love del build\game.love

echo Packaging game files...
cd build
powershell -command "Compress-Archive -Path ..\*.lua, ..\src, ..\assets -DestinationPath game.zip -Force"
rename game.zip game.love

echo Creating Windows executable...
:: Copy LÖVE files (assuming LÖVE is installed in Program Files)
copy "C:\Program Files\LOVE\*.dll" win\
copy "C:\Program Files\LOVE\love.exe" win\

:: Combine love.exe and game.love into a single executable
copy /b "C:\Program Files\LOVE\love.exe"+game.love win\FoodTruckJourney.exe

echo Done! Created:
echo - build\game.love
echo - build\win\FoodTruckJourney.exe

echo Done! Created build\game.love
