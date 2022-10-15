
DeadlineUtil.LogMessage "> >Render Color channel Post render"
global job_output = ""
job_output = DeadlineUtil.GetJobInfoEntry "RenderOutput"
DeadlineUtil.LogMessage ("> >job_output " + job_output as string )


global zall=#()
global oldmat=#()
fn ScaLinRen = --扫描线渲染器功能
(

	disableSceneRedraw()
	renderpresets.saveall 0 (GetDir #renderPresets + "\\temp.rps")
	EMlist = maxOps.GetCurRenderElementMgr()
	EMlist.removeallrenderelements()
	useEnvironmentMap = off
	backgroundColor = color 0 0 0
	coll=Target_Light
	if classof coll == Target_Light then
	for i in lights where classof i != targetobject do i.激活 = false
	col=VR阳光
	if classof col == VR阳光 then
	for i in lights where classof i != targetobject do i.on = false
	for i in $* do 
	(if (superclassof i)==geometryclass do append zall i) 
	for i=1 to zall.count do oldmat[i]=zall[i].material
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
		renderSceneDialog.update()
		renderers.current = RendererClass.classes[1]()
		rendOutputFilename = (getFilenamePath (job_output) + "\\" + "SCLine_material2" + getFilenameType(rendOutputFilename) )
		DeadlineUtil.LogMessage ("> >rendOutputFilename " + rendOutputFilename as string )
		renderSceneDialog.update()
		render outputfile:rendOutputFilename
		--↓↓↓渲染后↓↓↓--
			(
			col=VR阳光
			if classof col == VR阳光 then
			for i in lights where classof i != targetobject do i.on = on
			if classof coll == Target_Light then
			for i in lights where classof i != targetobject do i.激活 = on
			renderpresets.loadall 0 (GetDir #renderPresets + "\\temp.rps")
			for i=1 to zall.count do zall[i].material=oldmat[i]
			rendShowVFB =on
			renderSceneDialog.update()
			gc()
			enableSceneRedraw()
			)
	)
)
fn VrPanRen = --Vray全景渲染功能
(
 --↓↓↓渲染前↓↓↓--
 disableSceneRedraw()
 renderpresets.save 0 (GetDir #renderPresets + "\\XXZ_Temp.rps") #{3,4}
 XXZ_RO = renderers.current.output_saveRawFile --定义当前渲染输出开关
 renderers.current.output_saveRawFile = false --将RAW输出关闭
 XXZ_HLS = renderers.current.options_hiddenLights --定义当前隐藏灯光
 renderers.current.options_hiddenLights = false  --隐藏灯开关
 XXZ_SS = renderers.current.options_shadows --定义当前投影开关
 renderers.current.options_shadows = false --投影开关
 XXZ_DL = renderers.current.options_defaultLights --定义当前默认灯光开关
 renderers.current.options_defaultLights = 0 --默认灯光开关
 XXZ_RR = renderers.current.options_reflectionRefraction --定义当前默认灯光开关
 renderers.current.options_reflectionRefraction = false --反射折射开关
 XXZ_GE = renderers.current.options_glossyEffects --定义当前光泽度
 renderers.current.options_glossyEffects = false --光泽度效果开关
 XXZ_IT = renderers.current.imageSampler_type --定义当前采样器类型
 renderers.current.imageSampler_type = 1 -- 采样器类型
 XXZ_MSR = renderers.current.imageSampler_shadingRate --定义当前最小着色速率
 renderers.current.imageSampler_shadingRate = 1 --最小着色速率
 XXZ_FS = renderers.current.filter_on --定义当前过滤器开关
 renderers.current.filter_on = false --过滤器开关
 XXZ_AdpSW = renderers.current.twoLevel_adaptiveEnable --定义当前自适应采样开关
 renderers.current.twoLevel_adaptiveEnable = true --自适应采样开关
 XXZ_AMin = renderers.current.twoLevel_baseSubdivs --定义当前块采样器最小细分
 renderers.current.twoLevel_baseSubdivs = 7 --块采样器最小细分
 XXZ_AMax = renderers.current.twoLevel_fineSubdivs --定义当前块采样器最大细分
 renderers.current.twoLevel_fineSubdivs = 7 --块采样器最大细分
 XXZ_NTh = renderers.current.twoLevel_threshold --定义当前噪波阈值
 renderers.current.twoLevel_threshold = 0.002 --噪波阈值
 XXZ_BkW = renderers.current.twoLevel_bucket_width --定义当前渲染块大小
 renderers.current.twoLevel_bucket_width = 72 --渲染块大小
 XXZ_BL = renderers.current.twoLevel_bucket_lockSize --定义当前渲染块锁定
 renderers.current.twoLevel_bucket_lockSize = true --渲染块锁定
 XXZ_GiE = renderers.current.environment_gi_on --定义当前gi环境开关
 renderers.current.environment_gi_on = false --gi环境开关
 XXZ_RRE = renderers.current.environment_rr_on --定义当前反射折射环境开关
 renderers.current.environment_rr_on = false --反射折射环境开关
 XXZ_SME = renderers.current.environment_secondaryMatte_on --定义当前大气覆盖开关
 renderers.current.environment_secondaryMatte_on = false --大气覆盖开关
 XXZ_CM = renderers.current.colorMapping_type --定义当前颜色贴图模式
 renderers.current.colorMapping_type = 1 --颜色贴图模式
 XXZ_GI = renderers.current.gi_on --定义当前GI开关
 renderers.current.gi_on = false --GI开关
 XXZ_SRS = renderers.current.system_region_sequence --定义当前渲染格子方向
 renderers.current.system_region_sequence = 0 --渲染格子方向
 XXZ_VL = renderers.current.system_vrayLog_show --定义当前渲染log模式
 renderers.current.system_vrayLog_show = 0 --渲染log模式
 useEnvironmentMap = off --环境背景贴图
 backgroundColor = color 0 0 0 --环境背景颜色
 Rmlist = maxOps.GetCurRenderElementMgr() --获取当前渲染元素管理器
 Rmlist.removeallrenderelements() --删除所有渲染元素
 for i in $* do 
 (if (superclassof i)==geometryclass do append zall i) 
 for i=1 to zall.count do oldmat[i]=zall[i].material
	(
	 for i in $* do 
		( 
		 rcolor = random (color 0 0 0) (color 255 255 255)
		 zm = VRayMtl selfillumination:rcolor diffuse:(color 0 0 0)
		 if i.material==undefined do i.material=zm
		)
	 for x=1 to scenematerials.count do 
		(
		 rcolor = random (color 0 0 0) (color 255 255 255)
		 zm = VRayMtl selfillumination:rcolor diffuse:(color 0 0 0)
			for i in zall do 
			(
			 if i.material==scenematerials[x] do
				( 
				 if ((classof i.material)==multimaterial)
				 then  
					(
					 rcolorlan = random (color 0 0 0) (color 255 255 255)
					 zmlan = multimaterial  selfillumination:rcolorlan numsubs:(i.material.numsubs)\
					 diffuse:(color 0 0 0)
					 for j=1 to  i.material.numsubs  do
						(
						 rcolorlanx = random (color 0 0 0) (color 255 255 255)
						 zmlanx = VRayMtl selfillumination:rcolor diffuse:(color 0 0 0)
						 zmlan[j]=zmlanx
						)
					 i.material=zmlan
					)
				 else i.material=zm
				)
			)
		)
	)
	rendOutputFilename = (getFilenamePath (job_output) + "\\" + "VR_material3" + getFilenameType(rendOutputFilename) )
	DeadlineUtil.LogMessage ("> >rendOutputFilename " + rendOutputFilename as string )
	renderSceneDialog.update()
	render outputfile:rendOutputFilename
	(
	 for i=1 to zall.count do zall[i].material=oldmat[i]
	)
 --↓↓↓渲染后↓↓↓--
 renderers.current.output_saveRawFile = XXZ_RO --加载渲染输出开关
 renderers.current.options_hiddenLights = XXZ_HLS --加载隐藏灯光
 renderers.current.options_shadows = XXZ_SS --加载投影开关
 renderers.current.options_defaultLights = XXZ_DL --加载默认灯光开关
 renderers.current.options_reflectionRefraction = XXZ_RR --加载默认灯光开关
 renderers.current.options_glossyEffects = XXZ_GE --加载光泽度
 renderers.current.imageSampler_type = XXZ_IT --加载采样器类型
 renderers.current.imageSampler_shadingRate = XXZ_MSR --加载最小着色速率
 renderers.current.filter_on = XXZ_FS --加载过滤器开关
 renderers.current.twoLevel_adaptiveEnable = XXZ_AdpSW --加载自适应采样开关
 renderers.current.twoLevel_baseSubdivs = XXZ_AMin --加载块采样器最小细分
 renderers.current.twoLevel_fineSubdivs = XXZ_AMax --加载块采样器最大细分
 renderers.current.twoLevel_threshold = XXZ_NTh --加载噪波阈值
 renderers.current.twoLevel_bucket_width = XXZ_BkW --加载渲染块大小
 renderers.current.twoLevel_bucket_lockSize = XXZ_BL --加载渲染块锁定
 renderers.current.environment_gi_on = XXZ_GiE --加载gi环境开关
 renderers.current.environment_rr_on = XXZ_RRE --加载反射折射环境开关
 renderers.current.environment_secondaryMatte_on = XXZ_SME --加载大气覆盖开关
 renderers.current.colorMapping_type = XXZ_CM --加载颜色贴图模式
 renderers.current.gi_on = XXZ_GI --加载GI开关
 renderers.current.system_region_sequence = XXZ_SRS --定义当前渲染格子方向
 renderers.current.system_vrayLog_show = XXZ_VL --加载渲染log模式
 renderpresets.load 0 (GetDir #renderPresets + "\\XXZ_Temp.rps") #{3,4}
 renderSceneDialog.update()
 enableSceneRedraw()
)
fn CrPanRen = --Corona全景渲染功能
(
 --↓↓↓渲染前↓↓↓--
 disableSceneRedraw()
 renderpresets.save 0 (GetDir #renderPresets + "\\XXZ_Temp.rps") #{3,4}
 XXZ_CrGi = renderers.current.shading_primarySolver --定义当前GI引擎
 renderers.current.shading_primarySolver = 0 --GI引擎关闭
 XXZ_CrBg = renderers.current.bg_source --定义当前背景模式
 renderers.current.bg_source = 0 --设置背景为max背景
 XXZ_CrOvDir = renderers.current.bg_overrideDirect --定义当前背景直接光覆盖
 renderers.current.bg_overrideDirect = false --设置直接光覆盖为关闭
 XXZ_CRNoiLevLim = renderers.current.adaptivity_targetError --定义当前噪点阈值
 renderers.current.adaptivity_targetError = 2 --设置噪点阈值
 useEnvironmentMap = off --环境背景贴图
 backgroundColor = color 0 0 0 --环境背景颜色
 Rmlist = maxOps.GetCurRenderElementMgr() --获取当前渲染元素管理器
 Rmlist.removeallrenderelements() --删除所有渲染元素
 for i in $* do 
 (if (superclassof i)==geometryclass do append zall i) 
 for i=1 to zall.count do oldmat[i]=zall[i].material
	(
	 for i in $* do 
		( 
		 rcolor = random (color 0 0 0) (color 255 255 255)
		 zm = CoronaLegacyMtl colorSelfIllum:rcolor colorDiffuse:(color 0 0 0) levelSelfIllum:1
		 if i.material==undefined do i.material=zm
		)
	 for x=1 to scenematerials.count do 
		(
		 rcolor = random (color 0 0 0) (color 255 255 255)
		 zm = CoronaLegacyMtl colorSelfIllum:rcolor colorDiffuse:(color 0 0 0) levelSelfIllum:1
			for i in zall do 
			(
			 if i.material==scenematerials[x] do
				( 
				 if ((classof i.material)==multimaterial)
				 then  
					(
					 rcolorlan = random (color 0 0 0) (color 255 255 255)
					 zmlan = multimaterial  colorSelfIllum:rcolorlan numsubs:(i.material.numsubs)\
					 colorDiffuse:(color 0 0 0) levelSelfIllum:1
					 for j=1 to  i.material.numsubs  do
						(
						 rcolorlanx = random (color 0 0 0) (color 255 255 255)
						 zmlanx = CoronaLegacyMtl colorSelfIllum:rcolor colorDiffuse:(color 0 0 0) levelSelfIllum:1
						 zmlan[j]=zmlanx
						)
					 i.material=zmlan
					)
				 else i.material=zm
				)
			)
		)
	)
	rendOutputFilename = (getFilenamePath (job_output) + "\\" + "CR_material3" + getFilenameType(rendOutputFilename) )
	DeadlineUtil.LogMessage ("> >rendOutputFilename " + rendOutputFilename as string )
	renderSceneDialog.update()
	render outputfile:rendOutputFilename
	(
	 for i=1 to zall.count do zall[i].material=oldmat[i]
	)
 --↓↓↓渲染后↓↓↓--
 renderers.current.shading_primarySolver = XXZ_CrGi --定义当前GI引擎
 renderers.current.bg_source = XXZ_CrBg --定义当前背景模式
 renderers.current.bg_overrideDirect = XXZ_CrOvDir --定义当前背景直接光覆盖
 renderers.current.adaptivity_targetError = XXZ_CRNoiLevLim --定义当前噪点阈值
 renderpresets.load 0 (GetDir #renderPresets + "\\XXZ_Temp.rps") #{3,4}
 renderSceneDialog.update()
 enableSceneRedraw()
)
Global RenCamTyp = ()
global Shapirsol = ()
try(Global RenCamTyp = renderers.current.camera_type)catch()
try(Global ShaPirSol = renderers.current.shading_primarySolver)catch()
case of
(
 (RenCamTyp != undefined): --VR渲染器时
	(
     case of
	    (
		 (RenCamTyp!=0):
			(
			 try (VrPanRen()) catch ()
			)
		 (RenCamTyp==0):
			(
			 try (ScaLinRen()) catch ()
			)
		)
	)
 (ShaPirSol != undefined): --CR渲染器时
	(			 
	 try (CrPanRen()) catch ()
	)
)
