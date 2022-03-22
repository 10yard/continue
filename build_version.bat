set version=v0.16

set zip_path="C:\Program Files\7-Zip\7z"
del releases\continue_plugin_%version%.zip

copy readme.md continue\ /Y
%zip_path% a releases\continue_plugin_%version%.zip continue
del continue\readme.md /Q