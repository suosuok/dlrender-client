-- Kill ADSK Comm Center (only runs on Deadline)
-- Copyright © 2005-2017 by Thinkbox Software Inc.
-- All rights reserved.
(
	global Assassinate
	local du = DeadlineUtil  --this is the interface exposed by the Lightning Plug-in which provides communication between Deadline and 3ds Max
	if du != undefined do  --only run if the script is being run on Deadline
	(
		fn Assassinate type =
		(
			try(
			hiddendoscommand "taskkill /F /IM WSCommCntr.exe" donotwait:true
			for n = 1 to 10 do
			(
				local tempCommand = "taskkill /F /IM WSCommCntr" + (n as string) + ".exe"
				hiddendoscommand tempCommand donotwait:true
			)
			du.LogMessage ("Killed ADSK Communication Center process via Callback: #" + (type as string))
			)catch(du.WarnMessage ("Failed to Kill ADSK Communication Center process via Callback: #" + (type as string)))
		)

		callbacks.removeScripts id:#killCommCenter

		callbacks.addScript #filePreOpen "Assassinate(\"filePreOpen\")" id:#killCommCenter
		callbacks.addScript #filePostOpen "Assassinate(\"filePostOpen\")" id:#killCommCenter
		callbacks.addScript #preRender "Assassinate(\"preRender\")" id:#killCommCenter
		callbacks.addScript #PostSystemStartup "Assassinate(\"PostSystemStartup\")" id:#killCommCenter
		callbacks.addScript #PostSystemShutdown "Assassinate(\"PostSystemShutdown\")" id:#killCommCenter
	)--end if
)--end script