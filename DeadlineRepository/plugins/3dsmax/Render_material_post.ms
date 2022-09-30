
DeadlineUtil.LogMessage "> >Render Color channel Post render"
global job_output = ""
job_output = DeadlineUtil.GetJobInfoEntry "RenderOutput"
DeadlineUtil.LogMessage ("> >job_output " + job_output as string )


fn ocrender_1 =(
	try(
		(
			disableSceneRedraw()
			-- renderpresets.save 0 (GetDir #renderPresets + "\\chanel1.rps") #{32}
			coll=Target_Light
			if classof coll == Target_Light then
				
			for i in lights where classof i != targetobject do i.激活 = false
				col=VR阳光
			if classof col == VR阳光 then
				for i in lights where classof i != targetobject do i.on = false
			global zall=#()
			global oldmat=#()
			for i in $* do 
			(if (superclassof i)==geometryclass do append zall i) 
			for i=1 to zall.count do oldmat[i]=zall[i].material)
			--------------------------------------------------------------------
			(
			for i in $* do 
				( 
				rcolor = random (color 0 0 0) (color 255 255 255)
				zm = standardmaterial selfIllumAmount:100\
				ambient:rcolor diffuse:rcolor
				if i.material==undefined do i.material=zm
				)
				for x=1 to scenematerials.count do 
				(
				rcolor = random (color 0 0 0) (color 255 255 255)
				zm = standardmaterial selfIllumAmount:100\
				mbient:rcolor diffuse:rcolor
				for i in zall do 
				(if i.material==scenematerials[x] do i.material=zm)
				)
			)
			rendShowVFB =on
			OutputFilename = ( getFilenamePath (job_output) + "\\"  + "Color_material" + getFilenameType(rendOutputFilename) )
			DeadlineUtil.LogMessage ("> >rendOutputFilename " + OutputFilename as string )
			renderSceneDialog.update()
			renderers.current = RendererClass.classes[1]()
			render outputfile:OutputFilename
			
			(
				col=VR阳光
				if classof col == VR阳光 then
					for i in lights where classof i != targetobject do i.on = on
					if classof coll == Target_Light then
						for i in lights where classof i != targetobject do i.激活 = on
					-- renderpresets.load 0 (GetDir #renderPresets + "\\chanel1.rps") #{32}
					for i=1 to zall.count do zall[i].material=oldmat[i]
					rendShowVFB =off
					renderSceneDialog.update()
					gc()
					enableSceneRedraw()
		)
	)catch()
)
--------------------------
fn ocrender_2 =(
	try
	(
	(
	disableSceneRedraw()
	-- renderpresets.save 0 (GetDir #renderPresets + "\\chanel2.rps") #{32}
	coll=Target_Light
	if classof coll == Target_Light then
	for i in lights where classof i != targetobject do i.激活 = false
	col=VR阳光
	if classof col == VR阳光 then
	for i in lights where classof i != targetobject do i.on = false
	global zall=#()
	global oldmat=#()
	for i in $* do 
	(if (superclassof i)==geometryclass do append zall i) 
	for i=1 to zall.count do oldmat[i]=zall[i].material)
	--------------------------------------------------------------------
	(
		for i in $* do 
			( 
			rcolor = random (color 0 0 0) (color 255 255 255)
			zm = standardmaterial selfIllumAmount:100\
			ambient:rcolor diffuse:rcolor
			if i.material==undefined do i.material=zm
			)
	for x=1 to scenematerials.count do 
		(
			rcolor = random (color 0 0 0) (color 255 255 255)
				zm = standardmaterial selfIllumAmount:100\
				ambient:rcolor diffuse:rcolor
				for i in zall do 
				(
				if i.material==scenematerials[x] do
					( 
					if ((classof i.material)==multimaterial)
					then  
						(
							rcolorlan = random (color 0 0 0) (color 255 255 255)
								zmlan = multimaterial  selfIllumAmount:100 numsubs:(i.material.numsubs)\
								ambient:rcolorlan diffuse:rcolorlan
							for j=1 to  i.material.numsubs  do
								(
								rcolorlanx = random (color 0 0 0) (color 255 255 255)
								zmlanx = standardmaterial selfIllumAmount:100\ 
								ambient:rcolorlanx diffuse:rcolorlanx	
								zmlan[j]=zmlanx
								)
					i.material=zmlan
					)
					else i.material=zm
					)
				)
			)
		rendShowVFB =on
		OutputFilename = (getFilenamePath (job_output) + "\\" + "Color2_material" + getFilenameType(rendOutputFilename) )
		DeadlineUtil.LogMessage ("> >rendOutputFilename " + OutputFilename as string )
		renderSceneDialog.update()
		renderers.current = RendererClass.classes[1]()
		render outputfile:OutputFilename
		(
		col=VR阳光
		if classof col == VR阳光 then
		for i in lights where classof i != targetobject do i.on = on
		if classof coll == Target_Light then
		for i in lights where classof i != targetobject do i.激活 = on
		-- renderpresets.load 0 (GetDir #renderPresets + "\\chanel2.rps") #{32}
		for i=1 to zall.count do zall[i].material=oldmat[i]
		rendShowVFB =off
		renderSceneDialog.update()
		gc()
		enableSceneRedraw()
		)
	)
	)catch()
)   



try (
	local rem = MaxOps.GetCurRenderElementMgr()
	rem.RemoveAllRenderElements()
) catch()
ocrender_1()
ocrender_2()
