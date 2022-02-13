------------------------------------------------------------------------------------------------------------------------
-- PostLoad Path Mapping (only runs on Deadline)
------------------------------------------------------------------------------------------------------------------------
--This is called on AWS instances after the MAX scene has been loaded.
--It handles path remapping of assets that do not register with the 3ds Max Asset Tracker.
--See the related PreloadPathMapping.ms script for the Asset Tracker-compliant path remapping functions.
------------------------------------------------------------------------------------------------------------------------
(
	--Interface exposed by the Lightning plugin which provides communication between Deadline and 3ds Max.
	local du = DeadlineUtil
	
	
	fn PhoenixFDUpdate =
	(
		local theObjects = for o in objects where isKindOf o FireSmokeSim or isKindOf o LiquidSim or isKindOf o VRayVolumeGrid collect o
		if theObjects.count > 0 do
			du.LogMessage ( " >Processing " + theObjects.count as string + " Chaos Group Volumetric Object" + (if theObjects.count == 1 then "" else "s")  )
		for anObject in theObjects do
		(
			du.LogMessage ( "  >Chaos Group "+(classof anObject) as string +": " + anObject.name )
			local theSource = if matchPattern anObject.rendinput pattern:"$(same_as_output)" then
			(
				if matchPattern anObject.simoutput pattern:"$(scene_dir)" then 
					maxFilePath+maxFileName+"_Phoenix2_frames\\ND"+anObject.inode.handle as string+"_"+anObject.name+"_####.aur"
				else
					anObject.simoutput
			)
			else
				anObject.rendinput
			
			local theTarget = du.GetPathMappedFilename( theSource )
			anObject.rendinput = theTarget
		)--end fire loop
	)
	
	fn RealFlowUpdate =
	(	
		local theObjects = for o in objects where isKindOf o ParticleLoader collect o
		if theObjects.count > 0 do
			du.LogMessage ( " >Processing " + theObjects.count as string + " Real Flow Particle Loader Object" + (if theObjects.count == 1 then "" else "s")  )
		for anObject in theObjects do
		(
			du.LogMessage ( "  >Real Flow Particle Loader: " + anObject.name )
			local theSource = 
			anObject.binPath = du.GetPathMappedFilename( anObject.binPath )		
		)--end particle loader loop
		local theObjects = for o in objects where isKindOf o MeshLoader collect o
		if theObjects.count > 0 do
			du.LogMessage ( " >Processing " + theObjects.count as string + " Real Flow Mesh Loader Object" + (if theObjects.count == 1 then "" else "s")  )
		for anObject in theObjects do
		(
			du.LogMessage ( "  >Real Flow Mesh Loader: " + anObject.name )
			anObject.path = du.GetPathMappedFilename( anObject.path )
		)--end mesh loader loop			
	)	

	
	du.LogMessage ( "===========================================================================" )
	du.LogMessage ( ">Checking Non-Tracked Asset Paths..." )
	du.LogMessage ( "===========================================================================" )
	PhoenixFDUpdate()
	RealFlowUpdate()
	du.LogMessage ( ">Finished Checking Non-Tracked Asset Paths." )
	du.LogMessage ( "===========================================================================" )

	true
)
