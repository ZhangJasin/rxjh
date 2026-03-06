@echo off
echo 程序文件更新前，确保服务器已停止服务。更新目录“D:\MirRXJH”！
echo 默认更新到“D:\MirRXJH”，如果是其他盘，请使用鼠标右键，
echo 点击该文件，然后点编辑，修改里面的路径
pause
set WSDir=D:\MirRXJH
Copy Mir200\M2Server.exe %WSDir%\Mir200\ /y
Copy Mir200\M2Server.map %WSDir%\Mir200\ /y
Copy Mir200\lua5.4.0.dll %WSDir%\Mir200\ /y
Copy Mir200\mimalloc.dll %WSDir%\Mir200\ /y
Copy Mir200\mimalloc-redirect.dll %WSDir%\Mir200\ /y
Copy Mir200\cjson.dll %WSDir%\Mir200\ /y
Copy Mir200\libcrypto-3-x64.dll %WSDir%\Mir200\ /y
Copy Mir200\libmysql.dll %WSDir%\Mir200\ /y
Copy Mir200\libssl-3-x64.dll %WSDir%\Mir200\ /y
Copy DBServer\DBServer.exe %WSDir%\DBServer\ /y
Copy DBServer\DBServer.map %WSDir%\DBServer\ /y
Copy DBServer\libcrypto-3-x64.dll %WSDir%\DBServer\ /y
Copy DBServer\libmysql.dll %WSDir%\DBServer\ /y
Copy DBServer\libssl-3-x64.dll %WSDir%\DBServer\ /y
Copy DBServer\FastMM_FullDebugMode64.dll %WSDir%\DBServer\ /y
Copy LoginGate\LoginGate.exe %WSDir%\LoginGate\ /y
Copy LoginGate\libcrypto-1_1.dll %WSDir%\LoginGate\ /y
Copy LoginGate\libssl-1_1.dll %WSDir%\LoginGate\ /y
Copy LoginGate\wslib.dll %WSDir%\LoginGate\ /y
Copy LoginGate\wslib_x64.dll %WSDir%\LoginGate\ /y
Copy RunGate\RunGate.exe %WSDir%\RunGate\ /y
Copy RunGate\RunGate.map %WSDir%\RunGate\ /y
Copy RunGate\cmsgpack.dll %WSDir%\RunGate\ /y
Copy RunGate\liblz4.dll %WSDir%\RunGate\ /y
Copy RunGate\mimalloc.dll %WSDir%\RunGate\ /y
Copy RunGate\mimalloc-redirect.dll %WSDir%\RunGate\ /y
Copy JMySql.exe %WSDir%\ /y
Copy libcrypto-3-x64.dll %WSDir%\ /y
Copy libmysql.dll %WSDir%\ /y
Copy libssl-3-x64.dll %WSDir%\ /y
Copy GameCenter.exe %WSDir%\ /y
echo 程序文件文件已更新完成. . .
pause