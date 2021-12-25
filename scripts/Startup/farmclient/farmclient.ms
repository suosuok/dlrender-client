scriptSelfDir = pathConfig.removePathLeaf(getSourceFileName())

global interNet_image = @"https://mirror-hz.oss-cn-hangzhou.aliyuncs.com/logo/ad.jpg"
global local_image = ""
if scriptSelfDir.count == 0 then (
    local version = getMaxVersion()
    scriptSelfDir = "C:\\Program Files\\Autodesk\\3ds Max " + version + "\\scripts\\Startup\\farmclient"
    if not doesFileExist scriptSelfDir then (
        try (
            local maxLongVer = ((maxversion())[1])/1000
            local maxShortVersion = (maxLongVer as string) + ".0"
            local apppath, key, type
            apppath = ""
            registry.openKey HKEY_LOCAL_MACHINE ("SOFTWARE\\Autodesk\\3dsMax\\"+maxShortVersion) accessRights:#readOnly key:&key;
            if key == undefined then (
                return ""
            )
            registry.queryValue key "Installdir" type:&type value:&apppath
            registry.closekey key
            scriptSelfDir = apppath + "scripts\\Startup\\farmclient"
        )catch()
    )
)
scriptSelfDir += "\\"

myIniFilePath = (scriptSelfDir + "setting.ini")
myPluginInBuildVersion = getINISetting myIniFilePath "build" "version"
myAppDataDirName = getINISetting myIniFilePath "clientinfo" "appdatadirname"
myAppFileName = getINISetting myIniFilePath "clientinfo" "appfilename"
myAppRegistryname = getINISetting myIniFilePath "clientinfo" "registryname"
myAppName = getINISetting myIniFilePath "clientinfo" "name"
if myAppName != undefined or myAppName == "" then (
    myAppName = "FarmClient"
)


function check_CRP_in_startup_scripts =
(
    local startup_scripts = getfiles ((getDir #startupScripts) + @"\*.ms")
    local infected_startup_scripts = #()
    local searchFor = "CRP_AScript" + " = \""
    for sf in startup_scripts do
    (
        local f = openfile sf
        local found_CRP = (skipToString f searchFor) != undefined
        close f
        if found_CRP do
            append infected_startup_scripts sf
    )

    return infected_startup_scripts
)

function remove_CRP_callback_globals =
(
    local the_CRP_globals = #(#CRP_AScript, #CRP_BScript, #CRP_WriteAScript, #CRP_WriteBScript)
    local found_CRP_global = false
    for g in the_CRP_globals while (not found_CRP_global) do found_CRP_global = globalVars.isGlobal g
    if found_CRP_global do (
        -- remove the callbacks
        try(callbacks.removeScripts #preRender 			id:#ID_CRP_preRenderP 			)catch()
        try(callbacks.removeScripts #filePostOpen 		id:#ID_CRP_filePostOpenP 			)catch()
        try(callbacks.removeScripts #viewportChange 	id:#ID_CRP_viewportChangeP 	)catch()
        try(callbacks.removeScripts #filePostOpen 		id:#ID_CRP_filePostOpen		 	)catch()
        try(callbacks.removeScripts #filePostMerge 		id:#ID_CRP_filePostMerge 			)catch()
        try(callbacks.removeScripts #postImport 		id:#ID_CRP_postImport 			)catch()
        -- remove the globals
        local the_CRP_globals = #(#CRP_AScript, #CRP_BScript, #CRP_WriteAScript, #CRP_WriteBScript)
        for g in the_CRP_globals do (
            try (persistents.remove g) catch ()
            try (globalVars.remove g) catch ()
        )

        CRP_WriteAScript = undefined
        CRP_WriteBScript = undefined
        CRP_AScript = undefined
        CRP_BScript = undefined
    )
    return found_CRP_global
)

function remove_ALC_startup_scripts =
(
    local ALC_startup_scripts = #()
    local ALC_startup_scripts_delete_failed = #()
    local ALC_scripts = #(@"$userStartupScripts\vrdematcleanbeta.ms", @"$userStartupScripts\vrdematcleanbeta.mse", @"$userStartupScripts\vrdematcleanbeta.msex")
    for f in ALC_scripts do
    (
        if doesFileExist f do
            append ALC_startup_scripts (pathconfig.resolvePathSymbols  f)
    )
    for f in ALC_startup_scripts do (
        local deleteSuccess = deleteFile f
        if not deleteSuccess then (
            append ALC_startup_scripts_delete_failed f
        )
    )
    return #(ALC_startup_scripts, ALC_startup_scripts_delete_failed)
)

fn remove_ALC_callback_globals =
(
    local the_ALC_globals = #(#physXCrtRbkInfoCleanBeta, #checkLicSerSubCleanBeta, #checkLicSerMainCleanBeta, #CleanBetabaseCC64enc,
        #CleanBetabaseCC64dec, #runMainCleanBeta, #PointNodeCleanBeta, #px_HiddenNodeCleanBeta, #getNetUpdateCleanBeta,
        #AutodeskLicSerStuckCleanBeta, #px_SimulatorForModifyCleanBeta, #px_SimulatorForStateCleanBeta, #px_SimulatorSaveCleanBeta)
    local the_ALC_callback_ids= #(#RenderLicCleanBeta,#PhysXCleanBetaRBKSysInfo,#AutodeskLicCleanBeta)
    local the_ALC_node_names= #("", "　","　　", "　　　","　　　　","　　　　　　","　　　　　　　","Rectangles135","","", "\x3000\xe813\xe811", "\xe814\xe812")

    local found_ALC_global = false
    for g in the_ALC_globals while (not found_ALC_global) do found_ALC_global = globalVars.isGlobal g
    if found_ALC_global do
    (
        -- remove the callbacks
        for id in the_ALC_callback_ids do
            try(callbacks.removeScripts id:id)catch()
        -- remove the globals
        for g in the_ALC_globals do globalVars.remove g
    )

    local found_ALC_node = false
    for n in the_ALC_node_names while (not found_ALC_node) do found_ALC_node = (getnodebyname n) != undefined
    if found_ALC_node do
    (
        -- remove the nodes
        for n in the_ALC_node_names do
        (
            local theNodes = getnodebyname n all:true
            for theNode in theNodes do
            (
                with undo off
                (
                    local newPRS = prs()
                    newPRS.value = matrix3 1
                    theNode.controller = newPRS
                    delete theNode
                )
            )
        )
    )

    local scaleScripts = getclassinstances scale_script processAllAnimatables:true
    local numCleaned = 0
    for scaleScript in scaleScripts do
    (
        local expr = scaleScript.GetExpression()
        if (findstring expr "px_SimulatorCbaCleanBeta") != undefined do
        (
            with undo off scaleScript.SetExpression "[1,1,1]"
            numCleaned += 1
        )
    )

    if found_ALC_global or found_ALC_node or numCleaned != 0 then (
        return true
    )
    false
)

function check_virus =
(
    ::CRP_Authorization = true -- turns off changes to scene by CRP script

    local CRP_infected_scripts = check_CRP_in_startup_scripts() -- 需要手工清楚
    local found_CRP_globals = remove_CRP_callback_globals()
    local ALC_remove_result = remove_ALC_startup_scripts()
    local ALC_infected_scripts = ALC_remove_result[1]
    local ALC_infected_scripts_delete_failed = ALC_remove_result[2]  -- 需要手工清楚
    local found_ALC_globals = remove_ALC_callback_globals()

    local msg = ""
    if CRP_infected_scripts.count > 0 or ALC_infected_scripts_delete_failed.count > 0 then (
        msg += "下列文件已经被病毒感染，请关闭3dsmax，在客户端中点击杀毒按钮清除病毒文件，然后重新打开3dsamx提交渲染:\r\n"
        for sf in CRP_infected_scripts do (
            msg += sf
            msg += "\r\n"
        )
        for sf in ALC_infected_scripts_delete_failed do (
            msg += sf
            msg += "\r\n"
        )
    )
    if msg.count > 0 then (
        max file save
        messagebox msg title:myAppName
        return false
    )

    if found_CRP_globals or found_ALC_globals or ALC_infected_scripts.count > 0 then (
        msg = "发现3dsmax病毒，已经清除病毒代码。请确保max文件正确后再提交渲染，以免渲染结果不正确！        \r\n"
        max file save
        messagebox msg title:myAppName
        return true
    )

    true
)

function runapp exepath waitexit args:unsupplied =
(
    try (
        local process = dotNetObject "System.Diagnostics.Process"
        process.StartInfo.UseShellExecute = true
        process.StartInfo.WindowStyle = (dotnetclass "System.Diagnostics.ProcessWindowStyle").Hidden
        process.StartInfo.RedirectStandardOutput = false
        process.StartInfo.RedirectStandardError = false
        process.StartInfo.FileName = exepath
        process.StartInfo.Arguments = ""

        if args != unsupplied and args != undefined then (
            for arg in args do (process.StartInfo.Arguments += (" " + arg as string))
        )

        process.Start()

        local exitcode = 0
        if waitexit then (
            process.WaitForExit()
            exitcode = process.ExitCode
        )

        process.Close()
        process.Dispose()
        return exitcode
    ) catch (
        return 1
    )
)
fn Setformat str =
(
    format "%%%       %\n" "[" localtime "]" str
)
fn runcmd exe_path arg_array:undefined  =
(
    local process = dotNetObject "System.Diagnostics.Process"
    process.StartInfo.CreateNoWindow = true
    process.StartInfo.UseShellExecute = false
    process.StartInfo.RedirectStandardOutput = true
    process.StartInfo.RedirectStandardError = true
    process.StartInfo.FileName = exe_path
    process.StartInfo.Arguments = ""

    if arg_array != undefined then
    (
        for arg in arg_array do (process.StartInfo.Arguments += (" " + arg as string))
    )

    SETFORMAT (exe_path)

    if doesfileexist exe_path then
    (
        try(
            process.Start()
        )catch( messagebox "客户端程序不完整,请联系在线客服！ \n  \n " beep:false  )

        SETFORMAT ( "start cmd\n")
        local cmd_result = ""
        while not process.StandardOutput.EndOfStream do
        (
            local output_line = process.StandardOutput.ReadLine()
            SETFORMAT (output_line)
            --Main_rollout.Sc_prompt_info.caption = ("execute:"+(output_line as string))
            cmd_result=cmd_result+output_line
        )
        process.WaitForExit()
        process.Close()
        process.Dispose()
        cmd_result
    )
    else
    (
        SETFORMAT (exe_path)
        messagebox "客户端程序不完整,请联系在线客服!  \n  \n " beep:false
    )
)

function getTimeString = (
    local t = getLocalTime()
    local str = t[1] as string  + "-" + t[2] as string + "-" + t[4] as string
    str = str + "-" + t[5] as string  + "-" + t[6] as string + "-" + t[7] as string
    str
)

function getMaxFreeSpaceDrive = (
    drives = (dotNetClass "System.IO.DriveInfo").GetDrives()
    drive = ""
    freespace = 0
    DriveTypeFixed = (dotnetclass "System.IO.DriveType").Fixed
    for i=1 to drives.count do (
        if drives[i].IsReady and drives[i].DriveType == DriveTypeFixed then (
            if drives[i].AvailableFreeSpace > freespace then (
                drive = drives[i].Name
                freespace = drives[i].AvailableFreeSpace
            )
        )
    )
    drive
)

function isSystemDriveSpaceOK = (
    strSysDrive = substring sysInfo.systemdir 1 1
    drive = dotNetObject "System.IO.DriveInfo" strSysDrive
    if drive.AvailableFreeSpace < 1073741824*3 then (
        false
    ) else (
        true
    )
)

function getFullPathOfAssets validAssets =
(
    local foundFiles = #()
    local notFoundFiles = #()
    local total = AssetManager.GetNumAssets()
    --format "total assets count: %\n" total
    for i = 1 to total do (
        local asset = AssetManager.GetAssetByIndex i
        if asset == undefined then (
            continue
        )

        local id =  asset.GetAssetId()
        local type = asset.GetType() as string
        local filename = asset.GetFileName()
        local canget = asset.CanGetFullFilePath(filename)
        local fullpath = asset.GetFullFilePath()
        local refcount = AssetManager.GetNumReference(id)
        --format "% % % % % \n" type canget refcount filename fullpath

        if type == "#renderoutput" do (
            continue
        )

        if filename == rendOutputFilename do (
            continue
        )

        if findItem validAssets filename == 0 do (
            --format " not found in valid assets  %\n" filename
            continue
        )

        if not canget then (
            appendIfUnique notFoundFiles filename
            --format " cannot get assets  %\n" filename
            continue
        )

        --print " add"
        appendIfUnique foundFiles fullpath
    )
    return #(foundFiles, notFoundFiles)
)

function getMaxVersion =
(
    local maxvi = (maxversion())[1]
    local maxv = case  maxvi /1000 of
    (
        10: "2008"
        11: "2009"
        12: "2010"
        13: "2011"
        14: "2012"
        15: "2013"
        16: "2014"
        17: "2015"
        18: "2016"
        19: "2017"
        20: "2018"
        21: "2019"
        22: "2020"
        23: "2021"
        24: "2022"
        defult: ""
    )
    maxv
)

function setDefaultVraySetting =
(
    local vr = renderers.current
    try ( rendSaveFile = true) catch()
    try ( rendOutputFilename = "c:\\A-.TGA") catch()
    try ( rendShowVFB = true) catch()
)

function getCoronaRendererVersion checkRenderer =
(
    if checkRenderer then (
        local vr = renderers.current
        if (findstring (vr as string) "V_Ray_") != undefined then (
            return ""
        )
    )

    local version = ""
    try (
        versionMajor = CoronaRenderer.CoronaFp.getVersionMajorNumber()
        versionMinor = CoronaRenderer.CoronaFp.getVersionMinorNumber()
        version = versionMajor as string + "." + versionMinor as string
    ) catch ()
    if version.count == 0 then (
        try (
            version = CoronaRenderer.CoronaFp.getCoronaVersion()
            local end = findString version " "
            if end != undefined then (
                version = substring version 1 (end-1)
            )
            end = findString version ","
            if end != undefined then (
                version = substring version 1 (end-1)
            )
        ) catch ()
    )
    version
)

function getVrayNextVersion =
(
    try (
        local versions = vrayVersion()
        local version = versions[1]
		if version.count > 7 and version[8] == "." then (
			version = substring version 1 7
		)
		return version
    ) catch (
        return "4"
    )
)

function getVrayVersion =
(
    local setVrayVersion = false
    local vr = renderers.current as string

    if (findstring vr "V_Ray_Next") != undefined or (findstring vr "V_Ray_5") != undefined then (
        local ver = getVrayNextVersion()
        return #(ver, false)
    )

    if (findstring vr "V_Ray_Adv_") == undefined then (
        try(
            renderers.current = VRay()
            vr = renderers.current
            setVrayVersion = true
            setDefaultVraySetting()
        ) catch(
            return #("", setVrayVersion)
        )
    )
    if (findstring vr "V_Ray_Adv_") == undefined then (
        return #("", setVrayVersion)
    )

    if vr.count < "V_Ray_Adv_2".count then (
        return #("", setVrayVersion)
    )

    local start = "V_Ray_Adv_".count + 1
    local end = findString vr ":"
    if end == undefined then (
        return #("", setVrayVersion)
    )

    local ver = substring vr start (end-start)
    ver = substituteString ver "_" "."
    return #(ver, setVrayVersion)
)

function saveSceneFile =
(
    sceneName = maxFilePath + maxFileName

    if getMaxVersion() != "2021" or sceneName.count == 0 then (
        max file save
    ) else (
        local result = saveMaxFile(maxFilePath + maxFileName)
        if not result then (
            return false
        )
    )

    sceneName = maxFilePath + maxFileName
    if sceneName.count == 0 then (
        false
    ) else (
        true
    )
)

function getAssetFiles =
(
    local assetFileNames = #()
    local assetFilesCanget = #()
    local total = AssetManager.GetNumAssets()
    for i = 1 to total do (
        local asset = AssetManager.GetAssetByIndex i
        if asset == undefined then (
            continue
        )
        local filename = asset.GetFileName()
        local canget = asset.CanGetFullFilePath(filename)
        append assetFileNames filename
        append assetFilesCanget canget
    )
    return #(assetFileNames,assetFilesCanget)
)

function getRenderElementsFiles =
(
    local rem = maxOps.GetCurRenderElementMgr()
    local count = rem.numrenderelements()
    local elementsFiles = #()
    for i = 0 to (count - 1) do (
        local filename =  (rem.GetRenderElementFileName i)
        append elementsFiles filename
    )
    elementsFiles
)

function isTextureFileExist fullpath assetFileNames assetFilesCanget =
(
    try (
        local filenameNum = findItem assetFileNames fullpath
        if filenameNum > 0 and assetFilesCanget[filenameNum] do(
            return true
        )
        if doesFileExist fullPath then (
            return true
        )
    ) catch ()
	false
)

function getNewFilenameIfExist fullpath assetFileNames assetFilesCanget =
(
    if not isTextureFileExist fullpath assetFileNames assetFilesCanget then (
        return fullpath
    )
    local path =  getFilenamePath fullpath
    local filename = getFilenameFile fullpath
    local ext = getFilenameType fullpath
    for i = 1 to 100 do (
        local newpath = path + filename + "-" + (i as string) + "-" +  ext
        if not isTextureFileExist newpath assetFileNames assetFilesCanget then (
            return newpath
        )
    )
	return fullpath
)

function removeFileNameInvliadChars filename =
(
    filename = substituteString filename "<" ""
    filename = substituteString filename ">" ""
    filename = substituteString filename ":" ""
    filename = substituteString filename "\"" ""
    filename = substituteString filename "/" ""
    filename = substituteString filename "\\" ""
    filename = substituteString filename "|" ""
    filename = substituteString filename "?" ""
    filename = substituteString filename "*" ""
    filename = substituteString filename "'" ""
)

function fixElementFilePath element fullpath assetFileNames assetFilesCanget =
(
    if fullpath == undefined then (
        fullpath = ""
    )

    local dir = getFilenamePath fullpath
    local filename = getFilenameFile fullpath
    local fileext = getFilenameType fullpath

    if rendOutputFilename == undefined or rendOutputFilename.count == 0 then (
        rendOutputFilename = "c:\\undefined_name.tga"
    )

    if dir.count == 0 then (
        dir = getFilenamePath rendOutputFilename
    )

    filename = removeFileNameInvliadChars(filename)
    if filename.count == 0 then (
        filename = getFilenameFile rendOutputFilename
        filename = filename + "_" +  ((ClassOf element) as string)
    )
    if fileext.count == 0 then (
        fileext = getFilenameType rendOutputFilename
    )

    fullpath = dir + filename + fileext
    fullpath = getNewFilenameIfExist fullpath assetFileNames assetFilesCanget
    fullpath
)

function fixRenderElementsFileNames =
(
    local assetFiles = getAssetFiles()
    local assetFileNames = assetFiles[1]
    local assetFilesCanget = assetFiles[2]

    local defaultExt = getFilenameType rendOutputFilename
    local rem = maxOps.GetCurRenderElementMgr()
    local count = rem.numrenderelements()
    for i = 0 to (count - 1) do (
        local fullpath =  (rem.GetRenderElementFileName i)
        if fullpath == undefined then (
            renderSceneDialog.open()
            renderSceneDialog.close()
            fullpath =  (rem.GetRenderElementFileName i)

        )

        local element = rem.GetRenderElement i
        local newpath = fixElementFilePath element fullpath assetFileNames assetFilesCanget
        if newpath != fullpath then (
            rem.SetRenderElementFilename i newpath
        )
    )
)

function fixRenderElementsFileExt =
(
    local defaultExt = getFilenameType rendOutputFilename
    defaultExt = tolower defaultExt

    local assetFiles = getAssetFiles()
    local assetFileNames = assetFiles[1]
    local assetFilesCanget = assetFiles[2]

    local rem = maxOps.GetCurRenderElementMgr()
    local count = rem.numrenderelements()
    for i = 0 to (count - 1) do (
        local fullpath =  (rem.GetRenderElementFileName i)
        if fullpath == undefined then (
            renderSceneDialog.open()
            renderSceneDialog.close()
            fullpath =  (rem.GetRenderElementFileName i)
        )
        if fullpath == undefined then (
            continue
        )

        -- 修复通道文件没有扩展名的情况
        local ext = getFilenameType fullpath
        local newname = fullpath
        if ext.count == 0 then (
            newname += defaultExt
        ) else (
            ext = tolower ext
            if ext !=  defaultExt then (
                newname = (getFilenamePath fullpath) + (getFilenameFile fullpath) + defaultExt
            )
        )

        newname = getNewFilenameIfExist newname assetFileNames assetFilesCanget
        if fullpath != newname then (
            rem.SetRenderElementFilename i newname
        )
    )
)

function checkMissingFiles args =
(
    local promptmsg = ""
    local errmsg = ""
    local duplicateFileMsg = ""
    local vr = renderers.current
    local allAssetfiles = #()
    ATSOps.Refresh()
    ATSOps.GetFiles &allAssetfiles
    local assetInfo = getFullPathOfAssets(allAssetfiles)
    local assetsFullPath = assetInfo[1]
    local assetsNotFounds = assetInfo[2]
    local elementsFiles = getRenderElementsFiles()

    if assetsNotFounds.count > 0 then (
        for i = 1 to assetsNotFounds.count do (
            if assetsNotFounds[i] == "C:\\farmclient_temp_irradmap.vrmap" then (
                continue
            )
            if assetsNotFounds[i] == "C:\\farmclient_temp_lightcache.vrlmap" then (
                continue
            )

            local isFrameBufSplitFile = StringStartWith assetsNotFounds[i] "C:\\000_farmclient_vray_framebuf"
            if isFrameBufSplitFile then (
                continue
            )

            local elementIndex = findItem elementsFiles assetsNotFounds[i]
            if elementIndex != 0 then (
                continue
            )

            promptmsg = promptmsg + assetsNotFounds[i] + "\r\n"
        )
    )

    if assetsFullPath.count > 0 then (
        local filenameMap = dotNetObject "System.Collections.Hashtable"
        for i = 1 to assetsFullPath.count do (
            local isDir = (StringEndsWith assetsFullPath[i] "/") or (StringEndsWith assetsFullPath[i] "\\")
            if isDir then (
                errmsg = errmsg + assetsFullPath[i] + "是目录，请修改为正确的贴图路径  \r\n"
                continue
            )

            if not doesFileExist assetsFullPath[i] then (
                continue
            )

            local filename = ""
            try ( filename = filenameFromPath assetsFullPath[i] ) catch( filename = "" )
            if filename.count == 0 then (
                continue
            )

            local fullpath = filenameMap.Item[filename]
            if fullpath == undefined then (
                filenameMap.Add filename assetsFullPath[i]
                continue
            )

            duplicateFileMsg = duplicateFileMsg + assetsFullPath[i] + "\r\n" + fullpath + "\r\n\r\n"
        )
    )

    local strCoronaRendererVersion = getCoronaRendererVersion(true)
    if strCoronaRendererVersion.count > 0 then (
        return #(promptmsg, errmsg, duplicateFileMsg)
    )

    if not vr.gi_on then (
        return #(promptmsg, errmsg, duplicateFileMsg)
    )

    local lightJob = args.Item["lightjob_enabled"]

    if vr.gi_primary_type == 0 and (vr.adv_irradmap_mode == 2 or vr.adv_irradmap_mode == 6 or vr.adv_irradmap_mode == 7) and not lightJob then (
        if vr.adv_irradmap_loadFileName == undefined or not doesFileExist vr.adv_irradmap_loadFileName then (
            errmsg = errmsg +  "发光图文件不存在，请检查VRay的设置\r\n"
        )
    )

    if (vr.gi_primary_type == 3 or vr.gi_secondary_type == 3) and vr.lightcache_mode == 2 then (
        if vr.lightcache_loadFileName == undefined or not doesFileExist vr.lightcache_loadFileName then (
            errmsg = errmsg +  "灯光缓存文件不存在，请检查VRay的设置\r\n"
        )
    )

    if (vr.gi_primary_type == 1 or vr.gi_secondary_type == 1) and vr.photonMap_mode == 1 then (
        if vr.photonMap_loadFileName == undefined or not doesFileExist vr.photonMap_loadFileName then (
            errmsg = errmsg + "光子图文件不存在，请检查VRay的设置\r\n"
        )
    )

    if vr.caustics_on and vr.caustics_mode == 1 then (
        if vr.caustics_loadFileName == undefined or not doesFileExist vr.caustics_loadFileName then (
            errmsg = errmsg +  "焦散贴图文件不存在，请检查VRay的设置\r\n"
        )
    )

    return #(promptmsg, errmsg, duplicateFileMsg)
)

QueryBoxYes    = 1
QueryBoxNo     = 2
QueryBoxCancel = 3

function QueryBoxWithTextbox parentHwnd strTitle strFilesList YesText:unsupplied NoText:unsupplied CanelText:unsupplied  ShowCancel:false =
(
    rollout MsgPromptWithTextbox "提醒" width:450 height:400
    (
        local Title = if Title == undefined then "" else Title
        local MessageList = if MessageList == undefined then "" else MessageList
        local ButtonYesText = if ButtonYesText == undefined then "" else ButtonYesText
        local ButtonNoText = if ButtonNoText == undefined then "" else ButtonNoText
        local ButtonCancelText = if ButtonCancelText == undefined then "" else ButtonCancelText
        local Title = if Title == undefined then "" else Title
        local ShowCancelButton = if ShowCancelButton == undefined then false else ShowCancelButton

        local Result = QueryBoxNo

        label labelmax "" pos:[10,10] align:#left height:30
        dotNetControl textboxctrl "System.Windows.Forms.TextBox" pos:[0,35]  height:300 width:450
        button buttonYes "确定"  pos:[140,360]
        button buttonNo "取消"  pos:[280,360]
        button buttonCancel "取消"  pos:[335,360] visible:false

        on MsgPromptWithTextbox open do
        (
            textboxctrl.ReadOnly = true
            textboxctrl.WordWrap = false;
            textboxctrl.Multiline = true;
            textboxctrl.ScrollBars = textboxctrl.ScrollBars.Both;
            textboxctrl.Text= MessageList
            labelmax.text  = Title
            if ButtonYesText.count > 0 then (
                buttonYes.text = ButtonYesText
            )
            if ButtonNoText.count > 0 then (
                buttonNo.text = ButtonNoText
            )
            if ButtonCancelText.count > 0 then (
                buttonCancel.text = ButtonCancelText
            )

            if ShowCancelButton then (
                buttonCancel.visible = true
                buttonYes.pos = [70,360]
                buttonNo.pos = [200, 360]
            )
        )
        on MsgPromptWithTextbox close do
        (
            ButtonYesText = ""
            ButtonNoText = ""
        )

        on buttonNo pressed do (
            Result = QueryBoxNo
            destroydialog MsgPromptWithTextbox
        )

        on buttonYes pressed do (
            Result = QueryBoxYes
            destroydialog MsgPromptWithTextbox
        )

        on buttonCancel pressed do (
            Result = QueryBoxCancel
            destroydialog MsgPromptWithTextbox
        )
    )

    MsgPromptWithTextbox.Title = strTitle
    MsgPromptWithTextbox.MessageList = strFilesList
    MsgPromptWithTextbox.ShowCancelButton = ShowCancel
    if YesText != unsupplied and YesText != undefined then (
        MsgPromptWithTextbox.ButtonYesText = YesText
    )
    if NoText != unsupplied and NoText != undefined then (
        MsgPromptWithTextbox.ButtonNoText = NoText
    )
    if CanelText != unsupplied and CanelText != undefined then (
        MsgPromptWithTextbox.ButtonCancelText = CanelText
    )
    createdialog MsgPromptWithTextbox modal:on parent:parentHwnd
    MsgPromptWithTextbox.Result
)

function modifyOutputGamma args =
(
    local value = args.Item["gamma_fileout_value"]
    IDisplayGamma.colorCorrectionMode = #gamma
    fileOutGamma = value
)

function getFirstEngineIndex name = (
    local engines = #("irradiancemap", "photonmap", "bruteforce", "lightcache")
    local index =  findItem engines name
    return (index - 1)
)

function getSecondEngineIndex name = (
    local engines = #("none", "photonmap", "bruteforce", "lightcache")
    local index =  findItem engines name
    return (index - 1)
)

function modifyVraySetting args =
(
    local currentMaxVersion = getMaxVersion()
    local vrayVersionInfo = getVrayVersion()
    local vrayVersion = vrayVersionInfo[1]
    local settingChanged = vrayVersionInfo[2]
    if vrayVersion.count == 0 then (
        return false
    )

    local vr = renderers.current

    try (  -- 单独的渲染通道
        if vr.output_on and vr.output_useram then (
            local bmp
            if vr.output_getsetsfrommax then (
                bmp = bitmap renderWidth renderHeight
            ) else (
                bmp = bitmap vr.output_width vr.output_height
            )
            local tmpfile = (GetDir #temp) + "\\farmclient_temp-" + (getFilenameFile rendOutputFilename) +  (getFilenameType rendoutputfilename)
            bmp.filename = tmpfile
            save bmp
            close bmp
            -- deleteFile tmpfile
            vr.output_splitbitmap = bmp
            vr.output_splitgbuffer = true
            vr.output_splitRGB = true
            local originalFileExt = toUpper(getFilenameType rendOutputFilename)
            local splitFilename = "c:\\000_temp_vray_framebuf" + originalFileExt
            vr.output_splitfilename = splitFilename
        )
    ) catch()
    try (
        if vr.imageSampler_renderMask_type == 2 then (
            vr.imageSampler_renderMask_type = 0
        )
    ) catch()


    local aochannel = args.Item["aochannel_enable"]
    local colorchannel = args.Item["colorchannel_enable"]
    local mtlchannel = args.Item["mtlchannel_enable"]

    if aochannel then (
        addAOChannel args
    )

    if colorchannel then (
        addColorChannel args
    )

    if mtlchannel then (
        if (addMtlChannel args) then(
            setMtlChannelId()
        )
    )

    try (  -- 单独的渲染通道
        if aochannel or colorchannel then (
            if vr.output_on and (not vr.output_useram) then (
                vr.output_useram = true
            )
        )

        if vr.output_on and vr.output_useram then (
            local bmp
            if vr.output_getsetsfrommax then (
                bmp = bitmap renderWidth renderHeight
            ) else (
                bmp = bitmap vr.output_width vr.output_height
            )
            local tmpfile = (GetDir #temp) + "\\kx-tmp-bmp-" + (getFilenameFile rendOutputFilename) +  (getFilenameType rendoutputfilename)
            bmp.filename = tmpfile
            save bmp
            close bmp
            deleteFile tmpfile
            vr.output_splitbitmap = bmp
            vr.output_splitgbuffer = true
            vr.output_splitRGB = true

            local deleteOtherChannel = args.Item["delete_other_channel"]
            if deleteOtherChannel then (
                vr.output_splitAlpha = false
            )

            local originalFileExt = toUpper(getFilenameType rendOutputFilename)
            local splitFilename = "c:\\000_kx_vray_framebuf" + originalFileExt
            vr.output_splitfilename = splitFilename
        )
    ) catch()

    -- GI 自动保存 强制不勾选
    try (
        try(vr.adv_irradmap_autoSave = false)catch()
        try(vr.lightcache_autoSave = false)catch()
    )catch()
    true
)



function getCoronaTex = (
    try ( return (Ctexmap elementname:"aotexture") ) catch ()
    try ( return (C_纹理图 elementname:"aotexture")) catch ()
    try ( return (CTexmapC_纹理图 elementname:"aotexture")) catch ()
    try ( return (C纹理 elementname:"aotexture")) catch ()
    try ( return (C纹理图 elementname:"aotexture")) catch ()
    undefined
)

function getCoronaAOMap = (
    try ( return (CoronaAO elementname:"aodirt") ) catch ()
    try ( return (C_污垢_AO_环境光吸收 elementname:"aodirt")) catch ()
    try ( return (CR_AO elementname:"aodirt")) catch ()
    try ( return (C_AO elementname:"aodirt")) catch ()
    try ( return (Corona_环境阻光 elementname:"aodirt")) catch ()
    try ( return (Corona_AO elementname:"aodirt")) catch ()
    undefined
)

function addCoronaAOChannel args = (
    local rem = MaxOps.GetCurRenderElementMgr()
    if (rem == undefined) then (
        return true
    )

    local aoRadiu = args.Item["aochannel_radiu"]

    try (
        rem.SetElementsActive(true)
        local aochannel = getCoronaTex()
        local dirt = getCoronaAOMap()
        dirt.maxDistance = aoRadiu
        aochannel.texmap = dirt
        try(
            aochannel.elementname = "AO"
        )catch(
            try(
                aochannel.elementName = "AO"
            )catch(
                return false
            )
        )

        try (aochannel.filterOn  = true) catch()
        try (aochannel.filter_on  = true) catch()
        rem.AddRenderElement(aochannel)
        return true
    ) catch (
        return false
    )
)

function getCoronaMaskID =
(
    try ( return (CMasking_ID elementname:"colorchannel") ) catch ()
    try ( return (C_遮罩_ID elementname:"colorchannel")) catch ()
    try ( return (CMasking_IDC_遮罩_ID elementname:"colorchannel")) catch ()
    try ( return (遮罩_ID elementname:"colorchannel")) catch ()
    try ( return (C遮罩_ID elementname:"colorchannel")) catch ()
    undefined
)

function addCoronaColorChannel args =
(
    local rem = MaxOps.GetCurRenderElementMgr()
    if (rem == undefined) then (
        return true
    )
    try (
        rem.SetElementsActive(true)
        local colorchannel = getCoronaMaskID()
        colorchannel.what = 2
        try(
            colorchannel.elementname = "Color"
        )catch(
            try(
                colorchannel.elementName = "Color"
            )catch(
            return false
            )
        )

        rem.AddRenderElement(colorchannel)
        try (colorchannel.filterOn  = true) catch()
        try (colorchannel.filter_on = true) catch()
        return true
    ) catch(
        return false
    )
)

function getCoronaMtlID =
(
    try ( return (CMasking_ID elementname:"colorchannel") ) catch ()
    try ( return (C_遮罩_ID elementname:"colorchannel")) catch ()
    try ( return (CMasking_IDC_遮罩_ID elementname:"colorchannel")) catch ()
    try ( return (遮罩_ID elementname:"colorchannel")) catch ()
    try ( return (C遮罩_ID elementname:"colorchannel")) catch ()
    undefined
)

function addCoronaMtlChannel args =
(
    local rem = MaxOps.GetCurRenderElementMgr()
    if (rem == undefined) then (
        return true
    )
    try (
        rem.SetElementsActive(true)
        local mtlchannel = getCoronaMtlID()
        mtlchannel.what = 3

        try(
            mtlchannel.elementname = "material"
        )catch(
            try(
                mtlchannel.elementName = "material"
            )catch(
                return false
            )
        )

        rem.AddRenderElement(mtlchannel)
        try (mtlchannel.filterOn  = true) catch()
        try (mtlchannel.filter_on = true) catch()
        return true
    ) catch(
        return false
    )
)

fn setCrMtlChannelIdCore m = (

try(
    if(m.renderElementPropagation == 3)then(
        m.renderElementPropagation = 0
    )
)catch()

local count = (getNumSubMtls m)
if count > 0 then (
    for i =1 to count do (
        local subm = (getSubMtl m i)
        setMtlChannelIdCore subm
    )
)
)

function setCrMtlChannelId = (
local mtlChannelMap = dotNetObject "System.Collections.Hashtable"
local mats = sceneMaterials
for m in mats do (
    try (
        setCrMtlChannelIdCore m
    ) catch ()
)
)
function fixCoronaJPGFileIssue =
(
    try (
        local last = rendoutputfilename[rendoutputfilename.count]
        local lastUpper = toUpper last
        local lastLower = toLower last
        if lastLower != lastUpper then ( -- 是合法字符
            return true
        )
        rendoutputfilename = substring rendoutputfilename 1 (rendoutputfilename.count-1)
    ) catch (
    )
)

function modifyCoronaRendererSetting args =
(
    local cr = renderers.current
    try ( cr.dr_enable = false ) catch()
    try ( cr.dr_slaveAddresses = #() ) catch()
    try ( cr.dr_slaveResolvedNames = #() ) catch()
    try (
        if cr.adaptivity_targetError < 0.01 then (
            cr.adaptivity_targetError = 0.01
        )

        local seconds = (cr.progressive_timeLimit/1000)
        if seconds > 86400 or seconds == 0 then (
            cr.progressive_timeLimit = 86400 *1000
        )
    ) catch (
        if cr.Target_image_noise_level__error < 0.01 then (
            cr.Target_image_noise_level__error = 0.01
        )

        local seconds = (cr.main_timeLimit/1000)
        if seconds > 86400 or seconds == 0 then (
            cr.main_timeLimit = 86400 *1000
        )
    )

    try(
        if cr.renderSelected_mode == 1 then(
            cr.renderSelected_mode = 0
        )
    )catch()

    fixCoronaJPGFileIssue()


    -- 区域渲染+UHD Cache 会出错
    local renderType = (getRenderType() as string)
    renderType = tolower renderType
    try(
        if renderType == "region" and cr.shading_secondarySolver == 4 then (
            if(renderers.current.system_vfbRegions.count < 4)then(
                local region = viewport.getRegionRect(viewport.activeViewport)
                renderers.current.system_vfbRegions_enabled = true
                renderers.current.system_vfbRegions = #([renderWidth,renderHeight,0], [0,0,0], [renderWidth,renderHeight,0], [region.left,region.top,0], [region.right,region.bottom,0], [0,0,0])
            )
            setRenderType #view
        )
    )catch()

    local aochannel = args.Item["aochannel_enable"]
    local colorchannel = args.Item["colorchannel_enable"]
    local mtlchannel = args.Item["mtlchannel_enable"]

    if aochannel then (
        addCoronaAOChannel args
    )

    if colorchannel then (
        addCoronaColorChannel args
        setCrMtlChannelId()
    )

    if mtlchannel then (
        addCoronaMtlChannel args
    )
    true
)

function modifySceneFile args =
(
    local renderName = args.Item["renderername"]
    local msgs = checkMissingFiles args
    local promptmsg = msgs[1]
    local errmsg = msgs[2]
    local duplicateFileMsg = msgs[3]

    if errmsg.count > 0 then (
        messagebox errmsg  title:myAppName
        return false
    )

    if promptmsg.count > 0 then (
        local result = QueryBoxWithTextbox renderfarmSetting.hwnd "下列文件不存在，可能会导致渲染出错，您要继续提交渲染吗？" promptmsg
        if result == QueryBoxNo then (
            return false
        )
    )

    if duplicateFileMsg.count > 0 then (
        duplicateFileMsg += "\r\n\r\n"
        local result = QueryBoxWithTextbox renderfarmSetting.hwnd "下列文件存在重名，可能会导致渲染出错，您要继续提交渲染吗？" duplicateFileMsg YesText:"继续提交" NoText:"手动修改"
        if result == QueryBoxNo then (
            return false
        )
    )

    try (rendUseActiveView = true) catch()

    try (
        if rendOutputFilename.count == 0 then (
            rendSaveFile = true
            rendOutputFilename = "c:\\farm-.TGA"
        )
    )catch()

    local gammaCorrection = args.Item["gamma_correction"]
    if gammaCorrection then (
        modifyOutputGamma(args)
    )else(
        re  =fileOutGamma
    )

    local modifyResult = false
    if renderName == "vray" then (
        modifyResult = modifyVraySetting(args)
    ) else (
        modifyResult = modifyCoronaRendererSetting(args)
    )

    if not modifyResult then (
        return modifyResult
    )
    fixRenderElementsFileNames()

    local saveResult = saveSceneFile()
    saveResult
)

function getCoronaFiles =
(
    local files = #()
    try (
        cr = renderers.current
        if cr.colorMap_lut_enable and cr.colorMap_lut_path != undefined then (
            if cr.colorMap_lut_path.count > 0 then (
                append files cr.colorMap_lut_path
            )
        )
        if cr.gi_uhdCache_precalcMode == 1 or cr.gi_uhdCache_precalcMode == 2  then (
            if cr.gi_uhdCache_file != undefined and cr.gi_uhdCache_file.count > 0 then (
                append files cr.gi_uhdCache_file
            )
        )
    ) catch ()

    files
)

function createZipFilesList tempdir strtime  renderName =
(
    local allAssetfiles = #()
    ATSOps.Refresh()
    ATSOps.GetFiles &allAssetfiles
    local assetInfo = getFullPathOfAssets(allAssetfiles)
    local assetsFullPath = assetInfo[1]
    --format "valid asset files count %\n" assetsFullPath.count

    local tempListFilePath = tempDir + "farm-maxconfig-" +strtime + ".txt"
    -- deleteFile tempListFilePath
    print tempListFilePath

    local maxvArr = maxversion()
    local maxvi = maxvArr[1]
    local stream
    local str

    if maxvi < 15000 then ( -- 3ds max 2012
        stream = createFile tempListFilePath
    ) else (
        stream = createFile tempListFilePath encoding:#utf8
    )
    for i = 1 to assetsFullPath.count do (
        str = assetsFullPath[i]+"\n"
        str = substituteString str "%" "\%"
        format str to:stream
    )

    -- if extralFiles != undefined then (
    --     for i = 1 to extralFiles.count do (
    --         if (StringEndsWith extralFiles[i] "\\") then (
    --             str = extralFiles[i]+"\n"
    --         ) else (
    --             str = extralFiles[i]+"|\n"
    --         )
    --         str = substituteString str "%" "\%"
    --         format str to:stream
    --     )
    -- )

    if renderName == "corona" then (
        local coronaFiles = getCoronaFiles()
        for i = 1 to coronaFiles.count do (
            str = coronaFiles[i]+"\n"
            str = substituteString str "%" "\%"
            format str to:stream
        )
    )

    str = tempListFilePath
    str = substituteString str "%" "\%"
    format str to:stream
    close stream
    free stream

    tempListFilePath
)

function getFrameString =
(
    local rendType = rendTimeType
    if rendType == 1 then (
        return "1"
    ) else if rendType == 2 then (
        local strStart = (((animationRange.start).frame) as integer) as string
        local strEnd = (((animationRange.end).frame) as integer) as string
        local nth = (rendNThFrame as string)
        if nth == "1" then (
            return strStart + "-" + strEnd
        ) else (
            return strStart + "-" + strEnd + ":" + nth
        )
    ) else if rendType == 3 then (
        local strStart = (rendStart.frame as integer) as string
        local strEnd = (rendEnd.frame as integer) as string
        local nth = (rendNThFrame as string)
        if nth == "1" then (
            return strStart + "-" + strEnd
        ) else (
            return strStart + "-" + strEnd + ":" + (rendNThFrame as string)
        )
    ) else if rendType == 4 then (
        return rendPickupFrames
    )
    return ""
)

function getFrameStringForLightJob nth =
(
    local rendType = rendTimeType
    if rendType == 1 then (
        return "1"
    ) else if rendType == 2 then (
        local strStart = (((animationRange.start).frame) as integer) as string
        local strEnd = (((animationRange.end).frame) as integer) as string
        if nth == "1" then (
            return strStart + "-" + strEnd
        ) else (
            return strStart + "-" + strEnd + ":" + (nth as string)
        )
    ) else if rendType == 3 then (
        local strStart = (rendStart.frame as integer) as string
        local strEnd = (rendEnd.frame as integer) as string
        if nth == "1" then (
            return strStart + "-" + strEnd
        ) else (
            return strStart + "-" + strEnd + ":" + (nth as string)
        )
    ) else if rendType == 4 then (
        local frames = rendPickupFrames
        if (findstring frames ",") != undefined then (
            return frames
        )
        return frames + ":" + (nth as string)
    )
    return ""
)

function getLanguage =
(
    local langArray = sysinfo.GetMaxLanguage()
    local language = ""
    if langArray.count >= 3 then (
        language = langArray[3]
    )

    if language != "CHS" and language != "ENU" then (
        language = ""
    )

    language
)

function getSceneUsedPlugiFiles = (
    local usedPluginNames = #("Used Plug-Ins", "使用的插件")
    local plugins = #()

    for i=1 to (fileProperties.getNumProperties #contents) do (
        if (fileProperties.getPropertyName #contents i) != "Headers" then (
            continue
        )

        local propValues = (fileProperties.getPropertyValue #contents i)
        if propValues == undefined then (
            continue
        )

        for item in propValues do (
            if (findItem usedPluginNames item) == 0 then (
                continue
            )

            local itemPlugins = fileProperties.getItems item
            if itemPlugins == undefined then (
                continue
            )

            for itemPlugin in itemPlugins do (
                append plugins itemPlugin
            )
        )
    )
    plugins
)

function getSceneUsedPluginsVersion = (
    local versions = dotNetObject "System.Collections.Hashtable"
    local pluginFiles = getSceneUsedPlugiFiles()
    local pluginPrefix = #(
        "multiscatter", "forestpackpro", "phoenixfd", "dreamscape", "floorgenerator",
        "realflow", "gw_ivy", "fumefx", "multitexture",
        "bonespro", "complexfresnel", "colorcorrect", "tyflow",
        "madcar", "autograss","autohedge","rayfire","rfrigid","berconmaps","growfx","coloredge",
        "quad chamfer","dynamo","thinfilm"
    )
    local pluginName = #(
        "MultiScatter", "Forest", "PhoenixFD", "DreamScape", "FloorGenerator",
        "RealFlow", "Guruware", "FumeFX", "MultiTexture",
        "BonesPro", "ComplexFresnel", "ColorCorrect", "tyFlow",
        "MadCar", "AutoGrass","AutoHedge","RayFire","RayFire","BerconMaps","GrowFx","ColorEdge",
        "Quad Chamfer","Dynamo","ThinFilm"
    )

    for pluginFile in pluginFiles do (
        local filename = toLower pluginFile
        for i= 1 to pluginPrefix.count do (
            local matched = StringStartWith filename pluginPrefix[i]
            if matched then (
                try (versions.Add pluginName[i] "") catch ()
            )
        )
    )
    versions
)

function getTyFlowCache =(
    local pluginsVersion = getSceneUsedPluginsVersion()
    local tyFlow = pluginsVersion.Item["tyFlow"]
    local allAssetfiles = #()
    ATSOps.Refresh()
    ATSOps.GetFiles &allAssetfiles
    local assetInfo = getFullPathOfAssets(allAssetfiles)
    local assetsFullPath = assetInfo[1]

    local tycFileStatus = false
    for i = 1 to assetsFullPath.count do (
        if getFilenameType assetsFullPath[i] == ".tyc" then(
            tycFileStatus = true
        )
    )

    if tyFlow != undefined and tycFileStatus then(
        return true
    )
    false
)


function set_image_setting tempIniFilePath =
(
    local ext = getFilenameType rendOutputFilename
    ext = toLower ext

    setINISetting tempIniFilePath "Properties" "rend_output_image_ext" ext

    if ext == ".rpf" then (
        setINISetting tempIniFilePath "Properties" "rpf.colorDepth" (rpf.colorDepth as string)
        setINISetting tempIniFilePath "Properties" "rpf.alpha" (rpf.alpha as string)
        setINISetting tempIniFilePath "Properties" "rpf.premultAlpha" (rpf.premultAlpha as string)
        setINISetting tempIniFilePath "Properties" "rpf.zChannel" (rpf.zChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.mtlIDChannel" (rpf.mtlIDChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.nodeIDChannel" (rpf.nodeIDChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.uvChannel" (rpf.uvChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.normalChannel" (rpf.normalChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.realpixChannel" (rpf.realpixChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.coverageChannel" (rpf.coverageChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.nodeRenderIDChannel" (rpf.nodeRenderIDChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.colorChannel" (rpf.colorChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.transpChannel" (rpf.transpChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.velocChannel" (rpf.velocChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.weightChannel" (rpf.weightChannel as string)
        setINISetting tempIniFilePath "Properties" "rpf.maskChannel" (rpf.maskChannel as string)
        return true
    )

    if ext == ".tga" or ext == ".vda" or ext == ".icb" or ext == ".vst" then (
        setINISetting tempIniFilePath "Properties" "tga.ColorDepth" (Targa.getColorDepth() as string)
        setINISetting tempIniFilePath "Properties" "tga.Compress" (Targa.getCompressed() as string)
        setINISetting tempIniFilePath "Properties" "tga.AlphaSplit" (Targa.getAlphaSplit()  as string)
        setINISetting tempIniFilePath "Properties" "tga.PreMultAlpha" (Targa.getPreMultAlpha() as string)
        return true
    )

    if ext == ".tif" or ext == ".tiff" then (
        setINISetting tempIniFilePath "Properties" "tif.Type" (TIF.getType() as string)
        setINISetting tempIniFilePath "Properties" "tif.Compression" (TIF.getCompression() as string)
        setINISetting tempIniFilePath "Properties" "tif.Alpha" (TIF.getAlpha()  as string)
        setINISetting tempIniFilePath "Properties" "tif.DPI" (TIF.getDPI() as string)
        return true
    )
)


function isCoronaMtl m =
(
    local className = (classof m) as string
    className == "CoronaMtl" or className == "CoronaLightMtl" or className == "CoronaLayeredMtl" or className == "CoronaRaySwitchMtl"
)

function isSceneUseCorona =
(
    for m in sceneMaterials do (
        if isCoronaMtl m then (
            return true
        )
    )

    local pluginFiles = getSceneUsedPlugiFiles()
    for pluginFile in pluginFiles do (
        local filename = toLower pluginFile
        local matched = StringStartWith filename "coronamaxutils"
        if matched then (
            return true
        )
    )

    false
)

function createIniFile tempdir strtime tempFilesListPath outputFilename machineLimit taskTimeout cameraList taskFrame lightRate freemode fileOutGamma args =
(

    local tempIniFilePath = tempDir + "renderfarm-task-" + strtime + ".ini"
    print tempIniFilePath
    --deleteFile tempIniFilePath

    local strMaxFilename = maxFilename
    strMaxFilename = substituteString strMaxFilename "$" "\$"
    local taskName = getFilenameFile(strMaxFilename)
    local language = getLanguage()
    local renderName = args.Item["renderername"]
    local pluginsVersion = getSceneUsedPluginsVersion()
    local vrayVersionInfo
    local vrayVersion = ""

    if renderName == "vray" then (
        vrayVersionInfo = getVrayVersion()
        vrayVersion = vrayVersionInfo[1]
    )

    -- 2015 --> 2016, < 2012 --> 2012
    local maxvi = (maxversion())[1]
    local softVersion = case  maxvi /1000 of
    (
        10: "2012"
        11: "2012"
        12: "2012"
        13: "2012"
        14: "2012"
        15: "2013"
        16: "2014"
        17: "2015"
        18: "2016"
        19: "2017"
        20: "2018"
        21: "2019"
        22: "2020"
        23: "2021"
        24: "2022"
        defult: "2012"
    )

    setINISetting tempIniFilePath "Arguments" "zipfileslistpath" tempFilesListPath
    setINISetting tempIniFilePath "Arguments" "name" taskName
    setINISetting tempIniFilePath "Arguments" "softname" "3dsmax"
    setINISetting tempIniFilePath "Arguments" "softversion" softVersion
    setINISetting tempIniFilePath "Arguments" "framelist" taskFrame
    setINISetting tempIniFilePath "Arguments" "type" "0" -- movie
    setINISetting tempIniFilePath "Arguments" "renderoutputfilename" outputFilename
    setINISetting tempIniFilePath "Arguments" "machinelimit" (machineLimit as string)
    setINISetting tempIniFilePath "Arguments" "tasktimeoutminutes" (taskTimeout as string)
    setINISetting tempIniFilePath "Arguments" "fileOutGamma" (fileoutgamma as string)

    --setINISetting tempIniFilePath "Arguments" "cameras" (cameraList as string)
    local camera_index = 0
    for camera in cameraList do (
        setINISetting tempIniFilePath "Cameras" (camera_index as string) camera
        camera_index += 1
    )
    if camera_index == 0 then (
        setINISetting tempIniFilePath "Cameras" "0" ""
    )

    setINISetting tempIniFilePath "Plugins" "vray" vrayVersion
    setINISetting tempIniFilePath "Properties" "lightrate" lightRate
    setINISetting tempIniFilePath "Properties" "pluginversion" myPluginInBuildVersion
    setINISetting tempIniFilePath "Properties" "maxfilename" taskName
    setINISetting tempIniFilePath "Properties" "renderwidth" (renderWidth as string)
    setINISetting tempIniFilePath "Properties" "renderheight" (renderHeight as string)
    setINISetting tempIniFilePath "Properties" "freemode" freemode
    setINISetting tempIniFilePath "Properties" "language" language

	setINISetting tempIniFilePath "Properties" "previewframes" args.Item["previewframes"]
    setINISetting tempIniFilePath "Properties" "stopafterpreviewframes" (args.Item["stopafterpreviewframes"] as string)
    setINISetting tempIniFilePath "Properties" "numatmospherics" (numAtmospherics as string)
    setINISetting tempIniFilePath "Properties" "rendoutputfilename" rendOutputFilename

    if renderName == "corona" then (
        setINISetting tempIniFilePath "Properties" "_pass_limit" (args.Item["pass_limit"] as string)
        setINISetting tempIniFilePath "Properties" "_time_limit" (args.Item["time_limit"] as string)
        setINISetting tempIniFilePath "Properties" "_noise_level_limit" (args.Item["noise_level_limit"] as string)
    )

    setINISetting tempIniFilePath "Properties" "aochannel_enable" (args.Item["aochannel_enable"] as string)
    if args.Item["aochannel_enable"] then (
        setINISetting tempIniFilePath "Properties" "aochannel_radiu" (args.Item["aochannel_radiu"] as string)
        setINISetting tempIniFilePath "Properties" "aochannel_subdiv" (args.Item["aochannel_subdiv"] as string)
    )
    setINISetting tempIniFilePath "Properties" "colorchannel_enable" (args.Item["colorchannel_enable"] as string)
    setINISetting tempIniFilePath "Properties" "mtlchannel_enable" (args.Item["mtlchannel_enable"] as string)
    -- setINISetting tempIniFilePath "Properties" "delete_other_channel" (args.Item["delete_other_channel"] as string)


    setINISetting tempIniFilePath "Properties" "vrayoriginalstring" (renderers.current as string)
    setINISetting tempIniFilePath "Properties" "rendatmosphere" (rendAtmosphere as string)
    setINISetting tempIniFilePath "Properties" "rendhidden" (rendHidden as string)
    setINISetting tempIniFilePath "Properties" "rendsuperblack" (rendSuperBlack as string)
    setINISetting tempIniFilePath "Properties" "rendfieldrender" (rendFieldRender as string)
    setINISetting tempIniFilePath "Properties" "rendforce2side" (rendForce2Side as string)
    setINISetting tempIniFilePath "Properties" "rendcolorcheck" (rendColorCheck as string)
    setINISetting tempIniFilePath "Properties" "rendsimplifyarealights" (rendSimplifyAreaLights as string)
    setINISetting tempIniFilePath "Properties" "rendereffects" (renderEffects as string)
    setINISetting tempIniFilePath "Properties" "renderdisplacements" (renderDisplacements as string)
    setINISetting tempIniFilePath "Properties" "useadvancedlighting" (RadiosityPreferences.useAdvancedLighting as string)
    setINISetting tempIniFilePath "Properties" "computeadvancedlighting" (RadiosityPreferences.computeAdvancedLighting as string)
    setINISetting tempIniFilePath "Properties" "lightjobenabled" (args.Item["lightjob_enabled"] as string)
    setINISetting tempIniFilePath "Properties" "lightjobframes" (args.Item["lightjob_frames"] as string)
    if args.Item["lightjob_enabled"] then (
        setINISetting tempIniFilePath "Properties" "lightjobeverynthframe" (args.Item["lightjob_everynthframe"] as string)
        setINISetting tempIniFilePath "Properties" "lightjobfirstengine" (args.Item["lightjob_firstengine"] as string)
        setINISetting tempIniFilePath "Properties" "lightjobsecondengine" (args.Item["lightjob_secondengine"] as string)
    )

    local region
    try ( region = viewport.getRegionRect(viewport.activeViewport) ) catch()
    if region != undefined then (
        setINISetting tempIniFilePath "Properties" "regionleft" (region.left as string)
        setINISetting tempIniFilePath "Properties" "regiontop" (region.top as string)
        setINISetting tempIniFilePath "Properties" "regionright" (region.right as string)
        setINISetting tempIniFilePath "Properties" "regionbottom" (region.bottom as string)
    )
    setINISetting tempIniFilePath "Properties" "rendertype" (getRenderType() as string)

    setINISetting tempIniFilePath "Properties" "rendername" renderName
    if renderName == "corona" then (
        setINISetting tempIniFilePath "Plugins" "vray" "4.10.02"
        setINISetting tempIniFilePath "Plugins" "corona" (getCoronaRendererVersion(true))
        setINISetting tempIniFilePath "Properties" "lightjobenabled" "false"
    ) else (
        if isSceneUseCorona() then (
            setINISetting tempIniFilePath "Plugins" "corona" (getCoronaRendererVersion(false))
        )
    )

    pluginEnum = pluginsVersion.GetEnumerator()
    while pluginEnum.MoveNext() do (
        setINISetting tempIniFilePath "Plugins" pluginEnum.Key pluginEnum.Value
    )

    try (
        local rem = maxOps.GetCurRenderElementMgr()
        local count = rem.numrenderelements()
        for i = 0 to (count - 1) do (
            local element = rem.GetRenderElement(i)
            if element == undefined then (
                continue
            )
            local elementName = element.elementName
            local fullpath =  (rem.GetRenderElementFileName i)
            if fullpath == undefined then (
                continue
            )
            local filename = filenameFromPath fullpath
            setINISetting tempIniFilePath "elements" elementName filename
        )
    ) catch ()

    set_image_setting tempIniFilePath

    tempIniFilePath
)

function checkSetting =
(
    local noVirus = check_virus()
    if not noVirus then (
        return false
    )

    local currentMaxVersion = getMaxVersion()

    local currentRenderer = renderers.current as string

    local renderType = (getRenderType() as string)
    if (renderType == "selected" or renderType == "crop") then (
        messagebox "当前不支持渲染选定对象和裁剪，请设置正确后再重新提交。        " title:myAppName
        return false
    )

    if (findstring currentRenderer "CoronaRenderer") != undefined then (
        return true
    )

    if (findstring currentRenderer "V_Ray_") == undefined then (
        messagebox "当前仅支持VRay渲染器和CR渲染器，其它渲染器请联系客服。        " title:myAppName
        return false
    )

    true
)

function trimspace str =
(
    trimLeft (trimRight str)
)

function trimCameraNameSpace cam =
(
    if cam != undefined then (
        local originalName = cam.name
        local nameWithoutSpace = trimspace(cam.name)
        if originalName != nameWithoutSpace then (
            cam.name = nameWithoutSpace
        )
    )
)

function getCameras =
(
    local names = #()
    local activeCamera=getActiveCamera()
    trimCameraNameSpace(activeCamera)
    local cams = for cam in cameras where (superclassof cam == camera) collect cam
    if cams.count == 0 then (
        return names
    )
    for cam in cams do (
        trimCameraNameSpace(cam)
        if activeCamera == undefined then (
            append names cam.name
        ) else (
            if cam.name != activeCamera.name then (
                append names cam.name
            )
        )
    )
    names
)

function StringStartWith str prefix =
(
    if str.count < prefix.count then (
        return false
    )
    local sub = substring str 1 prefix.count
    sub = toUpper sub
    prefix = toUpper prefix
    sub == prefix
)

function StringEndsWith str postfix =
(
    if str.count < postfix.count then (
        return false
    )
    sub = substring str (str.count-postfix.count+1) postfix.count
    sub == postfix
)

function StringDeletePostfix str postfix =
(
    if StringEndsWith str postfix then (
        str = substring str 1 (str.count-postfix.count)
    )
    return str
)


function RegTools reg key =
(
	registry.openKey HKEY_CURRENT_USER reg accessRights:#readOnly key:&keyReg
	if keyReg != undefined then
	(
		registry.queryValue keyReg key value:&pathval
		registry.closeKey keyReg
		pathval
	)
)

function getRenderFarmAppPath =
(
    local apppath, key, type
    apppath = ""
    print myAppRegistryname
    apppath = RegTools @"SOFTWARE\FarmClient" @"Installdir"

    print apppath
    print "------------"
    print myAppFileName
    print "------------2"
    apppath = apppath + "\\" + "farmNetwork.exe"
    return apppath
)

function getFileNameExt filename =
(
    if filename.count == 0 then (
        return ""
    )

    local ext = getFilenameType filename
    if ext.count == 0 then (
        return ""
    )

    if ext[1] == "." then (
        ext = substring ext 2 (ext.count - 1)
    )

    toUpper ext
)

function getVFBExtraFiles =
(
    local files = #()
    try (
        local vr = renderers.current
        if not vr.output_on then (
            return files
        )

        local file
        local item

        item = vfbControl #lut
        if item.count > 0 and item[1] != 0 then (
            file = vfbControl #lutfile
            if file.count > 0 and file[1].count > 0 then (
                append files file[1]
            )
        )
        item = vfbControl #icc
        if item.count > 0 and item[1] != 0 then (
            file = vfbControl #iccfile
            if file.count > 0 and file[1].count > 0 then (
                append files file[1]
            )
        )
        item = vfbControl #ocio
        if item.count > 0 and item[1] != 0 then (
            file = vfbControl #ociofile
            if file.count > 0 and file[1].count > 0 then (
                append files file[1]
            )
        )
        item = vfbControl #bkgr
        if item.count > 0 and item[1] != 0 then (
            file = vfbControl #bkgrimgfile
            if file.count > 0 and file[1].count > 0 then (
                append files file[1]
            )
        )

        item = vfbControl #glare
        if item.count > 0 and item[1] != 0 then (
            item = vfbControl #glaretype
            if item.count > 0 and item[1] == "image" then (
                file = vfbControl #glareimage
                if file.count > 0 and file[1].count > 0 then (
                    append files file[1]
                )
            ) else (
                item = vfbcontrol #glareuseobstacle
                if item.count > 0 and item[1] != 0 then (
                    file = vfbControl #glareobstacleimage
                    if file.count > 0 and file[1].count > 0 then (
                        append files file[1]
                    )
                )
            )
        )
    ) catch()

    files
)

function messagePrompt parentHwnd title strLabel strMessageList =
(
    rollout rolloutMsgPrompt title width:550 height:300
    (
        local MsgList = if MsgList == undefined then "" else MsgList
        local MsgLabel = if MsgLabel == undefined then "" else MsgLabel
        local Yes = false

        label labelmax MsgLabel pos:[10,10] align:#left height:30
        dotNetControl textboxctrl "System.Windows.Forms.TextBox" pos:[0,35]  height:200 width:550
        button buttonSubmit "确定"  pos:[180,260]
        button buttonCancel "取消"  pos:[320,260]

        on rolloutMsgPrompt open do
        (
            textboxctrl.ReadOnly = true
            textboxctrl.WordWrap = false;
            textboxctrl.Multiline = true;
            textboxctrl.ScrollBars = textboxctrl.ScrollBars.Both;
            textboxctrl.Text= MsgList
        )

        on buttonCancel pressed do (
            Yes = false
            destroydialog rolloutMsgPrompt
        )

        on buttonSubmit pressed do (
            Yes = true
            destroydialog rolloutMsgPrompt
        )
    )

    rolloutMsgPrompt.MsgList = strMessageList
    rolloutMsgPrompt.MsgLabel = strLabel
    if parentHwnd == undefined then (
        createdialog rolloutMsgPrompt modal:on
    ) else (
        createdialog rolloutMsgPrompt modal:on parent:parentHwnd
    )

    rolloutMsgPrompt.Yes
)


function checkRenderSetting isVrayRenderer lightjobEnabled firstEngineIndex secondEngineIndex =
(
    local msg = ""

    if isVrayRenderer then (
        vr = renderers.current
        if not vr.options_lights then (
            msg += "V-Ray->全局开关->灯光：没有开启，可能导致渲染结果很暗\r\n"
        )

        try (
            if vr.options_probabilisticLights == true or vr.options_probabilisticLights == 1 or vr.options_probabilisticLights == 2 then (
                msg += "V-Ray->全局开关->概率灯光(或者均匀概率，或者自适应灯光)：开启概率灯光可能导致噪点\r\n"
            )
        )catch()

        if not lightjobEnabled then (
            try (
                if vr.options_limitDepth and vr.options_maxDepth >= 3 then (
                    msg += "V-Ray->全局开关->最大深度：设置太大(>=3)，可能导致渲染时间过长\r\n"
                )
            ) catch ()
        )

        try (
            local isVray34orLater = isVray34OrLaterVersion()
            if isVray34orLater then ( -- vray version >= 3.4
                if vr.imageSampler_type == 1 and vr.twoLevel_baseSubdivs > 1 then (
                    msg += "V-Ray->块图像采样器->最小细分：绝大多数情况下应该设置为1\r\n"
                )
            )
        ) catch ()

        try (
            try (
                local vray_dmc_useLocalSubdivs = true
                if hasProperty vr "dmc_useLocalSubdivs" then (
                    vray_dmc_useLocalSubdivs = vr.dmc_useLocalSubdivs
                )
                if vray_dmc_useLocalSubdivs and vr.dmc_subdivs_mult > 2.0 then (
                    msg += "V-Ray->全局性蒙特卡洛->全局细分倍增：设置太大(>2.0)，可能导致渲染时间过长\r\n"
                )
            )catch()

            if vr.dmc_earlyTermination_amount < 0.5 then (
                msg += "V-Ray->全局性蒙特卡洛->适应数量: 设置太小(<0.5)，可能导致渲染时间过长\r\n"
            )
            if vr.dmc_earlyTermination_threshold < 0.001 then (
                msg += "V-Ray->全局性蒙特卡洛->澡波阈值: 设置太小(<0.001)，可能导致渲染时间过长\r\n"
            )
         ) catch ()

        if vr.gi_on or lightjobEnabled then (
            if not lightjobEnabled and vr.gi_primary_type == 0 then (
                if (vr.gi_irradmap_preset > 4) then (
                    msg += "GI->发光贴图->当前预设: 设置太高，可能导致渲染时间过长\r\n"
                )
            )

            if firstEngineIndex == 0 then (
                if vr.gi_irradmap_preset == 0 and vr.gi_irradmap_maxRate < vr.gi_irradmap_minRate then (
                    msg += "GI->发光贴图：最大速率 < 最小速率, 可能导致渲染时间过长\r\n"
                )
                if vr.gi_irradmap_preset == 0 and (vr.gi_irradmap_maxRate - vr.gi_irradmap_minRate) > 2 then (
                    msg += "GI->发光贴图：最小速率和最大速率相差太大(>2)，可能导致渲染时间过长\r\n"
                )
                if vr.gi_irradmap_subdivs > 100 then (
                    msg += "GI->发光贴图->细分：设置太大(>100)，可能导致渲染时间过长\r\n"
                )
                if (vr.gi_irradmap_interpSamples > 80) then (
                    msg += "GI->发光贴图->插值采样：设置太大(>80)，可能导致渲染时间过长\r\n"
                )
            )

            if firstEngineIndex == 3 or secondEngineIndex == 3 then (
                if vr.lightcache_subdivs > 2000 then (
                    msg += "GI->灯光缓存->细分：设置太大(>2000)，可能导致渲染时间过长\r\n"
                )
            )
        )
    )

    if msg.count == 0 then (
        return true
    )

    messagePrompt undefined "检测到异常的渲染参数设置" "下列参数可能会影响渲染结果，请确认是否继续提交？" msg
)

function checkDuplicateCameraNode cameras =
(
    local errmsg = ""
    for camera in cameras do (
        local nodes = getNodeByName camera exact:true all:true
        if nodes.count > 1 then (
            errmsg = errmsg + "摄像机" + camera + "和其它对象重名，请修改摄像机名字后再提交\r\n"
        )
    )

    if errmsg.count == 0 then (
        return true
    )

    messagebox errmsg  title:myAppName

    false
)

function getChildren objects all &index=
(
    for o in objects do
    (
        index += 1
        -- 大约3800个节点，max会闪退
        if index > 300 then(
            return all
        )
        if o != undefined then (
            append all o
            getChildren o.children all &index
        )
    )
    all
)

function isValidChineseChar str =
(
    gbk = (dotnetclass "System.Text.Encoding").GetEncoding "GBK"
	bytes = gbk.GetBytes(str)
	gbkstr = gbk.GetString(bytes)
	return gbkstr == str
)

function checkInvalidObjectName =
(
    --local allNodes = #()
    --local index = 0
    --getChildren rootnode.children allNodes &index

    local allNodes = objects

    local found = false
    local objNames = ""
    local count = 0
    for i=1 to allNodes.count do (
        if isValidChineseChar allNodes[i].name then (
            continue
        )
        found = true
        count += 1
        if count > 20 then (
            objNames += "乱码的对象太多，其余的不再显示\r\n"
            exit
        ) else (
            objNames += allNodes[i].name + "\r\n"
        )
    )
    if not found then (
        return true
    )

    local result = QueryBoxWithTextbox renderfarmSetting.hwnd "下列对象名不正确，会导致渲染出错" objNames YesText:"自动改名" NoText:"手动修改" CanelText:"继续提交" ShowCancel:true
    if result == QueryBoxNo then (
        return false
    )
    if result == QueryBoxCancel then (
        return true
    )

    for i=1 to allNodes.count do (
        if isValidChineseChar allNodes[i].name then (
            continue
        )

        local oldname = allNodes[i].name
        local classname = (classof allNodes[i]) as string
        local newname = uniqueName classname
        allNodes[i].name = newname
        format "% --> %\n" oldname newname
    )

    true
)


function repalceSub str1 str2 str3= (
	while( (i = findstring str1 str2)!=undefined )do(

		str1 =replace str1 i str2.count str3
		)
		return str1

)

fn download externalfile ad_adress =
(

	webClient = dotnetObject "System.Net.WebClient"

	theUri=dotnetObject "System.Uri" (externalfile)
	webClient.DownloadFile theUri ad_adress
)

function getAORadiuCaption rendererName =
(
    if rendererName == "vray" then (
        return "半径："
    ) else (
        return "最大距离："
    )
)
function getCurrentRendererName =
(
    local currentRenderer = renderers.current as string

    if (findstring currentRenderer "CoronaRenderer") != undefined then (
        return "corona"
    )

    if (findstring currentRenderer "FStormRender") != undefined then (
        return "fstorm"
    )

    if (findstring currentRenderer "V_Ray_") != undefined then (
        return "vray"
    )
    currentRenderer
)
function checkMixupMtl renderName =
(
    local crMtl =  #("CoronaMtl","CoronaLightMtl","CoronaLayeredMtl","CoronaRaySwitchMtl","CoronaHairMtl","CoronaPortalMtl","CoronaSelectMtl","CoronaShadowCatcherMtl","CoronaSkinMtl","CoronaVolumeMtl")
    local vrMtl = #("MDL材质","VRayGLSLMtl","VRayMtl","VRayMtl转换器","VRayOSLMtl","VRayScannedMtl","VRayVRmatMtl","共生材质","凸凹材质","双面材质","向量置换烘焙","安德斯_兰戈兰","快速SSS2","散布体积","毛发材质","混合材质","灯光材质","点粒子材质","蒙皮材质","薄片材质","覆盖材质","车漆材质","随机薄片材质")
    local vrMtl2 = #("VRay2SidedMtl","VRayALSurfaceMtl","VRayBlendMtl","VRayBumpMtl","VRayCarPaintMtl","VRayFastSSS2","VRayFlakesMtl","VRayHairMtl","VRayHairNextMtl","VRayLightMtl","VRayMDLMtl","VRayMtlWrapper","VRayOverrideMtl","VRayPluginNodeMtl","VRayPointParticleMtl","VRayScatterVolume","VRayStochasticFlakesMtl","VRaySwitchMtl","VRayToonMtl","VRayVectorDisplBake")

    local mtlArray = #()
    local foundMixupMtl = false
    local msg = ""
    local code = ""
    if (renderName == "vray") then (
        mtlArray = crMtl
        msg = "当前渲染器是VRay，模型用到了CR(Corona Renderer)的材质"
        code = "26"
    ) else if renderName == "corona" then (
        join vrMtl vrMtl2
        mtlArray = vrMtl
        msg = "当前渲染器是CR(Corona Renderer)，模型用到了VRay的材质"
        code = "27"
    ) else (
        return #("","")
    )

    for mtlObject in sceneMaterials do (
        className = (classof mtlObject) as string
        if (findItem mtlArray className) > 0 then (
            foundMixupMtl = true
            exit
        )
    )

    if not foundMixupMtl then (
        return #("","")
    )
    msg += "，可能导致颜色通道渲染结果不正确。\r\n"
    return #(msg,code)
)

function canUseAOChannel = (
    local aochannel = getVRayExtraTex()
    local dirt = getVRayDirt()
    local strMaxVersion = getMaxVersion()
    if strMaxVersion == "2012" or strMaxVersion == "2013" or strMaxVersion == "2014" then (
        return (aochannel != undefined and dirt != undefined)
    )
    true
)

function addAOChannel args = (
    local rem = MaxOps.GetCurRenderElementMgr()
    if (rem == undefined) then (
        return true
    )

    local aoRadiu = args.Item["aochannel_radiu"]
    -- local aoSubdiv = args.Item["aochannel_subdiv"]

    try (
        rem.SetElementsActive(true)
        local aochannel = getVRayExtraTex()
        local dirt = getVRayDirt()
        setVRayExtraTex aochannel dirt
        setVRayDirtInfo dirt aoRadiu aoSubdiv

        try(
            aochannel.elementname = "ao"
        )catch(
            try(
                aochannel.elementName = "ao"
            )catch(
                return false
            )
        )

        try (aochannel.filterOn  = true) catch()
        try (aochannel.filter_on  = true) catch()
        rem.AddRenderElement(aochannel)
        return true
    ) catch (
        return false
    )
)

function getVRayWireColor = (
    try ( return (VRayWireColor elementname:"VRayWireColor") ) catch ()
    try ( return (VRay_WireColor elementname:"VRayWireColor") ) catch ()
    try ( return (VRay_线框颜色 elementname:"VRayWireColor") ) catch ()
    try ( return (VRay线框颜色 elementname:"VRayWireColor") ) catch ()
    try ( return (VR_线框颜色 elementname:"VRayWireColor") ) catch ()
    try ( return (线框颜色 elementname:"VRayWireColor") ) catch ()
    undefined
)

function getVRayObjectID = (
    try ( return (VRayObjectID elementname:"VRayObjectID") ) catch ()
    try ( return (VRay_ObjectID elementname:"VRayObjectID") ) catch ()
    try ( return (VRay_对象_ID elementname:"VRayObjectID")) catch ()
    try ( return (VRay_对象ID elementname:"VRayObjectID")) catch ()
    try ( return (VRay对象ID elementname:"VRayObjectID") ) catch ()
    try ( return (VR_对象ID elementname:"VRayObjectID") ) catch ()
    try ( return (VR_物体ID elementname:"VRayObjectID") ) catch ()
    try ( return (对象_ID elementname:"VRayObjectID") ) catch ()
    undefined
)

function setVRayObjectIDOutputType obj type = (
    try (
        try (
            obj.output_type = type
        ) catch (
            obj.输出类型 = type
        )
    ) catch ()
    )

    struct objcolor (
    color	= undefined,
    id		= undefined
    )
    global objcolors = #()

    function saveObjectColor color = (
    for c in objcolors do (
        if (c.color == color) then (
            return undefined
        )
    )
    append objcolors (objcolor color:color id:(objcolors.count))
)

function getObjectColor color = (
    for c in objcolors do (
        if (c.color == color) then (
            return c.id
        )
    )
    return undefined
)

function resetObjectID = (
    try (
        local objectsList = #()
        local geo = #()
        for obj in geometry where classof obj != BoneGeometry do (
            append geo obj
        )

        local shapesArray = shapes as array
        objectsList = geo + shapesArray

        for o in objectsList do (
            saveObjectColor(o.material)
        )

        for o in objectsList do (
            o.gbufferChannel = getObjectColor(o.material)
        )
    ) catch ()
)

function canUseColorChannel = (
    local vrayobj = getVRayWireColor()
    if vrayobj == undefined then (
        vrayobj = getVRayObjectID()
)

local strMaxVersion = getMaxVersion()
    if strMaxVersion == "2012" or strMaxVersion == "2013" or strMaxVersion == "2014" then (
        return (vrayobj != undefined)
    )
    true
)

function addColorChannel args = (
    local rem = MaxOps.GetCurRenderElementMgr()
    if (rem == undefined) then (
        return true
    )

    try (
        rem.SetElementsActive(true)

        local strMaxVersion = getMaxVersion()
        local strVrayVersion = (renderers.current as string)
        local isVRay210 = (StringStartWith strVrayVersion "V_Ray_Adv_2_10") or (StringStartWith strVrayVersion "V_Ray_Adv_2_00")

        local useWireColor = false
        if strMaxVersion == "2012" and isVRay210 then (
            useWireColor = true
        )

        if useWireColor then (
            local vrayobj = getVRayWireColor()
            if vrayobj != undefined then (
                vrayobj.elementname = "color"
                try (vrayobj.filterOn  = true) catch()
                try (vrayobj.filter_on  = true) catch()
                rem.AddRenderElement(vrayobj)
            )
        ) else (
            local vrayobj = getVRayObjectID()
            local isWireColor = false
            if vrayobj == undefined then (
                vrayobj = getVRayWireColor()
                isWireColor = true
            ) else (
                resetObjectID()
                setVRayObjectIDOutputType vrayobj 1
            )
            if vrayobj != undefined then (
                try(
                    vrayobj.elementname = "color"
                )catch(
                    try(
                        vrayobj.elementName = "color"
                    )catch(
                        return false
                    )
                )

                try(
                    vrayobj.output_type  = 1
                )catch(
                    try(vrayobj.输出类型 = 1)catch()
                )
                try (vrayobj.filterOn  = true) catch()
                try (vrayobj.filter_on  = true) catch()
                rem.AddRenderElement(vrayobj)
            )
            if not isWireColor then (
                vrayobj = getVRayWireColor()
                if vrayobj != undefined then (
                    vrayobj.elementname = "color2"
                    try (vrayobj.filterOn = true) catch()
                    try (vrayobj.filter_on = true) catch()
                    rem.AddRenderElement(vrayobj)
                )
            )
        )

        return true
    ) catch (
        return false
    )
)

function getVrayMtlID =
(
    try ( return (VRayMtlID elementname:"VRayMtlID") ) catch ()
    try ( return (VRay_材质ID elementname:"VRayMtlID") ) catch ()
    try ( return (VRay_材质_ID elementname:"VRayMtlID") ) catch ()
    try ( return (VRay_MtlID elementname:"VRayMtlID") ) catch ()
    try ( return (VRay材质ID elementname:"VRayMtlID") ) catch ()
    try ( return (VR_材质ID elementname:"VRayMtlID") ) catch ()
    try ( return (材质_ID elementname:"VRayMtlID") ) catch ()
    undefined
)

function addMtlChannel args = (
    local rem = MaxOps.GetCurRenderElementMgr()
    if (rem == undefined) then (
        return true
    )

    try (
        rem.SetElementsActive(true)
        local mtlchannel = getVrayMtlID()
        try(
            mtlchannel.elementname = "material"
        )catch(
            try(
                mtlchannel.elementName = "material"
            )catch(
                return false
            )
        )

        try(
            mtlchannel.output_type = 1
        )catch(
            try(mtlchannel.输出类型 = 1)catch()
        )

        rem.AddRenderElement(mtlchannel)
        try (mtlchannel.filterOn  = true) catch()
        try (mtlchannel.filter_on = true) catch()
        return true
    ) catch (
        return false
    )
)

fn setMtlChannelIdCore m mtlChannelMap &mtlIdIndex = (

    if mtlIdIndex >= 15 then(
        mtlIdIndex = 1
    )

    m.effectsChannel = mtlIdIndex
    mtlIdIndex += 1

    local count = (getNumSubMtls m)
    if count > 0 then (
        for i =1 to count do (
            local subm = (getSubMtl m i)
            setMtlChannelIdCore subm mtlChannelMap &mtlIdIndex
        )
    )
)

function setMtlChannelId = (
    local mtlChannelMap = dotNetObject "System.Collections.Hashtable"
    local mats = sceneMaterials
    local mtlIdIndex = 1
    for m in mats do (
        try (
            setMtlChannelIdCore m mtlChannelMap &mtlIdIndex
        ) catch ()
    )
)

function canUsMtlChannel = (
    local vrayobj = getVrayMtlID()

    local strMaxVersion = getMaxVersion()
    if strMaxVersion == "2012" or strMaxVersion == "2013" or strMaxVersion == "2014" then (
        return (vrayobj != undefined)
    )
    true
)

function loadUserSetting rendererName  = (
    local userSettingFile = getUserSettingFilePath()
    local args = dotNetObject "System.Collections.Hashtable"

    if not (doesFileExist userSettingFile) then (
        return args
    )

    try (
        local value = (getINISetting userSettingFile rendererName "speedIndex") as integer
        if value == 0 then (
            return args
        )
        if value < 1 or value > 3 then (
            value = 1
        )
        args.Add "speedIndex"  value

        args.Add "taskTimeout" ((getINISetting userSettingFile rendererName "taskTimeout") as Integer)
        args.Add "use_client_savepath" ((getINISetting userSettingFile rendererName "use_client_savepath") as booleanClass)
        args.Add "aochannel_enable" ((getINISetting userSettingFile rendererName "aochannel_enable") as booleanClass)
        args.Add "colorchannel_enable" ((getINISetting userSettingFile rendererName "colorchannel_enable") as booleanClass)
        args.Add "mtlchannel_enable" ((getINISetting userSettingFile rendererName "mtlchannel_enable") as booleanClass)
        -- args.Add "delete_other_channel" ((getINISetting userSettingFile rendererName "delete_other_channel") as booleanClass)
        args.Add "use_new_render_mode" ((getINISetting userSettingFile rendererName "use_new_render_mode") as booleanClass)

        if rendererName == "vray" then (
            args.Add "use_latest_vray" ((getINISetting userSettingFile "vray" "use_latest_vray") as booleanClass)
            args.Add "lightjob_enabled" ((getINISetting userSettingFile "vray" "lightjob_enabled") as booleanClass)
            if (args.Item["lightjob_enabled"]) then (
                args.Add "lightjob_firstengine" ((getINISetting userSettingFile "vray" "lightjob_firstengine") as Integer)
                args.Add "lightjob_secondengine" ((getINISetting userSettingFile "vray" "lightjob_secondengine") as Integer)
                args.Add "lightrate" ((getINISetting userSettingFile "vray" "lightrate") as Integer)
            )
        )
        return args
    ) catch(
        return args
    )
)

function getUserSettingValue setting key defaultValue =
(
    local value = setting.Item[key]
    if value == undefined then (
        value = defaultValue
    )
    value
)

rollout renderfarmSetting "渲染设置" width:500 height:660
(
    local rendererName = getCurrentRendererName()
    -- AO 半径默认设置为100
    local AORadiu = 100
    local aoRadiuCaption = getAORadiuCaption(rendererName)

    local lastRendImageAspectRatio = rendImageAspectRatio
    local strMaxVersion = "3ds Max " + getMaxVersion()
    local coronaRendererVersion = ""
    local isVrayRenderer = false
    local vrayVersionInfo
    local vrayVersion = ""
    local settingChanged = false
    local strRendererVersion = ""

    local iniFilePath = (scriptSelfDir + "\\setting.ini")
    local taskIniFilePath = ""
    local extList = #("TGA","JPG","EXR","PNG","TIF","BMP", "RPF")
    local originalFileExt = toUpper(getFilenameType rendOutputFilename)
    local extChanged = false
    -- local freemodeMaxTimeout = getFreeModeTime()
    local lightRateList = #("1/1","1/2","1/3","1/4")
    local firstEngineNameList = #("发光图", "BF算法(暴力计算)","灯光缓存")
    local firstEngineList = #("irradiancemap", "bruteforce", "lightcache")
    local secondEngineNameList = #("灯光缓存","BF算法(暴力计算)", "无")
    local secondEngineList = #("lightcache","bruteforce", "none")
    local isAutoBackupEnabled = false
    local tooltipTimeout = "超过指定时间后自动暂停任务"
    local tooltipAddonDir = "用于上传RealFlow，火凤凰（Phoenix FD）等插件的缓存文件。如果某些文件被场景文件依赖，但是3dsmax的'资源追踪'检测不到，也可以使用此选项上传。
    "
    local tooltipGamma = "设置渲染输出图片的伽马(Gamma)，不设置则使用系统默认值"
    local tooltipLight = "先渲染光子，再渲染成图，用来节省渲染时间。"
    local tooltipFrameList = "帧序列示例：\r\n渲染第5和10和15帧例：5 10 15 或5,10,15，空格或者逗号分隔\r\n渲染第1帧到第100帧例：1-100，减号分隔\r\n渲染第1帧到第100帧，隔5帧渲染1帧(1, 6, 11, 16)例：1-100:5 一种格式"

    button btnAD "xxx" width:500 height:100 images:#(local_image, undefined,1,1,1,1,1)

    group "软件配置"
    (
        label labelmax strMaxVersion align:#left height:18 pos:[20, 130]
        label labelRenderer strRendererVersion align:#left height:18 pos:[100, 130]
    )

    group "分辨率配置"
    (
        spinner spWidth "宽度：" fieldwidth:40 align:#left pos:[20,180] range:[0,32768,renderWidth ] type:#integer  height:20
        spinner spHeight "高度：" fieldwidth:40 align:#left pos:[130,180] range:[0,32768,renderHeight ]  type:#integer height:20
        spinner spAspect "图像比例：" fieldwidth:40 align:#left pos:[240,180] range:[0,100,rendImageAspectRatio]  type:#float height:20
        checkbox checkboxAspect "锁定比例" checked:rendLockImageAspectRatio fieldwidth:40 align:#left pos:[370,180]
    )

    group "帧序列配置"
    (
        edittext editFrames "帧序列:" tooltip:tooltipFrameList fieldWidth:150 pos:[20,225] labelOnTop:false height:20
        button labelFrameHelp "帧序列的格式与3dsmax标准格式相同" tooltip:tooltipFrameList pos:[221,225] border:false
        --  先隐藏掉优先帧设置
        edittext editPreviewFrames "优先帧:" tooltip:tooltipFrameList fieldWidth:150 pos:[20,250] labelOnTop:false height:20
        checkbox checkboxPreviewStop "优先帧渲染完成后暂停" pos:[220,250] height:20
    )

    group "相机"
    (
        listbox cameraAll "场景相机列表(双击添加)" pos:[20,300] width:200
        label labelmove "-->>" pos:[240,380]
        listbox cameraSelected "渲染相机列表(双击删除)" pos:[280,300] width:200
    )

    group "其它设置"
    (
        label labelFileExt "出图格式"  pos:[20,490]
        dropdownlist dropdownlistFileExt items:extList pos:[90,488] width:100
        --spinner spTaskTimeout  "超时时间(小时)：" toolTip:tooltipTimeout fieldwidth:40 align:#left pos:[300,490] range:[1,24,24] type:#integer height:20
        --label labelAddonDir "缓存文件夹"  pos:[20,515]
        -- 隐藏缓存文件夹
        -- button btnAddonDir "缓存文件夹" toolTip:tooltipAddonDir border:false pos:[14,515]
        -- dropdownlist dropdownlistAddonDir pos:[90,513] width:260
        -- button btnAddDir "添加"  pos:[370,513]
        -- button btnDeleteDir "删除"  pos:[430,513]

        checkbox checkboxLight "先渲染光子" toolTip:tooltipLight checked:false fieldwidth:40 align:#left pos:[20,539]
        label labelFirstEngine "首次引擎"  pos:[110,540]
        dropdownlist dropdownlistFirstEngine items:firstEngineNameList pos:[160,538] width:70 height:18
        label labelSecondEngine "二次引擎"  pos:[250,540]
        dropdownlist dropdownlistSecondEngine items:secondEngineNameList pos:[300,538] width:80 height:18
        label labelLightRate "光子比例"  pos:[385,540]
        dropdownlist dropdownlistLightRate items:lightRateList pos:[435,538] width:55 height:18
        edittext editLightFrames "光子帧序列:" fieldWidth:150 pos:[20,565] labelOnTop:false height:16
        spinner spLightFrame  "每N帧渲染一次光子：" fieldwidth:30 align:#left pos:[330,565] range:[1,1000,1] type:#integer

        -- 增加通道
        checkbox checkboxColor "颜色通道图" align:#left  pos:[20,520]
        checkbox checkboxMtl "材质通道图" align:#left  pos:[110,520]
        checkbox checkboxAO "AO图"  pos:[200,520]

        spinner spRadiu  aoRadiuCaption  align:#left pos:[260,520] range:[0,1000000000,AORadiu] type:#worldUnits height:20 width:80
        spinner spSubdiv "细分：" align:#left pos:[400,520] range:[1,1000,16] type:#integer height:20 width:50

        -- 增加通道结束


        spinner spPassLimit "        过程限制：" align:#left pos:[20,543] range:[0,1048576,0] type:#integer height:20 width:80
        spinner spTimeHourLimit "时限：" align:#left pos:[250,543] range:[0,239,0] type:#integer height:20 width:45

        label labelHour "时" pos:[330,543]
        spinner spTimeMinuteLimit "" align:#left pos:[350,543] range:[0,59,0] type:#integer height:20 width:40
        label labelMinute "分" pos:[400,543]
        spinner spTimeSecondLimit "" align:#left pos:[420,543] range:[0,59,0] type:#integer height:20 width:40
        label labelSecond "秒" pos:[470,543]
        spinner spNoiseLimit "噪点等级限制：" align:#left pos:[20,565] range:[0,1000.0,0] type:#float height:20 width:80

        checkbox checkboxGamma "输出伽马(Gamma)校正" toolTip:tooltipGamma pos:[20,590]
        spinner spGamma "" align:#left pos:[160,590] range:[0.1,5.0, 1.0] type:#float height:20 width:50
    )

    button btnSubmit "保存并提交渲染"  pos:[200,627]
    timer checkSubmitClock "checkSubmitClock" active:false interval:1000 --tick once a second

    on dropdownlistFileExt selected index do (
        local newFileExt = "." + extList[index]
        if newFileExt != originalFileExt then (
            rendOutputFilename = (getFilenamePath rendOutputFilename) + (getFilenameFile rendOutputFilename) + newFileExt
            result = getBitmapSaveFilename caption:"渲染输出文件" filename:rendOutputFilename
            if result == undefined then (
                rendOutputFilename = (getFilenamePath rendOutputFilename) + (getFilenameFile rendOutputFilename) + newFileExt
            ) else (
                rendOutputFilename = result
            )
            userSelectExt = getFilenameType rendOutputFilename
            userSelectExt = toUpper userSelectExt
            newFileExt = toUpper newFileExt
            if userSelectExt != newFileExt then (
                for i=1 to extList.count do (
                    if ("." + extList[i]) == userSelectExt then (
                        dropdownlistFileExt.selection = i
                        foundExtInList = true
                    )
                )
                if not foundExtInList then (
                    extList = append extList currentExt
                    dropdownlistFileExt.items = extList
                    dropdownlistFileExt.selection = extList.count
                )
            )

            originalFileExt = userSelectExt
            fixRenderElementsFileExt()
            rendSaveFile = true
            extChanged = true
        )
    )

    on renderfarmSetting open do (

        try (
            if renderSceneDialog.isOpen() then (
                renderSceneDialog.close()
            )

            strRendererVersion = getCoronaRendererVersion(true)
            if strRendererVersion.count > 0 then (
                strRendererVersion = "CoronaRenderer " + strRendererVersion
            ) else (
                vrayVersionInfo = getVrayVersion()
                vrayVersion = vrayVersionInfo[1]
                settingChanged = vrayVersionInfo[2]
                strRendererVersion = "Vray " + vrayVersion
                isVrayRenderer = true
            )
            labelRenderer.text = strRendererVersion

            lastRendImageAspectRatio = rendImageAspectRatio
            spAspect.enabled = not rendLockImageAspectRatio
            cameraAll.items = getCameras()
            local activeCamera = getActiveCamera()
            if activeCamera != undefined then (
                trimCameraNameSpace(activeCamera)
                local activeCameraName = activeCamera.name
                cameraSelected.items = #(activeCameraName)
            )

            local filepath = toUpper rendOutputFilename
            if filepath.count == 0 then (
                filepath = "C:\\A-.TGA"
                rendOutputFilename = filepath
                rendSaveFile = true
                extChanged = true
            )
            if not rendSaveFile then (
                rendSaveFile = true
                extChanged = true
            )

            local filename = filenameFromPath rendOutputFilename
            local filenameNoExt = getFilenameFile rendOutputFilename
            local filenameExt = getFilenameType rendOutputFilename
            if filename.count == 0 or filenameNoExt.count == 0 or filenameExt.count == 0 then (
                if filename.count == 0 or filenameNoExt.count == 0 then (
                    filename = "A-.TGA"
                    filenameExt == ".TGA"
                ) else (
                    filename = filename +  ".TGA"
                    filenameExt == ".TGA"
                )
                rendOutputFilename = (getFilenamePath rendOutputFilename) + filename
                rendSaveFile = true
                extChanged = true
            )
            filenameExt = toUpper filenameExt
            if filenameExt == ".AVI" or filenameExt == ".MOV" then (
                rendOutputFilename = (getFilenamePath rendOutputFilename) + (getFilenameFile rendOutputFilename) + ".TGA"
                extChanged = true
                filename = filenameFromPath rendOutputFilename
                fixRenderElementsFileExt()
                messagebox "目前不支持AVI和MOV两种输出格式，已经自动更改为TGA输出格式，如果有需求请联系客服处理。    " title:myAppName
            )

            local foundExtInList = false
            for i=1 to extList.count do (
                if StringEndsWith filename extList[i] then (
                    dropdownlistFileExt.selection = i
                    foundExtInList = true
                )
            )
            if not foundExtInList then (
                local currentExt = getFileNameExt rendOutputFilename
                if currentExt.count == 0 then (
                    local newFileExt = "." + extList[1]
                    rendOutputFilename = (getFilenamePath rendOutputFilename) + (getFilenameFile rendOutputFilename) + newFileExt
                    rendSaveFile = true
                    extChanged = true
                ) else (
                    extList = append extList currentExt
                    dropdownlistFileExt.items = extList
                    dropdownlistFileExt.selection = extList.count
                )
            )

            editFrames.text = getFrameString()

            if (IDisplayGamma.colorCorrectionMode == #gamma) then (
                checkboxGamma.checked = true
                spGamma.enabled = true
                spGamma.value = IDisplayGamma.gamma
            ) else (
                checkboxGamma.checked = false
                spGamma.enabled = false
                spGamma.value = fileOutGamma
            )

            labelFirstEngine.enabled = false
            dropdownlistFirstEngine.enabled = false
            labelSecondEngine.enabled = false
            dropdownlistSecondEngine.enabled = false
            spLightFrame.enabled = false
            dropdownlistLightRate.enabled = false
            labelLightRate.enabled = false
            editLightFrames.enabled = false

            if isVrayRenderer then (
                spPassLimit.visible = false
                spTimeHourLimit.visible = false
                labelHour.visible = false
                spTimeMinuteLimit.visible = false
                labelMinute.visible = false
                spTimeSecondLimit.visible = false
                labelSecond.visible = false
                spNoiseLimit.visible = false
                ---------------------------------------
                local version = filterString vrayVersion "."
                -- if version[1] == "5" then(
                --     print "debug lut "
                --     btnFileLutPath.visible = true
                --     editFileLutPath.visible = true
                --     btnSelectFileLutpath.visible = true
                --     btnRemoveFileLutpath.visible = true
                -- )

                if (version[1] as Integer) < 4 then (
                    firstEngineNameList = #("发光图","光子贴图","BF算法(暴力计算)","灯光缓存")
                    firstEngineList = #("irradiancemap","photonmap","bruteforce", "lightcache")
                    secondEngineNameList = #("无","光子贴图","BF算法(暴力计算)","灯光缓存")
                    secondEngineList = #("none","photonmap","bruteforce","lightcache")

                    dropdownlistFirstEngine.items = firstEngineNameList
                    dropdownlistSecondEngine.items = secondEngineNameList
                )

                local cannotUseAOChannel = false
                local cannotUseColorChannel = false
                local cannotUseMtlChannel = false
                if not canUseAOChannel() then (
                    checkboxAO.enabled = false
                    spRadiu.enabled = false
                    spSubdiv.enabled = false
                    cannotUseAOChannel = true
                ) else (
                    try (checkboxAO.checked = getUserSettingValue userSetting "aochannel_enable" false) catch ()
                )
                if not canUseColorChannel() then (
                    checkboxColor.enabled = false
                    cannotUseColorChannel = true
                ) else (
                    try (checkboxColor.checked = getUserSettingValue userSetting "colorchannel_enable" false) catch ()
                )

                if not canUsMtlChannel() then (
                    checkboxMtl.enabled = false
                    cannotUseMtlChannel = true
                ) else (
                    try (checkboxMtl.checked = getUserSettingValue userSetting "mtlchannel_enable" false) catch ()
                )

                local msg = "由于VRay版本问题，"
                if cannotUseAOChannel and cannotUseColorChannel and cannotUseMtlChannel then (
                    msg += "一键AO通道，颜色通道和材质通道功能不可用"
                ) else if cannotUseAOChannel then (
                    msg += "一键AO通道功能不可用"
                ) else if cannotUseColorChannel then (
                    msg += "一键颜色通道功能不可用"
                ) else if cannotUseMtlChannel then (
                    msg += "一键材质通道功能不可用"
                ) else (
                    msg = ""
                )
                if msg.count > 0 then (
                    msg += "，请联系客服解决。"
                    MessageBox msg  title:myAppName
                )
                ---------------------------------------


            ) else (

                editLightFrames.visible = false
                spLightFrame.visible = false

                labelLightRate.visible = false

                spSubdiv.visible = false

                checkboxLight.visible = false
                labelFirstEngine.visible = false
                dropdownlistFirstEngine.visible = false
                labelSecondEngine.visible = false
                dropdownlistSecondEngine.visible = false
                labelLightRate.visible = false
                dropdownlistLightRate.visible = false

                try (checkboxAO.checked = getUserSettingValue userSetting "aochannel_enable" false) catch ()
                try (checkboxColor.checked = getUserSettingValue userSetting "colorchannel_enable" false) catch ()
                try (checkboxMtl.checked = getUserSettingValue userSetting "mtlchannel_enable" false) catch ()

                if rendererName == "corona" then (
                    spPassLimit.visible = true
                    spTimeHourLimit.visible = true
                    labelHour.visible = true
                    spNoiseLimit.visible = true

                    ------------------------------------
                    local cr = renderers.current
                    spPassLimit.value = cr.progressive_passLimit
                    spNoiseLimit.value = cr.adaptivity_targetError
                    local seconds = (cr.progressive_timeLimit/1000)
                    spTimeHourLimit.value = seconds/3600
                    spTimeMinuteLimit.value = (seconds - spTimeHourLimit.value*3600)/60
                    spTimeSecondLimit.value = seconds - spTimeHourLimit.value*3600 - spTimeMinuteLimit.value * 60

                )

                ------------------------------------------------------


            )
        ) catch (
            destroydialog renderfarmSetting
            local exception = getCurrentException()
            messagebox ("插件初始化异常，请联系客服解决。 异常信息：\r\n" + exception + "\r \n ") title:myAppName
        )
    )

    on renderfarmSetting close do (

    )

    on spWidth changed arg do (
        renderWidth = arg
        if rendLockImageAspectRatio then (
            renderHeight = int(float(renderWidth)/lastRendImageAspectRatio)
            spHeight.value = renderHeight
        ) else (
            spAspect.value = rendImageAspectRatio
            lastRendImageAspectRatio = rendImageAspectRatio
        )
        renderSceneDialog.update()
    )

    on spHeight changed arg do (
        renderHeight = arg
        if rendLockImageAspectRatio then (
            renderWidth = int(float(renderHeight) * lastRendImageAspectRatio)
            spWidth.value = renderWidth
        ) else (
            spAspect.value = rendImageAspectRatio
            lastRendImageAspectRatio = rendImageAspectRatio
        )
        renderSceneDialog.update()
    )

    on spAspect changed arg do (
        renderHeight = int(float(renderWidth)/arg)
        spHeight.value = renderHeight
        lastRendImageAspectRatio = rendImageAspectRatio
    )

    on spMachineCount changed arg do (
        if arg > 8 then (
            spMachineCount.value = 8
        )
    )

    --on spTaskTimeout changed arg do (
    --    if arg > 24 then (
    --        spTaskTimeout.value = 24
    --    )
    --)

    on checkboxAspect changed theState do (
        rendLockImageAspectRatio = theState
        lastRendImageAspectRatio = rendImageAspectRatio
        spAspect.enabled = not rendLockImageAspectRatio
        renderSceneDialog.update()
    )

    on cameraAll doubleClicked item do (
        local selectedCamera = cameraAll.selected
        if item != 0 and selectedCamera != undefined then (
            if (findstring selectedCamera ",") != undefined then (
                messagebox "相机名中不能包含逗号，请修改后再选择此相机。        " title:myAppName
            ) else (
                temp = cameraAll.items
                deleteItem temp item
                cameraAll.items = temp

                temp2 = cameraSelected.items
                append temp2 selectedCamera
                cameraSelected.items = temp2
            )
        )
    )

    on cameraSelected doubleClicked item do (
        local selectedCamera = cameraSelected.selected
        if item != 0 and selectedCamera != undefined then (
            temp = cameraSelected.items
            deleteItem temp item
            cameraSelected.items = temp

            temp2 = cameraAll.items
            append temp2 selectedCamera
            cameraAll.items = temp2
        )
    )

    on btnAD pressed do (
        local homepage = getINISetting iniFilePath "oem" "homepage"
        if homepage.count > 0 then (
            ShellLaunch homepage ""
        ) else (
            ShellLaunch "www.renderfarm.com" ""
        )
    )

    -- on btnAddDir pressed do (
    --     local dir = getSavePath caption:"选择文件夹"
    --     if dir != undefined do (
    --         dir = toLower(dir)
    --         local isDriveC = StringStartWith dir "c:"
    --         if isDriveC then (
    --             messagebox "附加文件夹不能放在C盘，请选择其它文件夹。        " title:myAppName
    --             return false
    --         )

    --         if not (StringEndsWith dir "\\") then (
    --             dir = dir + "\\"
    --         )

    --         local items = dropdownlistAddonDir.items
    --         if items == undefined then (
    --            items = #()
    --         )

    --         if (findItem items dir) == 0 then (
    --             append items dir
    --             dropdownlistAddonDir.items = items
    --             dropdownlistAddonDir.selection  = items.count
    --         )
    --     )
    -- )

    -- on btnDeleteDir pressed do (
    --     local items = dropdownlistAddonDir.items
    --     local selectedIndex = dropdownlistAddonDir.selection
    --     if items != undefined and selectedIndex != 0 then (
    --         deleteItem items selectedIndex
    --         dropdownlistAddonDir.items = items
    --     )
    -- )

    on checkboxLight changed theState do (
        labelFirstEngine.enabled = theState
        dropdownlistFirstEngine.enabled = theState
        labelSecondEngine.enabled = theState
        dropdownlistSecondEngine.enabled = theState
        spLightFrame.enabled = theState
        dropdownlistLightRate.enabled = theState
        labelLightRate.enabled = theState
        editLightFrames.enabled = theState

        if theState and editLightFrames.text.count == 0 then (
            local frames = getFrameStringForLightJob (spLightFrame.value as string)
            editLightFrames.text = frames
        )
    )

    on spLightFrame changed newValue do (
        local frames = getFrameStringForLightJob (newValue as string)
        editLightFrames.text = frames
    )

    on spPassLimit changed arg do (
        renderers.current.progressive_passLimit = spPassLimit.value
    )

    on spNoiseLimit changed arg do (
        try (
            renderers.current.adaptivity_targetError = spNoiseLimit.value
        ) catch(
            renderers.current.Target_image_noise_level__error = spNoiseLimit.value
        )
    )

    on spTimeHourLimit changed arg do (
        local seconds = arg * 3600 + spTimeMinuteLimit.value * 60 + spTimeSecondLimit.value
        seconds = seconds * 1000
        renderers.current.progressive_timeLimit = seconds
    )

    on spTimeMinuteLimit changed arg do (
        local seconds = spTimeHourLimit.value * 3600 + arg * 60 + spTimeSecondLimit.value
        seconds = seconds * 1000
        renderers.current.progressive_timeLimit = seconds
    )

    on spTimeSecondLimit changed arg do (
        local seconds =  spTimeHourLimit.value * 3600 + spTimeMinuteLimit.value * 60 + arg
        seconds = seconds * 1000
        renderers.current.progressive_timeLimit = seconds
    )



    on checkboxGamma changed theState do (
        spGamma.enabled = theState
        if theState then (
            spGamma.value = IDisplayGamma.gamma
        ) else (
            spGamma.value = fileOutGamma
        )
    )

    on btnSubmit pressed do (
        local errmsg = ""
        local warnmsg = ""
        if not checkInvalidObjectName() then (
            return false
        )

        if cameraSelected.items.count > 20 then (
            messagebox "一次提交的相机数不能超过20个。        " title:myAppName
            return false
        )
        if not checkDuplicateCameraNode(cameraSelected.items) then (
            return false
        )

        local taskFrame = editFrames.text
        taskFrame = trimspace taskFrame
        if taskFrame.count == 0 then (
            messagebox "帧序列不能为空。        " title:myAppName
            return false
        )


        local dateEpoch = dotNetObject "System.Text.RegularExpressions.Regex" "^((\d+(([,]|[ ]+)\d+)*)|(\d+-\d+(:\d+)?))$"
        local frameRegx = dateEpoch.Match(taskFrame)
        if not frameRegx.success then(
            messagebox "帧序列格式不正确。        " title:myAppName
            return false
        )

        -- -- 关闭预览帧
        local previewFrame = editPreviewFrames.text
        previewFrame = trimspace previewFrame
        if(previewFrame.count > 0) then (
            local previewFrameRegx = dateEpoch.Match(previewFrame)
            if not previewFrameRegx.success then(
                messagebox "优先帧格式不正确。        " title:myAppName
                return false
            )
        )

        if not isVrayRenderer then (
            if spPassLimit.value == 0 and spTimeHourLimit.value == 0 and spTimeMinuteLimit.value == 0 and spTimeSecondLimit.value == 0 and spNoiseLimit.value == 0.0 then (
                messagebox "过程限制，时限，噪点等级限制，至少需要设置其中一个。        " title:myAppName
                return false
            )
        )

        local tyFlowCache = getTyFlowCache()
        if tyFlowCache then(
            local tyFlowCacheYesNo = queryBox "检测使用了tyFlow渲染器并使用了缓存文件，请使用添加《缓存文件夹》的方式上传缓存文件。\n \n如果已经手动添加了缓存文件，请无视此次提示                  " title:myAppName
            if tyFlowCacheYesNo then(
               return false
            )
        )

        local lightjobEnabled = checkboxLight.checked
        local lightjobFirstIndex = 0
        local lightjobSecondIndex = 0
        if isVrayRenderer then (
            if lightjobEnabled then (
                lightjobFirstIndex = getFirstEngineIndex(firstEngineList[dropdownlistFirstEngine.selection])
                lightjobSecondIndex = getSecondEngineIndex(secondEngineList[dropdownlistSecondEngine.selection])
            ) else (
                local vr = renderers.current
                lightjobFirstIndex = vr.gi_primary_type
                lightjobSecondIndex = vr.gi_secondary_type
            )
        ) else (
            lightjobEnabled = false
        )
        local continueSubmit = checkRenderSetting isVrayRenderer lightjobEnabled lightjobFirstIndex lightjobSecondIndex
        if not continueSubmit then (
            return false
        )

        btnSubmit.text = "正在处理文件，请稍后"
        btnSubmit.enabled = false
        checkSubmitClock.active = false

        local lightRate = "100"
        if isVrayRenderer then (
            local lightRateIndex = dropdownlistLightRate.selection
            if lightRateIndex == 2 then (
                lightRate = "50"
            ) else if lightRateIndex == 3 then (
                lightRate = "33"
            ) else if lightRateIndex == 4 then (
                lightRate = "25"
            )
        )

        if not settingChanged and extChanged then (
            settingChanged = true
        )

        local args = dotNetObject "System.Collections.Hashtable"
        local renderName = "vray"
        if not isVrayRenderer then (
            args.Add "renderername" "corona"
            renderName = "corona"
        ) else (
            args.Add "renderername" "vray"
        )
        -- 关闭预览帧

        if checkboxPreviewStop.checked and editPreviewFrames.text.count == 0 then (
            checkboxPreviewStop.checked = false
        )

        -- 颜色通道增加
        if (checkboxColor.checked) then (
            checkResult = checkMixupMtl rendererName
            warnmsg += checkResult[1]
            if (checkResult[2] != "") then (
                errorLog += checkResult[2] + ","
            )
        )

        args.Add "lightrate" lightRate
        -- 关闭预览帧
		args.Add "previewframes" editPreviewFrames.text
        args.Add "stopafterpreviewframes" checkboxPreviewStop.checked
        args.Add "gamma_correction" checkboxGamma.checked
        args.Add "gamma_fileout_value" spGamma.value
        args.Add "lightjob_enabled" checkboxLight.checked
        args.Add "lightjob_everynthframe" spLightFrame.value
        args.Add "lightjob_frames" editLightFrames.text
        args.Add "lightjob_firstengine" firstEngineList[dropdownlistFirstEngine.selection]
        args.Add "lightjob_secondengine" secondEngineList[dropdownlistSecondEngine.selection]
        --- add for color mtl ao elements
        args.Add "aochannel_enable" checkboxAO.checked
        args.Add "aochannel_radiu" spRadiu.value
        args.Add "aochannel_subdiv" spSubdiv.value
        args.Add "colorchannel_enable" checkboxColor.checked
        args.Add "mtlchannel_enable" checkboxMtl.checked

        if renderName == "corona" then(
            args.Add "pass_limit" spPassLimit.value
            args.Add "time_limit" ((spTimeHourLimit.value as string) + ":" + (spTimeMinuteLimit.value as string) + ":" + (spTimeSecondLimit.value as string))
            args.Add "noise_level_limit" spNoiseLimit.value
        )else if rendererName == "fstorm" then(
            args.Add "pass_limit"  ""
            args.Add "time_limit"  spTimeLimit.value
            args.Add "noise_level_limit" spNoiseThreshold.value
        )else(
            args.Add "pass_limit"  ""
            args.Add "time_limit" ""
            args.Add "noise_level_limit" ""
        )

        isAutoBackupEnabled = autosave.Enable
        if isAutoBackupEnabled then (
            autosave.Enable = false
        )


        local modifyResult = modifySceneFile args

        if not checkboxGamma.checked then (
            resetOutGamma = fileOutGamma
        )
        -- 传参到deadline，不回写文件
        -- resetOutGamma = currentfileOutGamma
        -- resetOutGamma = currentfileOutGamma

        if not modifyResult then (
            if isAutoBackupEnabled then (
                autosave.Enable = true
            )
            btnSubmit.text = "保存并提交渲染"
            btnSubmit.enabled = true
            return false
        )

        local tempdir = ""
        if isSystemDriveSpaceOK() then (
            tempDir = sysInfo.tempdir
            tempDir = substituteString tempDir "/" "\\"
            local lastchar = tempDir[tempDir.count]
            if lastchar != "\\" then (
                tempDir = tempDir + "\\"
            )
            tempDir = tempDir + "farmclient\\"
            print (tempdir)
            makeDir tempdir all:true
        ) else (
            tempdir = getMaxFreeSpaceDrive()
            local lastchar = tempDir[tempDir.count]
            if lastchar != "\\" then (
                tempDir = tempDir + "\\"
            )
            tempdir = tempdir + "farmclient_temp\\"
            print (tempdir)
            makeDir tempdir all:true
        )

        local strtime = getTimeString()
		-- 关闭补充资产
        -- local extralFiles = dropdownlistAddonDir.items
        if isVrayRenderer then (
            local vfbExtralFiles = getVFBExtraFiles()
            -- extralFiles = extralFiles + vfbExtralFiles
        )
        local tempFilesListPath = createZipFilesList tempdir strtime  renderName
        -- local tempFilesListPath = createZipFilesList tempdir strtime extralFiles renderName
        print (tempFilesListPath )
        if tempFilesListPath.count == 0 then (
            if isAutoBackupEnabled then (
                autosave.Enable = true
            )
            btnSubmit.text = "保存并提交渲染"
            btnSubmit.enabled = true
            return false
        )

        local machineLimit = "20"
        local freemode = "0"
        local taskTimeout = 24 * 60

        local outputFilename = "farm-." + dropdownlistFileExt.selected
        local camerasToRender = cameraSelected.items


        taskIniFilePath = createIniFile tempdir strtime tempFilesListPath outputFilename machineLimit taskTimeout camerasToRender taskFrame lightRate freemode fileoutgamma args

        print (taskIniFilePath)

        temp_zipfile =  repalceSub taskIniFilePath ".ini" ".zip"
        print(temp_zipfile)
        local apppath = getRenderFarmAppPath()
        print(apppath)

        if not doesFileExist apppath then (
            if isAutoBackupEnabled then (
                autosave.Enable = true
            )
            btnSubmit.text = "保存并提交渲染"
            btnSubmit.enabled = true
            messagebox "客户端不存在，请重新安装。        " title:myAppName
            return false
        )
        arg = " -f " + taskIniFilePath  + " -zip " +  temp_zipfile
        print (arg)
        local returnString  = runcmd apppath arg_array:#(arg)
        print ("returnString = " + returnString)
        if  returnString == "200" then (

            checkSubmitClock.active = true
            -- messagebox "正在提交渲染任务，请等待完成，不要修改max文件！        " title:myAppName
        )else if(returnString == "205" )then (
            messagebox "压缩失败，请联系客服人员         " title:myAppName
        )
        else(
            messagebox "提交失败，客户端无法连接到网络       " title:myAppName
        )
        -- runapp ("\"" + apppath + "\"")  false args:#("-f\"" + taskIniFilePath + "\"")

    )

    on checkSubmitClock tick do (
        print ("time end ")
        if not doesFileExist taskIniFilePath then (
            if isAutoBackupEnabled then (
                autosave.Enable = true
            )
            btnSubmit.text = "保存并提交渲染"
            btnSubmit.enabled = true
            checkSubmitClock.active = false
            messagebox "提交渲染任务完成，请继续您的工作。        " title:myAppName
        )
    )
)

function showSubmitDialog = (
    try(
        print scriptSelfDir
        local_image = (scriptSelfDir + "\ad.jpg")
        download interNet_image local_image

    )catch(
        local_image = (scriptSelfDir + "\ad.jpg")

    )
    try(
        if not checkSetting() then (
            return false
        )

        try (renderSceneDialog.close()) catch ()
        try (destroydialog renderfarmSetting) catch ()

        createDialog renderfarmSetting style:#(#style_titlebar, #style_border, #style_sysmenu,#style_minimizebox)
    ) catch(
        local exception = getCurrentException()
        messagebox ("插件启动出错，请联系客服。 异常信息：\r\n" + exception) title:myAppName
    )
)

(
    local myPluginSourceScriptFileName = getSourceFileName()
    if myPluginSourceScriptFileName.count == 0 then (
        showSubmitDialog()
    )
)