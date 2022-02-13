-- Pre Load Path Mapping (only runs on Deadline)
-- Copyright © 2005-2020 by Thinkbox Software Inc.
-- All rights reserved.
(
	--Interface exposed by the Lightning plugin which provides communication between Deadline and 3ds Max.
	local du = DeadlineUtil
	local MaxFileAssets = #() --collect any .MAX file XRefs in this array
	
	fn getMAXSceneFile =
	(
		local theMAXScene = ""
		local count = 0
		local theAux = ""
		
		do
		(
			theAux = du.GetAuxFilename count
			
			if theAux != undefined do
			(
				if matchPattern theAux pattern:"*.max" do
				(
					theMAXScene = theAux
					theAux = undefined
				)
			)
			
			count += 1
		)
		while theAux != undefined
		
		if theMAXScene == "" do 
		(
			--If the aux. file is not a .max file, look for the SceneFile in the Job Info.
			theMAXScene = du.GetJobInfoEntry "SceneFile"
			du.LogMessage ( ">No .max file found as an auxiliary data file, looking for referenced [SceneFile] in Job Info: [" + theMAXScene + "]." )
		)
		
		theMAXScene
	)

	-- Attempts to pull the Temp Directory that the worker created for this job from the process's environment variable.
	-- If the env variable has not been set this defaults back on the jobs Data folder
	fn getJobTempFolder = 
	(
		local tempFolder = systemTools.getEnvVariable( "DEADLINE_JOB_TEMP_FOLDER" )
		if tempFolder == undefined do
		(
			du.LogMessage ( "Failed to get Deadline Job's temp folder from System Environment.  Falling back to use Deadline Job's Data Folder." )
			tempFolder = du.JobsDataFolder
		)		
		tempFolder
	)

	fn createTempMAXSceneFile theMAXScene forceCopy:false =
	(
		local tempFilePath = ""
		local sysPath = dotNetClass "System.IO.Path"
		local sysDir = dotNetClass "System.IO.Directory"

		if du.GetJobInfoEntry "SceneFile" != undefined or forceCopy == true then
		(
			--Create a copy of the scene file if one has not already been made (by submitting the scene file).
			tempFilePath = sysPath.Combine (getJobTempFolder()) ( "tempMaxScene" + ( du.CurrentTask as string ) )

			if not sysDir.Exists tempFilePath then
			(
				makeDir tempFilePath
			)
		)

		if tempFilePath != "" then
		(
			local fileName = filenameFromPath theMAXScene
			tempFilePath = sysPath.Combine tempFilePath fileName
			du.LogMessage ( "A temporary copy of the .MAX file has been created for path mapping." )
			copyFile theMAXScene tempFilePath
		)
		else
		(
			tempFilePath = theMAXScene
		)

		tempFilePath
	)
	
	fn getMAXFileAssets theMAXScene isMain:true = 
	(
		local changesMade = False
		local tempFilePath = ""

		if theMAXScene != undefined and doesFileExist theMAXScene then
		(
			if isMain == true then
				tempFilePath = createTempMAXSceneFile theMAXScene
			else
				tempFilePath = theMAXScene --if an XRef, we are already working with a copy of the file
			du.LogMessage ( ">Remapping all asset paths of file ["+tempFilePath+"]" )
			local fileAssets = getMAXFileAssetMetadata theMAXScene
			if fileAssets != undefined then --the above function might return undefined instead of an array if the MAX scene file is corrupted!
			(
				for i = 1 to fileAssets.count do
				(
					local theSource = fileAssets[i].filename
					local theTarget = du.GetPathMappedFilename( theSource )

					if theSource != theTarget then
					(
						changesMade = True
						--du.LogMessage ( "  +Source Path: " + theSource )
						--du.LogMessage ( "  +Mapped Path: " + theTarget )
						--du.LogMessage ( "---------------------------------------------------------------------------" )
					)

					fileAssets[i].filename = theTarget
					if matchPattern (getFileNameType theTarget) pattern:".max" do --if the asset is a MAX scene file, collect it for remapping
					(
						local tempAssetFilePath = createTempMAXSceneFile theTarget forceCopy:true --create a copy of the XRef file for remapping
						fileAssets[i].filename = tempAssetFilePath --update the master scene's asset to the copy filename
						append MaxFileAssets tempAssetFilePath --collect the copy for asset remapping
					)
				)

				if changesMade then
				(
					setMAXFileAssetMetadata tempFilePath fileAssets
				)
				else
				(
					du.LogMessage ( ">No asset paths needed to be remapped." )
					tempFilePath = ""
				)
			)
			else
			(
				du.WarnMessage ( "--FAILED to access the Asset Metadata of "+ theMAXScene )
				tempFilePath = ""
			)
		)
		else
		(
			du.WarnMessage ( "--No .max scene file submitted with this job, so could not modify the asset paths." )
			du.WarnMessage ( "--Please make sure the .max scene file is submitted with the job as an auxiliary file." )
		)

		return tempFilePath
	)
	
	fn defineSessionPaths =
	(
		--This function sets map and xref session paths for all assets listed in the job's AWSAssetFile* properties (if any)
		--This is meant to help resolve nested XRefs and asset paths that are "Found" by 3ds Max when a scene is opened, 
		--but the paths stored in the objects' properties are old.
		--For example, 
			--A scene has an XRef to a .MAX file containing a textute pointing at "Z:/temp/sometexture.png"
			--The texture is actually on "M:/textures/sometexture.png" .
			--The path "M:/textures/" is defined in the map search paths of a local 3ds Max running on the submitting workstation.
			--3ds Max will resolve the texture from the M: path and mark it as "Found" in the Asset Tracker, but the internal path will still stay "Z:/temp/sometexture.png"
			--If this scene is submitted to AWS with Pre-Cache enabled, the AWSAssetFile will be written out to the Job Properties as the resolved "M:/textures/sometexture.png"
			--Before the scene is loaded, that texture will be copied over to the E: drive (EBS volume) attached to the EC2 instance.
			--Without the function, the metadata of the scene file(s) would be updated based on the Z:/temp/ pathing, and the texture would NOT be found and loaded.
			--By defining the Session Paths below, we allow 3ds Max to resolve the map path on the EC2 instance the same way the local machine that submitted the job did.
			--The same applies to resolving XRef scenes and object whose paths have been "Found" before submission, but were not updated in the submitted files.
		
		local sessionPathList = #()
		local theCnt = try(du.GetSubmitInfoEntryElementCount "AWSPortalAssets")catch(0)		--get the number of asset entries in the Job
		du.LogMessage (theCnt as string + " Assets Found in the Job's Metadata.")			--print the number of assets to the log
		for i = 0 to theCnt-1 do															--loop through the assets
		(
			local theValue = du.GetSubmitInfoEntryElement i "AWSPortalAssets"				--get the i-th asset
			appendIfUnique sessionPathList (getFileNamePath theValue)						--and collect the path only if it was not collected already
		)
		if sessionPathList.count > 0 do 													--if any paths were collected, print a title log message before setting them
			du.LogMessage (">Session Paths for Maps and XRefs: " )
		for f in sessionPathList do															--for each asset path
		(
			local theRemappedValue = du.GetPathMappedFilename f								--remap using the Mapped Paths data in the Repository
			sessionPaths.add #map theRemappedValue											--set the remapped path as a search path for missing textures
			sessionPaths.add #xref theRemappedValue											--and for resolving missing XRefs
			du.LogMessage ("  +" +  theRemappedValue )										--print the remapped value
		)
	)
	
	du.LogMessage ( "===========================================================================" )
	du.LogMessage ( ">Defining Sessions Paths..." )
	du.LogMessage ( "===========================================================================" )
	defineSessionPaths() 
	
	du.LogMessage ( "===========================================================================" )
	du.LogMessage ( ">Modifying asset paths of Main Scene File..." )
	du.LogMessage ( "===========================================================================" )
	local newMaxFilePath = getMAXFileAssets ( getMAXSceneFile() )
	du.LogMessage ( ">Finished modifying asset paths of Main Scene File." )
	while MaxFileAssets.count > 0 do --if any XRef MAX scenes were collected from assets, take the first one...
	(
		du.LogMessage ( ">Checking asset paths of XRef Scene File ["+MaxFileAssets[1]+"]" )
		getMAXFileAssets ( MaxFileAssets[1] ) --remap its assets, while collecting its possible .MAX file XRefs into the same array
		deleteItem MaxFileAssets 1 --and delete the first entry from the array
	)--this will loop until no MAX files are left to remap
	du.LogMessage ( "===========================================================================" )

	newMaxFilePath
)
