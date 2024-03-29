fn RunRenderFarmMaxscripts = (
	
	try
	(	
		filein ((getDir #scripts)+ @"\Startup\farmclient\farmclient.ms")
        showSubmitDialog()
	)
	catch
	(
		messagebox "打开菜单失败，请关闭max重启客户端，如未解决请联系客服!\n" beep:false title:"farmclient提醒您"
	)

	
)


fn RegTools reg key =
(
	registry.openKey HKEY_CURRENT_USER reg accessRights:#readOnly key:&keyReg
	if keyReg != undefined then
	(
		registry.queryValue keyReg key value:&pathval
		registry.closeKey keyReg
		pathval
	)
)

-- get app exe path from the regedit 
fn RUN_CLIENT_EXE = (
	MY_CLIENT_EXE = RegTools @"SOFTWARE\FarmClient" @"AppExePath"
    print (MY_CLIENT_EXE)
	if MY_CLIENT_EXE != undefined then
	(
		if DoesFileExist (MY_CLIENT_EXE as string) then
		(
			 shellLaunch MY_CLIENT_EXE ""
		)
	)
	else
	(
		messagebox "客户端安装异常 !\n" beep:false title:"RenderFarm提醒您"
	)
)

rollout RenderFarmAbout "关于RenderFarm" width:530 height:300
(
	local RenderCoolpicture = (getDir #scripts + @"\Startup\farmclient\AboutRenderFarm.png") 
	bitmap the_bmp "" pos:[-2,0] width:540 height:304 enabled:false fileName:RenderCoolpicture
	HyperLink INFO2 "版本号：0.01" pos:[220,240] width:350 height:16  color:(color 150 150 150) address:"http://www.RenderFarm.com/" hovercolor:(color 0 255 255) align:#center
	HyperLink INFO3 "RenderFarmTechnology Co., Ltd." pos:[160,260] width:350 height:16  color:(color 150 150 150) address:"http://www.RenderFarm.com/" hovercolor:(color 0 255 255) align:#center
)

-- max inside UI 
fn createMenu =(

	if (menuMan.findMenu "RenderFarm") != undefined then
	(
		menuMan.unRegisterMenu (menuMan.findMenu "RenderFarm")
	)
	if (menuMan.findMenu "subtask1") != undefined then (
		menuMan.unRegisterMenu (menuMan.findMenu "subtask1")
	)
	if (menuMan.findMenu "viewtask1") != undefined then (
		menuMan.unRegisterMenu (menuMan.findMenu "viewtask1")
	)
	if (menuMan.findMenu "rcabout1") != undefined then (
		menuMan.unRegisterMenu (menuMan.findMenu "rcabout1")
	)
	
	renderfarmMenu = menuMan.getMainMenuBar() 
	macroStr1 = "macroScript subtask1 category:\"farmclient\" buttonText:\"提交任务\" (\n RunRenderFarmMaxscripts() \n)"
	macroStr2 = "macroScript viewtask1 category:\"farmclient\" buttonText:\"查看任务进度\" (\n RUN_CLIENT_EXE() \n)"
	macroStr3 = "macroScript rcabout1 category:\"farmclient\" buttonText:\"关于RenderFarm\" (\n CreateDialog RenderFarmAbout \n)"
	execute macroStr1
	execute macroStr2
	execute macroStr3

	local bigMenu = menuMan.createMenu "RenderFarm"
	renderfarmMenu.addItem (menuMan.createSubMenuItem "bigMenu" bigMenu) (6) 
	for i = 1 to bigMenu.numItems() do bigMenu.removeItem (bigMenu.getItem i)
	bigMenu.addItem (menuMan.createActionItem "subtask1" "farmclient") 1
	bigMenu.addItem (menuMan.createSeparatorItem()) 2
	bigMenu.addItem (menuMan.createActionItem "viewtask1" "farmclient") 3
	bigMenu.addItem (menuMan.createSeparatorItem()) 4
	bigMenu.addItem (menuMan.createActionItem "rcabout1" "farmclient") 5
	menuMan.updateMenuBar()

)

createMenu()
clearlistener()