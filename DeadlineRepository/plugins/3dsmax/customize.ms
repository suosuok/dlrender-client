try
(
	DeadlineUtil.LogMessage ">Version Information:"
	DeadlineUtil.LogMessage ( "  >OS version: " + (dotNetClass "System.Environment").osVersion.versionString )
	DeadlineUtil.LogMessage ( "  >3ds MAX, API, SDK version: " + (maxversion() as string) )
	
	maxExe = (pathConfig.appendPath (pathConfig.GetDir #maxroot) "3dsmax.exe")
	if not doesFileExist maxExe do maxExe = (pathConfig.appendPath (pathConfig.GetDir #maxroot) "3dsmaxio.exe")
	
	try
	(
		VersionInfo = dotNetClass "System.Diagnostics.FileVersionInfo"
		MyMax = VersionInfo.GetVersionInfo maxExe
		DeadlineUtil.LogMessage ( "  >3ds Max Version: " + (MyMax.FileVersion as string) )
	)
	catch (DeadlineUtil.WarnMessage ( "  !! Unable to detect 3ds Max Version!" ) )

	DeadlineUtil.LogMessage ( "  >Assigned renderer: " + (renderers.current as string) )

	-- add for get file and filetype format !
	fn getFileNameOO file= (
		local ext = getFilenameType file
		local bname = getFileNameFile file
		local result = bname + ext
		result
	)

	fn getRendererIdString =
	(
		case (renderers.current.classid as string) of
		(
			"#(1, 0)": "scanline"
			"#(1L, 0L)": "scanline"
			
			"#(95494396, 474502030)": "brmax"
			"#(95494396L, 474502030L)": "brmax"
			
			"#(1492548972, 1338981315)": "mentalray"
			"#(1492548972L, 1338981315L)": "mentalray"
			
			"#(1941615238, 2012806412)": "vray"
			"#(1941615238L, 2012806412L)": "vray"
			
			"#(1770671000, 1323107829)": "vrayrt"
			"#(1770671000L, 1323107829L)": "vrayrt"
			
			"#(-1204370534, -399920359)": "krakatoa"
			"#(3090596762L, 3895046937L)": "krakatoa"
			
			"#(217131703, 58075251)": "finalrender"
			"#(217131703L, 58075251L)": "finalrender"
			
			"#(272052741, 712862621)": "maxwell"
			"#(272052741L, 712862621L)": "maxwell"
			
			"#(268839321, 1854680990)": "quicksilver"
			"#(268839321L, 1854680990L)": "quicksilver"
			
			"#(1048411834, 348141227)": "iray"
			"#(1048411834L, 348141227L)": "iray"
			
			"#(1655201228, 1379677700)": "corona"
			"#(1655201228L, 1379677700L)": "corona"
			
			"#(2980325325L, 2688898415L)": "art"
			
			"#(198269858, 1937796512)": "redshift"
			"#(198269858L, 1937796512L)": "redshift"

			"#(-1577524843, 1319335807)": "octane"
			"#(2717442453L, 1319335807L)": "octane"
			
			"#(2980329694L, 2688902778L)": "arnold"
			
			default: ""
		)   
	)
	
	fn setRenderSetting options_array =
	(
		
		for p in options_array do
		(
			param = p[1]
			prettyParam = p[2]
			
			local theVal = DeadlineUtil.GetJobInfoEntry param
			if theVal != undefined do
			(
				try
				(
					if execute (param + "!=" + theVal )  do
					(
						execute (param + "=" + theVal)
						DeadlineUtil.LogMessage ("  +" + prettyParam + " set to " + theVal )
					)
				) catch(DeadlineUtil.WarnMessage ("  --Failed to set " + prettyParam + " to " + theVal ) )
			)
		) 
	)
	
	fn setCurrentRendererSetting options_array  = 
	(
		for p in options_array do
		(
			param = p[1]
			convertParam = p[2]
			prettyParam = p[3]
			
			local theVal = DeadlineUtil.GetJobInfoEntry ( getRendererIdString()  + "_" + param)
			if theVal != undefined do
			(
				convertedVal = theVal
				if convertParam then
				(
					convertedVal = execute convertedVal
				)
				else
				(
					if convertedVal == "undefined" do
						convertedVal = ""
				)
				
				if try(convertedVal != (getProperty renderers.current (param as name)))catch(false) do
				(
					try
					(
						setProperty renderers.current (param as name) convertedVal
						DeadlineUtil.LogMessage ("  +" + prettyParam + " set to " + theVal )
					)
					catch
					(
						DeadlineUtil.WarnMessage ("  --Failed to set " + prettyParam + " to " + theVal ) 
					)
				)
			)
		)			
	)
	
	fn setCurrentRendererSettingArnold setting_value = 
	(
		local param = "abort_on_license_fail"
		local prettyParam = "Abort on License Fail"
		local convertedVal = execute setting_value
			
		if try(convertedVal != (getProperty renderers.current (param as name)))catch(false) do
		(
			try
			(
				setProperty renderers.current (param as name) convertedVal
				DeadlineUtil.LogMessage ("  +" + prettyParam + " set to " + setting_value )
			)
			catch
			(
				DeadlineUtil.WarnMessage ("  --Failed to set " + prettyParam + " to " + setting_value ) 
			)
		)
	)
	
	fn setCurrentRendererSettingVRayRT options_array  = 
	(
		for p in options_array do
		(
			param = p[1]
			convertParam = p[2]
			prettyParam = p[3]
			
			local theVal = DeadlineUtil.GetJobInfoEntry ( "vray_" + param)
			if theVal != undefined do
			(
				convertedVal = theVal
				if convertParam then
				(
					convertedVal = execute convertedVal
				)
				else
				(
					if convertedVal == "undefined" do
						convertedVal = ""
				)
				
				if try(convertedVal != (getProperty renderers.current.V_Ray_settings (param as name)))catch(false) do
				(
					try
					(
						setProperty renderers.current.V_Ray_settings (param as name) convertedVal
						DeadlineUtil.LogMessage ("  +" + prettyParam + " set to " + theVal )
					)
					catch(DeadlineUtil.WarnMessage ("  --Failed to set " + prettyParam + " to " + theVal ) )
				)
			)
		)
	)
	
	fn setCurrentRendererEnumIndex options_array =
	(
		for p in options_array do
		(
			param = p[1]
			prettyParam = p[2]
			enumOptions = p[3]
			indexMod = p[4]
			
			local theVal = DeadlineUtil.GetJobInfoEntry (getRendererIdString() + "_" + param + "_enums")
			if theVal != undefined AND theVal != "--" do 	
			(
				local theIndex = findItem enumOptions theVal
				if theIndex > 0 then 
				(
					try 
					(
						if ( (getProperty renderers.current param) != theIndex - indexMod ) do
						(
							setProperty renderers.current param  ( theIndex - indexMod )
							DeadlineUtil.LogMessage ("  +" + prettyParam + " set to " + theVal  )
						)
					)
					catch
					(
						DeadlineUtil.WarnMessage ("  --Failed to set " + prettyParam + " to " + theVal )
					)
				)
				else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for " + prettyParam + ": " + theVal )
			)
		)
	)
	
	fn setCurrentRendererEnumName options_array =
	(
		for p in options_array do
		(
			param = p[1]
			prettyParam = p[2]
			enumOptions = p[3]
			enumVals = p[4]
			
			local theVal = DeadlineUtil.GetJobInfoEntry (getRendererIdString() + "_" + param + "_enums")
			if theVal != undefined AND theVal != "--" do	
			(
				local theIndex = findItem enumOptions theVal
				if theIndex > 0 then 
				(
					try 
					(
						local newVal = enumVals[ theIndex ]
						
						if ( (getProperty renderers.current param) != newVal ) do
						(
							setProperty renderers.current param newVal 
							DeadlineUtil.LogMessage ("  +" + prettyParam + " set to " + theVal  )
						)
					)
					catch
					(
						DeadlineUtil.WarnMessage ("  --Failed to set " + prettyParam + " to " + theVal )
					)
				)
				else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for " + prettyParam + ": " + theVal )
			)
		)		
	)
	
	fn setCurrentRendererEnumIndexVRayRT options_array =
	(
		for p in options_array do
		(
			param = p[1]
			prettyParam = p[2]
			enumOptions = p[3]
			indexMod = p[4]
			
			local theVal = DeadlineUtil.GetJobInfoEntry ("vray_" + param + "_enums")
			if theVal != undefined AND theVal != "--" do
			(
				local theIndex = findItem enumOptions theVal
				if theIndex > 0 then 
				(
					try 
					(
						if ( (getProperty renderers.current.V_Ray_settings param) != theIndex - indexMod ) do
						(
							setProperty renderers.current.V_Ray_settings param  ( theIndex - indexMod )
							DeadlineUtil.LogMessage ("  +" + prettyParam + " set to " + theVal  )
						)
					)
					catch
					(
						DeadlineUtil.WarnMessage ("  --Failed to set " + prettyParam + " to " + theVal )
					)
				)
				else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for " + prettyParam + ": " + theVal )
			)
		)
	)
	
	fn setCurrentRendererEnum options_array =
	(
		for p in options_array do
		(
			param = p[1]
			prettyParam = p[2]
			
			local theVal = DeadlineUtil.GetJobInfoEntry (getRendererIdString() + "_" + param + "_enums")
			if theVal != undefined AND theVal != "--" do
			(
				try 
				(
					if ( (getProperty renderers.current param) != theVal ) do
					(
						setProperty renderers.current param theVal 
						DeadlineUtil.LogMessage ("  +" + prettyParam + " set to " + theVal  )
					)
				)
				catch
				(
					DeadlineUtil.WarnMessage ("  --Failed to set " + prettyParam + " to " + theVal )
				)
			)
		)		
	)
	
	fn pathmapRendererSetting cur_renderer options_array =
	(
		--Options_array is an array of arrays, the inner arrays are of the format:
		--	Parameter: the parameter from the renderer in which we want to apply pathmapping to
		--  Pretty Parameter Name: A human readable version of the parameter name that will be printed for any messages.
		for p in options_array do
		(
			param = p[1]
			prettyParam = p[2]
			
			origVal = try
			( 
				getProperty cur_renderer (param as name)
			) catch(
				DeadlineUtil.LogMessage ("  +Failed to retrieve " + prettyParam + " from the renderer "+ cur_renderer )
				continue 
			)
			
			if origVal == undefined do
				continue
			
			mappedVal = DeadlineUtil.GetPathMappedFilename( origVal )
			if origVal != mappedVal do
			(
				setProperty cur_renderer (param as name) mappedVal
				DeadlineUtil.LogMessage ("  +Pathmapping changed " + prettyParam + " to " + mappedVal )
			)
		)
	)
	
	--Dump 3dsMax Scene File Props if requested (for debugging purposes)
	local dumpFileProperties = DeadlineUtil.GetJobInfoEntry "DumpFileProperties"
	if dumpFileProperties != undefined do
	(
		if( execute( dumpFileProperties ) ) do
		(
			DeadlineUtil.LogMessage ">3dsMax Scene File Properties"
			pages = #(#summary, #contents, #custom)
			for pg in pages do
			(
				DeadlineUtil.LogMessage ( "--- " + (pg as string) + " ---" )
				for i=1 to (fileProperties.getNumProperties pg) do
				(
					local pname = (fileProperties.getPropertyName pg i)
					local pval = (fileProperties.getPropertyValue pg i)
					if (pname != "Headers") then
						DeadlineUtil.LogMessage ( "    " + (pname as string) + ": " + (pval as string) )
					else
					(
						for hdr in pval do
						(
							DeadlineUtil.LogMessage ( "        " + (hdr as string) )
							local docs = fileProperties.getItems hdr
							if docs != undefined then
								for d in docs do DeadlineUtil.LogMessage ( "            " + (d as string) )
						)
					)
				)
			)
		)
	)

	DeadlineUtil.LogMessage ">Applying customizations to max file..."
	
	DeadlineUtil.LogMessage (">Adding scene path '" + DeadlineUtil.SceneFilePath + "' to session paths")
	sessionPaths.add #map DeadlineUtil.SceneFilePath
	
	local AnimaDummies = try(getClassInstances anima2scene)catch(#())
	if AnimaDummies.count > 0 do 
	(
		DeadlineUtil.LogMessage ">Checking Anima2 Project Paths..."
		for o in AnimaDummies do 
		(	
			local newPath = DeadlineUtil.SceneFilePath + "\\" + (getFileNameFile o.anima2projectpath) + ".anipack"
			if doesFileExist newPath do o.changeanipack = newPath
			DeadlineUtil.LogMessage (" ["+o.anima2projectpath+ "] : "+(doesFileExist o.anima2projectpath) as string )
		)	
	)
	
	local SMTD_StateSetsTree = #()
	
	fn getStateSetChildrenRecursive theParent parentArray =
	(
		for i = 0 to theParent.Children.count-1 do
		(
			local theChild = theParent.Children.Item[i]
			currentParentArray = deepCopy parentArray
			local isActualState = theChild.ToString() == "Autodesk.Max.StateSets.Entities.StateSets.StateSet"
			local isScriptState = theChild.ToString() == "Autodesk.Max.StateSets.Entities.StateSets.Scripted"
			
			if isScriptState do append currentParentArray theChild
			if isActualState do
			(
				local theName = theChild.Name
				local theDesc = "No Changes Recorded"
				if not theChild.IsEmpty then
				(
					theDesc = ""
					try
					(
						for j = 0 to theChild.Children.Count - 1 do
						(
							if j > 0 then
								theDesc = theDesc + ", "
							local childName = theChild.Children.Item[j].Name
							if matchPattern childName pattern:"1 *" then
								childName = substring childName 1 (childName.count-1)
							theDesc = theDesc + childName
						)
					)
					catch
					(
						theDesc = "???"
					)
				)
				if matchPattern theDesc pattern:"1 *" then theDesc = substring theDesc 1 (theDesc.count-1)
				append currentParentArray theChild
				append SMTD_StateSetsTree #(currentParentArray, not theParent.Children.Item[i].IsEmpty, theName, theDesc)
				if findItem #("Autodesk.Max.StateSets.Entities.StateSets.StateSet", "Autodesk.Max.StateSets.Entities.StateSets.Master") (theChild.ToString()) > 0 do
				(
					getStateSetChildrenRecursive theChild currentParentArray
				)
			)
		)		
		return true
	)

	local renderStateSet = (DeadlineUtil.GetJobInfoEntry "RenderStateSet" == "1")
	if renderStateSet do
	(
		DeadlineUtil.LogMessage ">State Set Rendering Requested!"
		if (maxVersion())[1] == 14000 do
		( 
			DeadlineUtil.WarnMessage ("  !! WARNING: SHOULD YOUR JOB FAIL HERE, YOU MIGHT BE RUNNING THE UNPATCHED VERSION OF 3DSMAX 2012 SUBMISSION ADVANTAGE PACK!")
			DeadlineUtil.WarnMessage ("  !! A HotFix is required to restore State Sets in Slave Mode. In case of a crash at this point, please switch to")
			DeadlineUtil.WarnMessage ("  !! 'SAVE and Submit Current Scene File with the Job to the REPOSITORY' mode to restore the State Sets at submission!")
		)
		local stateSetToRender = execute (DeadlineUtil.GetJobInfoEntry "StateSetToRender")
		if stateSetToRender  == OK do stateSetToRender = 1
		local ssP = try(dotNetObject "Autodesk.Max.StateSets.Plugin")catch(undefined)
		if ssP != undefined then
		(
			local MasterStateSet = ssP.Instance.EntityManager.RootEntity.MasterStateSet
			if MasterStateSet != undefined then
			(
				getStateSetChildrenRecursive MasterStateSet #()
				MasterStateSet.CurrentState = SMTD_StateSetsTree[stateSetToRender][1]
				DeadlineUtil.LogMessage ("+Enabled State Set [" + SMTD_StateSetsTree[stateSetToRender][3] + "] : " + SMTD_StateSetsTree[stateSetToRender][4])
			)
			else
				DeadlineUtil.WarnMessage ("--FAILED to find State Sets in the scene!")
		)
		else
			DeadlineUtil.WarnMessage ("--FAILED to access State Sets system! 3ds Max 2012 SAP or Max 2013+ required.")
	)

	-- PROBLEM:
	-- If a state set is used to set the active viewport's camera then the viewport's
	-- FOV will not be updated. V-Ray relies on the viewport FOV being set by Max to match the camera
	-- to render correctly. Other renderers appear to use the camera's FOV directly and render correctly
	--
	-- WORKAROUND:
	-- Manually set the viewport FOV from the camera to make V-Ray work
	if (findItem #("vray", "vrayrt") (getRendererIdString())) > 0 then
	(
		local viewportCam = viewport.GetCamera()
		if viewportCam != undefined then
		(
			if (classof viewportCam) == Physical then
			(
				DeadlineUtil.LogMessage ("  +Changed viewport FOV from " + ((viewport.GetFOV()) as string) + " to " + (viewportCam.fov as string))
				viewport.SetFOV(viewportCam.fov)
			)
		)
	)

	--Restore Scene Selection
	try(local theSelectionArray = execute (DeadlineUtil.GetJobInfoEntry "SceneSelection"))catch(local theSelectionArray = undefined)
	if theSelectionArray != undefined do
		try
		(
			select (for o in theSelectionArray collect (theNode = maxOps.getNodeByHandle o; if isValidNode theNode then theNode else dontcollect))
			DeadlineUtil.LogMessage ( "  +Restored Scene Selection: " + (theSelectionArray as string) )
		)
		catch(DeadlineUtil.WarnMessage ("  --Failed to Restore Scene Selection: " + (theSelectionArray as string) ) )

	DeadlineUtil.LogMessage ">General Renderer Settings:"
	local options_array = #(
		#("RenderWidth", "Render Width"),
		#("RenderHeight", "Render Height"),
		#("renderPixelAspect", "Pixel Aspect"),
		#("rendAtmosphere", "Atmospherics"),
		#("renderEffects", "Effects"),
		#("renderDisplacements", "Displacements"),
		#("rendSimplifyAreaLights", "Area Lights/Shadows As Points"),
		#("rendForce2Side", "Force 2-Sided"),
		#("rendHidden", "Render Hidden Geometry"),
		#("rendColorCheck", "Video Color Check"),
		#("rendSuperBlack", "Super Black"),
		#("rendFieldRender", "Render To Fields"),
		#("SkipRenderedFrames", "Skip Existing Frames")
	)

	setRenderSetting options_array
	
	-- New bitmap pager setting for max 2010 and later handled here instead of 3dsmax.py
	if( ((maxVersion())[1]/1000 as integer) >= 12 ) do
	(
		DeadlineUtil.LogMessage ">Bitmap Pager Settings:"
		
		local overrideBitmapPager = DeadlineUtil.GetJobInfoEntry "OverrideBitmapPager"
		local enableBitmapPager = DeadlineUtil.GetJobInfoEntry "BitmapPager"
		if overrideBitmapPager != undefined and enableBitmapPager != undefined do
		(
			try
			(
				if( execute( overrideBitmapPager ) ) then
				(
					if( execute( enableBitmapPager ) ) then
					(
						IBitmapPager.enabled = true
						DeadlineUtil.LogMessage ("  +Bitmap Pager enabled")
					)
					else
					(
						IBitmapPager.enabled = false
						DeadlineUtil.LogMessage ("  +Bitmap Pager disabled")
					)
				)
				else
					DeadlineUtil.LogMessage ("  +Not overriding Bitmap Pager setting")
			)
			catch(DeadlineUtil.WarnMessage ("  --Failed to set Bitmap Pager to " + enableBitmapPager ) )
		)
	)
	
	DeadlineUtil.LogMessage ">Render Environment Settings:"
	local options_array = #(
		#("backgroundColor", "Background Color"),
		#("useEnvironmentMap", "Use Environment Map"),
		#("ambientColor", "Ambient Color"),
		#("lightTintColor", "Global Light Tint Color"),
		#("lightLevel", "Global Light Level")
	)

	setRenderSetting options_array
	
	local renderElementTiles = DeadlineUtil.GetJobInfoEntry "RenderElementTiles"
	if renderElementTiles == "1" then
	(
		local reManager = maxOps.GetCurRenderElementMgr()
		if reManager.GetElementsActive() then 
		(
			local printOnce = True
			local reCount = reManager.NumRenderElements()
			for i = 0 to reCount - 1 do
			(
				reObject = reManager.GetRenderElement i
				if reObject.enabled then
				(
					reFilename = DeadlineUtil.GetJobInfoEntry ("RenderElementOutputFilename"+i as string)
					if reFilename != undefined do
					(
						if (reManager.GetRenderElementFilename i) != reFilename do
						(
							if printOnce do DeadlineUtil.LogMessage ">Region Rendering with Render Elements requested:"
							reManager.SetRenderElementFilename i reFilename
							DeadlineUtil.LogMessage ("  +RE" + i as string + " filename updated to [" + reFilename +"]")
							printOnce = False
						)
					)
				)--end if enabled	
			)--end i loop
		)--end if REs active						
	)--end if 	

--SCANLINE SPECIFIC SETTINGS:
	if getRendererIdString() == "scanline" do
	(
		DeadlineUtil.LogMessage ">Default Scanline Renderer detected as current renderer."
		
		--Each element of the array is a sub-array containing
		--1. the name of the property as string, 
		--2. whether to convert the value to maxscript value or keep as string, 
		--3. the description string used to output to the log file.
		
		local options_array = #(
			#("mapping", true, "Mapping"),
			#("shadows", true, "Shadows"),
			#("autoReflect", true, "Auto-Reflect/Reflect and Mirrors"),
			#("autoReflectLevels", true, "Auto-Reflect Rendering Iterations"),
			
			#("forceWireframe", true, "Force Wireframe"),
			#("wireThickness", true, "Wireframe Thickness"),
			
			#("antiAliasing", true, "Antialiasing"),
			#("antiAliasFilterSize", true, "Antialiasing Filter Size"),
			#("filterMaps", true, "Filter Maps"),
	
	--		#("enablePixelSampler", true, "Enable Pixel Sampler"),
			#("globalSamplerEnabled", true, "Enable Global Sampler"),
			#("globalSamplerClassByName", false, "Global Sampler Class"),
			
			#("globalSamplerSampleMaps", true, "Global Sampler Supersample Maps"),
			#("globalSamplerQuality", true, "Global Sampler Quality"),
			#("globalSamplerAdaptive", true, "Global Sampler Adaptive"),
			#("globalSamplerAdaptiveThresh", true, "Global Sampler Adaptive Threshold"),
			
			#("objectMotionBlur", true, "Apply Object Motion Blur"),
			#("objectBlurDuration", true, "Object Motion Blur Duration"),
			#("objectBlurSamples", true, "Object Motion Blur Samples"),
			#("objectBlurSubdivisions", true, "Object Motion Blur Subdivisions"),
			
			#("imageMotionBlur", true, "Apply Image Motion Blur"),
			#("imageBlurDuration", true, "Image Motion Blur Duration"),
			
			#("imageBlurEnv", true, "Apply Image Motion Blur To Environment Map"),
			#("imageBlurTrans", true, "Image Motion Blur Transparency"),
	
	--		#("colorClampType", true, "Color Clamp Type"),
			
			#("enableSSE", true, "Enable SSE"),
			#("conserveMemory", true, "Conserve Memory")
		)
		
		local theVal = DeadlineUtil.GetJobInfoEntry "scanline_antialiasFilterClassByName" 
		if theVal != undefined do
		(
			execute ("try(scanlineRender.antiAliasFilter = "+ theVal + "();DeadlineUtil.LogMessage \"+Antialias Filter set to "+ theVal +"\")catch(DeadlineUtil.LogMessage \"--Failed To Set Antialias Filter To " + theVal + "\")")
			if classof scanlineRender.antiAliasFilter == blend do
			(
				theVal = DeadlineUtil.GetJobInfoEntry "scanline_antialiasFilterBlend" 
				if theVal != undefined do 
				(	
					try
					(
						if ( scanlineRender.antiAliasFilter.blend != theVal as float ) do
						(
							scanlineRender.antiAliasFilter.blend = theVal as float
							DeadlineUtil.LogMessage ("    +Antialias Filter Blend Value set to " + theVal)
						)
					)
					catch 
					(
						DeadlineUtil.WarnMessage ("    --Failed to set Antialias Filter Blend Value to " + theVal) 
					)
				)
			)
			
			if classof scanlineRender.antiAliasFilter == Mitchell_Netravali do
			(
				theVal = DeadlineUtil.GetJobInfoEntry "scanline_antialiasFilterBlur" 
				if theVal != undefined do 
				(
					try
					(
						if ( scanlineRender.antiAliasFilter.blur != theVal as float ) do
						(
							scanlineRender.antiAliasFilter.blur = theVal as float
							DeadlineUtil.LogMessage ("    +Antialias Filter Blur Value set to " + theVal)
						)
					)
					catch
					(
						DeadlineUtil.WarnMessage ("    --Failed to set Antialias Filter Blur Value to " + theVal)
					)
				)
				
				theVal = DeadlineUtil.GetJobInfoEntry "scanline_antialiasFilterRinging" 
				if theVal != undefined do 
				(
					try
					(
						if ( scanlineRender.antiAliasFilter.ringing != theVal as float ) do
						(
						
							scanlineRender.antiAliasFilter.ringing = theVal as float
							DeadlineUtil.LogMessage ("    +Antialias Filter Ringing Value set to " + theVal)
						)
					)
					catch
					(
						DeadlineUtil.WarnMessage ("    --Failed to set Antialias Filter Ringing Value to " + theVal)
					)
				)
			)
			
		)
		
		setCurrentRendererSetting options_array
		
	)--end if scanline
--END SCANLINE SPECIFIC SETTINGS	

--BRAZIL 2 SPECIFIC SETTINGS:
	if getRendererIdString() == "brmax" do
	(
		DeadlineUtil.LogMessage ">Brazil r/s 2.x detected as current renderer."
		
		--Each element of the array is a sub-array containing
		--1. the name of the property as string, 
		--2. whether to convert the value to maxscript value or keep as string, 
		--3. the description string used to output to the log file.
		
		local brazilRenderer = sfs.b2_lib.getActiveB2()
		
		local block = brazilRenderer["System_Options_Parameter_Block_Holder"]
		if block != undefined then
		(
			local options_array = #(
				#("reverse_order", true, "Bucket Reverse Order"),
				#("rend_low_priority_thread_on", true, "Low Priority Thread"),
				#("rend_force_thread_count", true, "Force Thread Count"),
				#("mapping_on", true, "Mapping On"),
				#("map_filtering_on", true, "Map Filtering On"),
				#("map_filtering_gi_on", true, "Map Filtering GI On"),
				#("map_filtering_glossy_on", true, "Map Filtering Glossy On"),
				#("float_output_on", true, "Float Output On"),
				#("camera_space_shading_on", true, "Camera Space Shading On"),
				#("flat_zbuffer_on", true, "Flat Z Buffer On"),
				#("atmos_camera_vis_on", true, "Atmos Camera On"),
				#("atmos_reflect_vis_on", true, "Atmos Reflect On"),
				#("atmos_refract_vis_on", true, "Atmos Refract On"),
				#("atmos_indir_vis_on", true, "Atmos Indir Vis On"),
				#("atmos_subsurface_vis_on", true, "Atmos Subsurface On"),
				#("frame_offset", true, "Frame Offset")
			)
			
			for p in options_array do (
				local theVal = DeadlineUtil.GetJobInfoEntry ("brmax_" + p[1])
				if theVal != undefined do (
					try(
						setProperty block.object (p[1] as name) (if p[2] then execute theVal else theVal)
						DeadlineUtil.LogMessage ("  +" + p[3] + " set to " + theVal )
					)catch
						DeadlineUtil.WarnMessage ("  --Failed to set " + p[3] + " to " + theVal ) 
				)	
			)
			
			local theVal = DeadlineUtil.GetJobInfoEntry "brmax_bucket_order_enums"
			if theVal != undefined do (
				local theArray = #("Hilbert","Top to Bottom","Left to Right","Center Out","Random")
				local theIndex = findItem theArray theVal
				if theIndex > 0 then (
					try (
						block.object.bucket_order = theIndex-1
						DeadlineUtil.LogMessage ("  +Bucket Order set to " + theVal  )
					)catch	
						DeadlineUtil.WarnMessage ("  --Failed to set Bucket Order to " + theVal )
				)
				else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for Bucket Order: " + theVal )
			)
			
			local theVal = DeadlineUtil.GetJobInfoEntry "brmax_bucket_size_enums"
			if theVal != undefined do 	(
				local theArray = #("16","24","32","48","64")
				local theIndex = findItem theArray theVal
				if theIndex > 0 then (
					try (
						block.object.bucket_size = theIndex-1
						DeadlineUtil.LogMessage ("  +Bucket Size set to " + theVal  )
					)catch	
						DeadlineUtil.WarnMessage ("  --Failed to set Bucket Size to " + theVal )
				)
				else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for Bucket Size: " + theVal )
			)
			
			local theVal = DeadlineUtil.GetJobInfoEntry "brmax_rend_threading_mode_enums"
			if theVal != undefined do 	(
				local theArray = #("Disable","Automatic","Specify")
				local theIndex = findItem theArray theVal
				if theIndex > 0 then (
					try (
						block.object.rend_threading_mode = theIndex-1
						DeadlineUtil.LogMessage ("  +Render Threading Mode set to " + theVal  )
					)catch	
						DeadlineUtil.WarnMessage ("  --Failed to set Render Threading Mode to " + theVal )
				)
				else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for Render Threading Mode: " + theVal )
			)
		)
		
		local block = brazilRenderer["Sampling_Parameter_Block_Holder"]
		if block != undefined then
		(
			local options_array = #(
				#("aa_min", true, "Sampling Min"),
				#("aa_max", true, "Sampling Max"),
				#("jitter_on", true, "Jitter On"),
				#("Jitter", true, "Jitter"),
				#("clamp", true, "Clamp"),
				#("show_adapt_on", true, "Adapt On"),
				#("show_adapt_color", true, "Adapt Color"),
				#("spatial_contrast_on", true, "Contrast On"),
				#("spatial_contrast_color", true, "Contrast Color"),
				#("normal_on", true, "Normal On"),
				#("normal_thresh", true, "Normal"),
				#("z_depth_on", true, "Z-Depth On"),
				#("z_depth_thresh", true, "Z-Depth"),
				#("prim_edge_on", true, "Object Edge On"),
				#("filter_radius", true, "Filter Radius"),
				#("filter_param1", true, "Filter Param 1"),
				#("filter_param2", true, "Filter Param 2")
			)
			
			for p in options_array do (
				local theVal = DeadlineUtil.GetJobInfoEntry ("brmax_" + p[1])
				if theVal != undefined do (
					try(
						setProperty block.object (p[1] as name) (if p[2] then execute theVal else theVal)
						DeadlineUtil.LogMessage ("  +" + p[3] + " set to " + theVal )
					)catch
						DeadlineUtil.WarnMessage ("  --Failed to set " + p[3] + " to " + theVal ) 
				)	
			)
			
			local theVal = DeadlineUtil.GetJobInfoEntry "brmax_filter_name_enums"
			if theVal != undefined do (
				try (
					block.object.filter_name = theVal
					DeadlineUtil.LogMessage ("  +Filter set to " + theVal  )
				)catch	
					DeadlineUtil.WarnMessage ("  --Failed to set Filter to " + theVal )
			)
		)
		
		local block = brazilRenderer["Motion_Blur_Parameter_Block_Holder"]
		if block != undefined then
		(
			local options_array = #(
				#("shutter_duration", true, "Shutter Duration"),
				#("shutter_bias", true, "Shutter Bias"),
				#("shutter_open", true, "Shutter Open"),
				#("shutter_close", true, "Shutter Close"),
				#("velocity_blur_env_on", true, "Velocity Blur Env On"),
				#("velocity_blur_after_renderfx_on", true, "Velocity Blur After RenderFX On"),
				#("mblur3d_cam_on", true, "MBlur3D Cam On"),
				#("mblur3d_xform_on", true, "MBlur3D Transform On"),
				#("mblur3d_deform_on", true, "MBlur3D Deform On"),
				#("mblur3d_cam_segments", true, "MBlur3D Cam Segments"),
				#("mblur3d_transform_segments", true, "MBlur3D Transform Segments"),
				#("mblur3d_deform_segments", true, "MBlur3D Deform Segments"),
				#("mblur3d_min_samples", true, "MBlur3D Min Samples"),
				#("mblur3d_max_samples", true, "MBlur3D Max Samples"),
				#("mblur3d_max_error", true, "MBlur3D Error")
			)
			
			for p in options_array do (
				local theVal = DeadlineUtil.GetJobInfoEntry ("brmax_" + p[1])
				if theVal != undefined do (
					try(
						setProperty block.object (p[1] as name) (if p[2] then execute theVal else theVal)
						DeadlineUtil.LogMessage ("  +" + p[3] + " set to " + theVal )
					)catch
						DeadlineUtil.WarnMessage ("  --Failed to set " + p[3] + " to " + theVal ) 
				)	
			)
			
			local theVal = DeadlineUtil.GetJobInfoEntry "brmax_motion_blur_type_enums"
			if theVal != undefined do 	(
				local theArray = #("Off","Image Motion Blur","3D Motion Blur")
				local theIndex = findItem theArray theVal
				if theIndex > 0 then (
					try (
						block.object.motion_blur_type = theIndex-1
						DeadlineUtil.LogMessage ("  +Motion Blur set to " + theVal  )
					)catch	
						DeadlineUtil.WarnMessage ("  --Failed to set Motion Blur to " + theVal )
				)
				else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for Motion Blur: " + theVal )
			)
			
			local theVal = DeadlineUtil.GetJobInfoEntry "brmax_shutter_type_enums"
			if theVal != undefined do 	(
				local theArray = #("None","Basic")
				local theIndex = findItem theArray theVal
				if theIndex > 0 then (
					try (
						block.object.shutter_type = theIndex-1
						DeadlineUtil.LogMessage ("  +Shutter Type set to " + theVal  )
					)catch	
						DeadlineUtil.WarnMessage ("  --Failed to set Shutter Type to " + theVal )
				)
				else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for Shutter Type: " + theVal )
			)
		)
		
		local block = brazilRenderer["Ray_Server_Parameter_Block_Holder"]
		if block != undefined then
		(
			local options_array = #(
				#("max_ref_depth", true, "Reflection Depth"),
				#("max_tra_depth", true, "Refracted Depth"),
				#("max_depth", true, "Total Depth"),
				#("max_depth_thresh", true, "Auto Cutoff"),
				#("ray_secondary_on", true, "Secondary Effects"),
				#("ray_reflection_on", true, "Raytrace Reflections"),
				#("ray_glossy_reflection_on", true, "Glossy Reflections"),
				#("ray_refraction_on", true, "Raytrace Refractions"),
				#("ray_glossy_refraction_on", true, "Glossy Refractions"),
				#("ray_self_reflect_on", true, "Self Reflect"),
				#("ray_sec_mat_ids_on", true, "Secondary Material IDs"),
				#("ray_conserve_memory_on", true, "Conserve Memory")
			)
			
			for p in options_array do (
				local theVal = DeadlineUtil.GetJobInfoEntry ("brmax_" + p[1])
				if theVal != undefined do (
					try(
						setProperty block.object (p[1] as name) (if p[2] then execute theVal else theVal)
						DeadlineUtil.LogMessage ("  +" + p[3] + " set to " + theVal )
					)catch
						DeadlineUtil.WarnMessage ("  --Failed to set " + p[3] + " to " + theVal ) 
				)	
			)
			
			local theVal = DeadlineUtil.GetJobInfoEntry "brmax_ray_accel_name_enums"
			if theVal != undefined do (
				try (
					block.object.ray_accel_name = theVal
					DeadlineUtil.LogMessage ("  +Ray Accelerator set to " + theVal  )
				)catch	
					DeadlineUtil.WarnMessage ("  --Failed to set Ray Accelerator to " + theVal )
			)
		)
		
		local block = brazilRenderer["Luma_Server_Parameter_Block_Holder"]
		if block != undefined then
		(
			local options_array = #(
				#("shadows_on", true, "Shadows"),
				#("default_light_on", true, "Default Light"),
				#("directlight_on", true, "Direct Light"),
				#("dirpoint_on", true, "Dir Point Lights"),
				#("dirarea_on", true, "Dir Area Lights"),
				#("dirsky_on", true, "Dir Sky Light"),
				#("subsurface_effects_on", true, "Subsurface Effects"),
				#("subsurface_sample_rate", true, "Subsurface Sample Rate"),
				#("subsurface_intensity", true, "Subsurface Intensity"),
				#("sss_depth_scale", true, "Subsurface Depth Scale"),
				#("global_illum_on", true, "GI On"),
				#("global_photon_map_on", true, "GI Photon Map"),
				#("regather_global_photon_map_on", true, "GI Regather"),
				#("indir_illum_rendercache_on", true, "GI Render Cache"),
				#("indirpoint_on", true, "QMC Point Lights"),
				#("indirarea_on", true, "QMC Area Lights"),
				#("indirsky_on", true, "QMC Sky Light"),
				#("qmc_caustics_on", true, "QMC Caustics"),
				#("qmc_atmosphere_on", true, "QMC Atmos"),
				#("qmc_toon_on", true, "QMC Toon"),
				#("view_rate", true, "QMC Rate"),
				#("gi_bounces", true, "QMC Bounces"),
				#("portals_on", true, "QMC Use Portals"),
				#("portal_rate", true, "QMC Portal Rate"),
				#("portals_only_on", true, "QMC Portal Only Skylight"),
				#("energy_multiplier", true, "Energy Multiplier"),
				#("energy_saturation", true, "Energy Saturation"),
				#("energy_black_point", true, "Energy Black Point"),
				#("energy_white_point", true, "Energy White Point"),
				#("energy_tint", true, "Energy Tint"),
				#("energy_gamma", true, "Energy Gamma"),
				#("skylight_use_3dsmax_env_on", true, "Skylight Use 3dsMax Env"),
				#("skylight_transp_shadows_on", true, "Skylight Transarent Shadows"),
				#("skylight_multiplier", true, "Skylight Mulitlier"),
				#("skylight_color", true, "Skylight Color"),
				#("skylight_map_amt", true, "Skylight Map Amount")
			)
			
			for p in options_array do (
				local theVal = DeadlineUtil.GetJobInfoEntry ("brmax_" + p[1])
				if theVal != undefined do (
					try(
						setProperty block.object (p[1] as name) (if p[2] then execute theVal else theVal)
						DeadlineUtil.LogMessage ("  +" + p[3] + " set to " + theVal )
					)catch
						DeadlineUtil.WarnMessage ("  --Failed to set " + p[3] + " to " + theVal ) 
				)	
			)
			
			local theVal = DeadlineUtil.GetJobInfoEntry "brmax_rendercache_detail_mode_enums"
			if theVal != undefined do 	(
				local theArray = #("No Enhancement","Auto-Occlusion","Retrace")
				local theIndex = findItem theArray theVal
				if theIndex > 0 then (
					try (
						block.object.rendercache_detail_mode = theIndex-1
						DeadlineUtil.LogMessage ("  +Render Cache Mode set to " + theVal  )
					)catch	
						DeadlineUtil.WarnMessage ("  --Failed to set Render Cache Mode to " + theVal )
				)
				else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for Render Cache Mode: " + theVal )
			)
		)
	)--end if Brazil r/s 2
--END BRAZIL 2 SPECIFIC SETTINGS	

--MENTAL RAY SPECIFIC SETTINGS:
	if getRendererIdString() == "mentalray" do
	(
		DeadlineUtil.LogMessage ">mental ray detected as current renderer."

		if ((maxVersion())[1]/1000 as integer) >= 19 do --Max2017 or later only
		(
			isMrPresent = try(NVIDIARenderersHelper.IsMentalrayDllPresent())catch(false)
			if not isMrPresent do DeadlineUtil.FailRender( "Mental Ray is NOT installed on this machine (install option in 3dsMax installer from Autodesk)" )
		)
		
		--Each element of the array is a sub-array containing
		--1. the name of the property as string, 
		--2. whether to convert the value to maxscript value or keep as string, 
		--3. the description string used to output to the log file.
		
		local options_array = #(
			--#("filter",true,"Filter"), --ENUM see below (integer)
			#("view",true,"Displacement: View"), --(boolean) ~removed in Max2016
			#("smooth",true,"Displacement: Smoothing"), --(boolean)
			--#("MinimumSamples",true,"Minimum Samples"), --ENUM see below (integer)
			--#("MaximumSamples",true,"Maximum Samples"), --ENUM see below (integer)
			#("UnifiedEnable",true,"Unified Enable"), --(boolean) ~new in Max2014
			#("UnifiedQuality",true,"Unified Quality"), --(float) ~new in Max2014
			#("UnifiedMinSamples",true,"Unified Min Samples"), --(integer) ~new in Max2014
			#("UnifiedMaxSamples",true,"Unified Max Samples"), --(integer) ~new in Max2014
			#("EnableLIS",true,"Enable LIS"), --(boolean) ~new in Max2016
			#("LISQuality",true,"LIS Quality"), --(float) ~new in Max2016
			#("RedSpatialContrast",true,"Red Spatial Contrast"), --(float) 
			#("GreenSpatialContrast",true,"Green Spatial Contrast"), --(float)
			#("BlueSpatialContrast",true,"Blue Spatial Contrast"), --(float)
			#("AlphaSpatialContrast",true,"Alpha Spatial Contrast"), --(float)
			#("RedTemporalContrast",true,"Red Temporal Contrast"), --(float)
			#("GreenTemporalContrast",true,"Green Temporal Contrast"), --(float)
			#("BlueTemporalContrast",true,"Blue Temporal Contrast"), --(float)
			#("AlphaTemporalContrast",true,"Alpha Temporal Contrast"), --(float)
			#("TimeSamples",true,"Motion Blur: Time Samples"), --(integer)
			#("BoxFilterWidth",true,"Box Filter Width"), --(float)
			#("BoxFilterHeight",true,"Box Filter Height"), --(float)
			#("GaussFilterWidth",true,"Gauss Filter Width"), --(float)
			#("GaussFilterHeight",true,"Gauss Filter Height"), --(float)
			#("TriangleFilterHeight",true,"Triangle Filter Height"), --(float)
			#("TriangleFilterWidth",true,"Triangle Filter Width"), --(float)
			#("MitchellFilterWidth",true,"Mitchell Filter Width"), --(float)
			#("MitchellFilterHeight",true,"Mitchell Filter Height"), --(float)
			#("LanczosFilterWidth",true,"Lanczos Filter Width"), --(float)
			#("LanczosFilterHeight",true,"Lanczos Filter Height"), --(float)
			#("Jitter",true,"Jitter"), --(boolean)
			#("LockSamples",true,"Lock Samples"), --(boolean)
			#("TaskSize",true,"Task Size"), --(integer)
			#("TaskSizeAuto",true,"Task Size Auto"), --(boolean) ~new in Max2012
			--#("TaskOrder",true,"Task Order"), --ENUM see below (integer)
			#("FrameBufferType",true,"Frame Buffer Type"), --(integer)
			#("ScanlineEnable",true,"Scanline Enable"), --(boolean)
			#("RaytraceEnable",true,"Raytrace Enable"), --(boolean)
			#("ReflectionsEnable",true,"Enable Reflections"), --(boolean)
			#("MaximumReflections",true,"Maximum Reflections"), --(integer)
			#("RefractionsEnable",true,"Enable Refractions"), --(boolean)
			#("MaximumRefractions",true,"Maximum Refractions"), --(integer)
			#("MaximumTraceDepth",true,"Maximum Trace Depth"), --(integer)
			#("ScanlineMethod",true,"Scanline Method"), --(integer)
			#("Autovolume",true,"Auto Volume"), --(boolean)
			--#("RapidCollectRate",true,"Rapid Collect Rate"), --ENUM see below (integer)
			#("RapidMotionResample",true,"Rapid Motion Resample"), --(integer)
			#("RapidShadingSamples",true,"Rapid Shading Samples"), --(float)
			#("BarycentricClipLimitMultiplier",true,"BarycentricClipLimitMultiplier"), --(float) ~new in Max2010
			#("ShadowsEnable",true,"Shadows Enable"), --(boolean)
			#("ShadowMethod",true,"Shadow Method"), --(integer)
			#("UseShadowMapFile",true,"Use Shadow Map File"), --(boolean)
			#("ShadowMapRebuild",true,"Rebuild ShadowMap"), --(boolean)
			#("ShadowMapFilename",false,"Shadow Map Filename"), --(string)
			#("MotionBlurShadowMapsEnable",true,"Enable ShadowMaps MotionBlur"), --(boolean)
			#("EnableShadowMaps",true,"Enable Shadow Maps"), --(boolean)
			#("DepthOfFieldEnable",true,"Depth Of Field: Enable"), --(boolean)
			#("FocusPlane",true,"Depth Of Field: FocusPlane"), --(float)
			#("DepthOfFieldMode",true,"Depth Of Field: Mode"), --(integer)
			#("fStop",true,"Depth Of Field: fStop"), --(float)
			#("NearFocus",true,"Depth Of Field: NearFocus"), --(float)
			#("FarFocus",true,"Depth Of Field: FarFocus"), --(float)
			#("MotionBlurEnable",true,"Motion Blur"), --(boolean)
			#("Shutter",true,"Shutter Duration"), --(float)
			#("MotionBlurOffset",true,"Shutter Offset"), --(float)
			#("Segments",true,"Motion Blur: Motion Segments"), --(boolean)
			#("IndirectDiffuseEnabled",true,"Enable Indirect Diffuse (GI)"), --(boolean) ~new in Max2017
			#("IndirectDiffuseGPUEnabled",true,"Use Available GPUs"), --(boolean) ~new in Max2017
			#("IndirectDiffuseQuality",true,"Indirect Diffuse Quality"), --(float) ~new in Max2017
			#("IndirectDiffuseDiffuseDepth",true,"Diffuse Reflections/Refractions"), --(integer) ~new in Max2017
			#("IndirectDiffuseReflectionDepth",true,"Glossy/Specular Reflections"), --(integer) ~new in Max2017
			#("IndirectDiffuseRefractionDepth",true,"Glossy/Specular Refractions"), --(integer) ~new in Max2017
			#("CausticsEnable",true,"Caustics Enable"), --(boolean)
			#("CausticAccuracy",true,"Caustic Accuracy"), --(integer)
			#("UseCausticRadius",true,"Use Caustic Radius"), --(boolean)
			#("CausticRadius",true,"Caustic Radius"), --(float)
			#("CausticsFilter",true,"Caustics Filter"), --(integer)
			#("Kernel",true,"Caustic Kernel"), --(float)
			#("CausticOpaqueShadows",true,"Caustic Opaque Shadows"), --(boolean)
			#("GlobalIllumEnable",true,"Global Illum Enable"), --(boolean)
			#("GlobalIllumAccuracy",true,"Global Illum Accuracy"), --(integer)
			#("UseGlobalIllumRadius",true,"Use Global Illum Radius"), --(boolean)
			#("GlobalIllumRadius",true,"Global Illum Radius"), --(float)
			#("GIPhotonMergeDistance",true,"Global Illum Photon Merge Distance"), --(float)
			#("VolumeAccuracy",true,"Volume Accuracy"), --(integer)
			#("UseVolumeRadius",true,"Use Volume Radius"), --(boolean)
			#("VolumeRadius",true,"Volume Radius"), --(boolean)
			#("CausticMultiplierScalar",true,"Caustics Multiplier Scalar"), --(float)
			#("CausticMultiplierColor",true,"Caustics Enable"), --(color)
			#("GIMultiplierScalar",true,"Global Illum Multiplier Scalar"), --(float)
			#("GIMultiplierColor",true,"Global Illum Multiplier Color"), --(color)
			#("IBLEnable",true,"IBL Enable"), --(boolean) ~new in Max2014
			#("IBLQuality",true,"IBL Quality"), --(float) ~new in Max2014
			#("IBLLighting",true,"IBL Lighting"), --(integer) ~new in Max2014
			#("IBLShadows",true,"IBL Shadows"), --(integer) ~new in Max2014
			#("FinalGatherEnable2",true,"Final Gather Enable"), --(boolean)
			#("UseFinalGatherFile",true,"Use Final Gather File"), --(boolean)
			#("FinalGatherFreeze",true,"FinalGatherFreeze"), --(boolean) ~new in Max2010
			#("FinalGatherPreview",true,"Final Gather Preview"), --(boolean) ~removed in Max2016
			#("FinalGatherFalloff",true,"Final Gather Falloff"), --(boolean)
			#("FinalGatherUseRadiusInterpolation",true,"Final Gather Use Radius Interpolation"), --(boolean) ~removed in Max2016
			#("UseFinalGatherRadius",true,"Use Final Gather Radius"), --(boolean) ~removed in Max2016
			#("UseFinalGatherMinRadius",true,"Use Final Gather Min. Radius"), --(boolean) ~removed in Max2016
			#("FinalGatherView",true,"Final Gather View"), --(boolean) ~removed in Max2016
			#("FinalGatherAccuracy",true,"Final Gather Accuracy"), --(integer)
			#("FinalGatherInterpolationSamples",true,"Final Gather Interpolation Samples"), --(integer)
			#("FinalGatherBounces",true,"Final Gather Bounces"), --(integer)
			#("FinalGatherFilter",true,"Final Gather Filter"), --(integer)
			#("FinalGatherTraceDepth",true,"Final Gather Trace Depth"), --(integer)
			#("FinalGatherReflectionDepth",true,"Final Gather Reflection Depth"), --(integer)
			#("FinalGatherRefractionDepth",true,"Final Gather Refraction Depth"), --(integer)
			#("FinalGatherDensity",true,"Final Gather Density"), --(float)
			#("FinalGatherBounceMultiplier",true,"Final Gather Bounce Weight"), --(float)
			#("FinalGatherFalloffStart",true,"Final Gather Falloff Start"), --(float)
			#("FinalGatherFalloffStop",true,"Final Gather Falloff Stop"), --(float)
			#("FinalGatherRadius",true,"Final Gather Radius"), --(float) ~removed in Max2016
			#("FinalGatherRadius_View",true,"Final Gather Radius View"), --(float) ~removed in Max2016
			#("FinalGatherMinRadius",true,"Final Gather Min. Radius"), --(float) ~removed in Max2016
			#("FinalGatherMinRadius_View",true,"Final Gather Min. Radius View"), --(float) ~removed in Max2016
			#("FGMultiplierScalar",true,"Final Gather Multiplier"), --(float)
			#("FGMultiplierColor",true,"Final Gather Multiplier Color"), --(color)
			#("FinalGatherFilename",false,"Final Gather Filename"), --(string)
			#("FinalGatherTempFilename",false,"Final Gather Temp Filename"), --(string) ~new in Max2010
			#("PhotonMapUseFile",true,"Photon Map Use File"), --(boolean)
			#("PhotonMapFilename",false,"Photon Map Filename"), --(string)
			#("GIMaximumReflections",true,"GI Maximum Reflections"), --(integer)
			#("GIMaximumRefractions",true,"GI Maximum Refractions"), --(integer)
			#("GIMaximumTraceDepth",true,"GI Maximum Trace Depth"), --(integer)
			#("OverrideIIObjProps",true,"Override Obj Props"), --(boolean)
			#("GlobalLightDecay",true,"Global Light Decay"), --(float)
			#("GlobalLightCausticPhotons",true,"Global Light Caustic Photons"), --(integer)
			#("GlobalLightGIPhotons",true,"Global Light GI Photons"), --(integer)
			#("FinalGatherOnly",true,"Final Gather Only"), --(boolean) ~new in Max2010
			#("PhotonFreeze",true,"Photon Freeze"), --(boolean) ~new in Max2010
			#("PhotonsOnly",true,"Photons Only"), --(boolean) ~new in Max2010
			#("FGInterpolateNFrames",true,"FG Interpolate N Frames"), --(integer) ~new in Max2010
			#("IlluminationCacheMode",true,"Illumination Cache Mode"), --(integer) ~new in Max2010
			#("SkipFinalRender",true,"Skip Final Render"), --(boolean) ~new in Max2010
			#("RaytraceMethod",true,"Raytrace Method"), --(integer)
			#("BSPDepth",true,"BSP Depth"), --(integer)
			#("BSPSize",true,"BSP Size"), --(integer)
			--#("DistributedEnable",true,"Distributed Enable") --(boolean) ~new in Max2010
			#("LocalBitmaps",true,"Local Bitmaps"), --(boolean)
			#("SlavesOnly",true,"Slaves Only"), --(boolean)
			#("DiagnosticGridMethod",true,"Diagnostic Grid Method"), --(integer)
			#("DiagnosticGridSize",true,"Diagnostic Grid Size"), --(float)
			#("DiagnosticPhotonMethod",true,"Diagnostic Photon Method"), --(integer)
			#("DiagnosticBSPMethod",true,"Diagnostic BSP Method"), --(integer)
			#("DiagnosticsEnabled",true,"Diagnostics Enabled"), --(boolean)
			#("DiagnosticMode",true,"Diagnostic Mode"), --(integer)
			#("Use_Placeholders",true,"Use Placeholders"), --(boolean)
			#("Memory_Limit",true,"Memory Limit"), --(integer)
			#("Memory_Limit_Auto",true,"Memory Limit Auto"), --(integer)
			#("Export_On_Render",true,"Export_On_Render"), --(boolean)
			#("Incremental_Echo",true,"Incremental_Echo"), --(boolean) ~new in Max2010
			#("Export_Filename",false,"Export_Filename"), --(string)
			#("Conserve_Memory",true,"Conserve Memory"), --(boolean)
			#("mental_ray_Manages_Maps",true,"mental ray Manages Maps"), --(boolean)
			#("Skip_Texture_Maps",true,"Skip Texture Maps"), --(boolean)
			#("Export_ASCII",true,"Export_ASCII"), --(boolean)
			#("Displace_Method",true,"Displace_Method"), --(integer) ~new in Max2016
			#("Edge_Length",true,"Displacement: Edge Length"), --(float)
			#("Max_Level",true,"Displacement: Max Level"), --(integer)
			#("Max_Displace",true,"Displacement: Max Displace"), --(float)
			#("EnableContours",true,"Enable Contours"),
			#("Enable_Material_Override",true,"Enable Material Override"),
			--#("Override_Material",false,"Override_Material"), --(material) --unsupported
			--#("Contour_Contrast_Shader",false,"Contour_Contrast_Shader"), --(shader) --unsupported
			--#("Contour_Store_Shader",false,"Contour_Store_Shader"), --(shader) --unsupported
			--#("Contour_Output_Shader",false,"Contour_Output_Shader"), --(shader) --unsupported
			--#("Camera_Lens_Shader",false,"Camera_Lens_Shader"), --(shader) --unsupported
			--#("Camera_Output_Shader",false,"Camera_Output_Shader"), --(shader) --unsupported
			#("Enable_Camera_Lens_Shader",true,"Enable_Camera_Lens_Shader"), --(boolean)
			#("Enable_Camera_Output_Shader",true,"Enable_Camera_Output_Shader"), --(boolean)
			#("Enable_Camera_Volume_Shader",true,"Enable_Camera_Volume_Shader"), --(boolean)
			#("Enable_Subset_Pixel_Rendering",true,"Enable Subset Pixel Rendering"), --(boolean)
			#("glossyreflectionsprecision",true,"Glossy Reflections Precision"), --(float)
			#("glossyrefractionsprecision",true,"Glossy Refractions Precision"), --(float)
			#("softshadowsprecision",true,"Soft Shadows Precision"),
			#("LockGeometryCache",true,"Lock Geometry Cache"), --(boolean) ~new in Max2010
			#("EnableGeometryCache",true,"Enable Geometry Cache"), --(boolean) ~new in Max2010
			--#("IsGeometryCacheEmpty",true,"Is Geometry Cache Empty"), --(boolean) ~new in Max2010, read-only
			--#("LastTotalNonRenderTime_ms", true, "Last Total Non Render Time_ms"), --(integer) ~new in Max2010, read-only
			--#("LastTotalGeomTranslationTime_ms",true,"Last Total Geom Translation Time_ms"), --(integer) ~new in Max2010, read-only
			#("FGProjectionMode",true,"FG Projection Mode"), --(integer) ~new in Max2010
			#("FGProjectionModeNumSegments",true,"FG Projection Mode Num Segments"), --(integer) ~new in Max2010
			--#("numFinalGatherPresets",true,"num Final Gather Presets"), --(integer) ~new in Max2010, read-only
			--#("numIndirectDiffusePresets",true,"num Indirect Diffuse Presets"), --(integer) ~new in Max2017, read-only

			--OLD Mental Ray properties, now removed in Max2010 or earlier (legacy support)
			#("FinalGatherFastLookups",true,"Final Gather Fast Lookups"),
			#("FinalGatherRebuild",true,"Final Gather Rebuild"),
			#("GlobalLightEnergyMultiplier",true,"Global Light Energy Multiplier"),
			#("GridDepth",true,"Grid Depth"),
			#("GridResolution",true,"Grid Resolution"),
			#("GridSize2",true,"Grid Size2"),			
			#("MotionBlurAllObjects",true,"MotionBlur: All Objects"),
			#("PhotonMapRebuild",true,"Photon Map Rebuild"),
			#("Render_Element_Final_Pass",true,"Render Element Final Pass")
		)
		
		setCurrentRendererSetting options_array
		
		local options_array = #(
			#("MinimumSamples", "Minimum Samples", #("1/64","1/16", "1/4", "1", "4", "16", "64", "256", "1024"), 4 ),
			#("MaximumSamples", "Maximum Samples", #("1/64","1/16", "1/4", "1", "4", "16", "64", "256", "1024"), 4 ),
			#("filter", "Filter Type", #("Box", "Gauss", "Triangle", "Mitchell", "Lanczos"), 1 ),
			#("TaskOrder", "Bucket Order", #("Hilbert (best)", "Spiral", "Left to right", "Right to left", "Top-down", "Bottom-up"), 1 ),
			#("RapidCollectRate", "RapidCollectRate (Fast Rasterizer : Samples per Pixel)", for i = 1 to 15 collect ((i*i) as string), 0 )
		)
		
		setCurrentRendererEnumIndex options_array
		
	)--end if mental ray
--END MENTAL RAY SPECIFIC SETTINGS	

--FINAL RENDER SPECIFIC SETTINGS
	if getRendererIdString() == "finalrender" do
	(
		local options_array = #(
			#("useAntialiasing",true,"useAntialiasing"),
			#("aaQuality",true,"aaQuality"),
			#("filterImage",true,"filterImage"),
			#("aaFilterName",false,"aaFilterName"),
			#("aaFilterSize",true,"aaFilterSize"),
			#("filterMaps",true,"filterMaps"),
			
			#("bucketReverseOrder",true,"bucketReverseOrder"),
			#("bucketColor",true,"bucketColor"),
			#("displayMessages",true,"displayMessages"),
			#("saveLogToFile",true,"saveLogToFile"),
			#("logFilePath",false,"logFilePath"),
			#("checkForMissingFiles",true,"checkForMissingFiles"),
			#("verboseLevel",true,"verboseLevel"),
			#("useLowPriority",true,"useLowPriority"),
			
			#("clearColor",true,"clearColor"),
			#("trackMouseInVFB",true,"trackMouseInVFB"),
			
			#("useInformationStamp",true,"useInformationStamp"),
			#("useHeader",true,"useHeader"),
			#("header",false,"header"),
			#("useFooter",true,"useFooter"),
			#("footer",false,"footer"),
			#("transparency",true,"transparency"),
			#("blurriness",true,"blurriness"),
			
			#("useMicroTriangleDisplacement",true,"useMicroTriangleDisplacement"),
			#("mtdSubdivisionLevel",true,"mtdSubdivisionLevel"),
			#("mtdHeight",true,"mtdHeight"),
			#("mtdViewDependend",true,"mtdViewDependend"),
			#("mtdEdgeLength",true,"mtdEdgeLength"),
			#("mtdThreshold",true,"mtdThreshold"),
			#("mtdUseSmoothingAngle",true,"mtdUseSmoothingAngle"),
			#("mtdSmoothingAngle",true,"mtdSmoothingAngle"),
			#("mtdKeepEdges",true,"mtdKeepEdges"),
			#("mtdRoundGeometry",true,"mtdRoundGeometry"),
			#("mtdViewClipping",true,"mtdViewClipping"),
			#("mtdMapGeometry",true,"mtdMapGeometry"),
			#("mtdMaxCompatibleMesh",true,"mtdMaxCompatibleMesh"),
			#("mtdDisableLocals",true,"mtdDisableLocals"),
			
			#("useDOF",true,"useDOF"),
			#("shutterSize",true,"shutterSize"),
			#("dofMaxSamples",true,"dofMaxSamples"),
			#("lensAngle",true,"lensAngle"),
			#("useCameraDistance",true,"useCameraDistance"),
			#("dofTargetDistance",true,"dofTargetDistance"),
			
			#("colorMapUse",true,"colorMapUse"),
			#("darkMultiplier",true,"darkMultiplier"),
			#("brightMultiplier",true,"brightMultiplier"),
			#("colorMapAffectBackground",true,"colorMapAffectBackground"),
			
			#("useMotionBlur",true,"useMotionBlur"),
			#("useObjMotionBlur",true,"useObjMotionBlur"),
			#("useCameraMotionBlur",true,"useCameraMotionBlur"),
			#("useOMblurTrails",true,"useOMblurTrails"),
			#("oMBlurDuration",true,"oMBlurDuration"),
			#("oMBlurPhase",true,"oMBlurPhase"),
			#("oMBlurMeshSamples",true,"oMBlurMeshSamples"),
			#("oMBlurMaxSamples",true,"oMBlurMaxSamples"),
			#("forceTweenMode",true,"forceTweenMode"),
			#("applyToMtls",true,"applyToMtls"),
			
			#("totalBounces",true,"totalBounces"),
			#("reflectBounces",true,"reflectBounces"),
			#("refractBounces",true,"refractBounces"),
			#("shadowBounces",true,"shadowBounces"),
			
			#("useReflections",true,"useReflections"),
			#("useRefractions",true,"useRefractions"),
			#("rayThreshold",true,"rayThreshold"),
			#("totalIntReflections",true,"totalIntReflections"),
			#("filterMapsFactor",true,"filterMapsFactor"),
			#("atmosphereIOR",true,"atmosphereIOR"),
			#("clipTransFromGBuffer",true,"clipTransFromGBuffer"),
			#("clipTransThreshold",true,"clipTransThreshold"),
			#("useBlurry",true,"useBlurry"),
			#("rtDisableLocals",true,"rtDisableLocals"),
			#("shadeAtmospherics",true,"shadeAtmospherics"),
			#("shadeScattering",true,"shadeScattering"),
			
			#("geomSmpMaxSamples",true,"geomSmpMaxSamples"),
			#("geomSmpRadius",true,"geomSmpRadius"),
			#("geomSmpIteration",true,"geomSmpIteration"),
			#("geomSmpShow",true,"geomSmpShow"),
			
			#("useCaustics",true,"useCaustics"),
			#("useVolumeCaustics",true,"useVolumeCaustics"),
			#("useReflectCaustics",true,"useReflectCaustics"),
			#("useRefractCaustics",true,"useRefractCaustics"),
			#("csDisableLocals",true,"csDisableLocals"),
			#("causticMultiplier",true,"causticMultiplier"),
			
			#("useSkyLight",true,"useSkyLight"),
			
			#("skyColorMultiplier",true,"skyColorMultiplier"),
			#("skyColor",true,"skyColor"),
			#("skySamples",true,"skySamples"),
			#("useSkyTransparency",true,"useSkyTransparency"),
			
			#("phySkyMultiplier",true,"phySkyMultiplier"),
			#("useSunlight",true,"useSunlight"),
			#("sunlightMultiplier",true,"sunlightMultiplier"),
			#("phySkyShowInEnvironment",true,"phySkyShowInEnvironment"),
			#("phySkyEnvMultiplier",true,"phySkyEnvMultiplier"),
			#("phySkyTurbidity",true,"phySkyTurbidity"),
			#("phySkyWater",true,"phySkyWater"),
			#("phySkyOzone",true,"phySkyOzone"),
			#("phySkyHours",true,"phySkyHours"),
			#("phySkyMinutes",true,"phySkyMinutes"),
			#("phySkySeconds",true,"phySkySeconds"),
			#("phySkyDay",true,"phySkyDay"),
			#("phySkyMonth",true,"phySkyMonth"),
			#("phySkyYear",true,"phySkyYear"),
			#("phySkyGMTOffset",true,"phySkyGMTOffset"),
			#("phySkyTimeOffset",true,"phySkyTimeOffset"),
			#("phySkyDaylightSavingTime",true,"phySkyDaylightSavingTime"),
			#("phySkyLongitude",true,"phySkyLongitude"),
			#("phySkyLatitude",true,"phySkyLatitude"),
			#("phySkyFilter",true,"phySkyFilter"),
			#("phySkySaturation",true,"phySkySaturation"),
			#("sunlightFilter",true,"sunlightFilter"),
			#("sunlightSaturation",true,"sunlightSaturation"),
			#("phySkyEnvFilter",true,"phySkyEnvFilter"),
			#("phySkyEnvSaturation",true,"phySkyEnvSaturation"),
			#("phySkyShadowAngle",true,"phySkyShadowAngle"),
			#("phySkyShadowAngleOffset",true,"phySkyShadowAngleOffset"),
			#("phySkyShadowSamples",true,"phySkyShadowSamples"),
			#("phySkyShadowBias",true,"phySkyShadowBias"),
			#("phySkyenableVisibleSun",true,"phySkyenableVisibleSun"),
			#("phySkyVisibleSunRadius",true,"phySkyVisibleSunRadius"),
			#("phySkyVisibleSunMultiplier",true,"phySkyVisibleSunMultiplier"),
			#("phySkyVisibleSunSharpness",true,"phySkyVisibleSunSharpness"),
			
			#("giEnable",true,"giEnable"),
			#("giBounces",true,"giBounces"),
			#("giMultiplier",true,"giMultiplier"),
			#("giSecMultiplier",true,"giSecMultiplier"),
			#("giColorBleeding",true,"giColorBleeding"),
			#("giContrast",true,"giContrast"),
			#("giContrastRange",true,"giContrastRange"),
			#("giHdriAngle",true,"giHdriAngle"),
			#("giDowngradeThreshold",true,"giDowngradeThreshold"),
			#("giDowngradeColor",true,"giDowngradeColor"),
			#("giDisableLocals",true,"giDisableLocals"),
			#("giRenderCaustics",true,"giRenderCaustics"),
			#("giShadeAtmospheric",true,"giShadeAtmospheric"),
			#("giShadeBG",true,"giShadeBG"),
			#("giShade3S",true,"giShade3S"),
			#("giShowDirectLight",true,"giShowDirectLight"),
			#("aoEnable",true,"aoEnable"),
			#("aoDiffuse",true,"aoDiffuse"),
			#("aoBlend",true,"aoBlend"),
			#("aosamples",true,"aosamples"),
			#("aoDistance",true,"aoDistance"),
			
			#("useDefLights",true,"useDefLights"),
			#("renderHiddenLights",true,"renderHiddenLights"),
			#("useMappings",true,"useMappings"),
			#("useSSS",true,"useSSS"),
			#("useShadows",true,"useShadows"),
			#("enhanceBumpShadows",true,"enhanceBumpShadows"),
			#("bumpShadowsFactor",true,"bumpShadowsFactor")
		)
		
		setCurrentRendererSetting options_array
		
		local options_array = #(
			#("bucketSize", "Bucket Size", #("16","32","64","128","256"), 1 ),
			#("bucketOrder", "Bucket Order", #("Top to Bottom","Left to Right","Spiral","Random","Hilbert"), 1 ),
			#("clearOptions", "Clear Options", #("Nothing","Clear Buffer","Clear Grid","Darken"), 1 ),
			#("storage", "Storage", #("int (8 bpc)","int (16 bpc)","float (32 bpc)"), 1 ),
			#("mtdMode", "MTD Mode", #("Intensity","Intensity Centered","Vector Local Space","Vector Camera Space","Vector World Space"), 1 ),
			#("lensType", "Lens Type", #("Circular","Rhombic","Hexagon","Octagon","Triangle","Pentagon","Heptagon","Nanogon"), 1 ),
			#("colorMapType", "Color Map Type", #("Linear","Exponential","HSV Exponential","Gamma"), 1 ),
			#("geomSmpMode", "Sampling Mode", #("Absolute","Relative","Automatic"), 1 ),
			#("skyType", "Skylight Type", #("Simple Sky","Physical Sky"), 1 )
		)
		
		setCurrentRendererEnumIndex options_array
	)
--END FINAL RENDER SPECIFIC SETTINGS

--VRAY / VRAY RT SPECIFIC SETTINGS:
	if getRendererIdString() == "vray" OR getRendererIdString() == "vrayrt" do
	(
		if getRendererIdString() == "vray" then
		(
			rendererID = "vray"
			DeadlineUtil.LogMessage ">V-Ray detected as current renderer."
		)
		else
		(
			rendererID = "vrayrt"
			DeadlineUtil.LogMessage ">V-Ray RT detected as current renderer."
		)

		--Check VRay version. Function available in VRay v3+
		vrayVersionCheck = try(vrayVersion())catch(undefined) --2 element array returned in VRay v3.0+ only #(version, build)
		if vrayVersionCheck != undefined then (
			DeadlineUtil.LogMessage ( ">V-Ray version, build: " + (vrayVersionCheck as string) )
			vrayVer = vrayVersionCheck[1][1] as integer
		)
		else ( vrayVer = 2 )

		vfbRegionEnabled = try(vrayVFBGetRegionEnabled())catch(False)
		if vfbRegionEnabled do DeadlineUtil.LogMessage( ">VFB region rendering enabled: " + (vrayVFBGetRegion() as string) )
		
		try
		(
			setVRaySilentMode()
			DeadlineUtil.LogMessage ">Enabled V-Ray silent mode"
		)
		catch
		(
			DeadlineUtil.WarnMessage "--Failed to enable V-Ray silent mode"
		)
		
		--Each element of the array is a sub-array containing
		--1. the name of the property as string, 
		--2. whether to convert the value to maxscript value or keep as string, 
		--3. the description string used to output to the log file.
		
		--NOTE: Some of the properties exposed to MAXScript are not exposed to the V-Ray Render UI or are un-supported.
		--We have disabled those and have not exposed them in the Deadline 3dsmax Properties tab.

		curRenderSettings = renderers.current
		if getRendererIdString() == "vrayrt" do
		(
			curRenderSettings = renderers.current.V_Ray_settings
		)
		
		local vray_options_array = #(
			#("filter_on",true,"filter_on"),
--			#("filter_Kernel",true,"filter_Kernel"), --vr.filter_Kernel = execute( "Area()" )
			#("filter_size",true,"filter_size"),
--			#("filter_paramA",true,"filter_paramA"),
--			#("filter_ParamB",true,"filter_ParamB"),
--			#("filter_paramC",true,"filter_paramC"),

			#("imageSampler_shadingRate",true,"imageSampler_shadingRate"), --v3
			#("imageSampler_renderMask_type",true,"imageSampler_renderMask_type"), --v3
--			#("imageSampler_renderMask_texmap",false,"imageSampler_renderMask_texmap (notUsed)"), --v3
-- 			#("imageSampler_renderMask_objectIDs",false,"imageSampler_renderMask_objectIDs (notUsed)"), --v3.1
--			#("imageSampler_renderMask_texmap",false,"imageSampler_renderMask_texmap"), --v3.45 --renamed from above
--			#("imageSampler_renderMask_objectIDs",false,"imageSampler_renderMask_objectIDs"), --v3.45 --renamed from above

			#("dmc_balance_subdivs",true,"dmc_balance_subdivs (dmc_balanceSubdivs)"), --v3
			#("dmc_useBlueNoiseOptimization",true,"dmc_useBlueNoiseOptimization (dmc_useBlueNoiseOptimization)"), --v5
--			#("imageSampler_renderMask_layers",false,"imageSampler_renderMask_layers"), --v3
			#("imageSampler_ui_view",true,"imageSampler_ui_view"), --v3.35.01 UI [Basic/Advanced/Expert]
--			#("imageSamper_renderMask_layers",true,"imageSamper_renderMask_layers (alias for imageSampler_renderMask_layers)"), --v3 
--			#("imageSamper_renderMask_texmap",true,"imageSamper_renderMask_texmap (alias for imageSampler_renderMask_texmap)"), --v3

			#("fixedRate_subdivs",true,"fixedRate_subdivs"),
--			#("fixedRate_rand",true,"fixedRate_rand"),

			#("twoLevel_baseSubdivs",true,"twoLevel_baseSubdivs"),
			#("twoLevel_fineSubdivs",true,"twoLevel_fineSubdivs"),
			#("twoLevel_showSamples",true,"twoLevel_showSamples"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("twoLevel_useDMCSamplerThresh",true,"twoLevel_useDMCSamplerThresh (twoLevel_useMCSamplerThresh)"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("twoLevel_threshold",true,"twoLevel_threshold"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("twoLevel_adaptiveMethod",true,"twoLevel_adaptiveMethod"), --v3.35

			#("twoLevel_adaptiveEnable",true,"twoLevel_adaptiveEnable"), -- v3.45.01 --boolean
			#("twoLevel_bucket_width",true,"twoLevel_bucket_width"), -- v3.45.01 --integer
			#("twoLevel_bucket_height",true,"twoLevel_bucket_height"), -- v3.45.01 --integer
			#("twoLevel_bucket_lockSize",true,"twoLevel_bucket_lockSize"), -- v3.45.01 --boolean

			#("adaptiveSubdivision_minRate",true,"adaptiveSubdivision_minRate"),
			#("adaptiveSubdivision_maxRate",true,"adaptiveSubdivision_maxRate"),
			#("adaptiveSubdivision_threshold",true,"adaptiveSubdivision_threshold"),
			#("adaptiveSubdivision_rand",true,"adaptiveSubdivision_rand"),
			#("adaptiveSubdivision_showSamples",true,"adaptiveSubdivision_showSamples"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("adaptiveSubdivision_dofMoblurSubdivs",true,"adaptiveSubdivision_dofMoblurSubdivs (adaptiveSubdivision_dofMoblur_subdivs)"), --v3

			#("imageSampler_outline",true,"imageSampler_outline"),
--			#("imageSampler_mtlID",true,"imageSampler_mtlID"),
			#("imageSampler_normal",true,"imageSampler_normal"),
			#("imageSamper_normal_threshold",true,"imageSamper_normal_threshold"),
--			#("imageSampler_zvalue",true,"imageSampler_zvalue"),
--			#("imageSampler_zvalue_threshold",true,"imageSampler_zvalue_threshold"),

			#("progressive_minSamples",true,"progressive_minSamples"), --v3
			#("progressive_maxSamples",true,"progressive_maxSamples"), --v3
			#("progressive_noise_threshold",true,"progressive_noise_threshold"), --v3
			#("progressive_max_render_time",true,"progressive_max_render_time"), --v3
			#("progressive_ray_bundle_size",true,"progressive_ray_bundle_size"), --v3
			#("progressive_show_mask",true,"progressive_show_mask"), --v3
			#("progressive_track_radius",true,"progressive_track_radius"), --v3.1, Exposed in Deadline v7.1
			#("progressive_dynNoiseThreshold",true,"progressive_dynNoiseThreshold"), --v3.35

			#("gi_ui_view",true,"gi_ui_view"), --v3 UI [Basic/Advanced/Expert]
			#("gi_on",true,"gi_on"),
			#("gi_reflectCaustics",true,"gi_reflectCaustics"),
			#("gi_refractCaustics",true,"gi_refractCaustics"),
			#("gi_primary_Multiplier",true,"gi_primary_Multiplier"),
			#("gi_secondary_Multiplier",true,"gi_secondary_Multiplier"),
			#("gi_saturation",true,"gi_saturation"),
			#("gi_contrast",true,"gi_contrast"),
			#("gi_contrast_base",true,"gi_contrast_base"),
			#("gi_saveMapsPerFrame",true,"gi_saveMapsPerFrame"),
			#("gi_ao_on",true,"gi_ao_on"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("gi_ao_amount",true,"gi_ao_amount"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("gi_ao_radius",true,"gi_ao_radius"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("gi_ao_subdivs",true,"gi_ao_subdivs"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("gi_rayDistanceOn",true,"gi_rayDistanceOn"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("gi_rayDistance",true,"gi_rayDistance"), --VRay v2 Setting, Exposed in Deadline v6.1

			#("irradmap_ui_view",true,"irradmap_ui_view"), --v3 [Basic/Advanced/Expert]
			#("gi_irradmap_minRate",true,"gi_irradmap_minRate"),
			#("gi_irradmap_maxRate",true,"gi_irradmap_maxRate"),
			#("gi_irradmap_subdivs",true,"gi_irradmap_subdivs"),
			#("gi_irradmap_interpSamples",true,"gi_irradmap_interpSamples"),
			#("gi_irradmap_colorThreshold",true,"gi_irradmap_colorThreshold"),
			#("gi_irradmap_normalThreshold",true,"gi_irradmap_normalThreshold"),
			#("gi_irradmap_distThreshold",true,"gi_irradmap_distThreshold"),
			#("gi_irradmap_showSamples",true,"gi_irradmap_showSamples"),
			#("gi_irradmap_showCalcPhase",true,"gi_irradmap_showCalcPhase"),
			#("gi_irradmap_showDirectLight",true,"gi_irradmap_showDirectLight"),
--			#("gi_irradmap_preset",true,"gi_irradmap_preset"), --VRay v2 Setting, Exposed in Deadline v6.1

			#("adv_irradmap_dontDelete",true,"adv_irradmap_dontDelete"),
--			#("adv_irradmap_loadFileName",false,"adv_irradmap_loadFileName"),
--			#("adv_irradmap_saveFileName",false,"adv_irradmap_saveFileName"),
			#("adv_irradmap_calcInterpSamples",true,"adv_irradmap_calcInterpSamples"),
			#("adv_irradmap_useCurrentPassSamples",true,"adv_irradmap_useCurrentPassSamples"),
--			#("adv_irradmap_autoSave",true,"adv_irradmap_autoSave"),
--			#("adv_irradmap_autoSaveFileName",false,"adv_irradmap_autoSaveFileName"),
			#("adv_irradmap_switchToSavedMap",true,"adv_irradmap_switchToSavedMap"),
			#("adv_irradmap_randomize",true,"adv_irradmap_randomize"),
			#("adv_irradmap_checkSampleVisibility",true,"adv_irradmap_checkSampleVisibility"),
--			#("adv_irradmap_limitSearchRange",true,"adv_irradmap_limitSearchRange"),

			#("gi_irradmap_multipleViews",true,"gi_irradmap_multipleViews"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("gi_irradmap_blurGI",true,"gi_irradmap_blurGI"),
			#("gi_irradmap_detail_on",true,"gi_irradmap_detail_on (irradmap_detail_on)"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("gi_irradmap_detail_radius",true,"gi_irradmap_detail_radius (irradmap_detail_radius)"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("gi_irradmap_detail_subdivsMult",true,"gi_irradmap_detail_subdivsMult (irradmap_detail_subdivsMult)"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("gi_irradmap_interpFrames",true,"gi_irradmap_interpFrames"), --VRay v2 Setting, Exposed in Deadline v6.1

			#("caustics_ui_view",true,"caustics_ui_view"), --v3 [Basic/Advanced]
			#("caustics_on",true,"caustics_on"),
			#("caustics_searchDist",true,"caustics_searchDist"),
			#("caustics_maxPhotons",true,"caustics_maxPhotons"),
			#("caustics_multiplier",true,"caustics_multiplier"),
--			#("caustics_mode",true,"caustics_mode"),
			#("caustics_dontDelete",true,"caustics_dontDelete"),
--			#("caustics_loadFileName",false,"caustics_loadFileName"),
--			#("caustics_saveFileName",false,"caustics_saveFileName"),
			#("caustics_autoSave",true,"caustics_autoSave"),
--			#("caustics_autoSaveFileName",false,"caustics_autoSaveFileName"),
			#("caustics_switchToSavedMap",true,"caustics_switchToSavedMap"),
			#("caustics_maxDensity",true,"caustics_maxDensity (caustics_maxDens)"),
			#("caustics_showCalcPhase",true,"caustics_showCalcPhase (caustics_directVisualization)"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("casutics_autoSave",true,"casutics_autoSave (alias for caustics_autoSave)"), --original spelling typo by ChaosGroup

			#("environment_gi_on",true,"environment_gi_on"),
			#("environment_gi_color",true,"environment_gi_color"),
			#("environment_gi_color_multiplier",true,"environment_gi_color_multiplier"),
--			#("environment_gi_map",false,"environment_gi_map"),
			#("environment_gi_map_on",true,"environment_gi_map_on"),
			#("environment_rr_on",true,"environment_rr_on"),
			#("environment_rr_color",true,"environment_rr_color"),
			#("environment_rr_color_multiplier",true,"environment_rr_color_multiplier"),
--			#("environment_rr_map",false,"environment_rr_map"),
			#("environment_rr_map_on",true,"environment_rr_map_on"),
			#("environment_refract_on",true,"environment_refract_on"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("environment_refract_color",true,"environment_refract_color"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("environment_refract_color_multiplier",true,"environment_refract_color_multiplier"), --VRay v2 Setting, Exposed in Deadline v6.1
--			#("environment_refract_map",false,"environment_refract_map"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("environment_refract_map_on",true,"environment_refract_map_on"), --VRay v2 Setting, Exposed in Deadline v6.1

			#("environment_secondaryMatte_on",true,"environment_secondaryMatte_on"), --v3.1, Exposed in Deadline v7.1
			#("environment_secondaryMatte_color",true,"environment_secondaryMatte_color"), --v3.1, Exposed in Deadline v7.1
			#("environment_secondaryMatte_color_multiplier",true,"environment_secondaryMatte_color_multiplier"), --v3.1, Exposed in Deadline v7.1
--			#("environment_secondaryMatte_map",false,"environment_secondaryMatte_map"), --v3.1, Exposed in Deadline v7.1
			#("environment_secondaryMatte_map_on",true,"environment_secondaryMatte_map_on"), --v3.1, Exposed in Deadline v7.1

			#("colormapping_ui_view",true,"colormapping_ui_view"), --v3 [Basic/Advanced/Expert]
--			#("gbuffer_channelMask",true,"gbuffer_channelMask"),
			#("colorMapping_type",true,"colorMapping_type"),
			#("colorMapping_darkMult",true,"colorMapping_darkMult"),
			#("colorMapping_brightMult",true,"colorMapping_brightMult"),
			#("colorMapping_gamma",true,"colorMapping_gamma"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("colorMapping_affectBackground",true,"colorMapping_affectBackground"),
			#("colorMapping_clampOutput",true,"colorMapping_clampOutput"),
			#("colorMapping_clampLevel",true,"colorMapping_clampLevel"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("colorMapping_subpixel",true,"colorMapping_subpixel"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("colorMapping_linearWorkflow",true,"colorMapping_linearWorkflow"), --VRay v2 Setting, Exposed in Deadline v6.1

			#("camera_overrideFOV",true,"camera_overrideFOV"),
			#("camera_fov",true,"camera_fov"),
			#("camera_cyl_height",true,"camera_cyl_height"),
			#("camera_fish_autoDistance",true,"camera_fish_autoDistance"),
			#("camera_fish_distance",true,"camera_fish_distance"),
			#("camera_fish_curve",true,"camera_fish_curve"),

			#("dof_on",true,"dof_on"),
			#("dof_distance",true,"dof_distance"),
			#("dof_getFromCamera",true,"dof_getFromCamera"),
			#("dof_shutter",true,"dof_shutter"),
			#("dof_subdivs",true,"dof_subdivs"),
			#("dof_bias",true,"dof_bias"),
			#("dof_sides_on",true,"dof_sides_on"),
			#("dof_sides_num",true,"dof_sides_num"),
			#("dof_sides_rotation",true,"dof_sides_rotation"),
			#("dof_anisotropy",true,"dof_anisotropy"),

			#("moblur_on",true,"moblur_on"),
			#("camera_motion_blur",true,"camera_motion_blur"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("moblur_duration",true,"moblur_duration"),
			#("moblur_intervalCenter",true,"moblur_intervalCenter"),
			#("moblur_geomSamples",true,"moblur_geomSamples"),
			#("moblur_prepassSamples",true,"moblur_prepassSamples"),
			#("moblur_dmc_minSamples",true,"moblur_dmc_minSamples (moblur_minSamples)"),
			#("moblur_geometryParticles",true,"moblur_geometryParticles"),
			#("moblur_bias",true,"moblur_bias"),
			#("moblur_shutterEfficiency",true,"moblur_shutterEfficiency"), --v3

			#("system_ui_view",true,"system_ui_view"), --v3 [Basic/Advanced/Expert]
--			#("system_distributedRender",true,"system_distributedRender"),
			#("system_raycaster_maxLevels",true,"system_raycaster_maxLevels"),
			#("system_raycaster_minLeafSize",true,"system_raycaster_minLeafSize"),
			#("system_raycaster_faceLevelCoeff",true,"system_raycaster_faceLevelCoeff"),
			#("system_raycaster_memLimit",true,"system_raycaster_memLimit"),
			#("system_raycaster_optLevel",true,"system_raycaster_optLevel"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("system_region_x",true,"system_region_x"),
			#("system_region_y",true,"system_region_y"),
			#("system_region_allow_dynamic_buckets",true,"system_region_allow_dynamic_buckets (Allow_dynamic_buckets_splitting)"), --v3
			#("system_region_sequence_reverse",true,"system_region_sequence_reverse"),
			#("system_region_lockSize",true,"system_region_lockSize"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("system_effects_progressive_update",true,"system_effects_progressive_update"), --v3.57 setting, exposed in Deadline v9.0
			#("system_frameStamp_on",true,"system_frameStamp_on"),
			#("system_frameStamp_string",false,"system_frameStamp_string"),
			#("system_frameStamp_fullWidth",true,"system_frameStamp_fullWidth"),
			#("system_workInCameraSpace",true,"system_workInCameraSpace"),
			#("system_checkForMissingFiles",true,"system_checkForMissingFiles"),
			#("system_optimizedAtmospherics",true,"system_optimizedAtmospherics"),
			#("system_lowThreadPriority",true,"system_lowThreadPriority"),
--			#("system_vrayLog_show",true,"system_vrayLog_show"), --v3.1, due to data type change, now handled within the system_vrayLog_show loop below
			#("system_vrayLog_level",true,"system_vrayLog_level"),
			#("system_vrayLog_file",false,"system_vrayLog_file"),
--			#("system_vrayLog_ccToDebugger",true,"system_vrayLog_ccToDebugger"),
--			#("system_numThreads",true,"system_numThreads"),
			#("system_embree_on",true,"system_embree_on"), --v3
			#("system_embree_moblur",true,"system_embree_moblur"), --v3
			#("system_embree_highPrecision",true,"system_embree_highPrecision"), --v3
			#("system_embree_hair",true,"system_embree_hair"), --v3.1, Exposed in Deadline v7.1
			#("system_embree_conserveMemory",true,"system_embree_conserveMemory"), --v3
			#("system_autoswitch_effectsResult",true,"system_autoswitch_effectsResult"), --v4, Exposed in Deadline v10

			#("qmc_timeDependent",true,"qmc_timeDependent"), --v1 legacy support
			#("qmc_importanceSampling",true,"qmc_importanceSampling"), --v1 legacy support
			#("qmc_earlyTermination_amount",true,"qmc_earlyTermination_amount"), --v1 legacy support
			#("qmc_earlyTermination_threshold",true,"qmc_earlyTermination_threshold"), --v1 legacy support
			#("qmc_earlyTermination_minSamples",true,"qmc_earlyTermination_minSamples"), --v1 legacy support
			#("qmc_subdivs_mult",true,"qmc_subdivs_mult"), --v1 legacy support

			#("dmc_timeDependent",true,"dmc_timeDependent (mc_lockToPixels)"), --v3.1 deprecated, included for legacy support
			#("dmc_lockNoisePattern",true,"dmc_lockNoisePattern (mc_lockNoisePattern)"), --v3.1, Exposed in Deadline v7.1

			#("dmc_importanceSampling",true,"dmc_importanceSampling (mc_importanceSampling)"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("dmc_earlyTermination_amount",true,"dmc_earlyTermination_amount (mc_earlyTermination_amount)"),
			#("dmc_earlyTermination_threshold",true,"dmc_earlyTermination_threshold (mc_earlyTermination_threshold)"),
			#("dmc_earlyTermination_minSamples",true,"dmc_earlyTermination_minSamples (mc_earlyTermination_minSamples)"),
			#("dmc_subdivs_mult",true,"dmc_subdivs_mult (mc_subdivs_mult)"),
			#("dmc_pathSampler_type",true,"dmc_pathSampler_type (mc_pathSampler_type)"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("dmc_randomSeed",true,"dmc_randomSeed"), --VRay v3.2 Setting, Exposed in Deadline v7.2
			#("dmc_useLocalSubdivs",true,"dmc_useLocalSubdivs"), --v3.35
  			#("dmc_optimizeShadingRate",true,"dmc_optimizeShadingRate"), --v3.35
			#("dmc_ui_view",true,"dmc_ui_view"), --v3 [Basic/Advanced] --VRay v3.2 Setting, Exposed in Deadline v7.2

			#("photonMap_bounces",true,"photonMap_bounces"),
			#("photonMap_searchDist",true,"photonMap_searchDist"),
			#("photonMap_autoDist",true,"photonMap_autoDist"),
			#("photonMap_maxPhotons",true,"photonMap_maxPhotons"),
			#("photonMap_convert",true,"photonMap_convert"),
			#("photonMap_interpSamples",true,"photonMap_interpSamples"),
			#("photonMap_multiplier",true,"photonMap_multiplier"),
			#("photonMap_convexHullEstimate",true,"photonMap_convexHullEstimate"),
			#("photonMap_storeDirectLight",true,"photonMap_storeDirectLight"),
			#("photonMap_retraceCorners",true,"photonMap_retraceCorners"),
			#("photonMap_retraceBounces",true,"photonMap_retraceBounces"),
			#("photonMap_maxDensity",true,"photonMap_maxDensity"),
--			#("photonMap_mode",true,"photonMap_mode"),
--			#("photonMap_loadFileName",true,"photonMap_loadFileName"),
--			#("photonMap_saveFileName",true,"photonMap_saveFileName"),
			#("photonMap_dontDelete",true,"photonMap_dontDelete"),
			#("photonMap_autoSave",true,"photonMap_autoSave"),
--			#("photonMap_autoSaveFileName",true,"photonMap_autoSaveFileName"),
			#("photonMap_switchToSavedMap",true,"photonMap_switchToSavedMap"),
			#("photonMap_showCalcPhase",true,"photonMap_showCalcPhase"),

			#("options_ui_view",true,"options_ui_view"), --v3 [Basic/Advanced/Expert]
			#("options_displacement",true,"options_displacement"),
			#("options_lights",true,"options_lights"),
			#("options_hiddenLights",true,"options_hiddenLights"),
			#("options_shadows",true,"options_shadows"),
			#("options_reflectionRefraction",true,"options_reflectionRefraction"),
			#("options_overrideDepth_on",true,"options_overrideDepth_on"), --v3
			#("options_overrideDepth",true,"options_overrideDepth"), --v3
			#("options_maps",true,"options_maps"),
			#("options_filterMaps",true,"options_filterMaps"),
			#("options_transpMaxLevels",true,"options_transpMaxLevels"),
			#("options_transpCutoff",true,"options_transpCutoff"),
			#("options_dontRenderImage",true,"options_dontRenderImage"),
			#("options_overrideMtl_on",true,"options_overrideMtl_on"),
--			#("options_overrideMtl_mtl",true,"options_overrideMtl_mtl"),

--			#("options_overrideMtl_excl_type",true,"options_overrideMtl_excl_type (options_overrideMtl_ExclType)"), --v3.35.01 (enum)
--			#("options_overrideMtl_excl_objectIDs",false,"options_overrideMtl_excl_objectIDs (notUsed)"), --v3.35.01 (string)
--			#("options_overrideMtl_excl_layers",false,"options_overrideMtl_excl_layers"), --v3.35.01 (string array)

			#("options_showGIOnly",true,"options_showGIOnly"),
			#("options_ray_bias",true,"options_ray_bias"),
			#("options_glossyEffects",true,"options_glossyEffects"),
			#("options_geom_backfaceCull",true,"options_geom_backfaceCull"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("options_mtl_filterMaps_indirect",true,"options_mtl_filterMaps_indirect"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("options_mtl_filterMaps_indirect_mult",true,"options_mtl_filterMaps_indirect_mult"), --v3.1, Exposed in Deadline v7.1
			#("options_useLegacyModels",true,"options_useLegacyModels"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("options_use3dsMaxPhotometricUnits",true,"options_use3dsMaxPhotometricUnits"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("options_maxRayIntensity_on",true,"options_maxRayIntensity_on (options_clampRayIntensity)"), --v3
			#("options_maxRayIntensity",true,"options_maxRayIntensity"), --v3
			#("options_probabilisticLights",true,"options_probabilisticLights"), --v3 (fyi - changed from boolean to integer in 3.50.01)
			#("options_probabilisticLightsCount",true,"options_probabilisticLightsCount"), --v3
--			#("options_rgbColorSpace",true,"options_rgbColorSpace"), --v3.35 --Disabled as setting this value to zero (default), causes it to potentially reset other values.
			#("options_limitDepth",true,"options_limitDepth (alias for options_overrideDepth_on)"), --VRay v2 Setting, Exposed in Deadline v6.1?
			#("options_maxDepth",true,"options_maxDepth (alias for options_overrideDepth)"), --VRay v2 Setting, Exposed in Deadline v6.1?
			#("options_useColorSpaceForBitmaps",true,"options_useColorSpaceForBitmaps"), --VRay v5
			#("options_useMikkTS",true,"options_useMikkTS"), --VRay v5

			#("output_on",true,"output_on"), --Now overridden within the overrideShowRendererFB enum loop below
			#("output_aspectlock",true,"output_aspectlock (Lock_aspect)"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("output_imageaspect",true,"output_imageaspect (Image_aspect)"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("output_width",true,"output_width"),
			#("output_height",true,"output_height"),
			#("output_aspect",true,"output_aspect"),
			#("output_fileOnly",true,"output_fileOnly"), --v1 legacy support
			#("output_saveFile",true,"output_saveFile"), --v1 legacy support
			#("output_fileName",false,"output_fileName"), --v1 legacy support
			#("output_saveRawFile",true,"output_saveRawFile"),
			
			#("output_rawFileName",false,"output_rawFileName"), --v3.5+
			#("output_rawFilename",false,"output_rawFilename"), --v3.4
			#("output_rawfilename",false,"output_rawfilename"), --v3.3 or earlier

			#("output_useram",true,"output_useram"),
			#("output_genpreview",true,"output_genpreview (output_genrpeview)"),
			#("output_splitgbuffer",true,"output_splitgbuffer"),
			#("output_splitfilename",false,"output_splitfilename"),
--			#("output_splitbitmap",false,"output_splitbitmap"),
			#("output_getsetsfrommax",true,"output_getsetsfrommax"),
			#("output_splitRGB",true,"output_splitRGB"),
			#("output_splitAlpha",true,"output_splitAlpha"),
--			#("output_renderType",true,"output_renderType"),
--			#("output_regxmin",true,"output_regxmin"),
--			#("output_regxmax",true,"output_regxmax"),
--			#("output_regymin",true,"output_regymin"),
--			#("output_regymax",true,"output_regymax"),
			#("output_force32bit_3dsmax_vfb",true,"output_force32bit_3dsmax_vfb"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("output_rawExrUseHalf",true,"output_rawExrUseHalf"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("output_rawExrDeep",true,"output_rawExrDeep"), --v3
			#("fileName_addDot",true,"fileName_addDot"), --v3.1, Exposed in Deadline v7.1
			#("output_resumableRendering",true,"output_resumableRendering (Resumable_rendering)"), --v3.45, Exposed in Deadline v8.1
			#("output_progressiveAutoSave",true,"output_progressiveAutoSave (Autosave__min)"), --v3.45, Exposed in Deadline v8.1
			#("output_separateFolders",true,"Save_to_separate_folders"), --v3.60.03, Exposed in Deadline v9.0
			#("output_expandFrameNumber",true,"output_expandFrameNumber"), --v4, Exposed in Deadline v10

			#("displacement_overrideMax",true,"displacement_overrideMax"),
			#("displacement_edgeLength",true,"displacement_edgeLength"),
			#("displacement_viewDependent",true,"displacement_viewDependent"),
			#("displacement_maxSubdivs",true,"displacement_maxSubdivs"),
			#("displacement_tightBounds",true,"displacement_tightBounds"),
			#("displacement_amount",true,"displacement_amount"),
			#("displacement_relative",true,"displacement_relative"),

			#("dmcgi_subdivs",true,"qmcgi_subdivs (mcgi_subdivs)"),
			#("dmcgi_depth",true,"qmcgi_depth (mcgi_depth)"),

			#("lightcache_ui_view",true,"lightcache_ui_view"), --v3 [Basic/Advanced/Expert]
			#("lightcache_subdivs",true,"lightcache_subdivs"),
			#("lightcache_sampleSize",true,"lightcache_sampleSize"),
			#("lightcache_filter_size",true,"lightcache_filter_size"),
			#("lightcache_bounces",true,"lightcache_bounces"),
			#("lightcache_showCalcPhase",true,"lightcache_showCalcPhase"),
			#("lightcache_storeDirectLight",true,"lightcache_storeDirectLight"),
			#("lightcache_multipleViews",true,"lightcache_multipleViews"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("lightcache_retrace_on",true,"lightcache_retrace_on"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("lightcache_retrace_threshold",true,"lightcache_retrace_threshold"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("lightcache_retrace_leakPrevention",true,"lightcache_retrace_leakPrevention"), --VRay v3.2 Setting, Exposed in Deadline v7.2
--			#("lightcache_loadFileName",false,"lightcache_loadFileName"),
--			#("lightcache_saveFileName",false,"lightcache_saveFileName"),
			#("lightcache_interpSamples",true,"lightcache_interpSamples"),
			#("lightcache_prefilter_on",true,"lightcache_prefilter_on"),
			#("lightcache_prefilter_samples",true,"lightcache_prefilter_samples"),
			#("lightcache_dontDelete",true,"lightcache_dontDelete"),
-- 			#("lightcache_autoSave",true,"lightcache_autoSave"),
--			#("lightcache_autoSaveFileName",false,"lightcache_autoSaveFileName"),
			#("lightcache_switchToSavedMap",true,"lightcache_switchToSavedMap"),
			#("lightcache_useForGlossyRays",true,"lightcache_useForGlossyRays"),
			#("lightcache_numPasses",true,"lightcache_numPasses"),
			#("lightcache_adaptiveTracing",true,"lightcache_adaptiveTracing"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("lightcache_adaptiveTracing_dirsOnly",true,"lightcache_adaptiveTracing_dirsOnly (lightcahe_adaptiveTracing_dirsOnly)"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("lightcache_premultiplied",true,"lightcache_premultiplied"), --v3.35.01 (boolean)
			#("lightcache_minPathsPerSample",true,"lightcache_minPathsPerSample"), --VRay v2 Setting, Exposed in Deadline v6.1
			#("lightcache_preset_retraceThreshold",true,"lightcache_preset_retraceThreshold"), --v5
			#("lightcache_preset_subdivs",true,"lightcache_preset_subdivs"), --v5
			#("lightcache_type",true,"lightcache_type"), --v5
			#("lightmap_preset",true,"lightmap_preset"), --v5

			#("textures_memLimit",true,"textures_memLimit (memory_limit)"), --v3.35.01 (integer)
			#("textures_clearMem",true,"textures_clearMem (Clear_memory_on_render_end)"), --v3.35.01 (boolean)
			
			#("preview_cache",true,"Use_preview_cache"), --v3.60.03, Exposed in Deadline v9.0
			
			#("ipr_fitToVFB",true,"ipr_fitToVFB"), --v3.60.03, Exposed in Deadline v9.0
			#("ipr_progressiveMode",true,"ipr_progressiveMode"), --v3.60.03, Exposed in Deadline v9.0
			#("ipr_debugshading_ao_radius_pix",true,"ipr_debugshading_ao_radius_pix"), --v5
			#("ipr_debugshading_wireframe_subtris",true,"ipr_debugshading_wireframe_subtris"), --v5
			#("ipr_debugshading_wireframe_width_pix",true,"ipr_debugshading_wireframe_width_pix"), --v5

--			#("excludeListOverrideMtl",true,"excludeListOverrideMtl"),
--			#("includeListOverrideMtl",true,"includeListOverrideMtl"),
--			#("excludeListRenderSubset",true,"excludeListRenderSubset"), --v3
--			#("includeListRenderSubset",true,"includeListRenderSubset"), --v3

			#("camera_autoExposure",true,"camera_autoExposure"), --v4, Exposed in Deadline v10
			#("camera_autoExposure_compensation",true,"camera_autoExposure_compensation"), --v4, Exposed in Deadline v10
			#("camera_autoExposure_mode",true,"camera_autoExposure_mode"), --v4, Exposed in Deadline v10
			#("camera_autoWhiteBalance",true,"camera_autoWhiteBalance") --v4, Exposed in Deadline v10
			
		)

		if rendererID == "vray" then
		(
			setCurrentRendererSetting vray_options_array
		)
		else
		(
			setCurrentRendererSettingVRayRT vray_options_array
		)

		--Special case to override V-Ray Frame Buffer (VFB) visibility:
		local overrideShowRendererFB = DeadlineUtil.GetJobInfoEntry "ShowRendererFrameBufferOverride"
		local showRendererFB = DeadlineUtil.GetJobInfoEntry "ShowRendererFrameBuffer"
		
		if overrideShowRendererFB != undefined and showRendererFB != undefined do
		(
			try
			(
				if( execute( overrideShowRendererFB ) ) then
				(
					if( execute( showRendererFB ) ) then
					(
						curRenderSettings.output_on = true
						DeadlineUtil.LogMessage ("  +Show V-Ray Frame Buffer (VFB) enabled")
					)
					else
					(
						curRenderSettings.output_on = false
						DeadlineUtil.LogMessage ("  +Show V-Ray Frame Buffer (VFB) disabled")
					)
				)
				else
					DeadlineUtil.LogMessage ("  +Not overriding Show V-Ray Frame Buffer (VFB) setting")
			)
			catch(DeadlineUtil.WarnMessage ("  --Failed to set Show V-Ray Frame Buffer (VFB) to " + showRendererFB ) )
		)

		--Special case to handle "vray_system_vrayLog_show" or "vray_system_vrayLog_show_enums":
		if (hasProperty renderers.current #system_vrayLog_show) do
		(
			if classof(renderers.current.system_vrayLog_show) == Integer then
			(
				local options_array = #(
					#("system_vrayLog_show", "Show Log Window", #("Never","Always","Only on error/warning","Only on error"), 1 )
				)
				
				if rendererID == "vray" then
				(
					setCurrentRendererEnumIndex options_array
				)
				else
				(
					setCurrentRendererEnumIndexVRayRT options_array
				)

			)--end if
			else 
			(
				--"vray_system_vrayLog_show" == BooleanClass
				local theVal = DeadlineUtil.GetJobInfoEntry "vray_system_vrayLog_show"
				if theVal != undefined do 
				(
					try 
					(
						if getProperty curRenderSettings #system_vrayLog_show != (execute theVal) do
						(
							setProperty curRenderSettings #system_vrayLog_show (execute theVal)
							DeadlineUtil.LogMessage ("  +Show Log Window set to " + theVal  )
						)
					)
					catch
					(
						DeadlineUtil.WarnMessage ("  --Failed to set Show Log Window: " + theVal )
					)
				)
			)--end else
		)

		--Special case handling code for "vray_colorMapping_adaptationOnly_enums":
		if theVal !=undefined do 
		(
			if vrayVer >= 3 or matchPattern ((classof renderers.current) as string) pattern:"*_2_40_04*" then 
			(
				local options_array = #(
					#("colorMapping_adaptationOnly", "Color Mapping Adaptation Only", #("Color mapping and gamma","None (don't apply anything)", "Color mapping only (no gamma)"), 1 )
				)
				
				if rendererID == "vray" then
				(
					setCurrentRendererEnumIndex options_array
				)
				else
				(
					setCurrentRendererEnumIndexVRayRT options_array
				)
				
			)
			else 
			(
				-- "colorMapping_adaptationOnly" - VRay v1/2.40.03 or earlier only
				local theArray = #("true","false") --Do NOT change the case of true/false! (keep it lowercase)
				local theIndex = findItem theArray theVal
				if theIndex > 0 then (
					try (
						if rendererID == "vray" then
							renderers.current.colorMapping_adaptationOnly = (execute theVal)
						else
							renderers.current.V_Ray_settings.colorMapping_adaptationOnly = (execute theVal)

						DeadlineUtil.LogMessage ("  +Color Mapping Adaptation Only set to " + theVal  )
					)catch
						DeadlineUtil.WarnMessage ("  --Failed to set Color Mapping Adaptation Only to " + theVal )
				)
				else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for Color Mapping Adaptation Only: " + theVal )
			)
		)--end

		local version_array = #()
		if vrayVer >= 3 then 
		(
			version_array = #(
					#("imageSampler_type", "Image Sampler", #("Bucket","Adaptive", "Adaptive subdivision","Progressive"), 1 ),
					#("imageSampler_type_new", "Image Sampler (NEW)", #("Bucket","Progressive","Adaptive subdivision"), 1 ),
					#("camera_type", "Camera Type", #("Default","Spherical","Cylindrical (point)","Cylindrical (ortho)","Box","Fish eye","Warped spherical (old-style)","Orthographic","Perspective","Spherical panorama"), 1 )
			)
		)
		else
		(
			version_array = #(
					#("imageSampler_type", "Image Sampler", #("Fixed Rate","Adaptive QMC", "Adaptive Subdivision"), 1 ),
					#("camera_type", "Camera Type", #("Default","Spherical","Cylindrical (point)","Cylindrical (ortho)","Box","Fish eye","Warped spherical (old-style)"), 1 )
			)
		)
		
		if rendererID == "vray" then
		(
			setCurrentRendererEnumIndex version_array
		)
		else
		(
			setCurrentRendererEnumIndexVRayRT version_array
		)

		local options_array = #(
			#("gi_irradmap_previewMode", "GI Irradiance Map Preview Mode", #("Show new samples as brighter","Show new samples as green","Full preview"), 1 ),
			#("gi_irradmap_detail_scale", "GI Irradiance Map Detail Scale", #("Screen","World"), 1 ),
			#("options_defaultLights", "Default Lights", #("Off","On","Off with GI"), 1 ),
			#("options_overrideMtl_excl_type", "Override Material Exclude Type", #("Include/Exclude list","Exclude layers","Exclude object IDs"), 1 ),
			#("gi_primary_type", "Primary Bounces GI Engine", #("Irradiance map","Photon map", "Brute force","Light cache"), 1 ),
			#("gi_secondary_type", "Secondary Bounces GI Engine", #("None","Photon map", "Brute force","Light cache"), 1 ),
			#("adv_irradmap_interpolationType", "Adv.Irradiance Map Interpolation Type", #("Weighted average (good/robust)","Least squares fit (good/smooth)", "Delone triangulation (good/exact)","Least squares w/ Voronoi weights (test)"), 1 ),
			#("adv_irradmap_lookupType", "Adv.Irradiance Map Sample Lookup", #("Quad-balanced (good)","Nearest (draft)", "Overlapping (very good/fast)","Density-based (best)"), 1 ),
			#("lightcache_scale", "Light Cache Scale", #("Screen","World"), 1 ),
			#("lightcache_filter_type", "Light Cache Filter Type", #("None","Nearest","Fixed"), 1 ),
			#("system_region_sequence", "Region Sequence", #("Top->Bottom","Left->Right", "Checker","Spiral","Triangulation","Hilbert curve"), 1 ),
			#("system_region_meaning", "Division Method", #("Size","Count"), 1 ),
			#("system_previousRender", "Previous Render", #("Unchanged","Cross","Fields","Darken","Blue","Clear"), 1 ),
			#("system_instancedObjects", "Instanced Objects", #("Static","Dynamic","Auto"), 1 ),
			#("system_frameStamp_justify", "Frame Stamp Justify", #("Left", "Center", "Right"), 1 )
			--LC Mode
			--Although it successfully applies the setting, it seems to have a secondary effect of resetting the *.vrlmap during "Single frame" mode,
			--which casues the LC to be RESET and dramatically increase overall rendering time.
			--#("lightcache_mode", "Light Cache Mode", #("Single frame","Fly-through","From file","Progressive path tracing"), 1 )
		)
		
		if rendererID == "vray" then
		(
			setCurrentRendererEnumIndex options_array
		)
		else
		(
			setCurrentRendererEnumIndexVRayRT options_array
		)
		
		-- --Special case handling code for "vray_adv_irradmap_mode_enums":
		-- local theVal = DeadlineUtil.GetJobInfoEntry "vray_adv_irradmap_mode_enums"
		-- if theVal != undefined do 	
		-- (
		-- 	if matchPattern ((classof renderers.current) as string) pattern:"*_1_4*" then
		-- 		local theArray = #("Bucket Mode","Single Frame", "Multiframe Incremental","From File","Add to Current Map","Incremental Add to Current Map")
		-- 	else 
		-- 		if matchPattern ((classof renderers.current) as string) pattern:"*_1_5*" then
		-- 			local theArray = #("Single Frame", "Multiframe Incremental","From File","Add to Current Map","Incremental Add to Current Map","Bucket Mode")
		-- 		else --VRay v2/v3+
		-- 			local theArray = #("Single frame", "Multiframe incremental","From file","Add to current map","Incremental add to current map","Bucket mode","Animation (prepass)","Animation (rendering)")

		-- 	local theIndex = findItem theArray theVal
		-- 	if theIndex > 0 then 
		-- 	(
		-- 		try 
		-- 		(
		-- 			if curRenderSettings.adv_irradmap_mode != theIndex-1 do
		-- 			(
					
		-- 				curRenderSettings.adv_irradmap_mode = theIndex-1
		-- 				DeadlineUtil.LogMessage ("  +Adv.Irradiance Map Mode set to " + theVal  )
		-- 			)
		-- 		)
		-- 		catch	
		-- 		(
		-- 			DeadlineUtil.WarnMessage ("  --Failed to set Adv.Irradiance Map Mode to " + theVal )
		-- 		)
		-- 	)
		-- 	else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for Adv.Irradiance Map Mode: " + theVal )
		-- )
		
		if rendererID == "vray" then
		(
			setCurrentRendererSetting vray_options_array
		)
		else
		(
			setCurrentRendererSettingVRayRT vray_options_array
		)

		--Pathmap any parameters that need to be pathmapped
		-- local pathmapping_options_array = #(
		-- 	#("adv_irradmap_loadFileName","Adv.Irradiance Map Load File Name"),
		-- 	#("adv_irradmap_saveFileName","Adv.Irradiance Map Save File Name"),
		-- 	#("adv_irradmap_autoSaveFileName","Adv.Irradiance Map Auto Save File Name"),
		-- 	#("caustics_loadFileName","Caustics Load File Name"),
		-- 	#("caustics_saveFileName","Caustics Save File Name"),
		-- 	#("caustics_autoSaveFileName","Caustics Auto Save File Name"),
		-- 	#("photonMap_loadFileName","Photon Map Load File Name"),
		-- 	#("photonMap_saveFileName","Photon Map Save File Name"),
		-- 	#("photonMap_autoSaveFileName","Photon Map Auto Save File Name"),
		-- 	#("lightcache_loadFileName","Light Cache Load File Name"),
		-- 	#("lightcache_saveFileName","Light Cache Save File Name"),
		-- 	#("lightcache_autoSaveFileName","Light Cache Auto Save File Name")
		-- )
		
		cur_renderer = renderers.current
		if rendererID == "vrayrt" then
		(
			cur_Renderer = cur_renderer.V_Ray_settings
		)
		
		-- pathmapRendererSetting cur_Renderer pathmapping_options_array


		if rendererID == "vray" then (
			local irradmapmode = DeadlineUtil.GetJobInfoEntry "vray_adv_irradmap_mode"
			DeadlineUtil.LogMessage("irradmapmode = " + irradmapmode as string )
			if irradmapmode != undefined then (
				if irradmapmode == "0" or irradmapmode == "1" or irradmapmode == "3" or irradmapmode == "4" or irradmapmode == "5" or irradmapmode == "6"then (
					irradmap_savepath = DeadlineUtil.GetJobInfoEntry "vray_adv_irradmap_autoSaveFileName"
					DeadlineUtil.LogMessage ("irradmap_savepath = " + irradmap_savepath as string )

					irradmap_save = DeadlineUtil.GetJobInfoEntry "vray_adv_irradmap_autoSave"
					DeadlineUtil.LogMessage ("irradmap_save = " + irradmap_save as string )
					if irradmap_save == "true" then (irradmap_save = True) else (irradmap_save = False )

					irradmap_dontDelete = DeadlineUtil.GetJobInfoEntry "vray_adv_irradmap_dontDelete"
					DeadlineUtil.LogMessage ("irradmap_dontDelete = " + irradmap_dontDelete as string )
					if irradmap_dontDelete == "true" then (irradmap_dontDelete = True) else (irradmap_dontDelete = False )

					renderers.current.adv_irradmap_autoSaveFileName = irradmap_savepath
					DeadlineUtil.LogMessage("adv_irradmap_autoSaveFileName = " + irradmap_savepath as string )

					renderers.current.adv_irradmap_autoSave = irradmap_save
					DeadlineUtil.LogMessage("adv_irradmap_autoSave = " + irradmap_save as string )

					renderers.current.adv_irradmap_dontDelete = irradmap_dontDelete

					DeadlineUtil.LogMessage("adv_irradmap_dontDelet = " + irradmap_dontDelete as string )
				)
				if irradmapmode == "2" or irradmapmode == "7" then (
					irradmap_loadpath = DeadlineUtil.GetJobInfoEntry "vray_adv_irradmap_loadFileName"
					DeadlineUtil.LogMessage ("irradmap_loadpath = " + irradmap_loadpath as string )
					renderers.current.adv_irradmap_loadFileName = irradmap_loadpath
					if irradmapmode == "2"  then ( 
						renderers.current.adv_irradmap_mode = 2
						DeadlineUtil.LogMessage ("irradmap_loadpath = " + renderers.current.adv_irradmap_mode as string )
					)
					if irradmapmode == "7" then (renderers.current.adv_irradmap_mode = 7)
				)
			)

			local lightcachemode = DeadlineUtil.GetJobInfoEntry "vray_lightcache_mode"
			DeadlineUtil.LogMessage("lightcachemode = " + lightcachemode as string )
			if lightcachemode != undefined then (
				if lightcachemode == "0" then (
					lightcache_savepath = DeadlineUtil.GetJobInfoEntry "vray_lightcache_autoSaveFileName"
					DeadlineUtil.LogMessage ("lightcache_savepath = " + lightcache_savepath as string )

					lightcache_save = DeadlineUtil.GetJobInfoEntry "vray_lightcache_autoSave"
					DeadlineUtil.LogMessage ("lightcache_save = " + lightcache_save as string )
					if lightcache_save == "true" then (lightcache_save = True) else (lightcache_save = False )


					lightcache_dontDelete = DeadlineUtil.GetJobInfoEntry "vray_lightcache_dontDelete"
					DeadlineUtil.LogMessage ("lightcache_dontDelete = " + lightcache_dontDelete as string )
					if lightcache_dontDelete == "true" then (lightcache_dontDelete = True) else (lightcache_dontDelete = False )

					renderers.current.lightcache_autoSaveFileName = lightcache_savepath
					DeadlineUtil.LogMessage("lightcache_autoSaveFileName = " + lightcache_savepath as string )

					renderers.current.lightcache_autoSave = lightcache_save
					DeadlineUtil.LogMessage("lightcache_autoSave = " + lightcache_save as string )

					renderers.current.lightcache_dontDelete = lightcache_dontDelete
					DeadlineUtil.LogMessage("lightcache_dontDelete = " + lightcache_dontDelete as string )
				)
				if lightcachemode == "2" then (
					lightcache_loadpath = DeadlineUtil.GetJobInfoEntry "vray_lightcache_loadFileName"
					DeadlineUtil.LogMessage ("lightcache_loadpath = " + lightcache_loadpath as string )
					renderers.current.lightcache_loadFileName = lightcache_loadpath
					renderers.current.lightcache_mode = 2
					DeadlineUtil.LogMessage ("lightcache_mode = " + renderers.current.lightcache_mode as string )

				) 
			)


		)

		







		
		
	)--end if VRAY
--END VRAY / VRAY RT SPECIFIC SETTINGS

--VRAY RT SPECIFIC SETTINGS
	if getRendererIdString() == "vrayrt" do
	(
		DeadlineUtil.LogMessage ">V-Ray RT renderer specific options."

		--Each element of the array is a sub-array containing
		--1. the name of the property as string, 
		--2. whether to convert the value to maxscript value or keep as string, 
		--3. the description string used to output to the log file.

		local options_array = #(
			#("rt_settings_ui_view",true,"rt_settings_ui_view"), --v3.55.01 [Default/Advanced]
			#("filter_on",true,"filter_on"),
			#("traceDepth",true,"traceDepth"),
			#("gi",true,"gi"),
			#("gi_depth",true,"gi_depth"),
			#("cpu_bundleSize",true,"cpu_bundleSize"),
			#("cpu_raysPerPixel",true,"cpu_raysPerPixel"),
			#("progressive_raysPerPixel",true,"progressive_raysPerPixel"),
			#("coherentTracing",true,"coherentTracing"),
			#("lowGPUThreadPriority",true,"lowGPUThreadPriority (Low_GPU_thread_priority)"), --v3.55.01
			#("Undersampling",true,"Undersampling"),
			#("showStatistics",true,"showStatistics"),
			#("aa_showMask",true,"aa_showMask"),
			#("aa_threshold",true,"aa_threshold"),
			#("overrideMtl_on",true,"overrideMtl_on"),
			--#("overrideMtl_mtl",false,"overrideMtl_mtl"), --unsupported. Unable to set material
			--#("overrideMtl_excl_type",true,"overrideMtl_excl_type (overrideMtl_ExclType)"), --v3.55.01, handled in vray enum already
			--#("overrideMtl_excl_objectIDs",true,"overrideMtl_excl_objectIDs"), --v3.55.01
			--#("overrideMtl_excl_layers",true,"overrideMtl_excl_layers"), --v3.55.01
			#("vrscene_on",true,"vrscene_on"),
			#("vrscene_fileName",false,"vrscene_fileName"),
			#("vrscene_dontRender",true,"vrscene_dontRender"),
			#("max_render_time",true,"max_render_time"),
			#("max_paths_per_pixel",true,"max_paths_per_pixel"),
			--#("stereo_type",true,"stereo_type"), --ENUM
			--#("output_layout",true,"output_layout"), --ENUM v3.55.01
			#("stereo_swapLR",true,"stereo_swapLR"),
			#("stereo_eye_distance",true,"stereo_eye_distance"),
			#("stereo_focus",true,"stereo_focus"),
			#("geometry_proxies",true,"geometry_proxies"),
			#("geometry_xrefs",true,"geometry_xrefs"),
			#("geometry_particles",true,"geometry_particles"),
			#("geometry_displacement",true,"geometry_displacement"),
			#("geometry_motionBlur",true,"geometry_motionBlur"),
			--#("engine_type",true,"engine_type"), --ENUM
			#("opencl_textureSize",true,"opencl_textureSize"),
			--#("opencl_resizeTextures",true,"opencl_resizeTextures"), --ENUM
			--#("opencl_textureFormat",true,"opencl_textureFormat"), --ENUM
			#("opencl_bundleSize",true,"opencl_bundleSize"),
			#("opencl_raysPerPixel",true,"opencl_raysPerPixel"),
			#("bundleSize",true,"bundleSize"),
			#("raysPerPixel",true,"raysPerPixel"),
			--#("distributed_rendering",true,"distributed_rendering"),
			#("inproc_rendering",true,"inproc_rendering (In_process_RT_rendering)"), --v3.55.01
			#("warn_unsupported",true,"warn_unsupported"),
			#("warn_nonPhysical",true,"warn_nonPhysical"),
			#("msg_delay",true,"msg_delay"),
			#("autoupdate_bitmaps",true,"autoupdate_bitmaps"),
			#("use_32bit_buffer",true,"use_32bit_buffer (Use_32_bit_frame_buffer)"),
			#("top_merge_angle",true,"top_merge_angle"), --v3.55.01
			#("bottom_merge_angle",true,"bottom_merge_angle") --v3.55.01
			--#("vrControllerLTouch",true,"vrControllerLTouch"), --INTERFACE, not applicable for render property setting
			--#("vrControllerRTouch",true,"vrControllerRTouch"), --INTERFACE, not applicable for render property setting
			--#("vrControllerRemote",true,"vrControllerRemote"), --INTERFACE, not applicable for render property setting
			--#("vrControllerXBox",true,"vrControllerXBox"), --INTERFACE, not applicable for render property setting
			--#("V_Ray_settings",false,"V_Ray_settings") --handled above in VRAY SPECIFIC SETTINGS
		)

		setCurrentRendererSetting options_array

		local options_array = #(
			#("stereo_type", "Stereo Mode", #("Disabled","Left/Right","Interlaced","Checkered","Anaglyph (Red, Cyan)","Anaglyph (Green, Magenta)","OpenGL stereo","Duplicate (mono)","OpenVR (mono)","OpenVR (stereo)","Oculus Rift (mono)","Oculus Rift (stereo)"), 1 ),
			#("engine_type", "Engine Type", #("CPU","OpenCL","CUDA"), 1 ),
			#("opencl_resizeTextures", "GPU Textures ", #("Full-size textures","Resize all textures","On-demand mip-mapped textures"), 1 ),
			#("opencl_textureFormat", "Texture format ", #("Float","Half","8-bit"), 1 ),
			#("output_layout", "Output layout", #("Side-by-side","Top-bottom"), 1 )
		)
		
		setCurrentRendererEnumIndex options_array
		
	)--end if VRAY RT
--END VRAY RT SPECIFIC SETTINGS

--MAXWELL SPECIFIC SETTINGS:
	if getRendererIdString() == "maxwell" do
	(
		DeadlineUtil.LogMessage ">Maxwell detected as current renderer."
		
		if rendTimeType == 1 do
		(
			rendTimeType = 3
			DeadlineUtil.LogMessage "  +Changed render time type from Single to Range so that the Maxwell process doesn't detach from the 3dsmax process"
		)
		
		--Each element of the array is a sub-array containing
		--1. the name of the property as string, 
		--2. whether to convert the value to maxscript value or keep as string, 
		--3. the description string used to output to the log file.
		
		local options_array = #(
			-- General Settings
			#("gsLowPriority", true, "Low Priority"),
			#("gsBitmaps", true, "Bitmaps"),
			--#("gsMultilight", true, "Multilight"),
			#("gsDisplay", true, "Display"),
			#("gsGlobalMotionBlur", true, "Global Motion Blur"),
			#("gsProtectGeometry", true, "Protect Geometry"),
			#("gsUseInstancing", true, "Use Instancing"),
			#("gsRenderTime", true, "Render Time"),
			#("gsSamplingLevel", true, "Sampling Level"),
			#("gsSceneScale", true, "Scene Scale"),
			#("gsAttenuationScale", true, "Attenuation Scale"),
			#("gsPreviewScale", true, "Preview Scale"),
			#("gsThreads", true, "CPU Threads"),
			#("gsMXCLFlags", false, "MXCL Flags"),
			
			-- Output
			#("gsGenerateMXSOutput", true, "Generate MXS Output"),
			#("gsMXSOutputPath", false, "MXS Output Path"),
			#("gsMaxwellSequenceRendering", true, "Maxwell Sequence Rendering"),
			#("gsGenerateMXIOutput", true, "Generate MXI Output"),
			#("gsMXIOutputPath", false, "MXI Output Path"),
			
			-- Render Channels
			#("gsChannelRGB", true, "Channel RGB"),
			#("gsChannelAlpha", true, "Channel Alpha"),
			#("gsChannelObjectId", true, "Channel Object Id"),
			#("gsChannelShaddow", true, "Channel Shaddow"),
			#("gsChannelOpaque", true, "Channel Opaque"),
			#("gsChannelMaterialId", true, "Channel Material Id"),
			#("gsChannelZ", true, "Channel Z"),
			#("gsChannelZMin", true, "Z Min"),
			#("gsChannelZMax", true, "Z Max"),
			
			-- Viewport
			#("gsToggleSkyPreview", true, "Sky Preview"),
			
			-- Tone Mapping
			#("tmGamma", true, "Gamma"),
			#("tmBurn", true, "Burn"),
			
			-- Render Layers
			#("rlLightingDirect", true, "Lighting Direct"),
			#("rlLightingIndirect", true, "Lighting Indirect"),
			#("rlDirectCausticsReflection", true, "Direct Caustics Reflection"),
			#("rlDirectCausticsRefraction", true, "Direct Caustics Refraction"),
			#("rlIndirectCausticsReflection", true, "Indirect Caustics Reflection"),
			#("rlIndirectCausticsRefraction", true, "Indirect Caustics Refraction"),
			
			-- Perspective/Lights Viewport
			#("defviewFStop", true, "FStop"),
			#("defviewShutterSpeed", true, "Shutter Speed"),
			#("defviewFilmISO", true, "Film ISO"),
			
			-- SimuLens
			#("slApertureImagePath", false, "Aperture Map"),
			#("slObscureImagePath", false, "Obstacle Map"),
			#("slUseDiffraction", true, "Use Diffraction"),
			#("slDiffraction", true, "Diffraction"),
			#("slFrequency", true, "Frequency"),
			#("slUseScattering", true, "Use Scattering"),
			#("slScattering", true, "Scattering"),
			#("slUseVignetting", true, "Use Vignetting"),
			#("slVignetting", true, "Vignetting")
		)
		
		setCurrentRendererSetting options_array
		
		/*
		--Special case handling code for Motion Blur enums:
		local theVal = DeadlineUtil.GetJobInfoEntry "maxwell_gsMotionBlur_enums"
		if theVal != undefined do 	(
			local theArray = #("Per Object","On", "Off")
			local theIndex = findItem theArray theVal
			if theIndex > 0 then (
				try (
					renderers.current.gsMotionBlur = theIndex-1
					DeadlineUtil.LogMessage ("  +Motion Blur set to " + theVal  )
				)catch	
					DeadlineUtil.WarnMessage ("  --Failed to set Motion Blur to " + theVal )
			)
			else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for Motion Blur: " + theVal )
		)
		*/
		
		local options_array = #(
			#("gsColorSpace", "Color Space", #("sRGB","Adobe RGB 98", "Apple RGB / SGI","PAL / SECAM","NTSC 1953","NTSC 1979","Wide Gamut RGB","ProPhoto RGB (ROMM)","ECI RGB","CIE 1931","Bruce RGB","ColorMatch RGB","Best RGB","Don RGB 4"), 1 ),
			#("gsChannelRenderType", "Render Type", #("Diffuse+Reflection","Diffuse", "Reflection"), 1 )
		)
		
		setCurrentRendererEnumIndex options_array
				
		/*
		--Special case handling code for Depth enums:
		local theVal = DeadlineUtil.GetJobInfoEntry "maxwell_gsDepth_enums"
		if theVal != undefined do 	(
			local theArray = #("8","16", "32")
			local theIndex = findItem theArray theVal
			if theIndex > 0 then (
				try (
					renderers.current.gsDepth = execute theArray[theIndex]
					DeadlineUtil.LogMessage ("  +Depth set to " + theVal  )
				)catch	
					DeadlineUtil.WarnMessage ("  --Failed to set Depth to " + theVal )
			)
			else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for Depth: " + theVal )
		)
		*/
	)--end if Maxwell
--END MAXWELL SPECIFIC SETTINGS	

--CORONA SPECIFIC SETTINGS:
	if getRendererIdString() == "corona" do
	(
		DeadlineUtil.LogMessage ">Corona Renderer detected as current renderer."

		--Check Corona version.
		coronaVersion = try(CoronaRenderer.CoronaFp.getCoronaVersion())catch(undefined)
		if coronaVersion != undefined then 
		(
			DeadlineUtil.LogMessage ( ">Corona version: " + (coronaVersion as string) )
		)

		--Each element of the array is a sub-array containing
		--1. the name of the property as string,
		--2. whether to convert the value to maxscript value or keep as string,
		--3. the description string used to output to the log file.
		
		local options_array = #(
			-- Corona v6 & v7.2 versions
			#("Pathtracing_samples", true, "GI/AA Balance"),
			#("Area_light_sampling_multiplier", true, "Light Samples Multiplier"),
            
            #("Max_sample_intensity_in_PT", true, "Max Sample Intensity"),
			#("Max_raycasting_depth", true, "Max Ray Depth"),
            
            #("Render_hidden_lights", true, "Render Hidden Lights"),
			#("Alpha_is_always_solid", true, "All Objects Have Solid Alpha"),
            
            #("Custom_mat_ed", true, "Custom Previews"),
			#("Mtl_editor_quality", true, "Preview Quality"),
            
            #("Use_projection_size_for_displacement", true, "Use Screen Size For Displacement"),
			#("Max_projected_poly_size_displacement", true, "Screen Size (px)"),
            #("Max_world_poly_size_displacement", true, "World Size (units)"),
			#("Max_subdiv_for_single_poly_in_MTD", true, "Max Subdivisions Per Poly"),
            
            #("Use_camera_settings_for_image_exposure", true, "Use Photographic Exposure"),
			#("color_mapping_exponent", true, "Exposure (EV)"),
            #("colormapping_white_multiplier", true, "Highlight Compression"),
			#("contrast", true, "Contrast"),
            #("Source_temperature", true, "White Balance [K]"),
			#("R_balance", true, "Color Channels Output (R)"),
            #("G_balance", true, "Color Channels Output (G)"),
			#("B_balance", true, "Color Channels Output (B)"),
            
            #("Scene_camera_override", true, "Override Scene Camera/CameraMod Settings"),
			#("f_stop_number", true, "F-stop"),
            #("MB_duration", true, "Shutter Speed [1/s]"),
			#("ISO__film_speed", true, "ISO"),
            #("Film_width", true, "Sensor Width [mm]"),
            
			#("use_dof", true, "Enable Depth Of Field"),
            #("Focal_distance", true, "Perspective View Distance"),
            #("Number_of_shutter_blades", true, "Blades (Bladed)"),
			#("Rotation_offset_of_blades", true, "Rotation (Bladed)"),
            #("DOF_Bokeh_resolution", true, "Resolution (Custom)"),
            
            #("Use_camera_motion_blur", true, "Enable Camera MB"),
            #("Use_geometry_motion_blur", true, "Enable Geometry MB"),
            #("MB_offset", true, "Frame Offset"),
			#("MB_Linear_segments", true, "Transformation Segments"),
            #("Geometry_segments", true, "Geometry Segments"),
            
            #("VFB_update_interval", true, "Update Interval [ms]"),
            
            #("internal_fb_resolution_multiplier", true, "Internal Resolution Multiplier"),
			#("Image_filter_width", true, "Width [px]"),
            
            #("Enable_autosave", true, "Enable Autosave"),
			#("Autosave_interval", true, "Autosave Interval (s)"),
            #("Autosave_filename", false, "During Render"),
			#("Maximum_number_of_autosave_files_to_keep", true, "Number Kept During Render"),
            #("Autosave_on_render_end_filename", false, "On Render End"),
			#("Number_of_autosaved_images", true, "Number Kept On Render End"),
            
            #("Use_render_stamp", true, "Enable Render Stamp"),
			#("Render_stamp", false, "Render Stamp"),
            
            #("progressive_time_limit", true, "Progressive Time Limit (s)"), --deprecated mxs property
			#("Progressive_rendering_max_passes", true, "Progressive Pass Limit"),
            
            #("Do_MIS_in_bidir", true, "Use MIS"),
            #("Photon_count", true, "Paths (Photons) Per Iteration"),
			#("PPM_Initial_radius", true, "Initial Lookup Radius [px]"),
            #("PPM_Alpha__reduction_radius", true, "Alpha (Radius Reduction)"),
            
            #("show_bucket_order", true, "Show Bucket Order"),
			#("Initial_samples", true, "Initial Samples"),
            #("Adaptive_steps", true, "Bucket Passes"),
            
            #("HDcache_precomp_multiplier", true, "Precomp Density"),
            #("pt_samples", true, "Record Quality"),
            #("interpolation_count", true, "Interpolation Count"),
            #("smoothing", true, "Smoothing"),
            #("HdCache_max_records", true, "Max Records"),
            #("Do_previz", true, "Do Previz"),
            #("HD_cache_glosssines_threshold", true, "Reflection Glossiness Threshold"),
            #("Write_passes", true, "Writable For # Passes"),
            #("dir_sensitivity", true, "Direction"),
            #("position_sensitivity", true, "Position"),
            #("HDCACHE_normal_sensitivity", true, "Normal"),
            
            #("HD_cache_save", true, "Save Cache"),
            #("HD_cache_dump_filename", false, "Cache Filename"),

            --Corona pre1.0 build and onwards
			#("lights_samplesMult", true, "Light Samples Multiplier"),
			#("system_lowThreadPriority", true, "Low thread priority"), --renamed in Corona 1.3 to just "lowThreadPriority" (see below)
			
			#("lowThreadPriority", true, "Low thread priority"), --NEW in Corona 1.3, deprecated in Corona 1.4

-- 			#("progressive_timeLimit", true, "Progressive Time limit (ms)"), --handled in a function further down
			#("bucket_showOrder", true, "Show bucket order"), --deprecated in Corona v1.4
			#("shading_giToAaRatio", true, "GI vs. AA balance"),
			#("image_prefiter_width", true, "Width [px]"), --NEW in Corona 1.4 RC2, note: typo in maxscript property name
			#("image_prefilter_width", true, "Width [px]"), --NEW in Corona 1.4, fixes above typo
			#("image_internalResMult", true, "Internal resolution"), --deprecated in Corona v1.4
			#("image_filter_blurring", true, "Blurring"), --deprecated in Corona v1.4
			#("geometry_minInstanceSaving", true, "Min. instance saving (not in UI)"),
			#("geometry_maxNormalDiff", true, "Max normal difference (not in UI)"),
			#("progressive_passLimit", true, "Progressive Pass limit"),
			#("shading_maxSampleIntensity", true, "Max Sample Intensity"),
			#("shading_maxRayDepth", true, "Max ray depth"),
			#("system_vfbUpdateInterval", true, "Update interval [ms]"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			#("bg_overrideDirect", true, "Direct visibility override"),
			#("bg_overrideReflect", true, "Reflections override"),
			#("mtlEditor_custom", true, "Custom previews"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			#("renderStamp", false, "Render stamp"),
			#("lights_renderHidden", true, "Render hidden lights"),
			#("bg_overrideRefract", true, "Refractions override"),
			#("alphaAlwaysSolid", true, "All objects have solid alpha (not in UI)"),
			#("vfb_autosave_count", true, "On render end"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			#("vfb_autosave_filename", false, "Autosave Filename"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			#("renderstamp_use", true, "Enable Render stamp"),
			#("vfb_autosave_countEnd", true, "On render end"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			#("system_numThreads", true, "# of threads (0 = unlim.)"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			#("vfb_autosave_enable", true, "Enable autosave"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			#("lights_solverFracLocal", true, "CombSolver local frac (not in UI)"),
			#("lights_solverFractGlobal", true, "CombSolver global frac (not in UI)"),
			#("lights_portalSampleFraction", true, "Portal fraction (not in UI)"),
			#("colorMap_simpleExposure", true, "Exposure (EV)"),
			#("colorMap_highlightCompression", true, "Highlight compress"),
			#("colorMap_colorTemp", true, "White balance [K]"),
			#("colorMap_contrast", true, "Contrast"),
			#("gi_photons_emitted", true, "Paths (photons) per iteration (k)"),
			#("gi_photons_lookupCount", true, "gi_photons_lookupCount (not in UI)"),
			#("gi_photons_storeDirect", true, "gi_photons_storeDirect (not in UI)"),
			#("gi_photons_depth", true, "gi_photons_depth (not in UI)"),
			
			#("gi_hdCache_precompDensity", true, "Precomp density"), --deprecated in Corona v1.4
			#("gi_hdCache_interpolationCount", true, "Interp. count"), --deprecated in Corona v1.4
			#("gi_hdCache_dirSensitivity", true, "Direction"), --deprecated in Corona v1.4
			#("gi_hdCache_posSensitivity", true, "Position"), --deprecated in Corona v1.4
			#("gi_hdCache_recordQuality", true, "Record quality"), --deprecated in Corona v1.4
			#("gi_hdCache_smoothing", true, "Smoothing"), --deprecated in Corona v1.4
			#("gi_hdCache_normalSensitivity", true, "Normal"), --deprecated in Corona v1.4
			#("gi_hdCache_glossyThreshold", true, "Refl glossiness threshold"), --deprecated in Corona v1.4
			#("gi_hdCache_maxRecords", true, "Max records [k]"), --deprecated in Corona v1.4
			#("gi_hdCache_writablePasses", true, "Writeable for # passes"), --deprecated in Corona v1.4
			#("bucket_samplesPerIteration", true, "Samples per iter."), --deprecated in Corona v1.4
			#("bucket_passes", true, "Passes"), --deprecated in Corona v1.4

			#("geometry_displace_maxSizeScreen", true, "Screen Size (px)"),
			#("geometry_displace_maxSubdiv", true, "Max subdiv per poly"), --deprecated in Corona v1.2.1
			#("mb_segmentsTransform", true, "Transform segments"),
			#("mb_segmentsGeometry", true, "Geometry segments"),
			#("mb_frameOffset", true, "Frame offset"),
			#("gi_ppm_alpha", true, "Alpha (radius reduction)"),
			#("gi_ppm_initialRadius", true, "Initial lookup radius [px]"),
			#("gi_ppm_ptSamplesPerIter", true, "gi_ppm_ptSamplesPerIter (not in UI)"),
			#("gi_ppm_photonsPerIter", true, "gi_ppm_photonsPerIter (not in UI)"),
			#("gi_vcm_mis", true, "Use MIS"),
			#("gi_vpl_emittedCount", true, "gi_vpl_emittedCount (not in UI)"),
			#("gi_vpl_usedCount", true, "gi_vpl_usedCount (not in UI)"),
			#("gi_vpl_clamping", true, "gi_vpl_clamping (not in UI)"),
			#("gi_vpl_progressiveBatch", true, "gi_vpl_progressiveBatch (not in UI)"),
			#("dof_bokehResolution", true, "Resolution (Custom)"),
			#("dof_bokehBlades", true, "Blades (Bladed)"),
			#("dof_bokehRotation", true, "Rotation (Bladed)"),
			#("dof_use", true, "Enable Depth of field"),
			#("dof_sensorWidth", true, "Sensor Width [mm]"),
			#("bg_texmapUseReflect", true, "Reflections texture map override"),
			#("bg_texmapUseMain", true, "Use main texture map"),
			#("bg_texmapUseRefract", true, "Refractions texture map override"),
			#("bg_texmapUseDirect", true, "Direct texture map override"),
			#("mtlEditor_quality", true, "Preview quality"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			#("mtlOverride_enabled", true, "Mtl. override:"),
			#("mtlOverride_includeMode", true, "Mtl. override include mode"),
			#("bg_color", true, "Background color"),
			#("shading_exitColor", true, "Exit color (not in UI)"),
			#("bg_colorDirect", true, "Direct visibility color"),
			#("bg_colorReflect", true, "Reflections color"),
			#("bg_colorRefract", true, "Refractions color"),
			#("geometry_displace_maxSizeWorld", true, "World Size (units)"),
			#("dof_focalDistance", true, "Perspective view focus distance"), --deprecated in Corona v1.5
			-- #("mtlOverride", true, "Mtl. override preserves displacement"), --unable to support 3dsmax material assignment
			#("lights_enviroDistance", true, "Enviro distance"),
			-- #("dr_slaveAddresses", false, "Slave machines : hostname(s) or IP address(es)"),
			-- #("dr_slaveResolvedNames", false, "Slave machines : resolved hostname(s)"),
			#("dr_enable", true, "Enable DR"),
			#("dr_synchInterval", true, "Synchronization interval [s]"),
			#("dr_searchDuringRender", true, "Search LAN during render"),
			#("system_drMaxDumpPixels", true, "Max pixels to transfer at once"),
			#("lockMax", true, "Lock 3dsmax during render"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5

			#("gi_ic_hemisphereSubdiv", true, "gi_ic_hemisphereSubdiv (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_useRotGrad", true, "gi_ic_useRotGrad (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_useTransGrad", true, "gi_ic_useTransGrad (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_maxError", true, "gi_ic_maxError (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_smoothing", true, "gi_ic_smoothing (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_colorThreshold", true, "gi_ic_colorThreshold (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_recordSpacingMin", true, "gi_ic_recordSpacingMin (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_recordSpacingMax", true, "gi_ic_recordSpacingMax (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_interpolationSchema", true, "gi_ic_interpolationSchema (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_searchStructure", true, "gi_ic_searchStructure"), --deprecated in Corona v1.6
			#("gi_ic_viz", true, "gi_ic_viz (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_pathtracingCorners", true, "gi_ic_pathtracingCorners (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_incrementalBuild", true, "gi_ic_incrementalBuild (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_minInterpSamples", true, "gi_ic_minInterpSamples (not in UI)"), --deprecated in Corona v1.6
			#("gi_ic_relaxedInterpolation", true, "gi_ic_relaxedInterpolation (not in UI)"), --deprecated in Corona v1.6

			#("globalVolumeMtl_use", true, "Global volume material"),
			#("gi_hdCache_doPreviz", true, "Do previz"), --removed in Corona 1.3 (left in for legacy support)
			#("mb_useCamera", true, "Enable camera"),
			#("mb_useGeometry", true, "Enable geometry"),
			#("stringOptions", false, "String options"),
			
			#("gi_hdCache_save", true, "After render"), --deprecated in Corona v1.6
			#("gi_hdCache_file", false, "Filename"), --deprecated in Corona v1.6
			#("gi_uhdCache_save", true, "After render"), --name change in Corona v1.6
			#("gi_uhdCache_file", false, "Filename"), --name change in Corona v1.6

			#("dr_retainExr", true, "[DEBUG] retain EXRs"),
			#("vfb_clearBetweenRenders", true, "VFB clear between renders"),
			#("colorMap_iso", true, "ISO"),
			#("colorMap_fStop", true, "F-stop"),
			#("colorMap_shutterSpeed", true, "Shutter Speed [1/s]"),
			#("colorMap_tint", true, "Color map tint"),
			#("geometry_embree_lowMemory", true, "Embree flags : Low memory (not in UI)"),
			#("geometry_embree_highQuality", true, "Embree flags : High quality"),
			#("geometry_embree_precise", true, "Embree flags : Precise"),
			#("shading_firstPassQuality", true, "shading_firstPassQuality (not in UI)"), --deprecated in Corona v1.7
			#("interactive_giSamplesMult", true, "interactive_giSamplesMult (not in UI)"),
			#("interactive_clearVfb", true, "Clear VFB inbetween renders"),  --deprecated in Corona v1.6
			#("interactive_hdPrecompMult", true, "interactive_hdPrecompMult (not in UI)"),
			#("interactive_hdQualityMult", true, "interactive_hdQualityMult (not in UI)"),
			#("interactive_enableMtlEditor", true, "Enable material editor"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			
			#("bucket_adaptiveThreshold", true, "adaptive thresh."), --deprecated in Corona v1.4

			#("multithreadedParsing", true, "Multithreaded parsing (not in UI)"),
			#("cloneTexmaps", true, "[DEBUG] clone texmaps (not in UI)"),
			
			#("gi_hdCache_doViz", true, "Do previz"), --deprecated in Corona v1.6
			#("gi_uhdCache_doViz", true, "Do previz"), --name change in Corona v1.6

			#("gi_uhdcache_precision", true, "Precision"),
			#("gi_uhdcache_precompDensity", true, "Precomp density (not in UI)"),
			#("gi_uhdcache_interpolationCount", true, "Interpolation count (not in UI)"),
			#("gi_uhdcache_recordQuality", true, "Record quality (not in UI)"), --deprecated in Corona v1.6
			#("gi_uhdcache_normalSensitivity", true, "Normal (not in UI)"),
			#("gi_uhdcache_dirSensitivity", true, "Direction (not in UI)"),
			#("gi_uhdcache_glossThreshold", true, "Gloss threshold (not in UI)"),
			#("gi_uhdcache_strictness", true, "uhdcache_strictness (not in UI)"), --deprecated in Corona v1.6
			#("gi_uhdcache_msi", true, "uhdcache_msi (not in UI)"), --deprecated in Corona v1.6
			#("rolloutsStatus", false, "rolloutsStatus (not in UI)"),
			#("mtlEditor_lightsIntensity", true, "mtlEditor_lightsIntensity (not in UI)"),
			#("mtlEditor_lightsSize", true, "mtlEditor_lightsSize (not in UI)"),
			#("renderElementsOnlyAa", true, "With AA"), --removed in Corona 1.3 (left in for legacy support)
			#("vfb_autosave_interval", true, "Autosave interval [minutes]"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			#("interactive_numThreads", true, "# of threads override"), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			#("interactive_passLimit", true, "Max passes"),
			#("mtlOverride_preserveDisplacement", true, "Mtl. override preserves displacement"),
			#("colormap_additionalGamma", true, "Additional gamma"),
			#("dr_numThreads", true, "DR Num Threads (not in UI)"),
			#("system_sceneExportHighQualityMaps", true, "Export High Quality Maps (not in UI)"), --removed in Corona 1.3 (left in for legacy support)
			#("lockSamplingPattern", true, "Lock sampling pattern"),
			--#("renderSelected_list", false, "Include/Exclude List"), --unsupported node array, respect current scene setting instead
			#("renderSelected_includeMode", true, "Viewport Selection"),
			#("renderSelected_objectId", true, "Object GBuffer ID"),
			#("adaptivity_enable", true, "adaptivity_enable (not in UI)"), --NEW in Corona 1.4 (boolean)
			#("adaptivity_targetError", true, "adaptivity_targetError" ), --NEW in Corona 1.4 (float)
			#("denoise_sensitivity", true, "Denoise Amount" ), --NEW in Corona 1.4 (float)
			#("denoise_blendAmount", true, "Denoise Radius" ), --NEW in Corona 1.4 (float)
			#("shading_fbSampleClamp", true, "shading_fbSampleClamp" ), --NEW in Corona 1.4 (float)
			#("adaptivity_interval", true, "adaptivity_interval (not in UI)" ), --NEW in Corona 1.4 (integer)
			#("denoise_textureBlur", true, "denoise_textureBlur (not in UI)" ), --NEW in Corona 1.4 (float)
			#("system_vfbHistoryAutosave", true, "system_vfbHistoryAutosave" ), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5
			#("system_vfbHistoryMaxSizeMb", true, "system_vfbHistoryMaxSizeMb" ), --removed, now in $plugcfg/corona/SystemSettings.conf --Corona 1.5

			--Corona v1.5 NEW features
			#("colorMap_filmic_highlightCompression", true, "colorMap_filmic_highlightCompression (colormap_filmic_highlights)"), --float
			#("colorMap_filmic_richShadows", true, "colorMap_filmic_richShadows (colormap_filmic_shadows)"), --float
			#("colorMap_saturation", true, "colorMap_saturation"), --float
			#("shading_onlyElements", true, "shading_onlyElements (Render_only_elements_and_masks__as_opposed_to_full_shading)"), --boolean
			#("vignette_intensity", true, "vignette_intensity"), --float
			#("vignette_falloff", true, "vignette_falloff"), --float
			#("bloomGlare_bloomIntensity", true, "bloomGlare_bloomIntensity"), --float
			#("bloomGlare_glareIntensity", true, "bloomGlare_glareIntensity"), --float
			#("bloomGlare_colorIntensity", true, "bloomGlare_colorIntensity"), --float
			#("bloomGlare_colorShift", true, "bloomGlare_colorShift"), --float
			#("bloomGlare_streakCount", true, "bloomGlare_streakCount"), --integer
			#("bloomGlare_rotation", true, "bloomGlare_rotation"), --float
			#("bloomGlare_streakBlur", true, "bloomGlare_streakBlur"), --float
			#("bloomGlare_threshold", true, "bloomGlare_threshold"), --float
-- 			#("colorMap_lightmixColors", true, "colorMap_lightmixColors (LightMix_individual_lights_colors)"), --point3 array
-- 			#("colorMap_lightmixIntensities", true, "colorMap_lightmixIntensities (LightMix_individual_lights_intensities)"), --float array
			#("colorMap_lut_enable", true, "colorMap_lut_enable (lut_enable)"), --boolean
			#("colorMap_lut_path", false, "colorMap_lut_path (lut_path)"), --filename
			#("colorMap_lut_opacity", true, "colorMap_lut_opacity (lut_opacity)"), --float
			#("colorMap_lut_convertToLog", true, "colorMap_lut_convertToLog (lut_convertToLog)"), --boolean
			#("bloomGlare_enabled", true, "bloomGlare_enabled"), --boolean
			#("colorMap_colorTemp15Hack", true, "colorMap_colorTemp15Hack (Legacy_1_5_color_balance)"), --boolean

			--Corona v1.6 NEW features
			#("lights_enviroSolver", true, "lights_enviroSolver (Environment_light_solver)"), --integer
			#("curves_enable", true, "curves_enable (Use_curve_color_mapping)"), -- boolean
--			#("curves_master_nodes", true, "curves_master_nodes (Nodes_of_the_brightness_channel_of_curve_color_mapping)"), --point3 array
			#("curves_master_interpol", true, "curves_master_interpol (Interpolation_type_of_the_brightness_channel)"), --integer
--			#("curves_r_nodes", true, "curves_r_nodes (Nodes_of_the_red_channel_of_curve_color_mapping)"), --point3 array
			#("curves_r_interpol", true, "curves_r_interpol (Interpolation_type_of_the_red_channel)"), --integer
--			#("curves_g_nodes", true, "curves_g_nodes (Nodes_of_the_green_channel_of_curve_color_mapping)"), --point3 array
			#("curves_g_interpol", true, "curves_g_interpol (Interpolation_type_of_the_green_channel)"), --integer
--			#("curves_b_nodes", true, "curves_b_nodes (Nodes_of_the_blue_channel_of_curve_color_mapping)"), --point3 array
			#("curves_b_interpol", true, "curves_b_interpol (Interpolation_type_of_the_blue_channel)"), --integer
			#("bloomGlare_halfFloat", true, "bloomGlare_halfFloat"), --boolean
			#("sharpening_amount", true, "sharpening_amount"), --float
			#("sharpening_radius", true, "sharpening_radius"), --float
  			#("renderstamp_fontSize", true, "renderstamp_fontSize (Render_Stamp_size__px)"), --integer			
--			#("system_vfbRegions", true, "system_vfbRegions (List_of_VFB_regions)"), --point3 array
			#("system_vfbRegions_enabled", true, "system_vfbRegions_enabled (Enable_disable_VFB_regions)"), --boolean
			#("colorMap_enabled", true, "colorMap_enabled (Enable_tone_mapping)"), --removed, boolean

			--Corona v1.6 RC1-RC2 NEW features
-- 			#("colormap_lightmix_elementNames", true, "colormap_lightmix_elementNames (Names_of_LightSelect_elements)"), --string array
-- 			#("colorMap_lightmixEnabledLayers", true, "colorMap_lightmixEnabledLayers (On_off_boolean_parameter_for_each_light_group)"), --boolean array
			#("blurring_radius", true, "blurring_radius"), --float
			#("sharpening_blurring_enable", true, "sharpening_blurring_enable"), --boolean
			#("progressive_interlacingLevel", true, "progressive_interlacingLevel (IR_progressive_renderer_subsampling)"), --integer
-- 			#("dr_slaveEnabled", true, "dr_slaveEnabled (Enable_each_slave_in_DR)"), --boolean array
			#("terminator_shadowShift", true, "terminator_shadowShift (Terminator_shadow_shift)"), --float
			#("terminator_bumpShadowSharpness", true, "terminator_bumpShadowSharpness (Terminator_bump_mapping_sharpness)"), --float
			#("system_drRenderStripOnly", true, "system_drRenderStripOnly (Render_only_one_strip_at_a_time)"), --boolean
			#("interactive_forcePt", true, "interactive_forcePt (Force_PT_PT_for_interactive_rendering)"), --boolean

			--Corona v1.7 NEW features
			#("geometry_hairSubdivs", true, "geometry_hairSubdivs (Hair_tesselation_subdivs) (not in UI)"), --integer
			#("hairPlanes", true, "hairPlanes (Planar_hair) (not in UI)"), --boolean
			#("lights_useAdaptiveSolver", true, "lights_useAdaptiveSolver (Use_1_7_experimental_adaptive_light_solver)"), --boolean
			
			--Corona v2.0 NEW features
			--#("bg_texmap", true, "Environment texture map"), --TextureMap Objects (we can't handle them)
			--#("bg_texmapDirect", true, "Direct visibility texture map"), --TextureMap Objects (we can't handle them)
			--#("bg_texmapReflect", true, "Reflections texture map"), --TextureMap Objects (we can't handle them)
			--#("bg_texmapRefract", true, "Refractions texture map"), --TextureMap Objects (we can't handle them)
			--#("dof_bokehTexmap", true, "Bokeh texture map"), --TextureMap Objects (we can't handle them)
			#("mtlOverride_preserveGlassMtl", true, "Material Override - Preserve Glass Material"),
			#("mtlOverride_preserveLightMtl", true, "Material Override - Preserve Light Material"),
			#("mtlOverride_preservePortalMtl", true, "Material Override - Preserve Portal Material"),
			#("mtlOverride_preserveUnsupportedMtl", true, "Material Override - Preserve Unsupported Material"),
			--#("overrideMtl_exclude", true, " Material Override - Exclude List"),

			--Corona v2-6 NEW features
			--#("globalVolumeMtl", true, "Global Volume Material"), --TextureMap Objects (we can't handle them)
			--#("obsoleteTabParam", true, "Obsolete Tab Param"), --Array (we can't handle them)
			#("bg_mapCount", true, "Map count"), --integer
			#("bloomGlare_size", true, "Bloom Glare - Size"), --float
			#("caustics_alpha", true, "Caustics - Alpha"), --float
			#("caustics_dispersionRadius", true, "Caustics - Dispersion Radius"), --float
			#("caustics_emitFromEnviro", true, "Caustics - Emit From Environment"), --boolean
			#("caustics_initialRadius", true, "Caustics - Initial Radius"), --float
			#("caustics_maxPhotonCount", true, "Caustics - Max Photon Count"), --integer
			#("caustics_motionBlurRadius", true, "Caustics - Motion Blur Radius"), --float
			#("caustics_onlyInCausticsElement", true, "Caustics - Only In Caustics Element"), --boolean
			#("caustics_use", true, "Caustics - Use"), --boolean
			#("caustics_useAdaptivity", true, "Caustics - Use Adaptivity"), --boolean
			#("caustics_usefulnessRatio", true, "Caustics - Usefulness Ration"), --float
			#("colorMap_greenMagentaTint", true, "Color Map - Green Magenta Tint"), --float
			#("denoise_duringRender", true, "Denoise - During Render"), --boolean
			#("devel_enable", true, "Development/Experimental - Enable"), --boolean
			#("geometry_displace_useAutoBump", true, "Geometry - Displace - Use Auto Bump"), --boolean
			#("gi_fourkcache_glossThreshold", true, "4K Cache - Gloss Threshold"),  --float
			#("gi_fourkcache_granularity", true, "4K Cache - Granularity"), --float
			#("gi_fourkcache_quality", true, "4K Cache - Quality"), --float
			#("gi_giCache_file", true, "Cache - File"),--filename
			#("gi_giCache_precalcMode", true, "Cache - Precalculation Mode"), --integer
			#("gi_giCache_save", true, "Cache - Save"), --boolean
			#("image_prefilter_width", true, "Image Prefilter - Width"), --integer
			#("interactive_dissolveWithPrevious", true, "Interactive - Dissolve With Previous"), --boolean
			#("interactive_giPrecompMult", true, "Interactive - interactive_giPrecompMult (not in UI)"), --float
			#("interactive_measureFps", true, "Interactive - Measure FPS"), --boolean
			#("interactive_mtlEditor", true, "Interactive - Material Editor"), --boolean
			#("interactive_showFps", true, "Interactive - Show FPS"), --boolean
			#("lensEffects_aperture_rotation", true, "Lens Effects - Aperture Rotation"), --float
			#("lensEffects_aperture_sides", true, "Lens Effects - Aperture Sides"), --integer
			#("lensEffects_customAperture", true, "Lens Effects - Custom Aperture"), --boolean
			#("lensEffects_dust_density", true, "Lens Effects - Dust - Density"), --float
			#("lensEffects_dust_enabled", true, "Lens Effects - Dust - Enabled"), --boolean
			#("lensEffects_dust_jitter", true, "Lens Effects - Dust - Jitter"), --float
			#("lensEffects_dust_pattern", true, "Lens Effects - Dust - Pattern"), --integer
			#("lensEffects_dust_radiusVar", true, "Lens Effects - Dust - Radius Var."), --float
			#("lensEffects_dust_rotation", true, "Lens Effects - Dust - Rotation"), --float
			#("lensEffects_dust_strength", true, "Lens Effects - Dust - Strength"), --float
			#("lensEffects_dust_zoom", true, "Lens Effects - Dust - Zoom"), --float
			#("lensEffects_occlusion_arc", true, "Lens Effects - Occlusion - Arc"), --float
			#("lensEffects_occlusion_enabled", true, "Lens Effects - Occlusion - Enabled"), --boolean
			#("lensEffects_occlusion_ratio", true, "Lens Effects - Occlusion - Ratio"), --float
			#("lensEffects_occlusion_rotation", true, "Lens Effects - Occlusion - Rotation"), --float
			#("lensEffects_occlusion_symmetric", true, "Lens Effects - Occlusion - Symmetric"), --boolean
			#("lensEffects_peripheralGrating_density", true, "Lens Effects - Peripheral Grating - Density"), --float
			#("lensEffects_peripheralGrating_enabled", true, "Lens Effects - Peripheral Grating - Enabled"), --boolean
			#("lensEffects_peripheralGrating_length", true, "Lens Effects - Peripheral Grating - Length"), --float
			#("lensEffects_peripheralGrating_slope", true, "Lens Effects - Peripheral Grating - Slope"), --float
			#("lensEffects_peripheralGrating_strength", true, "Lens Effects - Peripheral Grating - Strength"), --float
			#("lensEffects_peripheralGrating_zoom", true, "Lens Effects - Peripheral Grating - Zoom"), --float
			#("lensEffects_scratches_density", true, "Lens Effects - Scratches - Density"), --float
			#("lensEffects_scratches_enabled", true, "Lens Effects - Scratches - Enabled"), --boolean
			#("lensEffects_scratches_length", true, "Lens Effects - Scratches - Length"), --float
			#("lensEffects_scratches_pattern", true, "Lens Effects - Scratches - Pattern"), --integer
			#("lensEffects_scratches_rotation", true, "Lens Effects - Scratches - Rotation"), --float
			#("lensEffects_scratches_seed", true, "Lens Effects - Scratches - Seed"), --integer
			#("lensEffects_scratches_slopeVar", true, "Lens Effects - Scratches - Slope Var."), --float
			#("lensEffects_scratches_streaks", true, "Lens Effects - Scratches - Streaks"), --integer
			#("lensEffects_scratches_strength", true, "Lens Effects - Scratches - Strength"), --float
			#("lensEffects_scratches_symmetric", true, "Lens Effects - Scratches - Symmetric"), --boolean
			#("lensEffects_scratches_widthVar", true, "Lens Effects - Scratches - Width Var."), --float
			#("lensEffects_scratches_zoom", true, "Lens Effects - Scratches - Zoom"), --float
			#("lensEffects_useLegacyEffect", true, "Lens Effects - Use Legacy Effect"), --boolean
			#("medium_legacyResolving", true, "Medium - Legacy Resolving"), --boolean
			#("standaloneMaps", true, "Standalone Maps"), --boolean
			#("system_tooltips_enable", true, "System - Tooltips Enabled"), --boolean
			#("telemetry_enabled", true, "Telemetry Enabled") --float
		)
		
		setCurrentRendererSetting options_array
		
		local options_array = #(
			#("renderer", "Render Engine", #( "Bucket", "--", "Progressive", "Bidir/VCM" ), 1 ), --Deprecated in Corona 1.5
			#("GI_solver", "Primary Solver", #( "None", "Path Tracing" ), 1 ), --Removed in corona 2
			#("GI_secondary_solver", "Secondary Solver", #( "None", "Path Tracing", "--", "HD Cache" ), 1 ),--Removed in corona 2
			#("Type_of_bokeh_shape", "Aperture Shape (Bokeh)", #( "Circular", "Bladed", "Custom" ), 1 ),--Removed in corona 2
			#("Image_Filter", "Image Filter Type", #( "None", "Box", "Gaussian", "Tent" ), 1 ),--Removed in corona 2
			#("VCM_mode", "VCM Mode", #( "[PT+MIS] Path Tracing + Next Event Estimage", "[LT] Light Tracing", "[PPM] Progressive Photon Mapping", "[BDPM] Bidirectional PPM", "[BDPT] Bidirectional Path Tracing", "[VCM] Vertex Connection and Merging" ), 1 ),
			#("HD_cache_precalculation_mode", "Precomputation", #( "Calculate From Scratch", "Load From File", "Load From File + Append" ), 1 ),--Removed in corona 2
			#("colormap_exposureType", "Color Map Exposure Type", #( "Use simple exposure", "Use photographic exposure" ), 1 ),
			#("shading_primarySolver", "Primary Solver", #( "None (biased)", "Path Tracing" ), 1 ),
			#("shading_secondarySolver", "Secondary Solver", #( "None (biased)", "Path Tracing", "UHD Cache" ), 1 ),
			#("shading_primary_solver_enums", "Primary Solver", #( "None (biased)", "Path Tracing" ), 1 ),
			#("shading_secondary_solver_enums", "Secondary Solver", #( "None (biased)", "Path Tracing", "UHD Cache" ), 1 ),
			#("bg_source", "Background Source Environment", #( "Use 3ds max settings (Environment tab)", "Use Corona:" ), 1 ),
			#("dof_bokehShape", "Aperture Shape (Bokeh)", #( "Circular", "Bladed", "Custom" ), 1 ),
			#("geometry_displace_subdivType", "Geometry Displacement Type", #( "Screen size (px):", "World size (units):" ), 1 ),
			#("shading_renderEngine", "Render Engine", #( "Bucket", "--", "Progressive", "Bidir/VCM" ), 1 ),  --Deprecated in Corona 1.5
			#("geometry_accelerationStructure", "Acceleration Structure", #( "None (slooow)", "BVH full SAH", "Intel(r) Embree" ), 1 ),
			#("system_randomSampler", "Random Sampler (not in UI)", #( "Shared PRNG", "Per-pixel Shirley", "One-sample High-D", "5D Deterministic + PRNG", "Optimal 1S High-D", "Per-pixel Xorshift128", "Per-pixel TEA", "Per-pixel Xorshift*", "5D High-D + PRNG" ), 1 ),
			#("texmapFiltering", "Texmap Filtering (not in UI)", #( "None", "All but opacity", "All" ), 1 ),
			#("lights_solver", "Solver (not in UI)", #( "Combined", "Better Object-based", "Object-based" ), 1 ),
			#("lights_samplingMode", "Sampling Mode (not in UI)", #( "Lights only", "BSDF only", "MIS - both (best)" ), 1 ),
			#("gi_vcm_mode", "Mode", #( "[PT+MIS] Path Tracing + Next Event Estimage", "[LT] Light Tracing", "[PPM] Progressive Photon Mapping", "[BDPM] Bidirectional PPM", "[BDPT] Bidirectional Path Tracing", "[VCM] Vertex Connection and Merging" ), 1 ),
			#("gi_uhdcache_preset", "UHD Cache Preset", #( "Still frame (fast precomputation)", "Animation (flickerfree)" ), 1 ),
			#("gi_hdCache_precalcMode", "Precomputation", #( "Calculate From Scratch", "Load From File", "Load From File + Append" ), 1 ),
			#("gi_uhdCache_precalcMode", "Precomputation", #( "Calculate from scratch", "Load from file", "Load from file + append" ), 1 ), --Corona 1.6 changed the property name by prefixing the letter: "u" (gi_hd -> gi_uhd)
			#("image_filter_type", "Image Filter Type", #( "None", "Box", "Gaussian", "Tent" ), 1 ),  --Deprecated in Corona 1.4
			#("image_prefilter_type", "Pre Image Filter Type", #( "None", "Box", "Tent", "Parabolic", "Symmetric Tent", "Hann", "Blackman-Harris" ), 1 ), --NEW property in Corona 1.4
			#("renderSelected_mode", "Render Selected Mode", #( "Disabled", "Viewport selection", "Object GBuffer ID", "Include/exclude list" ), 1 ),
			#("denoise_filterType", "Denoise Filter Mode", #( "None", "Only remove fireflies", "Full denoising", "Gather data for later" ), 1 ) --NEW property in Corona 1.4
		)
		
		setCurrentRendererEnumIndex options_array
		
		--Special case to override Corona Frame Buffer (VFB) visibility
		local overrideShowRendererFB = DeadlineUtil.GetJobInfoEntry "ShowRendererFrameBufferOverride"
		local showRendererFB = DeadlineUtil.GetJobInfoEntry "ShowRendererFrameBuffer"

		if overrideShowRendererFB != undefined and showRendererFB != undefined do
		(
			--Corona 1.5 removed any VFB type, so check for either property to be present to proceed
			if (hasProperty renderers.current #Type_of_VFB_window) OR (hasProperty renderers.current #vfb_type) do
			(
				try
				(
					if( execute( overrideShowRendererFB ) ) then
					(
						if( execute( showRendererFB ) ) then
						(
							if (hasProperty renderers.current "Type_of_VFB_window") then
							(
								renderers.current.Type_of_VFB_window = 2 
							)
							else 
							(
								renderers.current.vfb_type = 2
							)
							DeadlineUtil.LogMessage ("  +Show Corona Frame Buffer (VFB) enabled")
						)
						else
						(
							if (hasProperty renderers.current "Type_of_VFB_window") then
							(
								renderers.current.Type_of_VFB_window = 0 
							)
							else 
							(
								renderers.current.vfb_type = 0
							)
							DeadlineUtil.LogMessage ("  +Show Corona Frame Buffer (VFB) disabled")
						)
					)
					else
					(
				        DeadlineUtil.LogMessage ("  +Not overriding Show Corona Frame Buffer (VFB) setting")

				        if (hasProperty renderers.current "Type_of_VFB_window") then
				        (
					        local theVal = DeadlineUtil.GetJobInfoEntry "corona_Type_of_VFB_window_enums"
							if theVal != undefined AND theVal != "--" do  
							(
								local theArray = #( "None", "Native 3dsmax VFB", "Corona VFB" )
								local theIndex = findItem theArray theVal
								if theIndex > 0 then 
								(	
									try 
									(
										if renderers.current.Type_of_VFB_window != theIndex-1 do
										(
											renderers.current.Type_of_VFB_window = theIndex-1
											DeadlineUtil.LogMessage ("  +VFB Type set to " + theVal)	
										)
									)
									catch
									(
										DeadlineUtil.WarnMessage ("  --Failed to set VFB Type to " + theVal)
									)
								)
								else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for VFB Type: " + theVal)
							)
						)--endif
						else
						(
							local theVal = DeadlineUtil.GetJobInfoEntry "corona_vfb_type_enums"
							if theVal != undefined AND theVal != "--" do  
							(
								local theArray = #( "None", "Native 3dsmax VFB", "Corona VFB" )
								local theIndex = findItem theArray theVal
								if theIndex > 0 then
								(
									try 
									(
										if renderers.current.vfb_type != theIndex-1 do
										(
											renderers.current.vfb_type = theIndex-1
											DeadlineUtil.LogMessage ("  +VFB Type set to " + theVal)
										)
									)
									catch
									(
										DeadlineUtil.WarnMessage ("  --Failed to set VFB Type to " + theVal)
									)
								)
								else DeadlineUtil.WarnMessage ("  --Missing / Not Recognized Value for VFB Type: " + theVal)
							)
						)--endelse
					)
				)
				catch(DeadlineUtil.WarnMessage ("  --Failed to set Show Corona Frame Buffer (VFB) to " + showRendererFB ) )
			)
		)
        
		--Handle progressive time limit special case if modified post job submission via 3dsmax.options file
		try(local timeLimit = execute (DeadlineUtil.GetJobInfoEntry "corona_progressive_timeLimit"))catch(local timeLimit = undefined)
		if timeLimit != undefined do --check maxscript renderer property exists before attempting to override it in renderer
		(
			local overrideTimeLimit = (DeadlineUtil.GetJobInfoEntry "corona_progressive_timeLimit_override" == "True")
			if overrideTimeLimit != undefined AND overrideTimeLimit do
			(
				local hh = try(execute (DeadlineUtil.GetJobInfoEntry "corona_progressive_timeLimit_hours"))catch(0)
				local mm = try(execute (DeadlineUtil.GetJobInfoEntry "corona_progressive_timeLimit_minutes"))catch(0)
				local ss = try(execute (DeadlineUtil.GetJobInfoEntry "corona_progressive_timeLimit_seconds"))catch(0)
				timeLimit = (hh*3600000)+(mm*60000)+(ss*1000)
			)
			local timeLimitStr = ((dotNetClass "TimeSpan").FromMilliseconds(timeLimit)).ToString()
			try (
				renderers.current.progressive_timeLimit = timeLimit
				DeadlineUtil.LogMessage ( "  +Progressive Time Limit set to " + timeLimitStr )
			)catch
				DeadlineUtil.WarnMessage ( "  --Failed to set Progressive Time Limit to " + timeLimitStr )
		)
		try(
		    lutfile2 =  renderers.current.colorMap_lut_path
			if lutfile2 != undefined then(
				newlutpath = maxFilePath + ( getFileNameOO lutfile2 )
                if ( renderers.current.colorMap_lut_enable) then (renderers.current.colorMap_lut_path = newlutpath )
                DeadlineUtil.LogMessage( newlutpath )
                )
		)catch(
            try(
                lutfile =  (getProperty (getProperty renderers.current "colorMap.pipeline") "colorMappingOperator.path" )


                if lutfile != undefined then(
                    newlutpath = maxFilePath + ( getFileNameOO lutfile)
                    DeadlineUtil.LogMessage( newlutpath )
                    setProperty (getProperty renderers.current "colorMap.pipeline") "colorMappingOperator.path" newlutpath
                )
            )catch(

				theFiles = getFiles (maxFilePath+"\\*.cube ")
				if theFiles.count > 0 then(
					assetLutfile = theFiles[1]
					DeadlineUtil.LogMessage( "Get Lut file by assets path >> " + assetLutfile  )
				)
				try(
					pipeline = getProperty renderers.current "colorMap.pipeline"
					while pipeline != undefined do
					(
						operatorClass = classOf pipeline
						if operatorClass == LutOperatorPlugin then exit
						pipeline = getProperty pipeline "colorMappingOperator.nextOperator"
					)
					if pipeline != undefined then setProperty pipeline "colorMappingOperator.path" theFiles[1]
					DeadlineUtil.LogMessage( "Set Lut file by assets path >> " + theFiles[1]  )
				)catch( DeadlineUtil.LogMessage( "Set Lut file by assets path  Failed ! >> " ) )
            )
        )
		try(
			rendShowVFB=True
			DeadlineUtil.LogMessage(" show the renderer vfb  " )
		)catch(DeadlineUtil.LogMessage(" unlock the camera " ))
	)--end if Corona
--END CORONA SPECIFIC SETTINGS

--AUTODESK ART SPECIFIC SETTINGS:
	if getRendererIdString() == "art" do
	(
		DeadlineUtil.LogMessage ">ART Renderer detected as current renderer."

		--Each element of the array is a sub-array containing
		--1. the name of the property as string,
		--2. whether to convert the value to maxscript value or keep as string,
		--3. the description string used to output to the log file.
		
		local options_array = #(
			#("enable_iterations", true, "Enable Iterations"),
			#("iterations", true, "Iterations"),
			#("quality_db", true, "Target Quality (dB)"),
			#("enable_time", true, "Enable Time Limit"),
			#("time_in_seconds", true, "Time Limit"),
			--#("time_split_seconds", true, ""), --ignored as we set it via time_in_seconds above
			--#("time_split_minutes", true, ""), --ignored as we set it via time_in_seconds above
			--#("time_split_hours", true, ""), --ignored as we set it via time_in_seconds above
			#("motion_blur_all_objects", true, "All Objects Receive Motion Blur"),
			--#("render_method", true, "Render Method"), --handled lower down as an enum
			#("point_light_diameter", true, "Point Light Diameter"),
			#("enable_outlier_clamp", true, "Enable Outlier Clamp"), --NOT in UI
			#("anti_aliasing_filter_diameter", true, "Anti-Aliasing Filter Diameter"),
			#("enable_animated_noise", true, "Animate Noise Pattern"),
			#("enable_noise_filter", true, "Enable Noise Filter"),
			--#("noise_filter_strength", true, "Noise Filter Strength"), --ignored as we set it via noise_filter_strength_percentage below
			#("noise_filter_strength_percentage", true, "Noise Filter Strength"),
			#("texture_bake_resolution", true, "Texture Bake Resolution"),
			#("maximum_interactive_down_res_factor", true, "Max. Interactive Down-Res Factor")
		)

		setCurrentRendererSetting options_array
		
		local options_array = #(
			#("render_method", "Rendering Method", #( "Advanced Path Tracing", "Fast Path Tracing" ), 1 )
		)
			
		setCurrentRendererEnumIndex options_array

	)--end if Autodesk Art
--END AUTODESK ART SPECIFIC SETTINGS

--IRAY SPECIFIC SETTINGS:
	if getRendererIdString() == "iray" do
	(
		DeadlineUtil.LogMessage ">iray Renderer detected as current renderer."

		try
		(
			DeadlineUtil.LogMessage (">iray Version: " + (DeadlineUtil.GetJobInfoEntry ("iray_version") as string) )
		)
		catch
		(
			DeadlineUtil.WarnMessage("--Unable to detect iray Version")
		)

		--Each element of the array is a sub-array containing
		--1. the name of the property as string, 
		--2. whether to convert the value to maxscript value or keep as string, 
		--3. the description string used to output to the log file.
		
		local options_array = #(
			#("durationInSeconds", true, "Render Time in Seconds"), --integer
			#("durationPasses", true, "Render Passes"), --integer
			#("durationMode", true, "Duration Mode"), --enum

			#("architecturalSamplerEnabled", true, "Architectural Sampler"), --boolean
			#("causticSamplerEnabled", true, "Caustic Sampler"), --boolean
			
			#("displacementView", true, "Displacement View"), --boolean
			#("displacementSmoothing", true, "Displacement Smoothing"), --boolean
			#("displacementEdgeLength", true, "Displacement Edge Length"), --float
			#("displacementMaximum", true, "Displacement Maximum"), --float
			#("displacementSubdivisionLevel", true, "Displacement Subdivision Level"), --integer

			#("displacementParametricSubdivisionLevel", true, "Parametric Subdivision Level"), --integer (added Max2016)
			#("displacementDisplaceMethod", true, "Displacement Method"), --enum (added Max2016)

			#("overrideMaterialEnabled", true, "Material Override Enable"), --boolean
--			#("overrideMaterial", false, "Override Material"), --#texturemap/material

			#("lightBouncesLimited", true, "Limit Number of Light Bounces"), --boolean
			#("lightBouncesMaximum", true, "Maximum Light Bounces"), --integer

			#("imageFilterType", true, "Image Filter Type"), --enum
			#("imageFilterWidth", true, "Image Filter Width"), --float

			#("textureCompressionEnabled", true, "Texture Compression Enable"), --boolean (added Max2016)
  			#("textureCompressionMinResolution", true, "Disable Compression Below"), --integer (added Max2016)

			#("motionBlurEnabled", true, "Motion Blur Enable"), --boolean
			#("blurAllObjectsEnabled", true, "Blur All Objects"), --boolean
			#("shutterDurationInFrames", true, "Shutter Duration In Frames"), --float
			#("shutterOffsetInFrames", true, "Shutter Offset In Frames"), --float
			#("motionSegments", true, "Motion Segments"), --integer
			#("iterationsPerMotionStep", true, "Iterations Per Motion Step"), --integer

			#("NumberOfAllocatedCPUS", true, "Allocate CPUs (Number Of Processors)") --integer
		)

		setCurrentRendererSetting options_array
	)--end if iray
--END IRAY SPECIFIC SETTINGS		

--QUICKSILVER SPECIFIC SETTINGS:
	if getRendererIdString() == "quicksilver" do
	(
		DeadlineUtil.LogMessage ">Quicksilver Renderer detected as current renderer."
		
		--Each element of the array is a sub-array containing
		--1. the name of the property as string, 
		--2. whether to convert the value to maxscript value or keep as string, 
		--3. the description string used to output to the log file.
		
		local options_array = #(
			#("UseDefaultLights", true, "Illuminate With Default Lights"),
			#("UseShadows", true, "Shadows"),
			#("SoftShadowMultiplier", true, "Soft Shadows Precision (Multiplier)"),
			
			#("AmbientOcclusionEnabled", true, "Enable Ambient Occlusion"),
			#("AmbientOcclusionIntensity", true, "Ambient Intensity/Fade"),
			#("AmbientOcclusionRadius", true, "Ambient Radius"),
			
			#("IndirectIlluminationEnabled", true, "Enable Indirect Illumination"),
			#("IndirectIlluminationMultiplier", true, "Illumination Multiplier"),
		--	#("IndirectIlluminationSamples", true, "Illumination Sample Distribution Area"),
			#("IndirectIlluminationShadowEnabled", true, "Enable Indirect Lighting Shadows"),
			
		--	#("IndirectIlluminationLODEnabled", true, "Indirect Illumination LOD Enabled"),
		--	#("IndirectIlluminationRSMSize", true, "IndirectIlluminationRSMSize"),
		--	#("IndirectIlluminationShadowSize", true, "IndirectIlluminationShadowSize"),
		--	#("IndirectIlluminationShadowRange", true, "IndirectIlluminationShadowRange"),
			
			#("TransparencyEnabled", true, "Enable Transparency"),
			#("ReflectionsEnabled", true, "Enable Reflections"),
			
		--	#("UseShaderCacheFileSystem", true, "SoftShadowMultiplier"),
			
			#("DepthOfFieldEnabled", true, "Enable Depth Of Field"),
			#("FocalPlane", true, "DOF Override Focal Plane"),
			#("NearPlane", true, "DOF Override Near Plane"),
			#("FarPlane", true, "DOF Override Far Plane")
		)
		
		setCurrentRendererSetting options_array
		
		local options_array = #(
			#("HardwareSamplingQuality", "Hardware Sampling Quality", #("None (Draft)", "2x", "4x", "8x"), #(#none, #2x, #4x, #8x) ),
			#("SoftwareSamplingQuality", "Software Sampling Quality", #("None (Draft)", "4x", "16x"), #(#none, #4x, #16x) ),
			#("DepthOfFieldMode", "Depth Of Field Mode", #("From Camera","Override Camera"), #(#camera, #Override) ),
			#("TransparencyMode", "Transparency Mode", #("Simple","Best"), #(#simple, #Best) )
		)
		setCurrentRendererEnumName options_array
	)--end if quicksilver
--END QUICKSILVER SPECIFIC SETTINGS	

--KRAKATOA SPECIFIC SETTINGS:
	if getRendererIdString() == "krakatoa" do
	(
		DeadlineUtil.LogMessage ">Krakatoa Volumetric Particle Renderer detected as current renderer."
		
		--Each element of the array is a sub-array containing
		--1. the INI FIle Property as string, 
		--2. the Krakatoa name of the property as string, 
		--3. the description string used to output to the log file.
		
		--Common Krakatoa Properties:
		local options_array = #(
			#("BackgroundColor", "BackgroundColor", "Custom Background Color"),
			#("UseEnvironmentColor", "UseEnvironmentColor", "Use Environment Color"),
			#("PostDivideByAlpha", "PostDivideByAlpha", "Post-Divide By Alpha"),
			
			#("Density_DensityPerParticle", "Density:DensityPerParticle", "Final Pass Density Per Particle"),
			#("Density_DensityExponent", "Density:DensityExponent", "Final Pass Density Exponent"),

			#("Density_LinkLightingAndRenderingDensity", "Density:LinkLightingAndRenderingDensity", "Density_LinkLightingAndRenderingDensity"),
			#("Lighting_Density_DensityPerParticle", "Lighting:Density:DensityPerParticle", "Lighting_Density_DensityPerParticle"),
			#("Lighting_Density_DensityExponent", "Lighting:Density:DensityExponent", "Lighting_Density_DensityExponent"),
			
			#("DrawPointFilter", "DrawPointFilter", "Draw Point Filter"),
			#("AttenuationLookupFilter", "AttenuationLookupFilter", "Attenuation Lookup Filter"),
			
			#("EnableMotionBlur", "EnableMotionBlur", "Enable Motion Blur"),
			#("MotionBlurSegments", "MotionBlurSegments", "Motion Blur Segments"),
			#("JitteredMotionBlur", "JitteredMotionBlur", "Jittered Motion Blur"),
			#("ShutterBias", "ShutterBias", "Shutter Bias"),
			#("ShutterAngleInDegrees", "ShutterAngleInDegrees", "Shutter Angle In Degrees"),
			
			#("EnableDepthOfField", "EnableDepthOfField", "Enable Depth Of Field"),
			#("DepthOfFieldSampleRate", "DepthOfFieldSampleRate", "Depth Of Field Sample Rate"),
			
			#("EnableAttenuationMapSaving", "EnableAttenuationMapSaving", "Enable Attenuation Map Saving"),
			#("UseDepthMaps", "UseDepthMaps", "Use Depth Maps"),
			#("Matte_UseMatteObjects", "Matte:UseMatteObjects", "Use Matte Objects")
		)	
		
		--Krakatoa Properties pre v1.5
		if execute (substring FranticParticles.version 1 3) < 1.5 then
		(
			additional_options_array = #(
				#("Density_DensityMethod", "Density:DensityMethod", "Final Pass Density Method"),
				#("DensityScalingSource", "DensityScalingSource", "Final Pass Density Scaling Source"),
				#("Lighting_Density_DensityMethod", "Lighting:Density:DensityMethod", "Lighting_Density_DensityMethod"),
				#("UseGlobalColorOverride", "UseGlobalColorOverride", "Use Global Color Override"),
				#("ParticleColorSource", "ParticleColorSource", "Particle Color Source"),
				#("ChosenColor", "ChosenColor", "Custom Particle Color"),
				#("UseLighting", "UseLighting", "UseLighting"),
				#("Lighting_Specular_Enabled", "Lighting:Specular:Enabled", "Use Normals"),
				#("Lighting_Specular_Glossiness", "Lighting:Specular:Glossiness", "Specular Glossiness"),
				#("Lighting_Specular_Level", "Lighting:Specular:Level", "Specular Level"),
				#("RenderParticleFlowGeometry", "RenderParticleFlowGeometry", "Render Particle Flow Geometry"),
				#("RenderParticleFlowBBox", "RenderParticleFlowBBox", "Render Particle Flow BBox"),
				#("RenderParticleFlowPhantom", "RenderParticleFlowPhantom", "Render Particle Flow Phantom"),
				#("RenderParticleObjectExt", "RenderParticleObjectExt", "Render Particle Object Ext"),
				#("RenderMaxParticles", "RenderMaxParticles", "Render Max Particles"),
				#("RenderThinkingParticles", "RenderThinkingParticles", "Render Thinking Particles"),
				#("RenderGeometryVertices", "RenderGeometryVertices", "Render Geometry Vertices"),
				#("RenderKrakatoaLoaders", "RenderKrakatoaLoaders", "Render Krakatoa Loaders")
			)
		)
		else
		(
			additional_options_array = #(
				#("IgnoreSceneLights", "IgnoreSceneLights", "Ignore Scene Lights"),
				#("UseEnvironmentReflections", "UseEnvironmentReflections", "Use Environment Reflections"),
				#("UseFilterColor", "UseFilterColor", "Use Absorption"),
				#("UseEmissionColor", "UseEmissionColor", "Use Emission"),
				#("AdditiveMode", "AdditiveMode", "Force Additive Mode"),
				
				#("ColorOverride_Enabled", "ColorOverride:Enabled", "Use Override Color"),
				#("ColorOverride_Color", "ColorOverride:Color", "Override Color"),
				#("ColorOverride_BlendAmount", "ColorOverride:BlendAmount", "Override Color Blend Amount"),
				
				#("AbsorptionOverride_Enabled", "AbsorptionOverride:Enabled", "Use Absorption Color"),
				#("AbsorptionOverride_Color", "AbsorptionOverride:Color", "Absorption Color"),
				#("AbsorptionOverride_BlendAmount", "AbsorptionOverride:BlendAmount", "Override Absorption Blend Amount"),

				#("EmissionOverride_Enabled", "EmissionOverride:Enabled", "Use Emission Color"),
				#("EmissionOverride_Color", "EmissionOverride:Color", "Emission Color"),
				#("EmissionOverride_BlendAmount", "EmissionOverride:BlendAmount", "Override Emission Blend Amount"),

				#("DensityOverride_Enabled", "DensityOverride:Enabled", "Use Density Color"),
				#("DensityOverride_Color", "DensityOverride:Color", "Density Color"),
				#("DensityOverride_BlendAmount", "DensityOverride:BlendAmount", "Override Density Blend Amount"),

				#("VoxelSize", "VoxelSize", "Voxel Size"),
				#("VoxelFilterRadius", "VoxelFilterRadius", "Voxel Filter Radius"),

				#("PhaseEccentricity", "PhaseEccentricity", "Phase Eccentricity"),
				#("IgnoreMissingParticles", "IgnoreMissingParticles", "Ignore Missing Particles"),
				
				#("RenderingMethod", "RenderingMethod", "Rendering Method"),
				#("PhaseFunction", "PhaseFunction", "Phase Function"),
				
				#("RenderParticleFlowGeometry", "RenderParticleFlowGeometry", "Render Particle Flow Geometry"),
				#("RenderParticleFlowBBox", "RenderParticleFlowBBox", "Render Particle Flow BBox"),
				#("RenderParticleFlowPhantom", "RenderParticleFlowPhantom", "Render Particle Flow Phantom"),
				
				#("RenderFumeFX", "RenderFumeFX", "Render FumeFX Simulations"),
				#("RenderMaxParticles", "RenderMaxParticles", "Render Max Particles"),
				#("RenderThinkingParticles", "RenderThinkingParticles", "Render Thinking Particles"),
				
				#("RenderGeometryVertices", "RenderGeometryVertices", "Render Geometry Vertices"),
				#("RenderKrakatoaLoaders", "RenderKrakatoaLoaders", "Render Krakatoa PRT Loaders"),
				#("RenderGeometryVolumes", "RenderGeometryVolumes", "Render Krakatoa PRT Volumes"),
				
				#("GlobalParticlePercentage", "GlobalParticlePercentage", "Global Particle Percentage"),
				#("Lighting_Specular_SpecularPower", "Lighting:Specular:SpecularPower", "Specular Power"),
				#("Lighting_Specular_Level", "Lighting:Specular:Level", "Specular Level"),
				
				#("Channel_Allocate_SpecularPower", "Channel:Allocate:SpecularPower", "Allocate SpecularPower Channel"),
				#("Channel_Allocate_SpecularLevel", "Channel:Allocate:SpecularLevel", "Allocate SpecularLevel Channel"),
				#("Channel_Allocate_PhaseEccentricity", "Channel:Allocate:PhaseEccentricity", "Allocate PhaseEccentricity Channel"),

				#("Matte_RayDivisions", "Matte:RayDivisions", "Matte SuperSampling"),
				#("Matte_SaveMultipleLayers", "Matte:SaveMultipleLayers", "Save Multiple Layers")
			)			
		)
		join options_array additional_options_array
		

		for p in options_array do
		(
			local theVal = DeadlineUtil.GetJobInfoEntry ("krakatoa_" + p[1])
			if theVal != undefined do
			(
				try
				(
					FranticParticles.setProperty (p[2]) theVal
					DeadlineUtil.LogMessage ("  +" + p[3] + " set to " + theVal )
				)
				catch(DeadlineUtil.WarnMessage ("  --Failed to set " + p[3] + " to " + theVal ) )
			)	
		)
	)--end if krakatoa
--END KRAKATOA SPECIFIC SETTINGS


--ARNOLD SPECIFIC SETTINGS:
	if getRendererIdString() == "arnold" do
	(
		DeadlineUtil.LogMessage ">Solid Angle Arnold detected as current renderer."
				
		--Each element of the array is a sub-array containing
		--1. the INI FIle Property as string, 
		--2. whether to convert the value to maxscript value or keep as string, 
		--3. the description string used to output to the log file.
		
		local options_array = #(
			--MAIN CONTROLS > OPTIONS:
			#("AA_sample_clamp",true,"AA Sample Clamp"),
			#("AA_sample_clamp_affects_aovs", true, "AA Sample Clamp Affects AOVs"),
			#("AA_sample_clamp_enabled", true, "AA Sample Clamp Enabled"),
			#("AA_samples", true, "AA Samples"),
			--#("AOV_Manager",true,"AOV Manager"),
			--#("Atmosphere",true,"Atmosphere"), --Material Object -- We currently do not support modifying object references
			#("GI_diffuse_depth",true,"GI Diffuse Depth"),
			#("GI_diffuse_samples",true,"GI Diffuse Samples"),
			#("GI_specular_depth",true,"GI Specular Depth"),
			#("GI_specular_samples",true,"GI Specular Samples"),
			#("GI_sss_samples",true,"GI SSS Samples"),
			#("GI_total_depth",true,"GI Total Depth"),
			#("GI_transmission_depth",true,"GI Transmission Depth"),
			#("GI_transmission_samples",true,"GI Transmission Samples"),
			#("GI_volume_depth",true,"GI Volume Depth"),
			#("GI_volume_samples",true,"GI Volume Samples"),
			#("abort_on_error", true, "Abort on Error"),
			#("abort_on_license_fail",true,"Abort on License Fail"),
			#("ass_file_path",false,"Ass File Path"),
			#("auto_shutter",true,"Auto Shutter"),
			#("auto_transparency_depth",true,"Auto Transparency Depth"),
			#("autodetect_threads",true,"Auto Detect Threads"),
			#("bucket_scanning",true,"Bucket Scanning"),
			#("bucket_size", true,"Bucket Size"),
			#("curves_default_basis", true,"Curves Default Basis"),
			#("curves_default_min_pixel_width", true,"Curves Default Min Pixel Width"),
			#("curves_default_mode", true,"Curves Default Mode"),
			#("deform_keys", true,"Deform Keys"),
			#("displacement_default_subdiv_adaptive_error", true,"Displacement Default Subdivide Adaptive Error"),
			#("displacement_default_subdiv_iterations", true,"Displacement Default Subdivide Iterations"),
			#("displacement_default_subdiv_type", true,"Displacement Default Subdivide Type"),
			#("driver_type", false,"Driver Type"),
			#("enable_deform_keys", true,"Enable Deform Keys"),
			#("enable_transform_keys", true,"Enable Transform Keys"),
			#("enable_user_options", true,"Enable User Options"),
			#("env_adv_bgnd_custom_color",true,"Environment: Advanced Background: Custom Color"),
			--#("env_adv_bgnd_custom_map",true,"Environment: Advanced Background: Custom Map"), --Material Object -- We currently do not support modifying object references
			--#("env_adv_bgnd_custom_shader",true,"Environment: Advanced Background: Custom Shader"), --Material Object -- We currently do not support modifying object references
			#("env_adv_bgnd_mode",true,"Environment: Advanced Background Mode"),
			#("env_adv_bgnd_visible_to_camera",true,"Environment: Advanced Background: Visible to Camera"),
			#("env_adv_bgnd_visible_to_diffuse_reflections",true,"Environment: Advanced Background: Visible to Diffuse Reflections"),
			#("env_adv_bgnd_visible_to_diffuse_transmission",true,"Environment: Advanced Background: Visible to Diffuse Transmission"),
			#("env_adv_bgnd_visible_to_specular_reflections",true,"Environment: Advanced Background: Visible to Specular Reflections"),
			#("env_adv_bgnd_visible_to_specular_transmission",true,"Environment: Advanced Background: Visible to Specular Transmission"),
			#("env_adv_bgnd_visible_to_volume_scattering",true,"Environment: Advanced Background: Visible to Volume Scattering"),
			#("env_adv_ibl_affect_indirect",true,"Environment: Advanced Affect Indirect"),
			#("env_adv_ibl_affect_sss",true,"Environment: Advanced Affect SSS"),
			#("env_adv_ibl_affect_volume",true,"Environment: Advanced Affect Volume"),
			#("env_adv_ibl_camera_mult",true,"Environment: Advanced Camera Multiplier"),
			#("env_adv_ibl_cast_shadows",true,"Environment: Advanced IBL Cast Shadows"),
			#("env_adv_ibl_diffuse_mult",true,"Environment: Advanced IBL Diffuse Multiplier"),
			#("env_adv_ibl_emit_camera",true,"Environment: Advanced IBL Emit Camera"),
			#("env_adv_ibl_emit_diffuse",true,"Environment: Advanced IBL Emit Diffuse"),
			#("env_adv_ibl_emit_specular",true,"Environment: Advanced IBL Emit Specular"),
			#("env_adv_ibl_emit_transmission",true,"Environment: Advanced IBL Emit Transmission"),
			#("env_adv_ibl_indirect_mult",true,"Environment: Advanced IBL Indirect Multiplier"),
			#("env_adv_ibl_max_bounces",true,"Environment: Advanced IBL Max Bounces"),
			#("env_adv_ibl_multiplier",true,"Environment: Advanced IBL Multiplier"),
			#("env_adv_ibl_portal_mode",true,"Environment: Advanced IBL Portal Mode"),
			#("env_adv_ibl_resolution",true,"Environment: Advanced IBL Resolution"),
			#("env_adv_ibl_resolution_enable",true,"Environment: Advanced IBL Resolution Enable"),
			#("env_adv_ibl_shadow_color",true,"Environment: Advanced IBL Shadow Color"),
			#("env_adv_ibl_shadow_density",true,"Environment: Advanced IBL Shadow Density"),
			#("env_adv_ibl_specular_mult",true,"Environment: Advanced IBL Specular Multiplier"),
			#("env_adv_ibl_sss_mult",true,"Environment: Advanced IBL SSS Multiplier"),
			#("env_adv_ibl_transmission_mult",true,"Environment: Advanced IBL Transmission Multiplier"),
			#("env_adv_ibl_volume_mult",true,"Environment: Advanced IBL Volume Multiplier"),
			#("env_adv_ibl_volume_samples",true,"Environment: Advanced IBL Volume Samples"),
			#("env_ibl_enable",true,"Environment: IBL Enable"),
			#("env_ibl_samples",true,"Environment: IBL Samples"),
			#("env_mode",true,"Environment Mode"),
			#("env_phys_bgnd_mode",true,"Environment: Physical Background Mode"),
			#("env_phys_bgnd_color",true,"Environment: Physical Background Color"),
			--#("env_phys_bgnd_map",true,"Environment: Physical Background Map"), --Material Object -- We currently do not support modifying object references
			#("error_color_bad_pixel",true,"Error Color Bad Pixel"),
			#("error_color_bad_shader",true,"Error Color Bad Shader"),
			#("error_color_bad_texture",true,"Error Color Bad Texture"),
			#("expand_procedurals",true,"Expand Procedurals"),
			#("export_binary",true,"Expand Binary"),
			#("export_cameras",true,"Expand Cameras"),
			#("export_driversfilters",true,"Expand Drivers Filters"),
			#("export_geometry",true,"Expand Geometry"),
			#("export_lights",true,"Expand Lights"),
			#("export_option",true,"Expand Options"),
			#("export_shaders",true,"Expand Shaders"),
			#("export_to_ass",true,"Export to Ass"),
			#("filter",true,"Filter"),
			#("filter_width",true,"Filter Width"),
			#("geometry_dicing_camera",false,"Geometry Dicing Camera"),
			#("ignore_atmosphere", true, "Ignore Atmosphere"),
			#("ignore_bump",true,"Ignore Bump"),
			#("ignore_displacement",true,"Ignore Displacement"),
			#("ignore_dof",true,"Ignore Depth of Field"),
			#("ignore_lights", true,"Ignore Lights"),
			#("ignore_motion_blur",true,"Ignore Motion Blur"),
			#("ignore_shaders",true,"Ignore Shaders"),
			#("ignore_shadows", true,"Ignore Shadows"),
			#("ignore_smoothing",true,"Ignore Smoothing"),
			#("ignore_sss",true,"Ignore SSS"),
			#("ignore_subdivision",true,"Ignore Subdivision"),
			#("ignore_textures", true,"Ignore Textures"),
			#("legacy_3ds_max_map_support", true,"Legacy 3DS Max Map Support"),
			#("lock_sampling_pattern",true,"Lock Sampling Pattern"),
			#("low_light_threshold",true,"Low Light Threshold"),
			#("max_subdivisions",true,"Max Subdivisions"),
			#("max_warnings",true,"Max Warnings"),
			#("plugin_searchpath",false,"Plugin Searchpath"),
			#("prepass_enabled",true,"Prepass Enabled"),
			#("prepass_samples",true,"Prepass Samples"),
			#("procedural_searchpath", false, "Procedural Searchpath"),
			#("respect_physical_camera_motion_blur", true, "Respect Physical Camera Motion Blur"),
			#("shutter_close", true, "Shutter Close"),
			#("shutter_length", true, "Shutter Length"),
			#("shutter_open", true, "Shutter Open"),
			#("shutter_position", true, "Shutter Position"),
			#("shutter_type", true, "Shutter Type"),
			#("skip_license_check", true, "Skip License Check"),
			#("sss_use_autobump",true,"SSS Use Autobump"),
			#("texture_accept_unmipped",true,"Texture Accept Unmipped"),
			#("texture_accept_untiled",true,"Texture Accept Untiled"),
			#("texture_automip",true,"Texture Automip"),
			#("texture_autotile",true,"Texture Autotile"),
			#("texture_diffuse_blur",true,"Texture Diffuse Blur"),
			#("texture_enable_autotile",true,"Texture Enable Autotile"),
			#("texture_max_memory_MB",true,"Texture Max Memory MB"),
			#("texture_max_open_files",true,"Texture Max Open Files"),
			#("texture_per_file_stats",true,"Texture Per File Stats"),
			#("texture_searchpath", false,"Texture Search Path"),
			#("texture_specular_blur",true,"Texture Specular Blur"),
			#("threads", true, "Threads"),
			#("transform_keys", true, "Transform Keys"),
			#("use_existing_tx", true, "Use Existing TX"),
			#("user_options",false,"User Options"),
			#("verbosity_level",true,"Verbosity Level")

			)

		setCurrentRendererSetting options_array	
		if systemTools.getEnvVariable( "ABORT_ON_ARNOLD_LICENSE_FAIL" ) == "Always Fail" then
		(
			setCurrentRendererSettingArnold "True"
		)
		else if systemTools.getEnvVariable( "ABORT_ON_ARNOLD_LICENSE_FAIL" ) == "Never Fail" do
		(
			setCurrentRendererSettingArnold "False"
		)
		
	)--end if arnold	
--END ARNOLD SPECIFIC SETTINGS	


--REDSHIFT SPECIFIC SETTINGS:
	if getRendererIdString() == "redshift" do
	(
		DeadlineUtil.LogMessage ">Redshift detected as current renderer."

		--Check Redshift version. Version function introduced in 2.0.66
		rsVersionCheck = try(rsVersion())catch(undefined) --3 element array returned: #(2, 5, 11)
		rsVersionMajor = rsVersionMinor = rsVersionPoint = 0
		if rsVersionCheck != undefined then (
			DeadlineUtil.LogMessage ( ">Redshift version: " + (rsVersionCheck as string) )
			rsVersionMajor = rsVersionCheck[1] as integer
			rsVersionMinor = rsVersionCheck[2] as integer
			rsVersionPoint = rsVersionCheck[3] as integer
		)

		local stringGpuAffinity = systemTools.getEnvVariable( "DEADLINE_GPU_AFFINITY" )
		if stringGpuAffinity != undefined do
		(
			--if Redshift version is undefined, < 2.0.91 or < 2.5.11, then use deprecated maxscript gpu affinity method
			if (rsVersionCheck == undefined) OR (rsVersionMajor <= 2 AND rsVersionMinor == 0 AND rsVersionPoint <= 90) OR (rsVersionMajor == 2 AND rsVersionMinor == 5 AND rsVersionPoint <= 10) do
			(				
				local gpuAffinity = execute( stringGpuAffinity )

				if rsSetCudaDevices( gpuAffinity ) then
					DeadlineUtil.LogMessage (" +Set GPU affinity via mxs to " + stringGpuAffinity)
				else
					DeadlineUtil.WarnMessage (" --Failed to set GPU affinity via mxs to " + stringGpuAffinity)
			)
		)

		--Each element of the array is a sub-array containing
		--1. the name of the property as string, 
		--2. whether to convert the value to maxscript value or keep as string, 
		--3. the description string used to output to the log file.

		local options_array = #(
			#( "RenderHiddenLights", true, "Render hidden lights" ),
			#( "VerboseFileLog", true, "Verbose File Log" ), --NEW in v2.5.x
			#( "RenderViewEnable", true, "Enable Render View" ), --NEW in v2.5.x --Now overridden within the overrideShowRendererFB enum loop below
			#( "BlockRenderingOrder", true, "Block rendering order" ),
			#( "BlockSize", true, "Block size" ),

			#( "ProgressiveRenderingEnabled", true, "Progressive rendering enabled" ),
			#( "ProgressiveRenderingNumPasses", true, "Progressive rendering num passes" ),

			#( "UnifiedMinSamples", true, "Unified min samples" ),
			#( "UnifiedMaxSamples", true, "Unified max samples" ),
			#( "UnifiedAdaptiveErrorThreshold", true, "Unified adaptive error threshold" ),
			#( "UnifiedFilterType", true, "Unified filter type" ),
			#( "UnifiedFilterSize", true, "Unified filter size" ),
			#( "UnifiedMaxSubsampleIntensity", true, "Unified Max Subsample Intensity" ),
			#( "UnifiedMaxSecondaryRayIntensity", true, "Unified max secondary ray intensity" ),
			#( "UnifiedDebugDrawSamples", true, "Unified debug draw samples" ),
			#( "UnifiedDisableDivision", true, "Unified disable division" ),
			#( "UnifiedRandomizePattern", true, "Unified randomize pattern" ),

			#( "MotionBlurEnabled", true, "Motion blur enabled" ),
			#( "MitionBlurDeformationEnabled", true, "Motion blur deformation enabled" ),
			#( "MotionBlurNumTransformationSteps", true, "Motion blur num transformation steps" ),
			#( "MotionBlurNumDeformationSteps", true, "Motion blur num deformation steps" ),
			#( "MotionBlurFrameDuration", true, "Motion blur frame duration" ),
			#( "MotionBlurShutterStart", true, "Motion blur shutter start" ),
			#( "MotionBlurShutterEnd", true, "Motion blur shutter end" ),
			#( "MotionBlurShutterPosition", true, "Motion blur shutter position" ),
			#( "MotionBlurShutterEfficiencyType", true, "Motion blur shutter efficiency type" ),
			#( "MotionBlurShutterEfficiencyForTrapezoidal", true, "Motion blur shutter efficiency for trapezoidal" ),

			#( "Do8BitQuantizationAndDithering", true, "Do 8-bit quantization and dithering" ),

			#( "MaxTraceDepthReflection", true, "Max trace depth reflection" ),
			#( "MaxTraceDepthRefraction", true, "Max trace depth refraction" ),
			#( "MaxTraceDepthCombined", true, "Max trace depth combined" ),

			#( "MPWHairEnabled", true, "MPW hair enabled" ),
			#( "MPWHairAutoThreshold", true, "MPW hair auto threshold" ),
			#( "MPWHairThreshold", true, "MPW hair threshold" ),
			#( "MPWHairTraceDepth", true, "MPW hair trace depth" ),
			#( "RussianRouletteImportanceThreshold", true, "Russian Roulette importance threshold" ),

			#( "RussianRouletteFalloff", true, "Russian Roulette falloff" ),
			#( "DiffuseSamplingCutOffThreshold", true, "Diffuse sampling cut off threshold" ),

			#( "ReflectionSamplingCutOffThreshold", true, "Reflection sampling cut off threshold" ),
			#( "RefractionSamplingCutOffThreshold", true, "Refraction sampling cut off threshold" ),

			#( "DirectLightingCutOffThreshold", true, "Direct lighting cut off threshold" ),
			#( "DirectLightingShadowCutOffThreshold", true, "Direct lighting shadow cut off threshold" ),

			#( "ReflectionsEnable", true, "Reflections enable" ),
			#( "RefractionsEnable", true, "Refractions enable" ),

			#( "SubsurfaceScatteringEnable", true, "Subsurface scattering enable" ),
			#( "TessellationDisplacementEnable", true, "Tesselation displacement enable" ),
			#( "EmissionEnable", true, "Emission enable" ),
			#( "EnableMaterialsMaxCombinedOverrides", true, "Enable Materials Max Combined Overrides" ), --NEW in v2.5.x
			#( "OverrideReflectionSamplesEnabled", true, "Override reflection samples enabled" ),
			#( "OverrideReflectionSamplesMode", true, "Override reflection samples mode" ),
			#( "OverrideReflectionSamplesCount", true, "Override reflection samples count" ),
			#( "OverrideReflectionSamplesScale", true, "Override reflection samples scale" ),

			#( "OverrideRefractionSamplesEnabled", true, "Override refraction samples enabled" ),
			#( "OverrideRefractionSamplesMode", true, "Override refraction samples mode" ),
			#( "OverrideRefractionSamplesCount", true, "Override refraction samples count" ),
			#( "OverrideRefractionSamplesScale", true, "Override refraction samples scale" ),

			#( "OverrideAOSamplesEnabled", true, "Override AO samples enabled" ),
			#( "OverrideAOSamplesMode", true, "Override AO samples mode" ),
			#( "OverrideAOSamplesCount", true, "Override AO samples count" ),
			#( "OverrideAOSamplesScale", true, "Override AO samples scale" ),

			#( "OverrideLightSamplesEnabled", true, "Override light samples enabled" ),
			#( "OverrideLightSamplesMode", true, "Override light samples mode" ),
			#( "OverrideLightSamplesCount", true, "Override light samples count" ),
			#( "OverrideLightSamplesScale", true, "Override light samples scale" ),

			#( "OverrideVolumeSamplesEnabled", true, "Override volume samples enabled" ),
			#( "OverrideVolumeSamplesMode", true, "Override volume samples mode" ),
			#( "OverrideVolumeSamplesCount", true, "Override volume samples count" ),
			#( "OverrideVolumeSamplesScale", true, "Override volume samples scale" ),

			#( "OverrideSingleScatteringSamplesEnabled", true, "Override single scattering samples enabled" ),
			#( "OverrideSingleScatteringSamplesMode", true, "Override single scattering samples mode" ),
			#( "OverrideSingleScatteringSamplesCount", true, "Override single scattering samples count" ),
			#( "OverrideSingleScatteringSamplesScale", true, "Override single scattering samples scale" ),

			#( "PrimaryGIEngine", true, "Primary GI engine" ),
			#( "SecondaryGIEngine", true, "Secondary GI engine" ),
			#( "NumGIBounces", true, "Num GI bounces" ),
			#( "ConserveGIReflectionEnergy", true, "Conserve GI reflection energy" ),

			#( "PhotonGIEnable", true, "Photon GI enable" ),
			#( "PhotonCausticsEnable", true, "Photon caustics enable" ),
			#( "PhotonMode", true, "Photon mode" ),
			#( "PhotonFilename", false, "Photon filename" ),
			#( "PhotonMaxTraceDepthReflection", true, "Photon max trace depth reflection" ),
			#( "PhotonMaxTraceDepthRefraction", true, "Photon max trace depth refraction" ),
			#( "PhotonMaxTraceDepthCombined", true, "Photon max trace depth combined" ),
			#( "PhotonGISearchRadius", true, "Photon GI search radius" ),
			#( "PhotonGIMaxNumToGather", true, "Photon GI max num to gather" ),
			#( "PhotonCausticsSearchRadius", true, "Caustics Search Radius" ),
			#( "PhotonCausticsMaxNumToGather", true, "Caustics Max Number to Gather" ),
			#( "PhotonFastIrradiance", true, "Photon fast irradiance" ),

			#( "BruteForceGINumRays", true, "Brute force GI num rays" ),

			#( "IrradiancePointCloudMode", true, "Irradiance point cloud mode" ),
			#( "IrradiancePointCloudFilename", false, "Irradiance point cloud filename" ),
			#( "IrradiancePointCloudNumFramesToBlend", true, "Irradiance point cloud num frames to blend" ),
			#( "ShowIrradiancePointCloudCalculation", true, "Show irradiance point cloud calculation" ),
			#( "IrradiancePointCloudScreenRadius", true, "Irradiance point cloud screen radius" ),
			#( "IrradiancePointCloudNumSamplesPerPixel", true, "Irradiance point cloud num samples per pixel" ),
			#( "IrradiancePointCloudFilterSize", true, "Irradiance point cloud filter size" ),
			#( "IrradiancePointCloudRetraceThreshold", true, "Irradiance point cloud retrace threshold" ),
			#( "IrradiancePointCloudGPUWorkingMemory", true, "Irradiance point cloud GPU working memory" ),

			#( "IrradianceCacheMode", true, "Irradiance cache mode" ),
			#( "IrradianceCacheFilename", false, "Irradiance cache filename" ),
			#( "IrradianceCacheNumFramesToBlend", true, "Irradiance cache num frames to blend" ),
			#( "IrradianceCacheFlythroughMode", true, "Irradiance cache flythrough mode" ),
			#( "IrradianceCacheUseSeparatePointsForSecondaryRays", true, "Irradiance cache use separate points for secondary rays" ),
			#( "IrradianceCacheMinRate", true, "Irradiance cache min rate" ),
			#( "IrradianceCacheMaxRate", true, "Irradiance cache max rate" ),
			#( "IrradianceCacheColorThreshold", true, "Irradiance cache color threshold" ),
			#( "IrradianceCacheDistanceThreshold", true, "Irradiance cache distance threshold" ),
			#( "IrradianceCacheNormalThreshold", true, "Irradiance cache normal threshold" ),
			#( "IrradianceCacheMinDetail", true, "Irradiance cache min detail" ),
			#( "IrradianceCacheRadiusFactor", true, "Irradiance cache radius factor" ),
			#( "IrradianceCacheNumRays", true, "Irradiance cache num rays" ),
			#( "IrradianceCacheAdaptiveAmount", true, "Irradiance cache adaptive amount" ),
			#( "IrradianceCacheAdaptiveErrorThreshold", true, "Irradiance cache adaptive error threshold" ),
			#( "IrradianceCacheNumSmoothingPasses", true, "Irradiance cache num smoothing passes" ),
			#( "IrradianceCacheDebugDrawPoints", true, "Irradiance cache debug draw points" ),
			#( "IrradianceCacheGPUWorkingMemory", true, "Irradiance cache CPU working memory" ),
			#( "ShowIrradianceCacheCalculation", true, "Show irradiance cache calculation" ),

			#( "SubsurfaceScatteringMode", true, "Subsurface scattering mode" ),
			#( "SubsurfaceScatteringFilename", false, "Subsurface scattering filename" ),
			#( "SubsurfaceScatteringRate", true, "Subsurface scattering rate" ),
			#( "SubsurfaceScatteringInterpolationQuality", true, "Subsurface scattering interpolation quality" ),
			#( "SubsurfaceScatteringNumGIRays", true, "Subsurface scattering num GI rays" ),

			#( "TextureSamplingTechnique", true, "Texture sampling technique" ),
			#( "TextureSamplingTechnique_SecondaryRays", true, "Texture sampling technique - secondary rays" ), --deprecated v2.5
			#( "TextureSamplingTechnique_Shadows", true, "Texture sampling technique - shadows" ), --deprecated v2.5

			#( "MIPFilteringTraceDepthThresholdSecondary", true, "MIP filtering trace depth threshold secondary" ), --deprecated v2.5
			#( "MIPFilteringTraceDepthThresholdShadow", true, "MIP filtering trace depth threhold shadow" ), --deprecated v2.5

			#( "CopyPreConvertedTexturesToTextureCache", true, "Copy pre-converted textures to texture cache" ),
			#( "PhotometricUnitsToMeterScale", true, "Photometric units to meter scale" ),
			#( "PhotometricCandelaMetersSquaredFactor", true, "Photometric candela meters squared factor" ),

			#( "DisableShadowRayBiasing", true, "Disable shadow ray biasing" ),
			#( "DoCompleteRTHConstruction", true, "Do complete RTH construction" ),
			#( "RTHMaxNumLeafPrimitives", true, "RTH max num leaf primitives" ),

			#( "AbortOnLicenseFail", true, "Abort on license fail" ),
			#( "RenderInCameraSpace", true, "Render in camera space" ),

			#( "FreezeTessellation", true, "Freeze Tessellation" ), --NEW in v2.5.x
			#( "RenderTwoPassesForDenoising", true, "Render Two Passes For Denoising" ), --NEW in v2.5.x

			#( "DisableBumpSmoothingOnLightingSilhouettes", true, "Disable bump smooting on lighting silhouettes" ),

			#( "EnableFaultyMemoryCheck", true, "Enable faulty memory check" ), --deprecated v2.5
			#( "FrameIndependantPatternRandomization", true, "Frame independant pattern randomization" ), --deprecated v2.5

			#( "EnableSecondaryRayClampingOnFirstBounce", true, "Enable Secondary Ray Clamping On First Bounce" ), --NEW in v2.5.x
			#( "EnableLegacyCutOffsRules", true, "Enable Legacy CutOffs Rules" ), --NEW in v2.5.x

			#( "HairTessellationMode", true, "Hair tessellation mode" ),
			#( "SuppressTiledTextureWarnings", true, "Suppress tiled texture warnings" ),
			#( "SuppressTextureConversionMessage", true, "Suppress texture conversion message" ),
			#( "EnableAutomaticReprocessingOfPreConvertedTextures", true, "Enable automatic reprocessing of pre-converted textures" ),

			#( "EnableDetailedTextureProcessingReporting", true, "Enable Detailed Texture Processing Reporting" ), --NEW in v2.5.x

			#( "PercentageOfGPUMemoryToUse", true, "Percentage of GPU memory to use" ),
			#( "PercentageOfFreeMemoryUsedForTextureCache", true, "Percentage of free memory used for texture cache" ),
			#( "TextureCacheGPUWorkingMemory", true, "Texture cache GPU working memory" ),
			#( "RayReservedMemory", true, "Ray reserved memory" ),
			#( "TextureCacheCPUWorkingMemory", true, "Texture cache CPU working memory" ),
			#( "AutomaticMemoryManagement", true, "Automatic memory management" ),
			
			#( "EnableDebugCapture", true, "Enable debug capture" ),
			#( "EnableDebugCaptureShaderIntegrityCheck", true, "Enable debug capture shader integrity check" ),
			#( "EnableDetailedTextureSamplingStats", true, "Enable detailed texture sampling stats" ),

			#( "AOVMaxOverbright", true, "AOV max overbright" ),
			#( "AOVMaxOverbrightEnable", true, "AOV max overbright enable" ),
			#( "AOVDisableImportanceOptimizations", true, "AOV disable importance optimizations" ),
			#( "AOVFixRawHaloArtifacts", true, "AOV fix raw halo artifacts" ),

			#( "MaterialOverrideEnabled", true, "Material override enabled" ),
			#( "MaterialOverrideColor", true, "Material override color" )
		)

		setCurrentRendererSetting options_array

		--Special case to override Redshift "Render View"
		local overrideShowRendererFB = DeadlineUtil.GetJobInfoEntry "ShowRendererFrameBufferOverride"
		local showRendererFB = DeadlineUtil.GetJobInfoEntry "ShowRendererFrameBuffer"

		if overrideShowRendererFB != undefined and showRendererFB != undefined do
		(
			try
			(
				if( execute( overrideShowRendererFB ) ) then
				(
					if( execute( showRendererFB ) ) then
					(
						renderers.current.RenderViewEnable = true
						DeadlineUtil.LogMessage ("  +Redshift Render View enabled")
					)
					else
					(
						renderers.current.RenderViewEnable = false
						DeadlineUtil.LogMessage ("  +Redshift Render View disabled")
					)
				)
				else
					DeadlineUtil.LogMessage ("  +Not overriding Redshift Render View setting")
			)
			catch(DeadlineUtil.WarnMessage ("  --Failed to set Redshift Render View to " + showRendererFB ) )
		)
	)--end if redshift	
--END REDSHIFT SPECIFIC SETTINGS

--OCTANE SPECIFIC SETTINGS:
	if getRendererIdString() == "octane" do
	(
		DeadlineUtil.LogMessage ">Octane detected as current renderer."

		local stringGpuAffinity = systemTools.getEnvVariable( "DEADLINE_GPU_AFFINITY" )
		if stringGpuAffinity != undefined do
		(
			local gpuAffinity = execute( stringGpuAffinity )
			local octaneGpuAffinity = #()
			
			for i = 0 to 31 do
			(
				append octaneGpuAffinity false
			)

			for gpu in gpuAffinity do
			(
				octaneGpuAffinity[gpu+1] = true
			)

			try
			(
				setProperty renderers.current("gpu_active")(octaneGpuAffinity)
				DeadlineUtil.LogMessage (" +Set GPU affinity via mxs to " + stringGpuAffinity )
			)
			catch
			(
				DeadlineUtil.WarnMessage (" --Failed to set GPU affinity via mxs to " + stringGpuAffinity )
			)
		)

		--Each element of the array is a sub-array containing
		--1. the name of the property as string, 
		--2. whether to convert the value to maxscript value or keep as string, 
		--3. the description string used to output to the log file.

		local options_array = #(
			#( "RefreshTime", true, "Refresh time" ),
			#( "interactiveSizeX", true, "Interactive Size X" ),
			#( "interactiveSizeY", true, "Interactive Size Y" ),
			#( "interactiveAspect", true, "Interactive Aspect" ),
			#( "lockAspect", true, "Lock Aspect" ),
			#( "useWindowRes", true, "Use Window Resolution" ),
			#( "useProductRes", true, "Use Product Resolution" ),
			#( "autoUpdateProxy", true, "Auto Update Proxy" ),
			#( "useBackGround", true, "Use Background" ),
			#( "updateGeometry", true, "Update Geometry" ),
			#( "subSampling", true, "Sub-Sampling" ),
			#( "motionBlurEnabled", true, "Motion Blur Enabled" ),
			#( "motionBlurDuration", true, "Motion Blur Duration" ),
			#( "clayMode", true, "Clay Mode" ),
			#( "displacementEnabled", true, "Displacement Enabled" ),
			#( "enableGammaHack", true, "Enable Gamma Hack" ),
			#( "useObjectRenderSettings", true, "Use Object Render Settings" ),
			#( "outOfCoreEnabled", true, "Out of Core Enabled" ),
			#( "outOfCoreLimit", true, "Out of Core Limit" ),
			#( "DiscardMultiMeshMotionBlur", true, "Discard Multi Mesh Motion Blur" ),
			#( "OctaneEngineServerAddress", false, "Octane Engine Server Address" ),
			#( "autoupdateProxy", true, "Autoupdate movable proxy" ),
			#( "enableStatsViewport", true, "Render View Settings - Enable stats in viewport" ),
			#( "useOctaneEngine", true, "Use Octane Engine" ),
			#( "viewportMultiPass", true, "Vieport Multi Pass" ),
			#( "viewportQuickUpdate", true, "Viewport Quick Update" ),
			#( "rstat_SPP", true, "RStat - SPP" ),
			#( "rstat_SPS", true, "RStat - SPS" ),
			#( "rstat_render", true, "RStat - Render" ),
			#( "rstat_timeTotal", true, "RStat - Time Total" ),
			#( "rstat_timeLeft", true, "RStat - Time Left" ),
			#( "rstat_zoom", true, "RStat - Zoom" ),
			#( "rstat_textures", true, "RStat - Textures" ),
			#( "rstat_memory", true, "RStat - Memory" ),
			#( "rstat_poly", true, "RStat - Poly" ),
			#( "kernel_kernelType", true, "Kernel - Type" ),
			#( "kernel_maxSamples", true, "Kernel - Max Samples" ),
			#( "kernel_filterSize", true, "Kernel - Filter Size" ),
			#( "kernel_rayEpsilon", true, "Kernel - Ray Epsilon" ),
			#( "kernel_alphaChannel", true, "Kernel - Alpha Channel" ),
			#( "kernel_alphaShadow", true, "Kernel - Alpha Shadow" ),
			#( "kernel_pathTerminationPower", true, "Kernel - Path Termination Power" ),
			#( "kernel_keepEnvironment", true, "Kernel - Keep Environment" ),
			#( "kernel_maxDiffuseDepth", true, "Kernel - Max Diffuse Depth" ),
			#( "kernel_specularDepth", true, "Kernel - Specular Depth" ),
			#( "kernel_maxGlossyDepth", true, "Kernel - Max Glossy Depth" ),
			#( "kernel_aoDist", true, "Kernel - AO Distance" ),
			#( "kernel_giMode", true, "Kernel - GI Mode" ),
			#( "kernel_explorationStrength", true, "Kernel - Exploration Strength" ),
			#( "kernel_directLightImportance", true, "Kernel - Direct Light Importance" ),
			#( "kernel_maxRejects", true, "Kernel - Max Rejects" ),
			#( "kernel_channelType", true, "Kernel - Channel Type" ),
			#( "kernel_zDepthMax", true, "Kernel - Z Depth Max" ),
			#( "kernel_uvMax", true, "Kernel - UV Max" ),
			#( "kernel_causticBlur", true, "Kernel - Caustic Blur" ),
			#( "kernel_pmcParallelism", true, "Kernel - PMC Parallelism" ),
			#( "kernel_backFaceHighlight", true, "Kernel - Back Face Highlight" ),
			#( "kernel_bumpNormalMapping", true, "Kernel - Bump Normal Mapping" ),
			#( "kernel_distributedRayTracing", true, "Kernel - Distributed Ray Tracing" ),
			#( "kernel_giClamp", true, "Kernel - GI Clamp" ),
			#( "kernel_staticNoise", true, "Kernel - Static Noise" ),
			#( "kernel_coherentRatio", true, "Kernel - Coherent Ratio" ),
			#( "kernel_parallelSamples", true, "Kernel - Parallel Samples" ),
			#( "kernel_maxTileSamples", true, "Kernel - Max Tile Samples" ),
			#( "kernel_deepImageEnable", true, "Kernel - Deep Image Enable" ),
			#( "kernel_maxDepthSamples", true, "Kernel - Max Depth Samples" ),
			#( "kernel_depthTolerance", true, "Kernel - Depth Tolerance" ),
			#( "kernel_pmcWorkChunkSize", true, "Kernel - PMC Work Chunk Size" ),
			#( "kernel_aoAlphaShadows", true, "Kernel - AO Alpha Shadows" ),
			#( "kernel_adaptiveSampling", true, "Kernel - Adaptive Sampling" ),
			#( "kernel_adaptiveSamplingExposureValue", true, "Kernel - Adaptive Sampling Expected exposure" ),
			#( "kernel_adaptiveStrength", true, "Kernel - Adaptive Strength" ),
			#( "kernel_affectRoughness", true, "Kernel - Affect roughness" ),
			#( "kernel_aiLight_enabled", true, "Kernel - AI Light" ),
			#( "kernel_aiLight_strenght", true, "Kernel - AI Light strength" ),
			#( "kernel_aiLight_update_enabled", true, "Kernel - AI Light update" ),
			#( "kernel_aoAmbientTexture_color", true, "Kernel - AO Ambient Texture Color" ),
			#( "kernel_aoAmbientTexture_tex", true, "Kernel - AO Ambient Texture Tex" ),
			#( "kernel_aoAmbientTexture_value", true, "Kernel - AO Ambient Texture Value" ),
			#( "kernel_enableIrradiance", true, "Kernel - Irradiance" ),
			#( "kernel_maxSubdivision", true, "Kernel - Max subdivision" ),
			#( "kernel_max_scatter_depth", true, "Kernel - Max. depth samples" ),
			#( "kernel_minAdaptiveSamples", true, "Kernel - Min. adaptive samples" ),
			-- Property kernel_minimizeNetTraffic is not added to 3dsmax.options as Deadline doesn't support Octane DBR
			#( "kernel_minimizeNetTraffic", true, "Kernel - Minimize net traffic" ),
			#( "kernel_noiseThreshold", true, "Kernel - Noise threshold" ),
			#( "kernel_oldVolumeBehavior", true, "Kernel - Old volume behaviour" ),
			#( "globalInvLightIDMask", true, "Light - L. inv: - Inverse Light ID Mask" ),
			#( "globalLightIDMask", true, "Light - L.IDs: Light ID Mask" ),
			#( "cryptomatte_binCount", true, "Cryptomatte passes setup - Bins" ),
			#( "cryptomatte_enable_stdRgbOut", true, "Cryptomatte passes setup - Save also as standard RGB image" ),
			#( "cryptomatte_seedFactor", true, "Cryptomatte passes setup - Seed factor" ),
			#( "iesDistributionAsShape", true, "IES distribution visualization - Show as shape in shaded viewports" ),
			#( "iesDistributionShapeOpacity", true, "IES distribution visualization - Shape opacity" ),
			#( "iesShowDistribution", true, "IES distribution visualization - Generate visualisation" ),
			#( "iesShowMaxCandela", true, "IES distribution visualization - Show max. candela" ),
			#( "beautypasses_raw", true, "Beauty Passes - Raw" ),
			#( "infopasses_maxSamples", true, "Info Passes - Max Samples" ),
			#( "infopasses_distributedTracing", true, "Info Passes - Distributed Tracing" ),
			#( "infopasses_opacity_threshold", true, "Info Passes - Opacity Threshold" ),
			#( "infopasses_zDepthMax", true, "Info Passes - Z-depth max" ),
			#( "infoPass_aoDist", true, "Info pass - AO dist." ),
			#( "interactivePassID", true, "Interactive Pass ID" ),
			#( "interactivePasses", false, "Interactive Passes" ),
			#( "renderlayer_enabled", true, "Render Layer - Enabled" ),
			#( "renderlayer_id", true, "Render Layer - ID" ),
			#( "renderlayer_invert", true, "Render Layer - Invert" ),
			#( "renderlayer_visibilityOnly", true, "Render Layer - Visibility Only" ),
			#( "viewcam_distortion", true, "View Cam - Distortion" ),
			#( "viewcam_aperture", true, "View Cam - Aperture" ),
			#( "viewcam_fstop", true, "View Cam - FStop" ),
			#( "viewcam_useFstop", true, "View Cam - Use FStop" ),
			#( "viewcam_apertureEdge", true, "View Cam - Aperture Edge" ),
			#( "viewcam_focusType", true, "View Cam - Focus Type" ),
			#( "viewcam_focalDepth", true, "View Cam - Focal Depth" ),
			#( "viewcam_pixelAspect", true, "View Cam - Pixel Aspect" ),
			#( "viewcam_apertureAspect", true, "View Cam - Aperture Aspect" ),
			#( "viewcam_stereoMode", true, "View Cam - Stereo Mode" ),
			#( "viewcam_stereoOutput", true, "View Cam - Stereo Output" ),
			#( "viewcam_stereoDist", true, "View Cam - Stereo Distance" ),
			#( "viewcam_leftFilter", true, "View Cam - Left Filter" ),
			#( "viewcam_rightFilter", true, "View Cam - Right Filter" ),
			#( "viewcam_lensShift", true, "View Cam - Lens Shift" ),
			#( "viewcam_nearClipDepth", true, "View Cam - Near Clip Depth" ),
			#( "viewcam_orthoViewPosShift", true, "View Cam - Ortho View Position Shift" ),
			#( "viewcam_perspCorrection", true, "View Cam - Perspective Correction" ),
			#( "viewcam_exposure", true, "View Cam - Exposure" ),
			#( "viewcam_gamma", true, "View Cam - Gamma" ),
			#( "viewcam_highlightComp", true, "View Cam - Highlight Comp" ),
			#( "viewcam_response", true, "View Cam - Response" ),
			#( "viewcam_neutral_resopnse", true, "View Cam - Neutral Response" ),
			#( "viewcam_vignetting", true, "View Cam - Vignetting" ),
			#( "viewcam_saturation", true, "View Cam - Saturation" ),
			#( "viewcam_hotPixRemoval", true, "View Cam - Hot Pix Removal" ),
			#( "viewcam_preMultAlpha", true, "View Cam - Pre Mult Alpha" ),
			#( "viewcam_minDispSamples", true, "View Cam - Minimum Disp Samples" ),
			#( "viewcam_dithering", true, "View Cam - Dithering" ),
			#( "viewcam_disablePartialAlpha", true, "View Cam - Disable Partial Alpha" ),
			#( "viewcam_max_tonemap_interval", true, "View Cam - Max Tone Map Interval" ),
			#( "viewcam_whiteSaturation", true, "View Cam - White Saturation" ),
			#( "viewcam_whiteBalance", true, "View Cam - White Balance" ),
			#( "viewcam_useTonemapping", true, "View Cam - Use Tonemapping" ),
			#( "viewcam_postProcEnable", true, "View Cam - Post Proc Enable" ),
			#( "viewcam_bloomPower", true, "View Cam - Bloom Power" ),
			#( "viewcam_glarePower", true, "View Cam - Glare Power" ),
			#( "viewcam_glareRays", true, "View Cam - Glare Rays" ),
			#( "viewcam_glareAngle", true, "View Cam - Glare Angle" ),
			#( "viewcam_glareBlur", true, "View Cam - Glare Blur" ),
			#( "viewcam_glareSpectralIntensity", true, "View Cam - Glare Spectral Intensity" ),
			#( "viewcam_glareSpectralShift", true, "View Cam - Glare Spectral Shift" ),
			#( "viewcam_clut_strength", true, "View Cam - Clut Strength" ),
			#( "viewcam_custom_lut_file", false, "View Cam - Custom LUT" ),
			#( "viewcam_cutoff", true, "View Cam - Cutoff" ),
			#( "viewcam_denoiser_blend", true, "View Cam - Denoiser Blend" ),
			#( "viewcam_denoiser_enab", true, "View Cam - Enable Denoising" ),
			#( "viewcam_denoiser_maxInterval", true, "View Cam - Max. denoiser interval" ),
			#( "viewcam_denoiser_minSamples", true, "View Cam - Min. denoiser samples" ),
			#( "viewcam_denoiser_onComp", true, "View Cam - Denoise on completion" ),
			#( "viewcam_denoiser_volumes", true, "View Cam - Denoise volumes" ),
			#( "viewcam_farClipDepth", true, "View Cam - Far clip depth" ),
			#( "viewcam_neutral_response", true, "View Cam - Imager Neutral Response" ),
			#( "viewcam_response", true, "View Cam - Imager Response" ),
			#( "viewcam_stereoSwapEyes", true, "View Cam - Stereo Swap Eyes" ),
			#( "viewcam_upsmpl_enab", true, "View Cam - Enable AI up-sampling" ),
			#( "viewcam_upsmpl_maxInterval", true, "View Cam - Max. u.s. interval" ),
			#( "viewcam_upsmpl_minSamples", true, "View Cam - Min. u.s. samples" ),
			#( "viewcam_upsmpl_onComplet", true, "View Cam - Up-sampling on completion" ),
			#( "exporter_useAnimation", true, "Exporter - Use Animation" ),
			#( "exporter_startTime", true, "Exporter - Start Time" ),
			#( "exporter_endTime", true, "Exporter - End Time" ),
			#( "exporter_path", false, "Exporter - Path" ),
			#( "exporter_shortname", false, "Exporter - Export as" ),
			#( "OSS_Exporter_EnableABC", true, "OSS Exporter - Enable ABC Export" ),
			#( "OSS_Exporter_EnableMaterialAnim", true, "OSS Exporter - Enable material animation Export" ),
			#( "OSS_Exporter_EnableNoCameraScript", true, "OSS Exporter - Enable temporary camera for Export" ),
			#( "OSS_Exporter_PassesFromRenderElements", true, "OSS ExporterExport - passes from Render Elements" ),
			#( "OSS_Exporter_PassesFromVPMultiPasses", true, "OSS Exporter - Export passes from MultiPasses" ),
			#( "OSS_ForestPack_UseLayerFromFPObj", true, "OSS Forest Pack - Layer settings: from FP object" ),
			#( "OSS_TyFlow_CreateDefaultPtc", true, "OSS TyFlow - Create default particle object" ),
			#( "OSS_TyFlow_UseParticleNodeMesh", true, "OSS TyFlow - Use particle node's mesh" ),
			#( "Ornatrix_IgnoreChangeSelectedInVP", true, "Ornatrix - Ignore incorrect changes" ),
			#( "Ornatrix_MainUVChannel", true, "Ornatrix - Hair geometry UV channel" ),
			#( "Ornatrix_Use_OrnatrixWs", true, "Ornatrix - Use Ws generated by Ontarix" ),
			#( "PFlow_OverrideRenderMode", true, "PFlow - Override PFlow Render mode" ),
			#( "PFlow_QueryRenderMode", true, "PFlow - Query Render Mode" ),
			#( "PFlow_VelocityScale", true, "PFlow - Particle Velocity scale" ),
			#( "Phoenix_EnablePtcDisplacementMap", true, "Phoenix FD - enable displacement map" ),
			#( "Phoenix_ForceRenderModeForLiquidMB", true, "Phoenix FD - Use Render mode for liquid with MB" ),
			#( "Phoenix_PtcVelocityScale", true, "Phoenix FD - General Paricle Velocity scale" ),
			#( "ScenCollec_KeepEmptyGeometry", true, "Scene Collection - Keep empty geometry" ),
			#( "ScenCollec_UseDirectGeoHandler", true, "Common Scene Scene Collection Settings - Use Direct geometry handler" ),
			#( "ScenCollec_UseDirectParticle", true, "Common Scene Scene Collection Settings - Use Direct Particle" ),
			#( "StdPtc_GlobalScale", true, "Standard Particles - Global Particle scale" ),
			#( "gpuGeoLimit", true, "GPU - Geo Limit" ),
			#( "gpuHeadRoom", true, "GPU - Head Room" ),
			#( "gpuTexLimit", true, "GPU - Tex Limit" ),
			#( "gpu_active", false, "GPU - Active" ),
			#( "gpu_denoise", false, "GPU - Denoise" ),
			#( "gpu_getConfigFromScene", true, "GPU - Scene specific config" ),
			#( "gpu_peerIdx", false, "GPU - Peer Index" ),
			#( "gpu_priority", false, "GPU - Priority" ),
			#( "gpu_tonemap", false, "GPU - Tone" ),
			#( "matPreviewHeight", true, "Kernel - Mat. preview H" ),
			#( "matPreviewSamples", true, "Kernel - Mat. preview spp" ),
			#( "matPreviewWidth", true, "Kernel - Mat. preview W" ),
			#( "renderOutput_enable_MultiLayerEXR", true, "Render Output - Save all render passes as a single multi later EXR file" ),
			#( "renderOutput_enable_stdRgbOut", true, "Render Output - Save each pass as standard RGB image" ),
			#( "renderOutput_exrUseFloat16", true, "Render Output - EXR 16-bit float" ),
			#( "renderOutput_exrUseTonemap", true, "Render Output - EXR Tonemap" ),
			#( "shutterSubFrameEnd", true, "Motion Blur - Shutter subframe end" ),
			#( "shutterSubFrameStart", true, "Motion Blur - Shutter subframe start" ),
			#( "shutterTime", true, "Motion Blur - Shutter Time" )
		)

		setCurrentRendererSetting options_array

		local options_array = #(
			#("OSS_ForestPack_SupportType", "OSS Forest Pack - Support type", #("Standard", "Direct", "Discard"), #(0, 2, 3) ),
			#("renderOutput_exrCompression", "Render Output - EXR compression", #("ZIP (lossless)"), #(4) ),
			#("OSS_ForestPack_UserIDSetting", "OSS Forest Pack -  User ID settings", #("None", "From sorted order", "From FP unique IDs", "From FP mesh IDs", "All 0", "All 1"), #(0, 1, 2, 3, 4, 5) ),
			#("OSS_PFlow_SupportType", "OSS PFlow - Support type", #("Standard", "Legacy", "Direct", "Discard"), #(0, 1, 2, 3) ),
			#("OSS_RailClone_SupportType", "OSS RailClone - Support type", #("Standard", "Direct", "Discard"), #(0, 1, 2) ),
			#("OSS_TyFlow_PtcUserIDType", "OSS TyFlow - Particle IDs", #("None", "Birth Unique ID"), #(0, 1) ),
			#("Ornatrix_GradientInterpolationType", "Ornatrix - Hair Gradient Interpolation", #("Hair length", "Segment count"), #(0, 1) ),
			#("ScenCollec_PercistencyType", "Scene Collection - Octane Scene Persistency", #("Clear All nodes on Render.", "Keep Materials only", "Keep All node"), #(0, 1, 2) ),
			#("StdPtc_UpdateType", "Standard Particles - Particle Update type", #("Never", "Only if 'use render'", "Always"), #(0, 1, 2) ),
			#("exporter_pathType", "Exporter - Export Location", #("User defined folder", "Current max file folder", "3dsMax user 'Scene' folder", "3dsMax user 'Export' folder", "3dsMax user temporary folder"), #(0, 1, 2, 3, 4) ),
			#("globalLightIDAction", "Light - Light IDs Action", #("Enable", "Disable"), #(0, 1) ),
			#("kernel_adaptiveSamplingPixelGroup", "Kernel - Adaptive Sampling Group pixels", #("None", "2x2", "4x4"), #(0, 1, 2) ),
			#("kernel_aoAmbientTexture_input_type", "AO Ambient Texture Input Type", #("None", "Value", "Color"), #(0, 1, 2) ),
			#("kernel_rdBrdcFrameMode", "Kernel - Broadcast Frame mode", #("None", "Normal (pre and post frame render)"), #(0, 1) ),
			#("kernel_rdBrdcMode", "Kernel - Broadcast Render mode", #("None", "Normal (pre and post frame render)", "Only on pre render"), #(0, 1, 2) ),
			#("renderlayer_visibilityMode", "Render Layer - Visibility Mode", #("Normal", "Hide intactive layers", "Only side effects", "Hide from camera"), #(0, 1, 2, 3) ),
			#("shutterAlignment", "Motion Blur - Shutter alignment", #("Before", "Symmetric", "After"), #(0, 1, 2) ),
			#("viewcam_imgr_order", "View Cam - Imager Order", #("Response, Gamma, LUT", "Gamma, Response, LUT", "LUT, Response, Gamma", "LUT, Gamma, Response", "Response, LUT, Gamma", "Gamma, LUT, Response"), #(0, 1, 2, 3, 4, 5) ),
			#("viewcam_upsmpl_mode", "View Cam - Sampling mode", #("No up-sampling", "2x2 up-sampling", "4x4 up-sampling"), #(1, 2, 4) )
		)

		setCurrentRendererEnumName options_array
	)--end if octane
--END OCTANE SPECIFIC SETTINGS:

	quickFixScript = DeadlineUtil.GetJobInfoEntry "QuickFixScript"
	if quickFixScript != undefined and quickFixScript != "" do (
		execute quickFixScript
	)
	
	-- WORKAROUND: XREF objects didn't pick up the xref, just rendered the proxy instead.  This maxscript
	--             ensures that all the xref objects have useProxy set to the same as renderProxy to fix that.
	/*
	for obj in geometry do (
		if hasProperty obj "useProxy" and hasProperty obj "renderProxy" do (
			obj.useProxy = obj.renderProxy
		)
	)
	*/
	
	DeadlineUtil.LogMessage ">Performing XREF workaround..."
	try
	(
		-- This can throw an exception because it causes an evaluation at time 0, so catch the exception
		-- and try again if necessary.
		for obj in geometry do (
			if hasProperty obj "useProxy" and hasProperty obj "renderProxy" do (
				obj.useProxy = obj.renderProxy
			)
		)
	)
	catch
	(
		try
		(
			DeadlineUtil.LogMessage "--XFEF workaround failed, trying again..."
			for obj in geometry do (
				if hasProperty obj "useProxy" and hasProperty obj "renderProxy" do (
					obj.useProxy = obj.renderProxy
				)
			)
		)
		catch
		(
			DeadlineUtil.LogMessage "--XFEF workaround failed a second time, ignoring"
		)
	)
	DeadlineUtil.LogMessage ">Completed XREF workaround."
	
	--BRAZIL 2 RENDERER ONLY
	if getRendererIdString() == "brmax" then
	(
		local brazilRenderer = ::sfs.b2_lib.getActiveB2() --Force global scope to access SplutterFish Script libraries!
		local theProp = brazilRenderer["Render_Cache_Parameter_Block_Holder"].user_filename
		local theLocalPath = DeadlineUtil.SceneFilePath + "\\"+ filenameFromPath theProp
		if doesFileExist theLocalPath then
		(
			brazilRenderer["Render_Cache_Parameter_Block_Holder"].user_filename = theLocalPath 
			DeadlineUtil.LogMessage (" +Found A Version Of The File In The Repository, Repathing To ["+theLocalPath+"]")
		)--end if local file exists		
		
		local theProp = brazilRenderer["Photon_Server_Parameter_Block_Holder"].gi_user_filename
		local theLocalPath = DeadlineUtil.SceneFilePath + "\\"+ filenameFromPath theProp
		if doesFileExist theLocalPath then
		(
			brazilRenderer["Photon_Server_Parameter_Block_Holder"].gi_user_filename = theLocalPath 
			DeadlineUtil.LogMessage (" +Found A Version Of The File In The Repository, Repathing To ["+theLocalPath+"]")
		)--end if local file exists		
		
		local theProp = brazilRenderer["Photon_Server_Parameter_Block_Holder"].cst_user_filename
		local theLocalPath = DeadlineUtil.SceneFilePath + "\\"+ filenameFromPath theProp
		if doesFileExist theLocalPath then
		(
			brazilRenderer["Photon_Server_Parameter_Block_Holder"].cst_user_filename = theLocalPath 
			DeadlineUtil.LogMessage (" +Found A Version Of The File In The Repository, Repathing To ["+theLocalPath+"]")
		)--end if local file exists
	)
	-- else
	-- (
	-- 	local theProps = try(getPropNames renderers.current)catch(#())
	-- 	if theProps.count > 0 do
	-- 	(
	-- 		DeadlineUtil.LogMessage ">Scanning Renderer Paths..."
			
	-- 		--DEALING WITH RENDERER PROPERTIES LIKE VRAY LIGHTCACHE AND IRRADIANCE MAPS
	-- 		for p in theProps do
	-- 		(
	-- 			local theProp = try(getProperty renderers.current p)catch(undefined)
	-- 			if (p != undefined) AND (p != #system_vrayLog_file) AND (classof theProp == String) AND theProp != "" then
	-- 			(
	-- 				--DeadlineUtil.LogMessage (" >Processing String Property ["+p as string+"] with value of ["+theProp+"]")
	-- 				local theLocalPath = DeadlineUtil.SceneFilePath + "\\"+ filenameFromPath theProp
	-- 				--DeadlineUtil.LogMessage (" >Local Path Would Be ["+theLocalPath +"]")
	-- 				if doesFileExist theLocalPath then
	-- 				(
	-- 					setProperty renderers.current p theLocalPath 
	-- 					DeadlineUtil.LogMessage (" +Found A Version Of The File In The Repository, Repathing To ["+theLocalPath+"]")
	-- 				)--end if local file exists
	-- 				else
	-- 				(
	-- 					--DeadlineUtil.LogMessage (" --Local Path ["+theLocalPath +"] does not exist!")
	-- 				)
	-- 			)--end if property is a string
	-- 		)--end p loop
	-- 		DeadlineUtil.LogMessage ">Done Scanning Renderer Paths."
	-- 	)
	-- )
	
	-- NOTE: This isn't hooked up to the render output shown in deadline monitor yet!!!
	--ro = DeadlineUtil.GetJobInfoEntry "RenderOutput"
	--if ro != undefined do (
	--	DeadlineUtil.LogMessage ("Setting render output to " + ro)
	--	rendOutputFilename = ro
	--)

	true
)
catch
(
	if ((maxVersion())[1]/1000 as integer) >= 19 then --Max2017 or later only
	(
		if hasCurrentExceptionStackTrace() then
		(
			local stackTrace = getCurrentExceptionStackTrace()
			stackTrace =  filterString stackTrace "\n"
			for line in stackTrace do
			(
				DeadlineUtil.WarnMessage(line)
			)
		)
	)
	throw()
)
