try
(	
	cr = renderers.current
	cr.dr_enable=true
	cr.dr_searchDuringRender=false
	cr.dr_slaveAddresses=#()
	cr.dr_slaveResolvedNames=#()
	
	local coronaConfigFile = systemTools.getEnvVariable( "DEADLINE_CORONA_CONFIG_FILE" )
	
	if coronaConfigFile != undefined then
	(
		cr = CoronaRenderer.CoronaFp
		cr.loadDrIpFile( coronaConfigFile ) 
		true
	)
	else
	( 
		false
	)
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