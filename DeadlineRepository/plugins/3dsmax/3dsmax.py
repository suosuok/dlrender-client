# -- coding: utf-8 --

from __future__ import print_function
import clr
import re
import traceback
import os
import hashlib
import subprocess
import stat
import shutil
import io

from filecmp import dircmp

from System import *
from System.Collections.Specialized import *
from System.Diagnostics import *
from System.Diagnostics import FileVersionInfo
from System.IO import *
from System.Text.RegularExpressions import *

from FranticX.Net import *
from FranticX.Processes import *
from FranticX import Environment2

from Deadline.Plugins import *
from Deadline.Scripting import *

#######################################################################

pkg_file = os.path.join(RepositoryUtils.GetCustomScriptsDirectory(), "render_shot", "RenderShot.py")
print("pkg_file = {}".format(pkg_file))
## exec(open(pkg_file, encoding = 'utf-8').read())
execfile(pkg_file)


#######################################################################


######################################################################
## This is the function that Deadline calls to get an instance of the
## main DeadlinePlugin class.
######################################################################
def GetDeadlinePlugin():
    return MaxPlugin()


def CleanupDeadlinePlugin(deadlinePlugin):
    deadlinePlugin.Cleanup()


######################################################################
## This is the main DeadlinePlugin class for the Max plugin.
######################################################################
class MaxPlugin(DeadlinePlugin):
    MyMaxController = None
    VRaySpawner = None

    def __init__(self):
        self.InitializeProcessCallback += self.InitializeProcess
        self.StartJobCallback += self.StartJob
        self.RenderTasksCallback += self.RenderTasks
        self.EndJobCallback += self.EndJob
        self.MonitoredManagedProcessExitCallback += self.MonitoredManagedProcessExit

        self.VrayDBRJob = False
        self.VrayRtDBRJob = False
        self.MentalRayDBRJob = False
        self.CoronaDBRJob = False
        self.IsDBRJob = False
        self.Prefix = ""

    def Cleanup(self):
        del self.InitializeProcessCallback
        del self.StartJobCallback
        del self.RenderTasksCallback
        del self.EndJobCallback
        del self.MonitoredManagedProcessExitCallback

        if self.MyMaxController:
            self.MyMaxController.Cleanup()
            del self.MyMaxController

        if self.VRaySpawner:
            self.VRaySpawner.Cleanup()
            del self.VRaySpawner

    def MaxStartupAutoUpdate(self, localPath, repoPath):
        updateNeeded = True
        if os.path.isdir(localPath):
            dcmp = dircmp(localPath, repoPath)
            diffFiles = len(dcmp.diff_files) + len(dcmp.left_only) + len(dcmp.right_only)
            if diffFiles == 0:
                updateNeeded = False
        elif not os.path.isdir(localPath):
            self.LogInfo("Creating local Max Startup directory...")
            os.makedirs(localPath)

        if (updateNeeded):
            self.LogInfo("Max Startup upgrade detected")
            localFiles = os.listdir(localPath)
            if len(localFiles) > 0:
                self.LogInfo("Removing local files...")
                for fileName in localFiles:
                    self.LogInfo("Removing '%s'..." % fileName)
                    os.remove(os.path.join(localPath, fileName))

            self.LogInfo("Copying updated files...")
            for fileName in os.listdir(repoPath):
                self.LogInfo("Copying '%s'..." % fileName)
                localFilePath = os.path.join(localPath, fileName)
                shutil.copy2(os.path.join(repoPath, fileName), localFilePath)
                try:
                    os.chmod(localFilePath, stat.S_IWRITE)
                except:
                    pass
            self.LogInfo("Max startup files update completed!")

    ## Called by Deadline to initialize the process.
    def InitializeProcess(self):
        # Set the plugin specific settings.
        self.LogInfo("3dsmax Plugin Initializing...")
        self.SingleFramesOnly = False
        self.PluginType = PluginType.Advanced
        self.HideDosWindow = True

        version = self.GetIntegerPluginInfoEntry("Version")

        self.LogInfo("Worker Running as Service: %s" % self.IsRunningAsService())

        maxStartupRepoPath = RepositoryUtils.GetRepositoryPath((os.path.join("maxStartup", str(version))), False)
        if not os.path.isdir(maxStartupRepoPath):
            self.FailRender("ERROR: Max startup files were not found in the Deadline Repository!")

        cachedir = os.path.join(ClientUtils.GetCurrentUserHomeDirectory(), "cache")
        if cachedir in maxStartupRepoPath:
            self.MaxStartupDir = maxStartupRepoPath

        else:
            maxStartupLocalPath = os.path.join(self.GetJobsDataDirectory(), "maxStartup", str(self.GetThreadNumber()))
            self.MaxStartupAutoUpdate(maxStartupLocalPath, maxStartupRepoPath)
            self.MaxStartupDir = maxStartupLocalPath

    ## Called by Deadline when the job is first loaded.
    def StartJob(self):
        self.LogInfo("Start Job called - starting up 3dsmax plugin")

        self.MyMaxController = MaxController(self)

        # If this is a DBR job, we can't load max until we know which task we are (which isn't until the RenderTasks phase).
        self.VrayDBRJob = self.GetBooleanPluginInfoEntryWithDefault("VRayDBRJob", False)
        self.VrayRtDBRJob = self.GetBooleanPluginInfoEntryWithDefault("VRayRtDBRJob", False)
        self.MentalRayDBRJob = self.GetBooleanPluginInfoEntryWithDefault("MentalRayDBRJob", False)
        self.CoronaDBRJob = self.GetBooleanPluginInfoEntryWithDefault("CoronaDBRJob", False)

        self.IsDBRJob = self.VrayDBRJob or self.VrayRtDBRJob or self.MentalRayDBRJob or self.CoronaDBRJob

        if self.IsDBRJob:
            if self.VrayDBRJob:
                self.Prefix = "V-Ray DBR: "
            elif self.VrayRtDBRJob:
                self.Prefix = "V-Ray RT DBR: "
            elif self.MentalRayDBRJob:
                self.Prefix = "Mental Ray Satellite: "
            elif self.CoronaDBRJob:
                self.Prefix = "Corona DR: "

            self.LogInfo(self.Prefix + "Delaying load of 3ds Max until RenderTasks phase")
        else:
            # Initialize the Max controller.
            self.MyMaxController.Initialize()
            self.MyMaxController.slaveDirectory = self.GetSlaveDirectory()

            # Start 3dsmax.
            self.MyMaxController.StartMax()

            # Start the 3dsmax job (loads the scene file, etc).
            self.MyMaxController.StartMaxJob()

    ## Called by Deadline when the job is unloaded.
    def EndJob(self):
        self.LogInfo("End Job called - shutting down 3dsmax plugin")

        # Nothing to do during EndJob phase for DBR jobs.
        if self.IsDBRJob:
            return

        if self.MyMaxController:
            # End the 3dsmax job (unloads the scene file, etc).
            self.MyMaxController.EndMaxJob()

            # Shutdown 3dsmax.
            self.MyMaxController.ShutdownMax()

    ## Called by Deadline when a task is to be rendered.
    def RenderTasks(self):
        self.LogInfo("Render Tasks called")

        # For V-RayDBRJob jobs, task 0 can't render until all the other tasks have been picked up unless Dynamic Start is enabled.
        if self.IsDBRJob:

            if self.GetCurrentTaskId() == "0":

                currentJob = self.GetJob()

                slaveName = self.GetCurrentTask().TaskSlaveName
                self.LogInfo("Releasing DBR job as MASTER has now been elected: %s" % slaveName)

                # Initialize the Max controller.
                self.MyMaxController.Initialize()

                self.LogInfo(self.Prefix + "Configuring Distributed Render Job...")

                # Load settings.
                if self.VrayDBRJob:
                    self.MyMaxController.GetVrayDBRSettings()
                    self.LogInfo(self.Prefix + "Dynamic Start: %s" % self.MyMaxController.VrayDBRDynamicStart)
                    self.LogInfo(self.Prefix + "Plugin Config Settings to be applied to local file: vray_dr.cfg")
                    self.LogInfo(self.Prefix + "Port Range: %s" % self.MyMaxController.VrayDBRPortRange)
                    self.LogInfo(self.Prefix + "Use Local Machine: %s" % self.MyMaxController.VrayDBRUseLocalMachine)
                    self.LogInfo(
                        self.Prefix + "Transfer Missing Assets: %s" % self.MyMaxController.VrayDBRTransferMissingAssets)
                    self.LogInfo(self.Prefix + "Use Cached Assets: %s" % self.MyMaxController.VrayDBRUseCachedAssets)
                    self.LogInfo(self.Prefix + "Cache Limit Type: %s" % self.MyMaxController.VrayDBRCacheLimitType)
                    self.LogInfo(self.Prefix + "Cache Limit: %s" % self.MyMaxController.VrayDBRCacheLimit)
                elif self.VrayRtDBRJob:
                    self.MyMaxController.GetVrayRtDBRSettings()
                    self.LogInfo(self.Prefix + "Dynamic Start: %s" % self.MyMaxController.VrayRtDBRDynamicStart)
                    self.LogInfo(self.Prefix + "Plugin Config Settings to be applied to local file: vrayrt_dr.cfg")
                    self.LogInfo(self.Prefix + "Port Range: %s" % self.MyMaxController.VrayRtDBRPortRange)
                    self.LogInfo(
                        self.Prefix + "Auto-Start Local Worker: %s" % self.MyMaxController.VrayRtDBRAutoStartLocalSlave)
                elif self.MentalRayDBRJob:
                    self.MyMaxController.GetMentalRaySettings()
                    self.LogInfo(
                        self.Prefix + "Satellite Port Number: %s" % self.MyMaxController.MentalRaySatPortNumber)
                elif self.CoronaDBRJob:
                    self.MyMaxController.GetCoronaSettings()
                    self.LogInfo(self.Prefix + "Server No GUI: %s" % self.MyMaxController.CoronaDRServerNoGui)

                # If job uses V-Ray Dynamic Start and V-Ray Use Local Host is Enabled than start immediately.
                if (
                        self.VrayDBRJob and self.MyMaxController.VrayDBRDynamicStart and self.MyMaxController.VrayDBRUseLocalMachine) or \
                        (
                                self.VrayRtDBRJob and self.MyMaxController.VrayRtDBRDynamicStart and self.MyMaxController.VrayRtDBRAutoStartLocalSlave):
                    # Start job immediately before all tasks have been dequeued.
                    self.LogInfo(self.Prefix + "Starting distributed render immediately")

                # If job uses V-Ray Dynamic Start and V-Ray Use Local Host is Disabled than wait for at least one job task to start.
                elif (
                        self.VrayDBRJob and self.MyMaxController.VrayDBRDynamicStart and not self.MyMaxController.VrayDBRUseLocalMachine) or \
                        (
                                self.VrayRtDBRJob and self.MyMaxController.VrayRtDBRDynamicStart and not self.MyMaxController.VrayRtDBRAutoStartLocalSlave):
                    # Wait until at least one job task start
                    self.LogInfo(
                        self.Prefix + "Waiting for at least one job task other than master node to start rendering before starting distributed render")
                    while True:
                        if self.IsCanceled():
                            self.FailRender("Task canceled")

                        updatedJob = RepositoryUtils.GetJob(currentJob.JobId, True)
                        # Wait until there are more rendering tasks then just a master node.
                        if updatedJob.JobRenderingTasks > 1:
                            break

                        # Sleep a bit so that we're not constantly polling the job.
                        SystemUtils.Sleep(5000)

                    self.LogInfo(
                        self.Prefix + "At least one job task other than master node is rendering, setting up distributed config file")

                # If job does not use V-Ray Dynamic Start then wait for all job tasks to dequeue.
                else:
                    # Wait until the job has no queued tasks left.
                    self.LogInfo(
                        self.Prefix + "Waiting for all job tasks to be dequeued before starting distributed render")
                    while True:
                        if self.IsCanceled():
                            self.FailRender("Task canceled")

                        # When checking for queued tasks, take into account a potential queued post job task.
                        updatedJob = RepositoryUtils.GetJob(currentJob.JobId, True)
                        if updatedJob.JobQueuedTasks == 0 or (
                                updatedJob.JobPostJobScript != "" and updatedJob.JobQueuedTasks <= 1):
                            break

                        # Sleep a bit so that we're not constantly polling the job.
                        SystemUtils.Sleep(5000)

                    self.LogInfo(self.Prefix + "All tasks dequeued, setting up distributed config file")

                # Get any global DBR settings.
                self.MyMaxController.GetDBRSettings()
                self.LogInfo(
                    self.Prefix + "Use IP Address instead of Hostname: %s" % self.MyMaxController.DBRUseIPAddresses)

                # Get the list of machines currently rendering the job.
                self.MyMaxController.DBRMachines = self.MyMaxController.GetDBRMachines()

                if len(self.MyMaxController.DBRMachines) > 0:
                    self.LogInfo(self.Prefix + "Commencing distributed render with the following machines:")
                    for machine in self.MyMaxController.DBRMachines:
                        self.LogInfo(self.Prefix + "  " + machine)
                else:
                    self.LogInfo(
                        self.Prefix + "0 machines available currently to DBR, local machine will be used unless configured in plugin settings to be ignored")

                # Now get the config file.
                self.MyMaxController.DBRConfigFile = self.MyMaxController.GetDBRConfigFile()
                backupConfigFile = os.path.join(self.GetJobsDataDirectory(),
                                                os.path.basename(self.MyMaxController.DBRConfigFile))

                if (os.path.isfile(self.MyMaxController.DBRConfigFile)):

                    # Check file permissions on config file.
                    fileAtt = os.stat(self.MyMaxController.DBRConfigFile)[0]
                    if (not fileAtt & stat.S_IWRITE):
                        # File is read-only, so make it writeable
                        try:
                            self.LogInfo(
                                self.Prefix + "Config File is read-only. Attempting to set the file to be writeable")
                            os.chmod(self.MyMaxController.DBRConfigFile, stat.S_IWRITE)
                        except:
                            self.FailRender("FAILED to make the config file writeable. Check Permissions!")

                    self.LogInfo(self.Prefix + "Backing up original config file to: " + backupConfigFile)
                    shutil.copy2(self.MyMaxController.DBRConfigFile, backupConfigFile)
                    self.LogInfo(self.Prefix + "Deleting original config file: " + self.MyMaxController.DBRConfigFile)
                    os.remove(self.MyMaxController.DBRConfigFile)
                else:
                    self.LogInfo(
                        self.Prefix + "Skipping backup and deletion of original config file as it does not exist")

                # Construct the V-Ray/V-RayRT/Mental Ray DR cfg file based on plugin config settings.
                if self.VrayDBRJob:
                    self.MyMaxController.UpdateVrayDBRConfigFile(self.MyMaxController.DBRMachines,
                                                                 self.MyMaxController.DBRConfigFile)
                elif self.VrayRtDBRJob:
                    self.MyMaxController.UpdateVrayRtDBRConfigFile(self.MyMaxController.DBRMachines,
                                                                   self.MyMaxController.DBRConfigFile)
                elif self.MentalRayDBRJob:
                    self.MyMaxController.UpdateMentalRayConfigFile(self.MyMaxController.DBRMachines,
                                                                   self.MyMaxController.DBRConfigFile)
                elif self.CoronaDBRJob:
                    self.MyMaxController.UpdateCoronaConfigFile(self.MyMaxController.DBRMachines,
                                                                self.MyMaxController.DBRConfigFile)

                self.LogInfo(self.Prefix + "Config file created: " + self.MyMaxController.DBRConfigFile)

                if self.VrayDBRJob or self.VrayRtDBRJob:
                    # Sleeping a bit for now to give V-Ray Spawner time to initialize on other machines.
                    self.LogInfo(
                        self.Prefix + "Waiting 10 seconds to give V-Ray Spawner time to initialize on other machines")
                    SystemUtils.Sleep(10000)

                self.LogInfo(self.Prefix + "Ready to go, moving on to distributed render")

                # Start 3dsmax.
                self.MyMaxController.StartMax()

                # Start the 3dsmax job (loads the scene file, etc).
                self.MyMaxController.StartMaxJob()

                if self.CoronaDBRJob:
                    self.MyMaxController.SetupCoronaDR()

                # Render the tasks.
                self.MyMaxController.RenderTasks()

                if (os.path.isfile(backupConfigFile)):
                    self.LogInfo(self.Prefix + "Restoring backup config file: %s to original location: %s" % (
                        backupConfigFile, self.MyMaxController.DBRConfigFile))
                    shutil.copy2(backupConfigFile, self.MyMaxController.DBRConfigFile)
                else:
                    self.LogWarning(self.Prefix + "Skipping restore of backup config file as it does not exist")

                # Need to mark all other rendering tasks as complete for this job (except for pre/post job script tasks).
                self.LogInfo(self.Prefix + "Marking other incomplete tasks as complete")

                tasks = RepositoryUtils.GetJobTasks(currentJob, True)
                for task in tasks.Tasks:
                    if task.TaskId != "0" and (task.TaskStatus == "Rendering" or task.TaskStatus == "Queued"):
                        RepositoryUtils.CompleteTasks(currentJob, [task, ], task.TaskSlaveName)

                # End the 3dsmax job.
                self.MyMaxController.EndMaxJob()

                # Shutdown 3dsmax.
                self.MyMaxController.ShutdownMax()
            else:
                # Non task 0 jobs just start the DBR process if necessary and wait for the render to finish.
                if self.VrayDBRJob or self.VrayRtDBRJob:
                    # For V-Ray, launch the V-Ray Spawner process and wait until we're marked as complete by the master (task 0).
                    self.LogInfo(
                        self.Prefix + "Launching V-Ray Spawner process and waiting for V-Ray DBR render to complete")
                    self.VRaySpawner = VRaySpawnerProcess(self, self.VrayRtDBRJob)
                    self.RunManagedProcess(self.VRaySpawner)
                elif self.MentalRayDBRJob:
                    # For mental ray DBR, there is nothing to do because the DBR service should already be running.
                    # Just chill until we're marked as complete by the master (task 0).
                    self.LogInfo(self.Prefix + "Waiting for Mental Ray Satellite render to complete")
                    while True:
                        if self.IsCanceled():
                            self.FailRender("Task canceled")
                        SystemUtils.Sleep(5000)
                elif self.CoronaDBRJob:
                    # For Corona, launch the Corona DRServer process and wait until we're marked as complete by the master (task 0).
                    self.LogInfo(
                        self.Prefix + "Launching Corona DR process and waiting for Corona DR render to complete")
                    self.CoronaDR = CoronaDRProcess(self)
                    self.RunManagedProcess(self.CoronaDR)
        else:
            # Render the tasks.
            self.MyMaxController.RenderTasks()

    def MonitoredManagedProcessExit(self, name):
        maxNetworkLog = self.MyMaxController.NetworkLogGet()
        if maxNetworkLog.find("in Init. nrGetIface() failed") >= 0:
            self.FailRender(
                "Monitored managed process \"" + name + "\" has exited because an error occurred while initializing Backburner. Please install or upgrade Backburner on this machine and try again.\n" + maxNetworkLog)
        else:
            self.FailRender(
                "Monitored managed process \"" + name + "\" has exited or been terminated.\n" + maxNetworkLog)


########################################################################
## Main Max Controller Class.
########################################################################
class MaxController(object):
    Plugin = None
    MaxProcess = None

    def __init__(self, plugin):
        self.Plugin = plugin
        self.ProgramName = "3dsmaxProcess"

        self.ManagedMaxProcessRenderExecutable = ""
        self.ManagedMaxProcessRenderArgument = ""
        self.ManagedMaxProcessStartupDirectory = ""

        self.MaxSocket = None
        self.Version = -1
        self.ForceBuild = "none"
        self.Is64Bit = False
        self.IsMaxDesign = False
        self.IsMaxIO = False
        self.LanguageCodeStr = ""
        self.LanguageSubDir = ""

        self.UseSlaveMode = True
        self.UseSilentMode = False
        self.UseSecureMode = False
        self.UseUserProfiles = False
        self.UserProfileDataPath = ""
        self.MaxDataPath = ""
        self.MaxPlugCfgPath = ""
        self.ScriptsStartupPath = ""
        self.UserMacroScriptsPath = ""
        self.WorkspacePath = ""
        self.FailOnExistingMaxProcess = True
        self.KillWsCommCntrProcesses = False
        self.StrictMaxCheck = True
        self.RestartEachFrame = False
        self.ShowFrameBuffer = True
        self.AuthentificationToken = ""
        self.MaxStartupFile = ""
        self.StartupKillScript = ""

        self.NetworkLogFile = ""
        self.NetworkLogFileSize = 0
        self.NetworkLogFilePostfix = ""
        self.NetworkLogValid = False
        self.NetworkLogError = ""

        self.RunSanityCheckTimeout = 60
        self.LoadMaxTimeout = 1000
        self.StartJobTimeout = 1000
        self.RunCustomizeScriptTimeout = 1000
        self.ProgressUpdateTimeout = 8000
        self.DisableProgressUpdateTimeout = False

        self.MaxScriptJob = False
        self.MaxScriptJobScript = ""

        self.MaxRenderExecutable = ""
        self.MaxIni = ""
        self.MaxPluginIni = ""
        self.UserPluginIni = ""
        self.UsingCustomPluginIni = False
        self.LightningPluginFile = ""
        self.TempPluginIni = ""
        self.TempLightningIni = ""

        self.MaxFilename = ""
        self.Camera = ""

        self.StartFrame = 0
        self.EndFrame = 0
        self.CurrentFrame = 0

        self.AuxiliaryFilenames = None

        self.SubmittedRendererName = ""
        self.SubmittedRendererId = ""

        self.LocalRendering = True
        self.RedirectOutput = False
        self.RenderOutputOverride = ""
        self.FrameNumberBase = 0
        self.RemovePadding = False
        self.OverrideSaveFile = False
        self.SaveFile = False

        self.UseJpegOutput = False
        self.JpegOutputPath = ""

        self.IgnoreMissingExternalFiles = True
        self.IgnoreMissingUVWs = True
        self.IgnoreMissingXREFs = True
        self.IgnoreMissingDLLs = False
        self.DisableMultipass = False

        self.GammaCorrection = True
        self.GammaInput = 1.0
        self.GammaOutput = 1.0

        self.IgnoreRenderElements = False
        self.IgnoreRenderElementsByName = []

        self.FailOnBlackFrames = False
        self.BlackPixelPercentage = 0
        self.BlackPixelThreshold = 0.0
        self.BlackFramesCheckRenderElements = False

        self.DisableAltOutput = False

        self.RegionRendering = False
        self.RegionAnimation = False
        self.RegionRenderingSingleJob = False
        self.RegionRenderingIndex = "0"
        self.RegionPadding = 0
        self.RegionLeft = 0
        self.RegionTop = 0
        self.RegionRight = 0
        self.RegionBottom = 0
        self.RegionLeftArray = []
        self.RegionTopArray = []
        self.RegionRightArray = []
        self.RegionBottomArray = []
        self.RegionType = "CROP"
        self.slaveDirectory = ""
        self.TempFolder = ""

        self.VraySplitBufferFile = False
        self.VrayRawBufferFile = False

        self.DBRUseIPAddresses = False
        self.DBRMachines = []
        self.DBRConfigFile = ""

        self.VrayDBRDynamicStart = False
        self.VrayDBRPortRange = "20204"
        self.VrayDBRUseLocalMachine = True
        self.VrayDBRTransferMissingAssets = False
        self.VrayDBRUseCachedAssets = False
        self.VrayDBRCacheLimitType = "None"
        self.VrayDBRCacheLimit = "100.000000"

        self.VrayRtDBRDynamicStart = False
        self.VrayRtDBRPortRange = "20206"
        self.VrayRtDBRAutoStartLocalSlave = True

        self.MentalRaySatPortNumber = ""

        self.CoronaDRServerNoGui = False

        self.PreFrameScript = ""
        self.PostFrameScript = ""
        self.PreLoadScript = ""
        self.PostLoadScript = ""
        self.PathConfigFile = ""
        self.MergePathConfigFile = False

        self.FunctionRegex = Regex("FUNCTION: (.*)")
        self.SuccessMessageRegex = Regex("SUCCESS: (.*)")
        self.SuccessNoMessageRegex = Regex("SUCCESS")
        self.CanceledRegex = Regex("CANCELED")
        self.ErrorRegex = Regex("ERROR: (.*)")

        self.ProgressRegex = Regex("PROGRESS (.*)")
        self.SetTitleRegex = Regex("SETTITLE (.*)")
        self.StdoutRegex = Regex("STDOUT: (.*)")
        self.WarnRegex = Regex("WARN: (.*)")
        self.GetJobInfoEntryRegex = Regex("GETJOBINFOENTRY (.*)")
        self.GetSubmitInfoEntryRegex = Regex("GETSUBMITINFOENTRY (.*)")
        self.GetSubmitInfoEntryElementCountRegex = Regex("GETSUBMITINFOENTRYELEMENTCOUNT (.*)")
        self.GetSubmitInfoEntryElementRegex = Regex("GETSUBMITINFOENTRYELEMENT ([^,]*),(.*)")
        self.GetAuxFileRegex = Regex("GETAUXFILE (.*)")
        self.GetPathMappedFilenameRegex = Regex("GETPATHMAPPEDFILENAME (.*)")

        self.MaxDescriptionDict = {
            "11.0.0.57": "3ds Max 2009 base install",
            "11.0.0.103": "3ds Max 2009 + hotfix3_2008.05.01",
            "11.1.0.208": "3ds Max 2009 + servicepack_sp1",
            "11.5.0.306": "3ds Max 2009 + hotfix4_2008.06.10_incl.previous_sp1",
            "11.5.2.315": "3ds Max 2009 + hotfix_2009.01.19_incl.previous_sp1",
            "11.5.2.318": "3ds Max 2009 + hotfix_2009.03.16_incl.previous_sp1",
            "11.5.2.324": "3ds Max 2009 + hotfix_2009.08.18",
            "11.5.3.330": "3ds Max 2009 + hotfix_2010.06.07/subs_creativity_extension",
            "12.0.0.106": "3ds Max 2010 base install",
            "12.0.1.201": "3ds Max 2010 + hotfix_2009.04.01",
            "12.0.3.203": "3ds Max 2010 + hotfix_2009.05.19",
            "12.1.0.310": "3ds Max 2010 + servicepack_sp1",
            "12.1.7.209": "3ds Max 2010 + hotfix_2009.09.22",
            "12.1.8.213": "3ds Max 2010 + hotfix_2010.02.17",
            "12.1.9.216": "3ds Max 2010 + hotfix_2010.06.08",
            "12.2.0.312": "3ds Max 2010 + servicepack_sp2/subs_connection_extension",
            "13.0.0.94": "3ds Max 2011 base install/hotfix_infocenter",
            "13.0.1.203": "3ds Max 2011 + hotfix_2010.06.07",
            "13.0.2.205": "3ds Max 2011 + hotfix_2010.07.21",
            "13.1.0.114": "3ds Max 2011 + service_pack_sp1/adv_pack_extension",
            "13.1.4.209": "3ds Max 2011 + hotfix4_2010.12.03",
            "13.6.0.118": "3ds Max 2011 + servicepack_sp2",
            "13.7.0.119": "3ds Max 2011 + servicepack_sp3",
            "14.0.0.121": "3ds Max 2012 base install - DOES NOT WORK WITH DEADLINE",
            "14.1.0.328": "3ds Max 2012 + servicepack_sp1/hotfix1",
            "14.1.2.210": "3ds Max 2012 + servicepack_sp1/hotfix2",
            "14.2.0.375": "3ds Max 2012 + servicepack_sp2",
            "14.6.0.388": "3ds Max 2012 + productupdate_pu6 - DOES NOT WORK WITH DEADLINE",
            "14.7.427.0": "3ds Max 2012 + productupdate_pu7",
            "14.8.437.0": "3ds Max 2012 + productupdate_pu8",
            "14.9.467.0": "3ds Max 2012 + productupdate_pu9",
            "14.10.483.0": "3ds Max 2012 + productupdate_pu10",
            "14.12.508.0": "3ds Max 2012 + productupdate_pu12/advantage_pack_extension",
            "15.0.0.347": "3ds Max 2013 base install - DOES NOT WORK WITH DEADLINE",
            "15.1.348.0": "3ds Max 2013 + productupdate_pu1 - DOES NOT WORK WITH DEADLINE",
            "15.2.54.0": "3ds Max 2013 + productupdate_pu2",
            "15.3.72.0": "3ds Max 2013 + productupdate_pu3",
            "15.4.99.0": "3ds Max 2013 + productupdate_pu4",
            "15.4.99.0": "3ds Max 2013 + subs_adv_pack_extension",
            "15.5.121.0": "3ds Max 2013 + productupdate_pu5",
            "15.6.164.0": "3ds Max 2013 + productupdate_pu6",
            "16.0.420.0": "3ds Max 2014 base install - ADSK GAMMA BUG (INSTALL SP5)",
            "16.1.178.0": "3ds Max 2014 + servicepack_sp1",
            "16.2.475.0": "3ds Max 2014 + servicepack_sp2",
            "16.3.207.0": "3ds Max 2014 + servicepack_sp3_BETA",
            "16.3.253.0": "3ds Max 2014 + servicepack_sp3/subs_py_stereo_cam_extension",
            "16.4.265.0": "3ds Max 2014 + servicepack_sp4 PR36 T265  - DOES NOT WORK WITH DEADLINE",
            "16.4.267.0": "3ds Max 2014 + servicepack_sp4 PR36.1 T267",
            "16.4.269.0": "3ds Max 2014 + servicepack_sp4 PR36.2 T269 (CIP fixed)",
            "16.4.270.0": "3ds Max 2014 + servicepack_sp4 (removed by ADSK due to bug - MAXX-16406)",
            "16.5.277.0": "3ds Max 2014 + servicepack_sp5",
            "16.6.556.0": "3ds Max 2014 + servicepack_sp6",
            "17.0.630.0": "3ds Max 2015 base install",
            "17.1.148.0": "3ds Max 2015 + servicepack_sp1 PR40.1 Elwood SP1 (Build E148)",
            "17.1.149.0": "3ds Max 2015 + servicepack_sp1",
            "17.2.259.0": "3ds Max 2015 + servicepack_sp2/subs_extension_1",
            "17.3.343.0": "3ds Max 2015 + servicepack_sp3/subs_extension_2 PR47 (Build E326.1)",
            "17.3.360.0": "3ds Max 2015 + servicepack_sp3/subs_extension_2 PR47 (Build E360)",
            "17.3.374.0": "3ds Max 2015 + servicepack_sp3/subs_extension_2",
            "17.4.476.0": "3ds Max 2015 + servicepack_sp4",
            "18.0.873.0": "3ds Max 2016 base install",
            "18.3.490.0": "3ds Max 2016 + servicepack_sp1/subs_extension_1",
            "18.6.667.0": "3ds Max 2016 + servicepack_sp2",
            "18.7.696.0": "3ds Max 2016 + servicepack_sp3",
            "18.8.739.0": "3ds Max 2016 + servicepack_sp4",
            "18.9.762.0": "3ds Max 2016 + servicepack_sp5",
            "19.0.1072.0": "3ds Max 2017 base install",
            "19.1.129.0": "3ds Max 2017 + servicepack_sp1",
            "19.2.472.0": "3ds Max 2017 + servicepack_sp2",
            "19.3.533.0": "3ds Max 2017 + servicepack_sp3",
            "19.5.917.0": "3ds Max 2017 + security fix",
            "19.50.781.0": "3ds Max 2017 + update 1",
            "19.51.835.0": "3ds Max 2017.1.1 Security Fix (Dec 9, 2016)",
            "19.52.915.0": "3ds Max 2017 + update 2",
            "20.0.0.966": "3ds Max 2018 base install",
            "20.1.0.228": "3ds Max IO 2018 PR4 (Build I228)",
            "20.1.0.1452": "3ds Max 2018 + update 1",
            "20.2.0.2345": "3ds Max 2018 + update 2",
            "20.3.0.3149": "3ds Max 2018 + update 3",
            "20.4.0.4224": "3ds Max 2018 + update 4",
            "20.4.0.4254": "3ds Max 2018 + update 4",
            "20.4.8.4036": "3ds Max 2018 + update 4 + Security Fix 1",
            "20.4.10.4301": "3ds Max 2018 + update 4 + Security Fix 2",
            "21.0.0.845": "3ds Max 2019 base install",
            "21.1.0.1314": "3ds Max 2019 + update 1",
            "21.1.1.1320": "3ds Max 2019.1.1",
            "21.2.0.2219": "3ds Max 2019 + update 2",
            "21.3.0.3250": "3ds Max 2019 + update 3",
            "21.3.2.3208": "3ds Max 2019 + update 3 + Security Fix 1",
            "21.3.4.3300": "3ds Max 2019 + update 3 + Security Fix 2",
            "22.0.0.757": "3ds Max 2020 base install",
            "22.1.0.1249": "3ds Max 2020 + update 1",
            "22.2.0.2176": "3ds Max 2020 + update 2",
            "22.3.0.3165": "3ds Max 2020 + update 3",
            "22.3.2.3204": "3ds Max 2020 + update 3 + Security Fix 1",
            "23.0.0.915": "3ds Max 2021 base install",
            "23.1.0.1314": "3ds Max 2021 + update 1",
            "23.2.0.2215": "3ds Max 2021 + update 2",
            "23.3.0.3201": "3ds Max 2021 + update 3",
            "24.0.0.923": "3ds Max 2022 base install",
        }

    def Cleanup(self):
        if self.MaxProcess:
            self.MaxProcess.Cleanup()
            del self.MaxProcess

    ########################################################################
    ## Main functions (to be called from Deadline Entry Functions)
    ########################################################################
    # Reads in the plugin configuration settings and sets up everything in preparation to launch 3dsmax.
    # Also does some checking to ensure a 3dsmax job can be rendered on this machine.
    def Initialize(self):
        # # PATH environment variable checking for Backburner
        # SysEnvVarPath = Environment.GetEnvironmentVariable( "PATH" )
        # self.Plugin.LogInfo( "Sys Env Var PATH: %s" % SysEnvVarPath )
        # self.Plugin.LogInfo( "Sys Env Var PATH length: %s" % len(SysEnvVarPath) )

        # # Check for malformed PATH sys env variable, such as PATH=;; from a bad 3rd party installer that tries to be clever with the existing PATH length
        # if SysEnvVarPath == "" or len(SysEnvVarPath) < 10:
        #     self.Plugin.LogWarning( "PATH is too short. Possibly malformed sys env var PATH or corrupt. Check your PATH environment variable!" )

        # # Check PATH isn't longer than 2048 characters.
        # if len(SysEnvVarPath) > 2048:
        #     self.Plugin.LogWarning( "If your PATH environment variable is more than 2048 characters it (and WINDIR) stop being visible in many contexts." )
        #     self.Plugin.LogWarning( "Bad Installers will try to add their application path to the end of PATH and if the Backburner application path is" )
        #     self.Plugin.LogWarning( "already at the end of PATH, it can sometimes delete the Backburner path from PATH!" )

        # SysEnvVarPaths = SysEnvVarPath.split( ";" )
        # BBRegEx = re.compile( r".*Backburner.*", re.IGNORECASE )
        # BBPaths = []
        # for SysEnvVarPath in SysEnvVarPaths:
        #     if BBRegEx.search( SysEnvVarPath ):
        #         BBPaths.append( SysEnvVarPath )

        # if len(BBPaths) >= 1: # print Backburner directory path(s) listing in PATH sys env variable
        #     tempStr = ", ".join(BBPaths)
        #     self.Plugin.LogInfo( "Backburner Path(s) Found in PATH: '%s'" % tempStr )

        # if len(BBPaths) > 1: # Generate Warning if more than 1 Backburner Path is discovered on the machine
        #     self.Plugin.LogWarning( "More than 1 Backburner Path can exist in PATH. However, ensure the latest version of Backburner is always the first entry in your PATH system environment variable" )

        # # Check .NET FileVersion of Backburner Server as identified in sys env var PATH
        # BBServerExeVersion = None
        # BBServerExecutable = PathUtils.GetApplicationPath( "server.exe" )
        # if BBServerExecutable == "" or not os.path.isfile( BBServerExecutable ):
        #     self.Plugin.LogWarning( "Autodesk Backburner server.exe could not be found on this machine, it is required to run Deadline-3dsMax plugin" )
        #     self.Plugin.LogWarning( "Please install or upgrade Backburner on this machine and try again." )
        # else:
        #     BBServerExeVersion = FileVersionInfo.GetVersionInfo( BBServerExecutable )
        #     self.Plugin.LogInfo( "Backburner server.exe version: %s" % BBServerExeVersion.FileVersion )

        # Read in the 3dsmax version.
        self.Version = self.Plugin.GetIntegerPluginInfoEntry("Version")
        if self.Version < 2010:
            self.Plugin.FailRender("Only 3ds Max 2010 and later is supported")

        # # Compare Backburner version to 3dsMax version if available and log warning if BB version < 3dsMax version
        # if BBServerExeVersion != None:
        #     bbVersion = (BBServerExeVersion.FileVersion).split(".")
        #     if (len(bbVersion) > 0):
        #         if (int(bbVersion[0]) < self.Version):
        #             self.Plugin.LogWarning( "Backburner version is too OLD to support this version of 3ds Max. 3ds Max will FAIL to start! Please upgrade Backburner and ensure machine is restarted." )

        # Max 2010-2015 have different settings for Design edition, so we need to handle appropriately. Design edition was retired in Max 2016.
        if self.Version < 2016:
            self.IsMaxDesign = self.Plugin.GetBooleanPluginInfoEntryWithDefault("IsMaxDesign", False)
        if self.IsMaxDesign:
            self.Plugin.LogInfo("Rendering with 3ds Max Design Version: %d" % self.Version)
        else:
            self.Plugin.LogInfo("Rendering with 3ds Max Version: %d" % self.Version)

        # Read in the Build of 3dsmax to force.
        self.ForceBuild = self.Plugin.GetPluginInfoEntryWithDefault("MaxVersionToForce", "none").lower()
        if self.Version > 2013:
            self.ForceBuild = "none"
            self.Plugin.LogInfo("Not forcing a build of 3ds Max because version 2014 and later is 64 bit only")
        else:
            self.Plugin.LogInfo("Build of 3ds Max to force: %s" % self.ForceBuild)

        # Figure out the render executable to use for rendering.
        renderExecutableKey = "RenderExecutable" + str(self.Version)
        prettyName = "3ds Max %s" % str(self.Version);
        if self.IsMaxDesign:
            renderExecutableKey = renderExecutableKey + "Design"
            prettyName = "3ds Max Design %s" % str(self.Version)

        self.MaxRenderExecutable = self.Plugin.GetRenderExecutable(renderExecutableKey, prettyName)
        self.Plugin.LogInfo("Rendering with executable: %s" % self.MaxRenderExecutable)

        # Identify if 3dsmaxio executable is being used
        exeName = os.path.splitext(os.path.basename(self.MaxRenderExecutable))[0]
        if exeName.endswith("io"):
            self.IsMaxIO = True

        # Figure out .NET FileVersion of 3dsmax.exe / 3dsmaxio.exe
        MaxExe = FileVersionInfo.GetVersionInfo(self.MaxRenderExecutable)
        SlaveExeVersion = MaxExe.FileVersion
        self.Plugin.LogInfo("Worker 3ds Max Version: %s" % SlaveExeVersion)

        # If known version of 3dsMax, then print out English description of 3dsmax.exe / 3dsmaxio.exe version
        if SlaveExeVersion in self.MaxDescriptionDict:
            self.Plugin.LogInfo("Worker 3ds Max Description: %s" % self.MaxDescriptionDict[SlaveExeVersion])

        # If PluginInfoFile key=value pair "SubmittedFromVersion" available in job settings, then if version known in look-up dict, then print out English description of 3dsmax.exe version that job was submitted with.
        SubmittedFromVersion = self.Plugin.GetPluginInfoEntryWithDefault("SubmittedFromVersion", "")
        if SubmittedFromVersion != "":
            self.Plugin.LogInfo("Submitted from 3ds Max Version: %s" % SubmittedFromVersion)
            if SubmittedFromVersion in self.MaxDescriptionDict:
                self.Plugin.LogInfo(
                    "Submitted from 3ds Max Description: %s" % self.MaxDescriptionDict[SubmittedFromVersion])
            if SlaveExeVersion != SubmittedFromVersion:
                self.Plugin.LogWarning(
                    "Worker's 3ds Max version is NOT the same as the 3ds Max version that was used to submit this job! Unexpected results may occur!")

        self.SubmittedRendererName = self.Plugin.GetPluginInfoEntryWithDefault("SubmittedRendererName", "")
        if self.SubmittedRendererName != "":
            self.Plugin.LogInfo("Submitted using Renderer Name: %s" % self.SubmittedRendererName)

        self.SubmittedRendererId = self.Plugin.GetPluginInfoEntryWithDefault("SubmittedRendererId", "")
        if self.SubmittedRendererId != "":
            self.Plugin.LogInfo("Submitted using Renderer Class Id: %s" % self.SubmittedRendererId)

        self.Plugin.LogInfo("Checking registry for 3ds Max language code")
        maxInstallDirectory = Path.GetDirectoryName(self.MaxRenderExecutable)

        maxIntVersion = self.Version - 1998
        maxVersionStr = str(maxIntVersion)
        maxVersionStr += ".0"

        if self.Version < 2013:
            languageCode = ""

            englishCode = "409"
            frenchCode = "40C"
            germanCode = "407"
            japaneseCode = "411"
            simplifiedChineseCode = "804"
            koreanCode = "412"

            maxKeyName = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Autodesk\\3DSMAX\\" + maxVersionStr + "\\MAX-1:"
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxKeyName, englishCode, languageCode)
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxKeyName, frenchCode, languageCode)
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxKeyName, germanCode, languageCode)
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxKeyName, japaneseCode,
                                                             languageCode)
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxKeyName, simplifiedChineseCode,
                                                             languageCode)
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxKeyName, koreanCode, languageCode)

            maxWowKeyName = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Autodesk\\3dsMax\\" + maxVersionStr + "\\MAX-1:"
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxWowKeyName, englishCode,
                                                             languageCode)
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxWowKeyName, frenchCode,
                                                             languageCode)
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxWowKeyName, germanCode,
                                                             languageCode)
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxWowKeyName, japaneseCode,
                                                             languageCode)
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxWowKeyName, simplifiedChineseCode,
                                                             languageCode)
            languageCode = self.AutoCheckRegistryForLanguage(maxInstallDirectory, maxWowKeyName, koreanCode,
                                                             languageCode)

            if languageCode != "":
                self.Plugin.LogInfo("Found language code: " + languageCode)
                if languageCode == englishCode:
                    self.LanguageCodeStr = "enu"
                elif languageCode == frenchCode:
                    self.LanguageCodeStr = "fra"
                elif languageCode == germanCode:
                    self.LanguageCodeStr = "deu"
                elif languageCode == japaneseCode:
                    self.LanguageCodeStr = "jpn"
                elif languageCode == simplifiedChineseCode:
                    self.LanguageCodeStr = "chs"
                elif languageCode == koreanCode:
                    self.LanguageCodeStr = "kor"
                else:
                    self.Plugin.FailRender(
                        "Unsupported language code: " + languageCode + ". Please email this error report to support@thinkboxsoftware.com so we can add support for this language code.")
            else:
                self.Plugin.LogInfo("Language code could not be found. Defaulting to 409 (English)")
                self.LanguageCodeStr = "enu"

            self.Plugin.LogInfo("Language code string: " + self.LanguageCodeStr)
        else:
            languageCode = "ENU"
            languageSubDir = "en-US"

            languageOverride = self.Plugin.GetPluginInfoEntryWithDefault("Language", "Default")
            if languageOverride == "Default":
                maxKeyName = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Autodesk\\3DSMAX\\" + maxVersionStr
                languageCode = SystemUtils.GetRegistryKeyValue(maxKeyName, "DefaultLanguage", "")
                if (languageCode == ""):
                    maxKeyName = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Autodesk\\3DSMAX\\" + maxVersionStr
                    languageCode = SystemUtils.GetRegistryKeyValue(maxKeyName, "DefaultLanguage", "")
                    if (languageCode == ""):
                        self.Plugin.LogInfo("Language code could not be found in registry. Defaulting to ENU (English)")
                        languageCode = "ENU"

                maxKeyName = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Autodesk\\3DSMAX\\" + maxVersionStr + "\\LanguagesInstalled\\" + languageCode
                languageSubDir = SystemUtils.GetRegistryKeyValue(maxKeyName, "LangSubDir", "")
                if (languageSubDir == ""):
                    maxKeyName = "HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\Autodesk\\3DSMAX\\" + maxVersionStr + "\\LanguagesInstalled\\" + languageCode
                    languageSubDir = SystemUtils.GetRegistryKeyValue(maxKeyName, "LangSubDir", "")
                    if (languageSubDir == ""):
                        self.Plugin.LogInfo(
                            "Language sub directory could not be found in registry. Defaulting to en-US (English)")
                        languageSubDir = "en-US"
            else:
                self.Plugin.LogInfo("Overriding language code: " + languageOverride)

                languageCode = languageOverride
                if languageCode == "ENU":
                    languageSubDir = "en-US"
                elif languageCode == "FRA":
                    languageSubDir = "fr-FR"
                elif languageCode == "DEU":
                    languageSubDir = "de-DE"
                elif languageCode == "JPN":
                    languageSubDir = "ja-JP"
                elif languageCode == "CHS":
                    languageSubDir = "zh-CN"
                elif languageCode == "KOR":
                    languageSubDir = "ko-KR"
                elif languageCode == "PTB":
                    languageSubDir = "pt-BR"
                else:
                    self.Plugin.LogInfo(
                        "Language code override \"" + languageOverride + "\" is not supported. Defaulting to ENU (English)")
                    languageCode = "ENU"
                    languageSubDir = "en-US"

            self.LanguageCodeStr = languageCode
            self.LanguageSubDir = languageSubDir

            self.Plugin.LogInfo("Language code string: " + self.LanguageCodeStr)
            self.Plugin.LogInfo("Language sub directory: " + self.LanguageSubDir)

        # Read in the Fail On Existing Max Process setting, which can be overridden in the plugin info file.
        if (self.Plugin.GetBooleanPluginInfoEntryWithDefault("OverrideFailOnExistingMaxProcess", False)):
            self.FailOnExistingMaxProcess = self.Plugin.GetBooleanPluginInfoEntryWithDefault("FailOnExistingMaxProcess",
                                                                                             True)
            self.Plugin.LogInfo(
                "Fail on existing 3dsmax process: %d (from plugin info override)" % self.FailOnExistingMaxProcess)
        else:
            self.FailOnExistingMaxProcess = self.Plugin.GetBooleanConfigEntryWithDefault("FailOnExistingMaxProcess",
                                                                                         True)
            self.Plugin.LogInfo("Fail on existing 3dsmax process: %d" % self.FailOnExistingMaxProcess)

        # Get timeouts.
        self.RunSanityCheckTimeout = self.Plugin.GetIntegerConfigEntryWithDefault("RunSanityCheckTimeout", 60)
        self.Plugin.LogInfo("Run render sanity check timeout: %d seconds" % self.RunSanityCheckTimeout)
        self.LoadMaxTimeout = self.Plugin.GetIntegerConfigEntryWithDefault("LoadMaxTimeout", 1000)
        self.Plugin.LogInfo("Load 3dsmax timeout: %d seconds" % self.LoadMaxTimeout)
        self.StartJobTimeout = self.Plugin.GetIntegerConfigEntryWithDefault("StartJobTimeout", 1000)
        self.Plugin.LogInfo("Start 3dsmax job timeout: %d seconds" % self.StartJobTimeout)
        self.RunCustomizeScriptTimeout = self.Plugin.GetIntegerConfigEntryWithDefault("RunCustomizeScriptTimeout", 1000)
        self.Plugin.LogInfo("Execute customize.ms script timeout: %d seconds" % self.RunCustomizeScriptTimeout)
        self.ProgressUpdateTimeout = self.Plugin.GetIntegerConfigEntryWithDefault("ProgressUpdateTimeout", 8000)
        self.Plugin.LogInfo("Progress update timeout: %d seconds" % self.ProgressUpdateTimeout)
        self.DisableProgressUpdateTimeout = self.Plugin.GetBooleanPluginInfoEntryWithDefault(
            "DisableProgressUpdateTimeout", False)
        self.Plugin.LogInfo("Progress update timeout disabled: %s" % self.DisableProgressUpdateTimeout)

        # Read in Worker Mode setting.
        self.UseSlaveMode = self.Plugin.GetBooleanPluginInfoEntryWithDefault("UseSlaveMode", True)
        self.Plugin.LogInfo("Worker mode enabled: %s" % self.UseSlaveMode)

        # Read in Silent Mode setting.
        self.UseSilentMode = self.Plugin.GetBooleanPluginInfoEntryWithDefault("UseSilentMode", False)
        self.Plugin.LogInfo("Silent mode enabled: %s" % self.UseSilentMode)

        # Read in Secure setting for 3ds Max IO.
        self.UseSecureMode = self.Plugin.GetBooleanConfigEntryWithDefault("UseSecureMode", False)
        self.Plugin.LogInfo("Secure mode enabled: %s" % self.UseSecureMode)

        # Read in Local Rendering setting.
        self.LocalRendering = self.Plugin.GetBooleanPluginInfoEntryWithDefault("LocalRendering", True)
        self.Plugin.LogInfo("Local rendering enabled: %s" % self.LocalRendering)

        # Read in the Strict Max Check setting.
        # self.StrictMaxCheck = self.Plugin.GetBooleanConfigEntryWithDefault( "StrictMaxCheck", True )
        # self.Plugin.LogInfo( "Strict 3dsmax check enabled: %d" % self.StrictMaxCheck )
        # Disabling this because it's really not necessary anymore, and the 3dsmaxcmd.exe check is good enough at telling us if there is a problem with the 3dsmax/backburner installation
        self.StrictMaxCheck = False

        maxInstallPath = Path.GetDirectoryName(self.MaxRenderExecutable)

        # # This is sometimes necessary for 3dsmax/3dsmaxio to run on a fresh install.
        # if( self.Plugin.GetBooleanConfigEntryWithDefault( "RunCmdWorkaround", True ) ):
        #     self.Plugin.LogInfo( "Running render sanity check using 3ds Max Cmd" )
        #     self.Hack3dsmaxCommand()

        # Set 3dsmax startup filename.
        self.MaxStartupFile = os.path.join(self.Plugin.MaxStartupDir, "deadlineStartupMax" + str(self.Version) + ".max")
        if (not os.path.isfile(self.MaxStartupFile)):
            self.Plugin.FailRender("The 3dsmax start up file %s does not exist" % self.MaxStartupFile)
        if (not os.path.isfile(Path.ChangeExtension(self.MaxStartupFile, ".xml"))):
            self.Plugin.FailRender(
                "The Backburner xml job file %s does not exist" % Path.ChangeExtension(self.MaxStartupFile, ".xml"))
        self.Plugin.LogInfo("3dsmax start up file: %s" % self.MaxStartupFile)

        # Check if we are running the 64 bit version.
        self.Is64Bit = FileUtils.Is64BitDllOrExe(self.MaxRenderExecutable)

        # Figure out if we are using user profiles or not (version 9 or later).
        installIni = PathUtils.ChangeFilename(self.MaxRenderExecutable, "InstallSettings.ini")
        useUserProfiles = FileUtils.GetIniFileSetting(installIni, "Least User Privilege", "useUserProfiles", "1")
        if (useUserProfiles == "1"):
            self.UseUserProfiles = True
        self.Plugin.LogInfo("Using user profiles: %d" % self.UseUserProfiles)

        # Set 3dsmax Ini file, and figure out the network log path.
        networkLogFilePath = ""
        if self.UseUserProfiles:
            if not self.IsMaxDesign:
                # The 3dsmax.ini file is in the user profile directory if UseUserProfiles is enabled.
                if (self.Is64Bit):
                    maxDirName = "3dsMaxIO" if self.IsMaxIO else "3dsMax"
                    self.UserProfileDataPath = os.path.join(PathUtils.GetLocalApplicationDataPath(),
                                                            "Autodesk\\" + maxDirName + "\\" + str(
                                                                self.Version) + " - 64bit\\" + self.LanguageCodeStr)
                else:
                    self.UserProfileDataPath = os.path.join(PathUtils.GetLocalApplicationDataPath(),
                                                            "Autodesk\\3dsmax\\" + str(
                                                                self.Version) + " - 32bit\\" + self.LanguageCodeStr)
            else:
                # The user profile directory is different for the Design version
                if (self.Is64Bit):
                    self.UserProfileDataPath = os.path.join(PathUtils.GetLocalApplicationDataPath(),
                                                            "Autodesk\\3dsMaxDesign\\" + str(
                                                                self.Version) + " - 64bit\\" + self.LanguageCodeStr)
                else:
                    self.UserProfileDataPath = os.path.join(PathUtils.GetLocalApplicationDataPath(),
                                                            "Autodesk\\3dsMaxDesign\\" + str(
                                                                self.Version) + " - 32bit\\" + self.LanguageCodeStr)

            self.Plugin.LogInfo("3dsmax user profile path: %s" % self.UserProfileDataPath)
            self.MaxIni = os.path.join(self.UserProfileDataPath, "3dsmax.ini")

            self.MaxDataPath = self.UserProfileDataPath
            self.MaxPlugCfg = os.path.join(self.UserProfileDataPath, self.LanguageSubDir + "\\plugcfg")
            networkLogFilePath = os.path.join(self.UserProfileDataPath, "Network")
        else:
            if self.Version < 2013:
                self.MaxIni = PathUtils.ChangeFilename(self.MaxRenderExecutable, "3dsmax.ini")
            else:
                self.MaxIni = PathUtils.ChangeFilename(self.MaxRenderExecutable, self.LanguageSubDir + "\\3dsmax.ini")

            self.MaxDataPath = Path.GetDirectoryName(self.MaxRenderExecutable)
            self.MaxPlugCfg = os.path.join(self.MaxDataPath, Path.GetDirectoryName(self.MaxIni) + "\\plugcfg")
            networkLogFilePath = os.path.join(self.MaxDataPath, "Network")

        self.Plugin.LogInfo("3dsmax plugcfg directory: %s" % self.MaxPlugCfg)
        self.Plugin.LogInfo("3dsmax network directory: %s" % networkLogFilePath)

        # Build the path to the "scripts/startup" and "usermacros" directory
        if self.UseUserProfiles:
            self.ScriptsStartupPath = os.path.join(self.UserProfileDataPath, "scripts\\startup")
            if self.Version >= 2013:
                self.UserMacroScriptsPath = os.path.join(self.UserProfileDataPath, "usermacros")
            else:
                self.UserMacroScriptsPath = os.path.join(self.UserProfileDataPath, "UI\\usermacros")
        else:
            if self.Version >= 2013:
                self.ScriptsStartupPath = PathUtils.ChangeFilename(self.MaxRenderExecutable, "scripts\\Startup")
                self.UserMacroScriptsPath = PathUtils.ChangeFilename(self.MaxRenderExecutable, "usermacros")
            else:
                self.ScriptsStartupPath = PathUtils.ChangeFilename(self.MaxRenderExecutable, "Scripts\\Startup")
                self.UserMacroScriptsPath = PathUtils.ChangeFilename(self.MaxRenderExecutable, "UI\\usermacros")

        # Create the "usermacros" directory path if it doesn't exist.
        if (not os.path.isdir(self.UserMacroScriptsPath)):
            try:
                Directory.CreateDirectory(self.UserMacroScriptsPath)
                self.Plugin.LogInfo("Creating usermacros directory path: %s" % self.UserMacroScriptsPath)
            except:
                self.Plugin.LogWarning("Failed to create usermacros directory: %s" % self.UserMacroScriptsPath)

        self.Plugin.LogInfo("3dsmax usermacros directory: %s" % self.UserMacroScriptsPath)

        # Cleanup any temp macroscripts from an earlier session/crash of 3dsMax (caused by ADSK race condition bug/older versions of V-Ray)
        scriptFiles = Directory.GetFiles(self.UserMacroScriptsPath, "*.*", SearchOption.TopDirectoryOnly)

        if len(scriptFiles) > 0:
            for scriptFile in scriptFiles:
                tmpFile = os.path.basename(scriptFile)
                if (tmpFile.startswith("__temp")):
                    try:
                        os.remove(scriptFile)
                        self.Plugin.LogInfo("Successfully deleted '__temp' script file: %s" % tmpFile)
                    except:
                        self.Plugin.LogWarning("Could not delete '__temp' script file: %s" % tmpFile)

        self.Plugin.LogInfo("Scripts Startup Directory: %s" % self.ScriptsStartupPath)

        # Create the scripts startup directory if it doesn't already exist.
        if (not os.path.isdir(self.ScriptsStartupPath)):
            try:
                Directory.CreateDirectory(self.ScriptsStartupPath)
                self.Plugin.LogInfo("Created scripts startup directory path: %s" % self.ScriptsStartupPath)
            except:
                self.Plugin.LogWarning("Failed to create scripts startup directory: %s" % self.ScriptsStartupPath)

        # Build the path to the Startup Kill Script script
        self.pluginStartupKillScript = os.path.join(self.Plugin.GetPluginDirectory(), "killCommCenter.ms")
        self.StartupKillScript = os.path.join(self.ScriptsStartupPath, "killCommCenter.ms")

        # Read in Kill ADSK InfoCenter (Communications Center) exe setting.
        self.KillWsCommCntrProcesses = self.Plugin.GetBooleanConfigEntryWithDefault("KillWsCommCntrProcesses", False)
        self.Plugin.LogInfo("Kill ADSK WSCommCntr*.exe process: %s" % self.KillWsCommCntrProcesses)

        # If enabled, copy the killCommCenter.ms file to the max_root or userProfile "scripts\\startup" directory
        if self.KillWsCommCntrProcesses:
            try:
                shutil.copy2(self.pluginStartupKillScript, self.StartupKillScript)
                self.Plugin.LogInfo("Copied %s to %s" % (self.pluginStartupKillScript, self.StartupKillScript))
            except:
                self.Plugin.LogWarning(
                    "Could not copy %s to %s" % (self.pluginStartupKillScript, self.StartupKillScript))
                self.Plugin.LogInfo(
                    "If this fails, make sure that the necessary permissions are set on this destination folder to allow for this copy to take place")

        # This is to workaround a bug in 3ds max 2015 that requires Visible=False for Scene Explorer to be hidden when rendering in service mode
        if self.Version >= 2015:
            if self.UseUserProfiles:
                self.WorkspacePath = os.path.join(self.UserProfileDataPath, self.LanguageSubDir + "\\UI\\Workspaces")
            else:
                self.WorkspacePath = PathUtils.ChangeFilename(self.MaxRenderExecutable,
                                                              self.LanguageSubDir + "\\UI\\Workspaces")

            self.Plugin.LogInfo("Workspace Directory: %s" % self.WorkspacePath)

            # Create the workspace directory path if it doesn't exist.
            if (not os.path.isdir(self.WorkspacePath)):
                self.Plugin.LogInfo("Creating workspace directory path: %s" % self.WorkspacePath)
                Directory.CreateDirectory(self.WorkspacePath)

            iniFiles = Directory.GetFiles(self.WorkspacePath, "*.ini", SearchOption.TopDirectoryOnly)

            if len(iniFiles) > 0:
                for iniFile in iniFiles:
                    seVisible = FileUtils.GetIniFileSetting(iniFile, "Explorer", "Visible", "True")
                    fsVisible = FileUtils.GetIniFileSetting(iniFile, "FormStates", "Visible", "True")
                    if bool(seVisible) or bool(fsVisible):
                        FileUtils.SetIniFileSetting(iniFile, "Explorer", "Visible", "False")
                        FileUtils.SetIniFileSetting(iniFile, "FormStates", "Visible", "False")
                        self.Plugin.LogInfo("Workspace ini file: %s [Scene Explorer] set to [Visible=False]" % iniFile)
            else:
                seFileName = "Workspace1.se.ini"
                seFile = os.path.join(self.WorkspacePath, seFileName)
                writer = File.CreateText(seFile)
                writer.WriteLine("[Explorer]\n")
                writer.WriteLine("Visible=False\n")
                writer.WriteLine("[FormStates]\n")
                writer.WriteLine("Visible=False\n")
                writer.Close()
                self.Plugin.LogInfo("Workspace1.se.ini file created: [Scene Explorer] set to [Visible=False]")

        self.Plugin.LogInfo("3dsmax data path: %s" % self.MaxDataPath)
        if (os.path.isfile(self.MaxIni)):
            self.Plugin.LogInfo("3dsmax ini file: %s" % self.MaxIni)
        else:
            self.Plugin.LogWarning("3dsmax ini file does not exist: %s" % self.MaxIni)

        # Create the network log path if it doesn't exist.
        if (not os.path.isdir(networkLogFilePath)):
            self.Plugin.LogInfo("Creating network log path: %s" % networkLogFilePath)
            Directory.CreateDirectory(networkLogFilePath)

        self.NetworkLogFile = os.path.join(networkLogFilePath, "Max.log")
        self.Plugin.LogInfo("Network log file: %s" % self.NetworkLogFile)

        # Create output paths if they don't exist
        self.Plugin.LogInfo("Creating output directories if necessary...")
        self.CreateOutputFolders()

        # Figure out which plugin ini file to use. First check if there is an override in the plugin info file.
        self.MaxPluginIni = self.Plugin.GetPluginInfoEntryWithDefault("OverridePluginIni", "")
        if (self.MaxPluginIni != ""):
            self.MaxPluginIni = os.path.join(self.Plugin.GetPluginDirectory(), self.MaxPluginIni)
            if (not os.path.isfile(self.MaxPluginIni)):
                self.Plugin.FailRender("The alternative plugin ini file %s does not exist" % self.MaxPluginIni)
            self.UsingCustomPluginIni = True
        else:
            # Now check if there is an override in the plugin config file.
            self.MaxPluginIni = self.Plugin.GetConfigEntryWithDefault("AlternatePluginIni", "")
            if (self.MaxPluginIni != ""):
                self.UsingCustomPluginIni = True
            else:
                # Now simply use the plugin ini file in the 3dsmax directory.
                if self.Version < 2013:
                    self.MaxPluginIni = os.path.join(Path.GetDirectoryName(self.MaxRenderExecutable),
                                                     "pluginnetrender.ini")
                    if (not os.path.isfile(self.MaxPluginIni)):
                        self.MaxPluginIni = os.path.join(Path.GetDirectoryName(self.MaxRenderExecutable), "plugin.ini")
                        if (not os.path.isfile(self.MaxPluginIni)):
                            self.Plugin.FailRender(
                                "The plugin ini file %s does not exist, and no alternative plugin.ini file was provided" % self.MaxPluginIni)
                else:
                    self.MaxPluginIni = os.path.join(
                        os.path.join(Path.GetDirectoryName(self.MaxRenderExecutable), self.LanguageSubDir),
                        "pluginnetrender.ini")
                    if (not os.path.isfile(self.MaxPluginIni)):
                        self.MaxPluginIni = os.path.join(
                            os.path.join(Path.GetDirectoryName(self.MaxRenderExecutable), self.LanguageSubDir),
                            "plugin.ini")
                        if (not os.path.isfile(self.MaxPluginIni)):
                            self.Plugin.FailRender(
                                "The plugin ini file %s does not exist, and no alternative plugin.ini file was provided" % self.MaxPluginIni)

        self.Plugin.LogInfo("Plugin ini file: %s" % self.MaxPluginIni)

        if self.UsingCustomPluginIni:
            self.Plugin.LogInfo("Not including user profile plugin.ini because a custom plugin.ini is being used")
        else:
            # Check if we have to use a user profile ini file as well.
            if (self.UseUserProfiles):
                # This is based on the MaxData path.
                self.UserPluginIni = os.path.join(self.MaxDataPath, "pluginnetrender.ini")
                if (not os.path.isfile(self.UserPluginIni)):
                    self.UserPluginIni = os.path.join(self.MaxDataPath, "plugin.ini")
                    if (not os.path.isfile(self.UserPluginIni)):
                        self.UserPluginIni = os.path.join(self.MaxDataPath, "Plugin.UserSettings.ini")

                if (os.path.isfile(self.UserPluginIni)):
                    self.Plugin.LogInfo("Including user profile plugin ini: %s" % self.UserPluginIni)
                else:
                    self.Plugin.LogInfo(
                        "Not including user profile plugin ini because it does not exist: %s" % self.UserPluginIni)
            else:
                self.UserPluginIni = os.path.join(self.MaxDataPath, "Plugin.UserSettings.ini")
                if (os.path.isfile(self.UserPluginIni)):
                    self.Plugin.LogInfo("Including user profile plugin ini: %s" % self.UserPluginIni)
                else:
                    self.Plugin.LogInfo(
                        "Not including user profile plugin ini because it does not exist: %s" % self.UserPluginIni)

        # Determine lightning plugin location.
        if (self.Is64Bit):
            self.LightningPluginFile = os.path.join(self.Plugin.MaxStartupDir,
                                                    "lightning64Max" + str(self.Version) + ".dlx")
        else:
            self.LightningPluginFile = os.path.join(self.Plugin.MaxStartupDir,
                                                    "lightningMax" + str(self.Version) + ".dlx")
        if (not os.path.isfile(self.LightningPluginFile)):
            self.Plugin.FailRender("Lightning connection plugin %s does not exist" % self.LightningPluginFile)
        self.Plugin.LogInfo("Lightning connection plugin: %s" % self.LightningPluginFile)

        # Create temp directory (thread-safe).
        self.TempFolder = self.Plugin.CreateTempDirectory(str(self.Plugin.GetThreadNumber()))
        self.Plugin.LogInfo("Temp folder: " + self.TempFolder)

    # This starts up 3dsmax with our custom plugin ini file, and initially loads the 3dsmax startup scene file,
    # which contains a maxscript callback that runs a startup script which connects 3dsmax to our listening MaxSocket.
    def StartMax(self):
        if (self.FailOnExistingMaxProcess):
            processName = Path.GetFileNameWithoutExtension(self.MaxRenderExecutable)
            if (ProcessUtils.IsProcessRunning(processName)):
                self.Plugin.LogWarning("Found existing %s process" % processName)
                process = Process.GetProcessesByName(processName)[0]
                self.Plugin.FailRender(
                    "FailOnExistingMaxProcess is enabled, and a process %s with pid %d exists - shut down this copy of 3dsmax to enable network rendering on this machine" % (
                        processName, process.Id))

        # Reset where we're at in the 3dsmax network log.
        self.NetworkLogStart()

        # The LoadSaveSceneScripts setting is what runs the callback script we need to initiate the connection to 3dsmax.
        if (os.path.isfile(self.MaxIni)):
            if (FileUtils.GetIniFileSetting(self.MaxIni, "MAXScript", "LoadSaveSceneScripts", "1") != "1"):
                self.Plugin.FailRender(
                    "3dsmax.ini setting in [MAXScript], LoadSaveSceneScripts, is disabled - it must be enabled for deadline to render with 3dsmax")
        else:
            writer = File.CreateText(self.MaxIni)
            writer.WriteLine("[MAXScript]\n")
            writer.WriteLine("LoadSaveSceneScripts=1\n")
            writer.Close()
            self.Plugin.LogInfo("3dsmax.ini file created [MAXScript] [LoadSaveSceneScripts=1]: %s" % self.MaxIni)

        # Initialize the listening socket.
        self.MaxSocket = ListeningSocket()
        self.MaxSocket.StartListening(0, True, True, 10)
        if (not self.MaxSocket.IsListening):
            self.Plugin.FailRender("Failed to open a port for listening to the lightning max daemon")
        else:
            self.Plugin.LogInfo("3dsmax socket connection port: %d" % self.MaxSocket.Port)

        # Create the startup script which is executed by the callback in the 3dsmax startup scene file.
        self.CreateStartupScript(self.MaxSocket.Port)

        # Create our custom plugin ini file, which includes the location of our lightning plugin.
        lightningDir = self.CopyLightningDlx()
        pluginIni = self.CreatePluginInis(lightningDir)

        # This is a workaround for 3dsmax 2010-2012 where the ini file passed to the command line needs to be in the 3dsmax install root folder.
        if self.Version < 2013:
            # This is based on the MaxData path.
            self.Plugin.LogInfo("Copying " + os.path.basename(pluginIni) + " to 3dsmax data path: " + self.MaxDataPath)
            self.Plugin.LogInfo(
                "If this fails, make sure that the necessary permissions are set on this folder to allow for this copy to take place")

            tempPluginIni = pluginIni
            newPluginIni = os.path.join(self.MaxDataPath, os.path.basename(pluginIni))

            shutil.copy2(tempPluginIni, newPluginIni)
            pluginIni = os.path.basename(pluginIni)

        # Setup the command line parameters, and then start max.
        parameters = ""

        if self.Version >= 2013:
            languageOverride = self.Plugin.GetPluginInfoEntryWithDefault("Language", "Default")
            if languageOverride != "Default":
                parameters += " /Language=" + languageOverride

        parameters += " -p \"" + pluginIni + "\" -q"
        if self.UseSlaveMode:
            parameters += " -s"
        if self.UseSilentMode:
            parameters += " -silent"
        if self.IsMaxIO:
            if self.UseSecureMode:
                parameters += " -secure on"
            else:
                parameters += " -secure off"

        parameters = parameters + " \"" + self.MaxStartupFile + "\""

        should_abort = self.Plugin.GetConfigEntryWithDefault("AbortOnArnoldLicenseFail", "Always Fail")
        if should_abort == "Always Fail" or should_abort == "Never Fail":
            self.Plugin.SetProcessEnvironmentVariable("ABORT_ON_ARNOLD_LICENSE_FAIL", should_abort)

        self.LaunchMax(self.MaxRenderExecutable, parameters, Path.GetDirectoryName(self.MaxRenderExecutable))

        # Wait for max to connect to us.
        self.Plugin.LogInfo("Waiting for connection from 3dsmax")
        self.WaitForConnection("3dsmax startup")

        # Now get the version of lightning that we're connected to.
        self.MaxSocket.Send("DeadlineStartup")
        try:
            version = self.MaxSocket.Receive(500)
            if (version.startswith("ERROR: ")):
                self.Plugin.FailRender("Error occurred while getting version from lightning: %s" % version[7:])
            self.Plugin.LogInfo("Connected to 3dsmax plugin: %s" % version)
        except SimpleSocketTimeoutException:
            self.Plugin.FailRender(
                "Timed out waiting for the lightning version to be sent - check the install of lightningMax.dlx\n%s" % self.NetworkLogGet())

    # This tells 3dsmax to load the 3dsmax scene file we want to render. It also configures some other render settings.
    def StartMaxJob(self):
        # Reset where we're at in the 3dsmax network log.
        # self.NetworkLogStart()

        # Get the 3dsmax scene file to render.
        self.MaxFilename = self.Plugin.GetPluginInfoEntryWithDefault("SceneFile", self.Plugin.GetDataFilename())
        if (self.MaxFilename == None):
            self.Plugin.FailRender("No scene file was included with the job")

        self.MaxFilename = RepositoryUtils.CheckPathMapping(self.MaxFilename).replace("/", "\\")
        self.Plugin.LogInfo("Scene file to render: \"%s\"" % self.MaxFilename)

        # Get the cameras.
        self.Camera = self.Plugin.GetPluginInfoEntryWithDefault("Camera", "")
        if (self.Camera == ""):
            self.Plugin.LogInfo("Camera: no camera specified, rendering active viewport")
        else:
            self.Plugin.LogInfo("Camera: \"%s\"" % self.Camera)

        # Get the list of auxiliary filenames.
        self.AuxiliaryFilenames = self.Plugin.GetAuxiliaryFilenames()

        # Check if we are rendering a maxscript job.
        self.MaxScriptJob = self.Plugin.GetBooleanPluginInfoEntryWithDefault("MAXScriptJob", False)
        if (self.MaxScriptJob):
            self.Plugin.LogInfo("This is a MAXScript Job")

            if self.Plugin.GetPluginInfoEntryWithDefault("SceneFile", "") == "":
                # Scene file submitted with job, so maxscript will be the second auxiliary file.
                if (len(self.AuxiliaryFilenames) == 1):
                    self.Plugin.FailRender("A MAXScript job must include a script to execute")
                self.MaxScriptJobScript = self.AuxiliaryFilenames[1]
            else:
                # Scene file not submitted with job, so maxscript will be the first auxiliary file
                if (len(self.AuxiliaryFilenames) == 0):
                    self.Plugin.FailRender("A MAXScript job must include a script to execute")
                self.MaxScriptJobScript = self.AuxiliaryFilenames[0]

            if (not os.path.isfile(self.MaxScriptJobScript)):
                self.Plugin.FailRender(
                    "The maxscript submitted with the MAXScript job, \"%s\", does not exist" % self.MaxScriptJobScript)
            self.Plugin.LogInfo("MAXScript to be executed: \"%s\"" % self.MaxScriptJobScript)

        # Get the RestartEachFrame setting.
        self.RestartEachFrame = self.Plugin.GetBooleanPluginInfoEntryWithDefault("RestartRendererMode", False)
        self.Plugin.LogInfo("Restarting renderer after each frame: %d" % self.RestartEachFrame)

        # Get the ShowFrameBuffer setting.
        self.ShowFrameBuffer = self.Plugin.GetBooleanPluginInfoEntryWithDefault("ShowFrameBuffer", True)
        self.Plugin.LogInfo("Showing frame buffer: %d" % self.ShowFrameBuffer)

        # Get the single job region rendering setting.
        self.RegionRenderingSingleJob = self.Plugin.IsTileJob()
        self.RegionRenderingIndex = self.Plugin.GetCurrentTaskId()

        # Get the RenderOutputOverride setting.
        if self.RegionRenderingSingleJob:
            self.RenderOutputOverride = self.Plugin.GetPluginInfoEntryWithDefault(
                "RegionFilename" + self.RegionRenderingIndex, "").strip()
        else:
            self.RenderOutputOverride = self.Plugin.GetPluginInfoEntryWithDefault("RenderOutput", "").strip()

        if (self.RenderOutputOverride != ""):
            self.RedirectOutput = True
            self.RenderOutputOverride = RepositoryUtils.CheckPathMapping(self.RenderOutputOverride).replace("/", "\\")
            self.Plugin.LogInfo("Overriding render output: \"%s\"" % self.RenderOutputOverride)

        # Get the OverrideSaveFile setting.
        if self.Plugin.GetBooleanPluginInfoEntryWithDefault("SaveFile",
                                                            True) == self.Plugin.GetBooleanPluginInfoEntryWithDefault(
            "SaveFile", False):
            self.OverrideSaveFile = True
            self.SaveFile = self.Plugin.GetBooleanPluginInfoEntry("SaveFile")
            self.Plugin.LogInfo("Overriding save file option: %s" % self.SaveFile)

        # Get the FrameNumberBase setting.
        self.FrameNumberBase = self.Plugin.GetIntegerPluginInfoEntryWithDefault("FrameNumberBase", 0)
        self.Plugin.LogInfo("Frame number base: %d" % self.FrameNumberBase)

        # Get the RemovePadding setting.
        self.RemovePadding = self.Plugin.GetBooleanPluginInfoEntryWithDefault("RemovePadding", False)
        self.Plugin.LogInfo("Remove padding from output filename: %d" % self.RemovePadding)

        # Get the Gamma Correction settings.
        self.GammaCorrection = self.Plugin.GetBooleanPluginInfoEntryWithDefault("GammaCorrection", False)
        self.Plugin.LogInfo("Enable gamma correction: %d" % self.GammaCorrection)
        if self.GammaCorrection:
            self.GammaInput = 1.0
            self.GammaOutput = self.Plugin.GetFloatPluginInfoEntryWithDefault("GammaOutput", 1.0)
            self.Plugin.LogInfo("Gamma Input: %s" % self.GammaInput)
            self.Plugin.LogInfo("Gamma Output: %s" % self.GammaOutput)

        # Get the IgnoreMissingExternalFiles setting.
        self.IgnoreMissingExternalFiles = self.Plugin.GetBooleanPluginInfoEntryWithDefault("IgnoreMissingExternalFiles",
                                                                                           True)
        self.Plugin.LogInfo("Ignore missing external file errors: %d" % self.IgnoreMissingExternalFiles)

        # Get the IgnoreMissingUVWs setting.
        self.IgnoreMissingUVWs = self.Plugin.GetBooleanPluginInfoEntryWithDefault("IgnoreMissingUVWs", True)
        self.Plugin.LogInfo("Ignore missing UVW errors: %d" % self.IgnoreMissingUVWs)

        # Get the IgnoreMissingXREFs setting.
        self.IgnoreMissingXREFs = self.Plugin.GetBooleanPluginInfoEntryWithDefault("IgnoreMissingXREFs", True)
        self.Plugin.LogInfo("Ignore missing XREF errors: %d" % self.IgnoreMissingXREFs)

        # Get the IgnoreMissingDLLs setting.
        self.IgnoreMissingDLLs = self.Plugin.GetBooleanPluginInfoEntryWithDefault("IgnoreMissingDLLs", False)
        self.Plugin.LogInfo("Ignore missing DLL errors: %d" % self.IgnoreMissingDLLs)

        # Get the DisableMultipass setting.
        self.DisableMultipass = self.Plugin.GetBooleanPluginInfoEntryWithDefault("DisableMultipass", False)
        self.Plugin.LogInfo("Disabling Multipass: %d" % self.DisableMultipass)

        # Get the Ignore Render Elements By Name setting.
        self.IgnoreRenderElementsByName = []
        elementIndex = 0
        while True:
            elementToIgnore = self.Plugin.GetPluginInfoEntryWithDefault(
                "IgnoreRenderElementsByName" + str(elementIndex), "")
            if elementToIgnore != "":
                self.IgnoreRenderElementsByName.append(elementToIgnore)
            else:
                break
            elementIndex = elementIndex + 1

        # Get the Ignore Render Elements setting.
        self.IgnoreRenderElements = self.Plugin.GetBooleanPluginInfoEntryWithDefault("IgnoreRenderElements", False)
        if (self.IgnoreRenderElements):
            self.Plugin.LogInfo("Render elements will not be saved")
        elif (len(self.IgnoreRenderElementsByName) > 0):
            self.Plugin.LogInfo("The following elements will not be saved")
            for elementToIgnore in self.IgnoreRenderElementsByName:
                self.Plugin.LogInfo("   " + elementToIgnore)

        # Get the UseJpegOutput settings.
        self.UseJpegOutput = self.Plugin.GetBooleanPluginInfoEntryWithDefault("UseJpegOutput", False)
        self.JpegOutputPath = self.Plugin.GetPluginInfoEntryWithDefault("JpegOutputPath", "").strip()
        if (self.UseJpegOutput and self.JpegOutputPath == ""):
            self.UseJpegOutput = False
            self.Plugin.LogWarning("Disabling saving of jpeg output because JpegOutputPath was not specified")
        if (self.UseJpegOutput):
            if (not self.JpegOutputPath.endswith("\\") or not self.JpegOutputPath.endswith("/")):
                self.JpegOutputPath = self.JpegOutputPath + "\\"

            self.JpegOutputPath = RepositoryUtils.CheckPathMapping(self.JpegOutputPath).replace("/", "\\")
            self.Plugin.LogInfo("Saving jpeg copy of original output file to: \"%s\"" % self.JpegOutputPath)

        # Get the FailOnBlackFrames settings.
        self.FailOnBlackFrames = self.Plugin.GetBooleanPluginInfoEntryWithDefault("FailOnBlackFrames", False)
        self.BlackFramesCheckRenderElements = self.Plugin.GetBooleanPluginInfoEntryWithDefault(
            "BlackFramesCheckRenderElements", False)
        self.BlackPixelPercentage = self.Plugin.GetIntegerPluginInfoEntryWithDefault("BlackPixelPercentage", 0)
        self.BlackPixelThreshold = self.Plugin.GetFloatPluginInfoEntryWithDefault("BlackPixelThreshold", 0.0)
        if (self.FailOnBlackFrames):
            if (self.BlackPixelPercentage < 0):
                self.BlackPixelPercentage = 0
            if (self.BlackPixelPercentage > 100):
                self.BlackPixelPercentage = 100
            if (self.BlackPixelThreshold < 0.0):
                self.BlackPixelThreshold = 0.0
            if (self.BlackPixelThreshold > 1.0):
                self.BlackPixelThreshold = 1.0
            self.Plugin.LogInfo(
                "Fail on black frames enabled: black pixel percentage = %d, black pixel threshold = %.4f, check render elements = %s" % (
                    self.BlackPixelPercentage, self.BlackPixelThreshold, self.BlackFramesCheckRenderElements))

        self.DisableAltOutput = self.Plugin.GetBooleanConfigEntryWithDefault("DisableAltOutput", False)
        if self.DisableAltOutput:
            self.Plugin.LogInfo("Disabling saving alternate output")

        # Get the RegionRendering settings.
        self.RegionRendering = self.Plugin.GetBooleanPluginInfoEntryWithDefault("RegionRendering", False)
        self.RegionPadding = self.Plugin.GetIntegerPluginInfoEntryWithDefault("RegionPadding", 0)
        self.RegionAnimation = self.Plugin.GetBooleanPluginInfoEntryWithDefault("RegionAnimation", False)
        self.RegionType = self.Plugin.GetPluginInfoEntryWithDefault("RegionType", "CROP").upper()

        if self.RegionRenderingSingleJob:
            if not self.RegionAnimation:
                self.RegionLeft = self.Plugin.GetIntegerPluginInfoEntryWithDefault(
                    "RegionLeft" + self.RegionRenderingIndex, 0)
                self.RegionTop = self.Plugin.GetIntegerPluginInfoEntryWithDefault(
                    "RegionTop" + self.RegionRenderingIndex, 0)
                self.RegionRight = self.Plugin.GetIntegerPluginInfoEntryWithDefault(
                    "RegionRight" + self.RegionRenderingIndex, 0)
                self.RegionBottom = self.Plugin.GetIntegerPluginInfoEntryWithDefault(
                    "RegionBottom" + self.RegionRenderingIndex, 0)
            else:
                self.RegionLeftArray = self.Plugin.GetPluginInfoEntryWithDefault(
                    "RegionLeft" + self.RegionRenderingIndex, "0")
                self.RegionTopArray = self.Plugin.GetPluginInfoEntryWithDefault("RegionTop" + self.RegionRenderingIndex,
                                                                                "0")
                self.RegionRightArray = self.Plugin.GetPluginInfoEntryWithDefault(
                    "RegionRight" + self.RegionRenderingIndex, "0")
                self.RegionBottomArray = self.Plugin.GetPluginInfoEntryWithDefault(
                    "RegionBottom" + self.RegionRenderingIndex, "0")
                self.RegionLeftArray = map(int, self.RegionLeftArray.split(','))
                self.RegionTopArray = map(int, self.RegionTopArray.split(','))
                self.RegionRightArray = map(int, self.RegionRightArray.split(','))
                self.RegionBottomArray = map(int, self.RegionBottomArray.split(','))
        else:
            if not self.RegionAnimation:
                self.RegionLeft = self.Plugin.GetIntegerPluginInfoEntryWithDefault("RegionLeft", 0)
                self.RegionTop = self.Plugin.GetIntegerPluginInfoEntryWithDefault("RegionTop", 0)
                self.RegionRight = self.Plugin.GetIntegerPluginInfoEntryWithDefault("RegionRight", 0)
                self.RegionBottom = self.Plugin.GetIntegerPluginInfoEntryWithDefault("RegionBottom", 0)
            else:
                self.RegionLeftArray = self.Plugin.GetPluginInfoEntryWithDefault("RegionLeft", "0")
                self.RegionTopArray = self.Plugin.GetPluginInfoEntryWithDefault("RegionTop", "0")
                self.RegionRightArray = self.Plugin.GetPluginInfoEntryWithDefault("RegionRight", "0")
                self.RegionBottomArray = self.Plugin.GetPluginInfoEntryWithDefault("RegionBottom", "0")
                self.RegionLeftArray = map(int, self.RegionLeftArray.split(','))
                self.RegionTopArray = map(int, self.RegionTopArray.split(','))
                self.RegionRightArray = map(int, self.RegionRightArray.split(','))
                self.RegionBottomArray = map(int, self.RegionBottomArray.split(','))

        if (self.RegionRendering):
            self.Plugin.LogInfo(
                "Region rendering enabled: left = %d, top = %d, right = %d, bottom = %d, padding = %d, type = %s" % (
                    self.RegionLeft, self.RegionTop, self.RegionRight, self.RegionBottom, self.RegionPadding,
                    self.RegionType))

        # Get the PreFrameScript setting.
        self.PreFrameScript = self.Plugin.GetPluginInfoEntryWithDefault("PreFrameScript", "").strip().strip("\"")
        if (self.PreFrameScript != ""):
            if (not Path.IsPathRooted(self.PreFrameScript)):
                self.PreFrameScript = os.path.join(self.Plugin.GetJobsDataDirectory(), self.PreFrameScript)
            else:
                self.PreFrameScript = RepositoryUtils.CheckPathMapping(self.PreFrameScript).replace("/", "\\")
            self.Plugin.LogInfo("Pre frame script: \"%s\"" % self.PreFrameScript)

        # Get the PostFrameScript setting.
        self.PostFrameScript = self.Plugin.GetPluginInfoEntryWithDefault("PostFrameScript", "").strip().strip("\"")
        if (self.PostFrameScript != ""):
            if (not Path.IsPathRooted(self.PostFrameScript)):
                self.PostFrameScript = os.path.join(self.Plugin.GetJobsDataDirectory(), self.PostFrameScript)
            else:
                self.PostFrameScript = RepositoryUtils.CheckPathMapping(self.PostFrameScript).replace("/", "\\")
            self.Plugin.LogInfo("Post frame script: \"%s\"" % self.PostFrameScript)

        # Get the PreLoadScript setting.
        self.PreLoadScript = self.Plugin.GetPluginInfoEntryWithDefault("PreLoadScript", "").strip().strip("\"")
        if (self.PreLoadScript != ""):
            if (not Path.IsPathRooted(self.PreLoadScript)):
                self.PreLoadScript = os.path.join(self.Plugin.GetJobsDataDirectory(), self.PreLoadScript)
            else:
                self.PreLoadScript = RepositoryUtils.CheckPathMapping(self.PreLoadScript).replace("/", "\\")
            self.Plugin.LogInfo("Pre load script: \"%s\"" % self.PreLoadScript)

        # Get the PostLoadScript setting.
        self.PostLoadScript = self.Plugin.GetPluginInfoEntryWithDefault("PostLoadScript", "").strip().strip("\"")
        if self.PostLoadScript != "":
            if not Path.IsPathRooted(self.PostLoadScript):
                self.PostLoadScript = os.path.join(self.Plugin.GetJobsDataDirectory(), self.PostLoadScript)
            else:
                self.PostLoadScript = RepositoryUtils.CheckPathMapping(self.PostLoadScript).replace("/", "\\")
            self.Plugin.LogInfo("Post load script: \"%s\"" % self.PostLoadScript)

        # Get the Path Configuration File setting.
        self.PathConfigFile = self.Plugin.GetPluginInfoEntryWithDefault("PathConfigFile", "").strip().strip("\"")
        if self.PathConfigFile != "":
            if not Path.IsPathRooted(self.PathConfigFile):
                self.PathConfigFile = os.path.join(self.Plugin.GetJobsDataDirectory(), self.PathConfigFile)
            else:
                self.PathConfigFile = RepositoryUtils.CheckPathMapping(self.PathConfigFile).replace("/", "\\")
            self.Plugin.LogInfo("Path configuration file (*.mxp): \"%s\"" % self.PathConfigFile)

            self.MergePathConfigFile = self.Plugin.GetBooleanPluginInfoEntryWithDefault("MergePathConfigFile", False)
            self.Plugin.LogInfo("Merge configuration file: %d" % self.MergePathConfigFile)

        # Execute pre load script if it is specified.
        if self.PreLoadScript != "":
            self.ExecuteMaxScriptFile(self.PreLoadScript)

        # A behind-the-scenes pre load script. 3dsMax fails to load the scene if the asset file paths don't exist.
        # This will change the paths in the scene file and if the scene file wasn't submitted it will create a copy.
        pathMappingScript = os.path.join(self.Plugin.GetPluginDirectory(), "preloadPathMapping.ms")
        slaveInfo = RepositoryUtils.GetSlaveInfo(self.Plugin.GetSlaveName(), True)
        pathMapAssets = slaveInfo.IsAWSPortalInstance or self.Plugin.GetBooleanConfigEntryWithDefault(
            "EnableAssetFilePathMapping", True)
        if os.path.isfile(pathMappingScript) and pathMapAssets:
            self.MaxSocket.Send("SlaveFolders,\"" + self.Plugin.GetJobsDataDirectory().replace("\\",
                                                                                               "/") + "\",\"" + self.Plugin.GetPluginDirectory().replace(
                "\\", "/") + "\"")
            newFileName = self.ExecuteMaxScriptFile(pathMappingScript, returnAsString=True)

            if newFileName != "":
                self.MaxFilename = newFileName

        # Load the max file.
        self.LoadMaxFile()

        # A behind-the-scenes post load script.
        # This will handle the paths that are not registered with the AssetTracker.
        pathMappingScriptFix = os.path.join(self.Plugin.GetPluginDirectory(), "postloadPathMapping.ms")
        slaveInfo = RepositoryUtils.GetSlaveInfo(self.Plugin.GetSlaveName(), True)
        pathMapAssets = slaveInfo.IsAWSPortalInstance or self.Plugin.GetBooleanConfigEntryWithDefault(
            "EnableAssetFilePathMapping", True)
        if os.path.isfile(pathMappingScriptFix) and pathMapAssets:
            self.MaxSocket.Send("SlaveFolders,\"" + self.Plugin.GetJobsDataDirectory().replace("\\",
                                                                                               "/") + "\",\"" + self.Plugin.GetPluginDirectory().replace(
                "\\", "/") + "\"")
            self.ExecuteMaxScriptFile(pathMappingScriptFix)

        # Execute post load script if it is specified.
        if self.PostLoadScript != "":
            self.ExecuteMaxScriptFile(self.PostLoadScript)

    # This renders the current task.
    def RenderTasks(self):
        # Check if we should just skip the rendering part (which might be the case if this is a FumeFX sim).
        if not self.Plugin.GetBooleanPluginInfoEntryWithDefault("SkipRender", False):

            if self.Plugin.IsDBRJob:
                dbrJobFrame = self.Plugin.GetIntegerPluginInfoEntryWithDefault("DBRJobFrame", 0)
                self.Plugin.LogInfo(self.Plugin.Prefix + "Rendering frame " + str(dbrJobFrame))

                self.StartFrame = dbrJobFrame
                self.EndFrame = dbrJobFrame
            else:
                if self.RegionRenderingSingleJob:
                    self.StartFrame = self.Plugin.GetStartFrame()
                    self.EndFrame = self.Plugin.GetStartFrame()
                else:
                    self.StartFrame = self.Plugin.GetStartFrame()
                    self.EndFrame = self.Plugin.GetEndFrame()

            self.Plugin.VerifyMonitoredManagedProcess(self.ProgramName)

            self.Plugin.SetProgress(0.0)

            denominator = self.EndFrame - self.StartFrame + 1.0

            # Render every frame, one at a time.
            frame = self.StartFrame
            while frame <= self.EndFrame:
                shot_obj = RenderShot(job=self.Plugin.GetJob(), task_id=self.Plugin.GetCurrentTaskId(), frame=frame,
                                      logger=self.Plugin.LogInfo)
                shot_obj.start_shot()
                self.RenderFrame(frame)

                if denominator != 0:
                    progress = ((frame - self.StartFrame + 1.0) / denominator) * 100.0
                    self.Plugin.SetProgress(progress)

                self.Plugin.VerifyMonitoredManagedProcess(self.ProgramName)
                shot_obj.stop_shot()
                frame = frame + 1
            #### add for render material
            material_postRenderScript = os.path.join(self.Plugin.GetPluginDirectory(), "Render_material_post.ms")
            self.Plugin.LogInfo( " ++++   >>  material_postRenderScript = {}".format( material_postRenderScript ))
            if os.path.isfile(material_postRenderScript) :
                self.Plugin.LogInfo( " ++++   >>  Run material_postRenderScript " )
                self.ExecuteMaxScriptFile(material_postRenderScript)
            #### add for render material
            self.Plugin.SetProgress(100.0)
        else:
            self.Plugin.LogInfo("Skipping frame rendering because 'Disable Frame Rendering' is enabled")

    # This tells 3dsmax to unload the current scene file.
    def EndMaxJob(self):
        if (not self.Plugin.MonitoredManagedProcessIsRunning(self.ProgramName)):
            self.Plugin.LogWarning("3ds Max was shut down before the proper shut down sequence")
        else:
            response = ""

            # If an error occurs while sending EndJob, set the response so that we don't enter the while loop below.
            try:
                self.MaxSocket.Send("EndJob")
            except Exception as e:
                response = ("ERROR: Error sending EndJob command: %s" % e.Message)

            timeout = 5
            startTime = DateTime.Now
            while (DateTime.Now.Subtract(startTime).TotalSeconds < timeout and response == ""):
                try:
                    response = self.MaxSocket.Receive(100)

                    # If this is a STDOUT message, print it out and reset 'response' so that we keep looping
                    match = self.StdoutRegex.Match(response)
                    if (match.Success):
                        self.Plugin.LogInfo(match.Groups[1].Value)
                        response = ""

                    # If this is a WARN message, print it out and reset 'response' so that we keep looping
                    match = self.WarnRegex.Match(response)
                    if (match.Success):
                        self.Plugin.LogWarning(match.Groups[1].Value)
                        response = ""

                except Exception as e:
                    if (not isinstance(e, SimpleSocketTimeoutException)):
                        response = ("ERROR: Error when waiting for renderer to close: %s" % e.Message)

            if (response == ""):
                self.Plugin.LogWarning("Timed out waiting for the renderer to close.")

            if (response.startswith("ERROR: ")):
                self.Plugin.LogWarning(response[7:])

            if (not response.startswith("SUCCESS")):
                self.Plugin.LogWarning("Did not receive a success message in response to EndJob: %s" % response)

    # This disconnects the socket connection with 3dsmax, and then shuts 3dsmax down.
    def ShutdownMax(self):
        self.DeletePluginInis()
        self.DeleteStartupKillScript()

        self.Plugin.LogInfo("Disconnecting socket connection to 3dsmax")
        try:
            if self.MaxSocket != None:
                self.MaxSocket.Disconnect(True)
        except Exception as e:
            self.Plugin.LogWarning("Error disconnecting socket connection to 3dsmax: %s" % e.Message)

        if (not self.Plugin.MonitoredManagedProcessIsRunning(self.ProgramName)):
            self.Plugin.LogWarning("The 3ds Max process has already quit")
        else:
            # processIDs = self.Plugin.GetMonitoredManagedProcessIDs( self.ProgramName )
            # self.Plugin.LogInfo( "3dsmax process has %d objects" % len( processIDs ) )

            self.Plugin.LogInfo("Waiting for 3ds Max to shut down")
            self.Plugin.ShutdownMonitoredManagedProcess(self.ProgramName)
            # SystemUtils.Sleep( 10000 )

            # self.Plugin.LogInfo( "Terminating 3dsmax child processes" )
            # for id in processIDs:
            #    ProcessUtils.KillParentAndChildProcesses( id )

            # self.Plugin.ShutdownMonitoredManagedProcess( self.ProgramName )

            self.Plugin.LogInfo("3ds Max has shut down")

    ########################################################################
    ## Helper functions
    ########################################################################
    def GetDBRSettings(self):
        # DBR Settings
        self.DBRUseIPAddresses = True

    def GetVrayDBRSettings(self):
        self.VrayDBRDynamicStart = self.Plugin.GetBooleanConfigEntryWithDefault("VRayDBRDynamicStart", False)
        self.VrayDBRPortRange = self.Plugin.GetConfigEntryWithDefault("VRayDBRPortRange", "20204")
        self.VrayDBRUseLocalMachine = self.Plugin.GetBooleanConfigEntryWithDefault("VRayDBRUseLocalMachine", True)
        self.VrayDBRTransferMissingAssets = self.Plugin.GetBooleanConfigEntryWithDefault("VRayDBRTransferMissingAssets",
                                                                                         False)
        self.VrayDBRUseCachedAssets = self.Plugin.GetBooleanConfigEntryWithDefault("VRayDBRUseCachedAssets", False)
        self.VrayDBRCacheLimitType = self.Plugin.GetConfigEntryWithDefault("VRayDBRCacheLimitType", "None")
        self.VrayDBRCacheLimit = self.Plugin.GetConfigEntryWithDefault("VRayDBRCacheLimit", "100.000000")

    def GetVrayRtDBRSettings(self):
        self.VrayRtDBRDynamicStart = self.Plugin.GetBooleanConfigEntryWithDefault("VRayRTDBRDynamicStart", False)
        self.VrayRtDBRPortRange = self.Plugin.GetConfigEntryWithDefault("VRayRTDBRPortRange", "20206")
        self.VrayRtDBRAutoStartLocalSlave = self.Plugin.GetBooleanConfigEntryWithDefault("VRayRTDBRUseLocalMachine",
                                                                                         True)

    def GetMentalRaySettings(self):
        # Mental Ray Settings
        self.MentalRaySatPortNumber = self.Plugin.GetConfigEntryWithDefault("MentalRaySatPortNumber%i" % self.Version,
                                                                            "")

    def GetCoronaSettings(self):
        # Corona DBR Settings
        self.CoronaDRServerNoGui = self.Plugin.GetBooleanConfigEntryWithDefault("CoronaDRServerNoGui", False)

    def GetDBRMachines(self):
        currentJob = self.Plugin.GetJob()
        machines = list(RepositoryUtils.GetMachinesRenderingJob(currentJob.JobId, self.DBRUseIPAddresses, False))
        machines = [x.lower() for x in machines]  # Ensure all machine names are lowercase

        localFQDN = (Environment2.FullyQualifiedDomainName).lower()
        localMachineName = (Environment2.MachineName).lower()
        localCleanMachineName = (Environment2.CleanMachineName).lower()

        slaveName = self.Plugin.GetSlaveName()
        slaveInfo = RepositoryUtils.GetSlaveInfo(slaveName, True)
        localIPAddress = SlaveUtils.GetMachineIPAddresses([slaveInfo])[0]

        while localFQDN in machines: machines.remove(localFQDN)
        while localMachineName in machines: machines.remove(localMachineName)
        while localCleanMachineName in machines: machines.remove(localCleanMachineName)
        while localIPAddress in machines: machines.remove(localIPAddress)

        return machines

    def GetDBRConfigFile(self):
        if self.Plugin.VrayDBRJob:
            # Config file is in the plugcfg file, which the MaxController already knows about.
            configFile = os.path.join(self.MaxPlugCfg, "vray_dr.cfg")
        elif self.Plugin.VrayRtDBRJob:
            # Config file is in the plugcfg file, which the MaxController already knows about.
            configFile = os.path.join(self.MaxPlugCfg, "vrayrt_dr.cfg")
        elif self.Plugin.MentalRayDBRJob:
            # Figure out where the max.rayhosts file is located.
            configDirectory = Path.GetDirectoryName(self.MaxRenderExecutable)

            # The config directory for the max.rayhosts file is different for different versions of max.
            if self.Version <= 2010:
                configDirectory = os.path.join(configDirectory, "mentalray")
            elif self.Version >= 2011:
                mainDir = configDirectory
                configDirectory = os.path.join(self.TempFolder, "mentalRayHosts")
                if self.Version <= 2014:
                    self.Plugin.SetProcessEnvironmentVariable("MAX2011_MI_ROOT", configDirectory)
                else:
                    self.Plugin.SetProcessEnvironmentVariable("MAX%i_MI_ROOT" % self.Version, configDirectory)

                rayFile = os.path.join(configDirectory, "rayrc")
                if (not os.path.isdir(configDirectory)):
                    Directory.CreateDirectory(configDirectory)

                if self.Version >= 2011 and self.Version <= 2012:
                    mainDir = os.path.join(mainDir, "mentalimages")
                else:
                    mainDir = os.path.join(mainDir, "NVIDIA")
                mainRayFile = os.path.join(mainDir, "rayrc")
                shutil.copy2(mainRayFile, rayFile)
                fileLines = File.ReadAllLines(rayFile)
                newLines = []
                for line in fileLines:
                    line = line.replace("\".", "\"" + mainDir + "\\.")
                    line = line.replace(";.", ";" + mainDir + "\\.")
                    newLines.append(line)
                File.WriteAllLines(rayFile, newLines)

            configFile = os.path.join(configDirectory, "max.rayhosts")
        elif self.Plugin.CoronaDBRJob:
            configFile = os.path.join(self.TempFolder, "coronaDRSlaves.txt")
            self.Plugin.SetProcessEnvironmentVariable("DEADLINE_CORONA_CONFIG_FILE", configFile)

        return configFile

    def UpdateVrayDBRConfigFile(self, machines, configFile):
        writer = File.CreateText(configFile)

        for machine in machines:
            if machine != "":
                writer.WriteLine("%s 1 %s\n" % (machine, self.VrayDBRPortRange))

        writer.WriteLine(
            "restart_slaves 0\n")  # no point restarting Worker after end of render as the job will be completed and V-Ray Spawner will be shutdown.
        writer.WriteLine(
            "list_in_scene 0\n")  # we should never respect the V-Ray spawners as declared/saved in the max scene file.
        writer.WriteLine(
            "max_servers 0\n")  # we should always try to use ALL V-Ray spawners that are configured in the cfg file.

        if self.VrayDBRUseLocalMachine:
            writer.WriteLine("use_local_machine 1\n")
        else:
            writer.WriteLine("use_local_machine 0\n")

        if self.VrayDBRTransferMissingAssets:
            writer.WriteLine("transfer_missing_assets 1\n")
        else:
            writer.WriteLine("transfer_missing_assets 0\n")

        if self.VrayDBRUseCachedAssets:
            writer.WriteLine("use_cached_assets 1\n")
        else:
            writer.WriteLine("use_cached_assets 0\n")

        if self.VrayDBRCacheLimitType == "None":
            writer.WriteLine("cache_limit_type 0\n")
        if self.VrayDBRCacheLimitType == "Age (hours)":
            writer.WriteLine("cache_limit_type 1\n")
        if self.VrayDBRCacheLimitType == "Size (GB)":
            writer.WriteLine("cache_limit_type 2\n")

        writer.WriteLine("cache_limit %s\n" % self.VrayDBRCacheLimit)
        writer.Close()

    def UpdateVrayRtDBRConfigFile(self, machines, configFile):
        writer = File.CreateText(configFile)

        for machine in machines:
            if machine != "":
                writer.WriteLine("%s 1 %s\n" % (machine, self.VrayRtDBRPortRange))

        if self.VrayRtDBRAutoStartLocalSlave:
            writer.WriteLine("autostart_local_slave 1\n")
        else:
            writer.WriteLine("autostart_local_slave 0\n")

        writer.Close()

    def UpdateMentalRayConfigFile(self, machines, configFile):
        # Mental Ray - write out machine names, one entry per line into configFile, incl. port number if defined. If not, use default.
        writer = File.CreateText(configFile)

        for machine in machines:
            if machine != "":
                if self.MentalRaySatPortNumber != "":
                    writer.WriteLine("%s:%s\n" % (machine, self.MentalRaySatPortNumber))
                else:
                    writer.WriteLine("%s\n" % machine)

        writer.Close()

    def UpdateCoronaConfigFile(self, machines, configFile):
        # Corona - Write out machine names, one entry per line into configFile.

        with io.open(configFile, mode="w", encoding="utf-8") as configFileHandle:
            for machine in machines:
                if machine != "":
                    configFileHandle.write("%s\n" % machine)

    def SetupCoronaDR(self):
        setupScript = os.path.join(self.Plugin.GetPluginDirectory(), "setupCoronaDR.ms")
        if (os.path.isfile(setupScript)):
            self.ExecuteMaxScriptFile(setupScript)

    def AutoCheckRegistryForLanguage(self, installDirectory, keyName, languageCode, autoDetectedLanguageCode):
        if (autoDetectedLanguageCode == ""):
            tempInstallDir = SystemUtils.GetRegistryKeyValue(keyName + languageCode, "Installdir", "")
            if (tempInstallDir != ""):
                tempInstallDir = tempInstallDir.lower().replace("/", "\\").rstrip("\\")
                if (tempInstallDir == installDirectory.lower().replace("/", "\\").rstrip("\\")):
                    autoDetectedLanguageCode = languageCode
        return autoDetectedLanguageCode

    def AutoCheckRegistry(self, filenameOnly, keyName, valueName, autoDetectedDirectory):
        if (autoDetectedDirectory == ""):
            tempDirectory = SystemUtils.GetRegistryKeyValue(keyName, valueName, "")
            if (tempDirectory != "" and os.path.isfile(os.path.join(tempDirectory, filenameOnly))):
                autoDetectedDirectory = tempDirectory
        return autoDetectedDirectory

    # def Hack3dsmaxCommand( self ):
    #     cmdExe = "3dsmaxcmdio.exe" if self.IsMaxIO else "3dsmaxcmd.exe"

    #     maxCmd = PathUtils.ChangeFilename( self.MaxRenderExecutable, cmdExe )
    #     if( os.path.isfile( maxCmd ) ):
    #         line = self.Run3dsmaxCommand( maxCmd )
    #         self.Plugin.LogInfo( "%s returned: %s" % ( cmdExe, line ) )

    #         maxInstallDirectory = Path.GetDirectoryName( self.MaxRenderExecutable ).lower().replace( "/", "\\" ).rstrip( "\\" )

    #         # in max 6, the file quoted is ""
    #         # in max 7, it is "c:\3dsmax7\", but that could change based on where max is installed
    #         # in max 8 and later, the date/time is printed out on the line before "Error opening..."
    #         # in newer versions of max, this output can differ depending on the region, so we can't really check that anymore (a plus though is that often a popup will come up if the max install is messed up)
    #         if( line.find( "Error initializing max backburner plugin" ) >= 0 or line.find( "Error initializing backburner path system" ) >= 0 ):
    #             self.Plugin.FailRender( "An error occurred while initializing Backburner. Please install or upgrade Backburner on this machine and try again." )
    #         #elif( line.find( "Error opening scene file: \"" ) < 0 ):
    #         #elif( line.lower().replace( "/", "\\" ).find( maxInstallDirectory ) < 0 ):
    #         #    self.Plugin.FailRender( "There was an error running 3dsmaxcmd.exe. This may be caused by an incorrect or out of date install of 3dsmax. Try updating 3dsmax on this machine and try again." )
    #         else:
    #             self.Plugin.LogInfo( "Render sanity check using %s completed successfully. Please ignore the 'Error opening...' message thrown by %s above." % ( cmdExe, cmdExe ) )
    #     else:
    #         self.Plugin.FailRender( "Could not find %s at %s. This may be caused by an incorrect or out of date install of 3ds Max. Try updating 3ds Max on this machine and try again." % ( cmdExe, maxCmd ) )

    # def Run3dsmaxCommand( self, maxCmd ):
    #     startTime = DateTime.Now
    #     freshline = ""
    #     line = ""
    #     popupHandler = PopupHandler()

    #     mcmd = ChildProcess()
    #     mcmd.ControlStdOut = True
    #     mcmd.TerminateOnExit = True
    #     mcmd.HideWindow = True
    #     mcmd.UseProcessTree = True
    #     mcmd.Launch( maxCmd, "", Path.GetDirectoryName( maxCmd ) )

    #     while( DateTime.Now.Subtract( startTime ).TotalSeconds < self.RunSanityCheckTimeout and ( mcmd.IsRunning() or mcmd.IsStdoutAvailable() ) ):
    #         blockingDialogMessage = popupHandler.CheckForPopups( mcmd )
    #         if( blockingDialogMessage != "" ):
    #             mcmd.Terminate()
    #             self.Plugin.FailRender( "Dialog box detected while trying to run the 3ds Max command line renderer, %s\nThis may be caused by an incorrect install of 3ds Max.\n%s" % (mcmd, blockingDialogMessage) )

    #         start = DateTime.Now.Ticks
    #         while( TimeSpan.FromTicks( DateTime.Now.Ticks - start ).Milliseconds < 500 ):
    #             result, freshline = mcmd.GetStdoutLine( freshline )
    #             if result:
    #                 if( freshline != "" ):
    #                     line = freshline
    #             else:
    #                 SystemUtils.Sleep( 50 )

    #     if( mcmd.IsRunning() ):
    #         mcmd.Terminate()
    #         self.Plugin.FailRender( "The 3ds Max command line renderer, %s, hung during the verification of the 3ds Max install" % maxCmd )

    #     self.Plugin.LogInfo( "3ds Max Cmd exit code: %s" % mcmd.GetExitCode() )

    #     mcmd.Reset()
    #     mcmd = None

    #     return line

    def NetworkLogStart(self):
        self.NetworkLogValid = False
        self.NetworkLogError = ""
        try:
            self.NetworkLogFileSize = 0
            if os.path.isfile(self.NetworkLogFile):
                self.NetworkLogFileSize = FileUtils.GetFileSize(self.NetworkLogFile)

            if (self.NetworkLogFileSize > 0):
                stream = FileStream(self.NetworkLogFile, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)
                reader = StreamReader(stream)
                reader.BaseStream.Seek(max(self.NetworkLogFileSize - 192, 0), SeekOrigin.Begin)
                self.NetworkLogFilePostfix = reader.ReadToEnd()
                reader.Close()
                stream.Close()
            else:
                self.NetworkLogFileSize = 0
                self.NetworkLogFilePostfix = ""

            self.NetworkLogValid = True
        except IOException as e:
            self.Plugin.LogWarning("Cannot start network log because: " + e.Message)
            self.NetworkLogError = e.Message

    def NetworkLogGet(self):
        if self.NetworkLogValid:
            attempts = 0
            while attempts < 5:
                try:
                    if os.path.isfile(self.NetworkLogFile):
                        stream = FileStream(self.NetworkLogFile, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)
                        reader = StreamReader(stream)
                        if (self.NetworkLogFileSize >= 0):
                            reader.BaseStream.Seek(max(self.NetworkLogFileSize - 2048, 0), SeekOrigin.Begin)
                        networkLog = reader.ReadToEnd()
                        reader.Close()
                        stream.Close()

                        index = networkLog.find(self.NetworkLogFilePostfix)
                        if (self.NetworkLogFilePostfix == "" or index < 0):
                            return networkLog
                        else:
                            return networkLog[index + len(self.NetworkLogFilePostfix):]
                    else:
                        return "Network log file does not exist: " + self.NetworkLogFile
                except IOException as e:
                    self.Plugin.LogWarning("Cannot read from network log because: " + e.Message)

                    attempts = attempts + 1
                    if attempts < 5:
                        self.Plugin.LogWarning("Waiting " + str(attempts) + " seconds to try again")
                        SystemUtils.Sleep(attempts * 1000)
                    else:
                        return "Cannot read network log file because: " + e.Message
        else:
            return "Cannot read network log file because: " + self.NetworkLogError

    def GetGpuOverrides(self):
        resultGPUs = []

        # If the number of gpus per task is set, then need to calculate the gpus to use.
        gpusPerTask = self.Plugin.GetIntegerPluginInfoEntryWithDefault("GPUsPerTask", 0)
        gpusSelectDevices = self.Plugin.GetPluginInfoEntryWithDefault("GPUsSelectDevices", "")

        if self.Plugin.OverrideGpuAffinity():
            overrideGPUs = self.Plugin.GpuAffinity()
            if gpusPerTask == 0 and gpusSelectDevices != "":
                gpus = gpusSelectDevices.split(",")
                notFoundGPUs = []
                for gpu in gpus:
                    if int(gpu) in overrideGPUs:
                        resultGPUs.append(gpu)
                    else:
                        notFoundGPUs.append(gpu)

                if len(notFoundGPUs) > 0:
                    self.Plugin.LogWarning(
                        "The Worker is overriding its GPU affinity and the following GPUs do not match the Workers affinity so they will not be used: " + ",".join(
                            notFoundGPUs))
                if len(resultGPUs) == 0:
                    self.Plugin.FailRender(
                        "The Worker does not have affinity for any of the GPUs specified in the job.")
            elif gpusPerTask > 0:
                if gpusPerTask > len(overrideGPUs):
                    self.Plugin.LogWarning(
                        "The Worker is overriding its GPU affinity and the Worker only has affinity for " + str(
                            len(overrideGPUs)) + " Workers of the " + str(gpusPerTask) + " requested.")
                    resultGPUs = overrideGPUs
                else:
                    resultGPUs = list(overrideGPUs)[:gpusPerTask]
            else:
                resultGPUs = overrideGPUs
        elif gpusPerTask == 0 and gpusSelectDevices != "":
            resultGPUs = gpusSelectDevices.split(",")

        elif gpusPerTask > 0:
            gpuList = []
            for i in range((self.Plugin.GetThreadNumber() * gpusPerTask),
                           (self.Plugin.GetThreadNumber() * gpusPerTask) + gpusPerTask):
                gpuList.append(str(i))
            resultGPUs = gpuList

        resultGPUs = list(resultGPUs)

        return resultGPUs

    def CreateStartupScript(self, port):
        self.AuthentificationToken = str(DateTime.Now.TimeOfDay.Ticks)

        self.Plugin.LogInfo("Setting up startup environment")
        self.Plugin.SetProcessEnvironmentVariable("DEADLINE_MAX_PORT", str(port))
        self.Plugin.SetProcessEnvironmentVariable("DEADLINE_MAX_TOKEN", self.AuthentificationToken)
        self.Plugin.LogInfo("Setting NW_ROOT_PATH to '%s' for this session" % self.TempFolder)
        self.Plugin.SetProcessEnvironmentVariable("NW_ROOT_PATH", self.TempFolder)
        self.Plugin.LogInfo("Setting DEADLINE_JOB_TEMP_FOLDER to '%s' for this session" % self.TempFolder)
        self.Plugin.SetProcessEnvironmentVariable("DEADLINE_JOB_TEMP_FOLDER", self.TempFolder)

        # Check if we are overriding GPU affinity
        selectedGPUs = self.GetGpuOverrides()
        if len(selectedGPUs) > 0:
            gpus = ",".join(str(gpu) for gpu in selectedGPUs)
            self.Plugin.LogInfo(
                "This Worker is overriding its GPU affinity, so the following GPUs will be used by Octane/RedShift/V-Ray RT: %s" % gpus)
            self.Plugin.SetProcessEnvironmentVariable("DEADLINE_GPU_AFFINITY",
                                                      "#(" + gpus + ")")  # Octane / Redshift (prior to 2.0.91-prod or prior to 2.5.11-beta)
            self.Plugin.SetProcessEnvironmentVariable("REDSHIFT_GPUDEVICES", gpus)  # Redshift (newer env var method)
            vrayGpus = "index" + ";index".join([str(gpu) for gpu in selectedGPUs])  # "index0;index1"
            self.Plugin.SetProcessEnvironmentVariable("VRAY_OPENCL_PLATFORMS_x64", vrayGpus)  # V-Ray RT

    def CopyLightningDlx(self):
        lightningDir = os.path.join(self.TempFolder, "lightning")
        if (not os.path.isdir(lightningDir)):
            Directory.CreateDirectory(lightningDir)

        newLightningPluginFile = os.path.join(lightningDir, "lightning.dlx")
        self.Plugin.LogInfo("Copying %s to %s" % (self.LightningPluginFile, newLightningPluginFile))

        if (os.path.isfile(newLightningPluginFile)):
            try:
                os.remove(newLightningPluginFile)
                shutil.copy2(self.LightningPluginFile, newLightningPluginFile)
            except:
                self.Plugin.LogWarning(
                    "Could not delete old %s - this file may be locked by another copy of 3dsmax" % newLightningPluginFile)
        else:
            shutil.copy2(self.LightningPluginFile, newLightningPluginFile)

        if (not os.path.isfile(newLightningPluginFile)):
            self.Plugin.FailRender("Could not copy %s to %s" % (self.LightningPluginFile, newLightningPluginFile))

        return lightningDir

    def CreateOutputFolders(self):
        outputFolders = self.Plugin.GetJob().OutputDirectories
        for folder in outputFolders:
            folder = RepositoryUtils.CheckPathMapping(folder).replace("/", "\\")
            if not os.path.isdir(folder):
                try:
                    self.Plugin.LogInfo('Creating the output directory "%s"' % folder)
                    os.makedirs(folder)
                except:
                    self.Plugin.FailRender(
                        'Failed to create output directory "%s". The path may be invalid or permissions may not be sufficient.' % folder)

    def CreatePluginInis(self, lightningDir):
        self.DeletePluginInis()

        self.TempLightningIni = os.path.join(PathUtils.GetSystemTempPath(),
                                             "lightningplugin_" + self.AuthentificationToken + ".ini")
        writer = File.CreateText(self.TempLightningIni)
        writer.WriteLine("[Directories]")
        writer.WriteLine("Lightning Plugin=%s" % lightningDir)
        writer.Close()

        # Long paths tend to cause Max 2008 (32 bit) to crash on 64 bit OS - no idea why...
        self.TempPluginIni = os.path.join(PathUtils.ToShortPathName(PathUtils.GetSystemTempPath()),
                                          "dl_" + self.AuthentificationToken + ".ini")
        if os.path.isfile(self.TempPluginIni):
            os.remove(self.TempPluginIni)

        writer = File.CreateText(self.TempPluginIni)
        writer.WriteLine("[Include]")
        writer.WriteLine("Original=%s" % self.MaxPluginIni)
        if (self.UserPluginIni != "" and os.path.isfile(self.UserPluginIni)):
            writer.WriteLine("UserProfile=%s" % self.UserPluginIni)
        writer.WriteLine("Deadline Lightning=%s" % self.TempLightningIni)
        writer.Close()

        self.Plugin.LogInfo("Created temporary plugin ini file: " + self.TempPluginIni)
        self.Plugin.LogInfo("Temporary plugin ini contains:\n" + File.ReadAllText(self.TempPluginIni))

        return self.TempPluginIni

    def DeletePluginInis(self):
        if (self.TempPluginIni != ""):
            if (os.path.isfile(self.TempPluginIni)):
                try:
                    os.remove(self.TempPluginIni)
                    self.TempPluginIni = ""
                except:
                    self.Plugin.LogWarning("Could not delete temp plugin ini: %s" % self.TempPluginIni)
            else:
                self.TempPluginIni = ""

        if (self.TempLightningIni != ""):
            if (os.path.isfile(self.TempLightningIni)):
                try:
                    os.remove(self.TempLightningIni)
                    self.TempLightningIni = ""
                except:
                    self.Plugin.LogWarning("Could not delete temp lightning ini: %s" % self.TempLightningIni)
            else:
                self.TempLightningIni = ""

    def DeleteStartupKillScript(self):
        if (self.StartupKillScript != ""):
            if (os.path.isfile(self.StartupKillScript)):
                try:
                    os.remove(self.StartupKillScript)
                except:
                    self.Plugin.LogWarning("Could not delete kill adsk comm center script: %s" % self.StartupKillScript)

    def LaunchMax(self, executable, arguments, startupDir):
        self.ManagedMaxProcessRenderExecutable = executable
        self.ManagedMaxProcessRenderArgument = arguments
        self.ManagedMaxProcessStartupDirectory = startupDir

        self.MaxProcess = MaxProcess(self)
        self.Plugin.StartMonitoredManagedProcess(self.ProgramName, self.MaxProcess)
        self.Plugin.VerifyMonitoredManagedProcess(self.ProgramName)

    def WaitForConnection(self, errorMessageOperation):
        startTime = DateTime.Now
        receivedToken = ""

        while (DateTime.Now.Subtract(
                startTime).TotalSeconds < self.LoadMaxTimeout and not self.MaxSocket.IsConnected and not self.Plugin.IsCanceled()):
            try:
                self.Plugin.VerifyMonitoredManagedProcess(self.ProgramName)
                self.Plugin.FlushMonitoredManagedProcessStdout(self.ProgramName)

                blockingDialogMessage = self.Plugin.CheckForMonitoredManagedProcessPopups(self.ProgramName)
                if (blockingDialogMessage != ""):
                    self.Plugin.FailRender(blockingDialogMessage)

                # ~ if( os.path.isfile( self.ErrorMessageFile ) ):
                # ~ reader = File.OpenText( self.ErrorMessageFile )
                # ~ message = reader.ReadToEnd()
                # ~ reader.Close
                # ~ self.Plugin.FailRender( message )

                self.MaxSocket.WaitForConnection(500, True)

                receivedToken = self.MaxSocket.Receive(3000)

                if (receivedToken.startswith("TOKEN:")):
                    receivedToken = receivedToken[6:]
                else:
                    self.MaxSocket.Disconnect(False)

            except Exception as e:
                if (not isinstance(e, SimpleSocketTimeoutException)):
                    self.Plugin.FailRender("%s: Error getting connection from 3dsmax: %s\n%s" % (
                        errorMessageOperation, e.Message, self.NetworkLogGet()))

            if (self.Plugin.IsCanceled()):
                self.Plugin.FailRender("%s: Initialization was canceled by Deadline" % errorMessageOperation)

        if (not self.MaxSocket.IsConnected):
            if (DateTime.Now.Subtract(startTime).TotalSeconds < self.LoadMaxTimeout):
                self.Plugin.FailRender(
                    "%s: Max exited unexpectedly - check that max starts up with no dialog messages\n%s" % (
                        errorMessageOperation, self.NetworkLogGet()))
            else:
                self.Plugin.FailRender(
                    "%s: Timed out waiting for 3ds max to start - consider increasing the LoadMaxTimeout in the 3dsmax plugin configuration (current value is %d seconds).\n%s" % (
                        errorMessageOperation, self.LoadMaxTimeout, self.NetworkLogGet()))

        if (receivedToken != self.AuthentificationToken):
            self.Plugin.FailRender(
                "%s: Did not receive expected token from Lightning plugin (got \"%s\") - an unexpected error may have occurred during initialization\n%s" % (
                    errorMessageOperation, receivedToken, self.NetworkLogGet()))

    def LoadMaxFile(self):
        # Set some pre-loading settings.
        if (self.GammaCorrection):
            self.Plugin.LogInfo("GammaCorrection," + str(self.GammaInput) + "," + str(self.GammaOutput))
            self.MaxSocket.Send("GammaCorrection," + str(self.GammaInput) + "," + str(self.GammaOutput))
        if (self.IgnoreMissingExternalFiles):
            self.MaxSocket.Send("IgnoreMissingExternalFiles")
        if (self.IgnoreMissingUVWs):
            self.MaxSocket.Send("IgnoreMissingUVWs")
        if (self.IgnoreMissingXREFs):
            self.MaxSocket.Send("IgnoreMissingXREFs")
        if (self.IgnoreMissingDLLs):
            self.MaxSocket.Send("IgnoreMissingDLLs")
        if (self.DisableMultipass):
            self.MaxSocket.Send("DisableMultipass")
        if (self.PathConfigFile != ""):
            self.MaxSocket.Send("PathConfigFile,\"" + self.PathConfigFile.replace("\\", "/") + "\"")
            if (self.MergePathConfigFile):
                self.MaxSocket.Send("MergePathConfigFile")

        # Now load the max scene file.
        self.Plugin.LogInfo("Loading 3dsmax scene file")
        message = "StartJob,\"" + self.MaxFilename.replace("\\", "/") + "\",\"" + self.Camera + "\""
        self.MaxSocket.Send(message)

        startTime = DateTime.Now
        response = ""

        while (DateTime.Now.Subtract(
                startTime).TotalSeconds < self.StartJobTimeout and response == "" and not self.Plugin.IsCanceled()):
            self.Plugin.VerifyMonitoredManagedProcess(self.ProgramName)
            self.Plugin.FlushMonitoredManagedProcessStdout(self.ProgramName)

            blockingDialogMessage = self.Plugin.CheckForMonitoredManagedProcessPopups(self.ProgramName)
            if (blockingDialogMessage != ""):
                self.Plugin.FailRender(blockingDialogMessage)

            try:
                response = self.MaxSocket.Receive(100)

                # If this is a STDOUT message, print it out and reset 'response' so that we keep looping
                match = self.StdoutRegex.Match(response)
                if (match.Success):
                    self.Plugin.LogInfo(match.Groups[1].Value)
                    response = ""

                # If this is a WARN message, print it out and reset 'response' so that we keep looping
                match = self.WarnRegex.Match(response)
                if (match.Success):
                    self.Plugin.LogWarning(match.Groups[1].Value)
                    response = ""

            except Exception as e:
                if (not isinstance(e, SimpleSocketTimeoutException)):
                    self.Plugin.FailRender("Unexpected error while waiting for the max file to load: %s" % e.Message)

        if (self.Plugin.IsCanceled()):
            self.Plugin.FailRender("StartJob was canceled by Deadline.")

        if (response == ""):
            self.Plugin.FailRender(
                "Timed out waiting for the 3dsmax scene file to load - likely caused by ADSK Comms Center, 3rd party plugin/script " \
                "or bad configuration of 3ds Max. Alternatively, the scene file could be taking a very long time to load (lots of " \
                "assets, slow network connection). Please review the following network log for further details to debug. Contact " \
                "Thinkbox Support if unresolvable.\n%s" % self.NetworkLogGet())

        if (response.startswith("ERROR: ")):
            self.Plugin.FailRender("3dsmax: %s\n%s" % (response[7:], self.NetworkLogGet()))

        if (not response.startswith("SUCCESS")):
            self.Plugin.FailRender("Did not receive a success message in response to StartJob.\nResponse: %s\n%s" % (
                response, self.NetworkLogGet()))

        if (len(response) > 7):
            self.Plugin.LogInfo(response[8:])

        # Check if ADSK WSCommCntr process is running and kill it if necessary.
        if (self.KillWsCommCntrProcesses):
            processName = "WSCommCntr"
            if ProcessUtils.KillProcesses(processName):
                self.Plugin.LogInfo("Killed ADSK Communication Center process via Python: " + processName)

            for i in range(1, 10):
                tempProcessName = processName + str(i)
                if ProcessUtils.KillProcesses(tempProcessName):
                    self.Plugin.LogInfo("Killed ADSK Communication Center process via Python: " + tempProcessName)

        # Execute the customizations script if it exists. Note that this needs to be done before the
        # post-load settings below because customize.ms sets the output image size, and some settings
        # (like RegionRendering) need to be set AFTER the output image size is set.
        customizationScript = os.path.join(self.Plugin.GetPluginDirectory(), "customize.ms")
        if (os.path.isfile(customizationScript)):
            self.ExecuteMaxScriptFile(customizationScript, timeout=self.RunCustomizeScriptTimeout)

        # Set some post-load settings.
        self.MaxSocket.Send("SlaveFolders,\"" + self.Plugin.GetJobsDataDirectory().replace("\\",
                                                                                           "/") + "\",\"" + self.Plugin.GetPluginDirectory().replace(
            "\\", "/") + "\"")
        self.MaxSocket.Send("TempFolder,\"" + self.TempFolder.replace("\\", "/") + "\"")

        if (self.LocalRendering):
            self.MaxSocket.Send("LocalRendering")
        if (self.RestartEachFrame):
            self.MaxSocket.Send("RestartRendererMode")
        if (not self.ShowFrameBuffer):
            self.MaxSocket.Send("HideFrameBuffer")
        if (self.RegionRendering):
            self.MaxSocket.Send("RegionRendering,%d,%d,%d,%d,%d,%s" % (
                self.RegionPadding, self.RegionLeft, self.RegionTop, self.RegionRight, self.RegionBottom,
                self.RegionType))
        if (self.OverrideSaveFile):
            self.MaxSocket.Send("OverrideSaveFile,%d" % self.SaveFile)
        if (self.RedirectOutput):
            self.MaxSocket.Send("OutputImageFilename,%s" % self.RenderOutputOverride.replace("\\", "/"))

        reFilenameIndex = 0
        reFilename = self.Plugin.GetPluginInfoEntryWithDefault("RenderElementOutputFilename" + str(reFilenameIndex), "")
        while reFilename != "":
            reFilename = RepositoryUtils.CheckPathMapping(reFilename).replace("/", "\\")

            self.MaxSocket.Send("OutputImageReFilename,%d,%s" % (reFilenameIndex, reFilename.replace("\\", "/")))
            reFilenameIndex = reFilenameIndex + 1
            reFilename = self.Plugin.GetPluginInfoEntryWithDefault("RenderElementOutputFilename" + str(reFilenameIndex),
                                                                   "")

        if (self.FrameNumberBase != 0):
            self.MaxSocket.Send("FrameNumberBase,%d" % self.FrameNumberBase)
        if (self.RemovePadding):
            self.MaxSocket.Send("RemovePadding")
        if (self.FailOnBlackFrames):
            self.MaxSocket.Send("FailOnBlackFrames,%d,%.4f" % (self.BlackPixelPercentage, self.BlackPixelThreshold))
            if (self.BlackFramesCheckRenderElements):
                self.MaxSocket.Send("BlackFramesCheckRenderElements")
        if (self.UseJpegOutput):
            self.MaxSocket.Send("UseJpegOutput,%s" % self.JpegOutputPath.replace("\\", "/"))
        if (self.DisableAltOutput):
            self.MaxSocket.Send("DisableAltOutput")
        if (self.IgnoreRenderElements):
            self.MaxSocket.Send("IgnoreRenderElements")
        elif (len(self.IgnoreRenderElementsByName) > 0):
            ignoreElementMessage = "IgnoreRenderElementsByName,\"" + self.IgnoreRenderElementsByName[0] + "\""
            for elementIndex in range(1, len(self.IgnoreRenderElementsByName)):
                ignoreElementMessage = ignoreElementMessage + ",\"" + self.IgnoreRenderElementsByName[
                    elementIndex] + "\""
            self.MaxSocket.Send(ignoreElementMessage)

    def RenderFrame(self, frameNumber):
        if (not self.Plugin.MonitoredManagedProcessIsRunning(self.ProgramName)):
            self.Plugin.FailRender("3dsmax exited unexpectedly before being told to render a frame")

        self.CurrentFrame = frameNumber

        # Check if ADSK WSCommCntr process is running and kill it if necessary.
        if (self.KillWsCommCntrProcesses):
            processName = "WSCommCntr"
            if ProcessUtils.KillProcesses(processName):
                self.Plugin.LogInfo("Killed ADSK Communication Center process via Python: " + processName)

            for i in range(1, 10):
                tempProcessName = processName + str(i)
                if ProcessUtils.KillProcesses(tempProcessName):
                    self.Plugin.LogInfo("Killed ADSK Communication Center process via Python: " + tempProcessName)

        VraySplitBufferFile = self.Plugin.GetBooleanPluginInfoEntryWithDefault("SplitBufferFile", False)
        VrayRawBufferFile = self.Plugin.GetBooleanPluginInfoEntryWithDefault("RawBufferFile", False)

        # Update output filename if necessary.
        if self.RegionRendering and self.RegionRenderingSingleJob:
            self.RegionRenderingIndex = self.Plugin.GetCurrentTaskId()
            if not self.RegionAnimation:
                self.RegionLeft = self.Plugin.GetIntegerPluginInfoEntryWithDefault(
                    "RegionLeft" + self.RegionRenderingIndex, 0)
                self.RegionTop = self.Plugin.GetIntegerPluginInfoEntryWithDefault(
                    "RegionTop" + self.RegionRenderingIndex, 0)
                self.RegionRight = self.Plugin.GetIntegerPluginInfoEntryWithDefault(
                    "RegionRight" + self.RegionRenderingIndex, 0)
                self.RegionBottom = self.Plugin.GetIntegerPluginInfoEntryWithDefault(
                    "RegionBottom" + self.RegionRenderingIndex, 0)
            else:
                self.RegionLeftArray = self.Plugin.GetPluginInfoEntryWithDefault(
                    "RegionLeft" + self.RegionRenderingIndex, "0")
                self.RegionTopArray = self.Plugin.GetPluginInfoEntryWithDefault("RegionTop" + self.RegionRenderingIndex,
                                                                                "0")
                self.RegionRightArray = self.Plugin.GetPluginInfoEntryWithDefault(
                    "RegionRight" + self.RegionRenderingIndex, "0")
                self.RegionBottomArray = self.Plugin.GetPluginInfoEntryWithDefault(
                    "RegionBottom" + self.RegionRenderingIndex, "0")
                self.RegionLeftArray = map(int, self.RegionLeftArray.split(','))
                self.RegionTopArray = map(int, self.RegionTopArray.split(','))
                self.RegionRightArray = map(int, self.RegionRightArray.split(','))
                self.RegionBottomArray = map(int, self.RegionBottomArray.split(','))

                frameVal = int(self.Plugin.GetCurrentTaskId())

                self.RegionLeft = self.RegionLeftArray[frameVal]
                self.RegionTop = self.RegionTopArray[frameVal]
                self.RegionRight = self.RegionRightArray[frameVal]
                self.RegionBottom = self.RegionBottomArray[frameVal]

            self.Plugin.LogInfo(
                "Region rendering enabled: left = %d, top = %d, right = %d, bottom = %d, padding = %d, type = %s" % (
                    self.RegionLeft, self.RegionTop, self.RegionRight, self.RegionBottom, self.RegionPadding,
                    self.RegionType))
            self.MaxSocket.Send("RegionRendering,%d,%d,%d,%d,%d,%s" % (
                self.RegionPadding, self.RegionLeft, self.RegionTop, self.RegionRight, self.RegionBottom,
                self.RegionType))

            self.RenderOutputOverride = self.Plugin.GetPluginInfoEntryWithDefault(
                "RegionFilename" + str(self.RegionRenderingIndex), "").strip()
            if self.RenderOutputOverride != "":
                self.RenderOutputOverride = RepositoryUtils.CheckPathMapping(self.RenderOutputOverride).replace("/",
                                                                                                                "\\")

            self.Plugin.LogInfo("Overriding render output: %s" % self.RenderOutputOverride)
            self.MaxSocket.Send("OutputImageFilename,%s" % self.RenderOutputOverride.replace("\\", "/"))

            reRegionFilenameIndex = 0
            reRegionFilename = self.Plugin.GetPluginInfoEntryWithDefault(
                "RegionReFilename" + self.RegionRenderingIndex + "_" + str(reRegionFilenameIndex), "")
            while reRegionFilename != "":
                reRegionFilename = RepositoryUtils.CheckPathMapping(reRegionFilename).replace("/", "\\")

                self.MaxSocket.Send(
                    "OutputImageReFilename,%d,%s" % (reRegionFilenameIndex, reRegionFilename.replace("\\", "/")))
                reRegionFilenameIndex = reRegionFilenameIndex + 1
                reRegionFilename = self.Plugin.GetPluginInfoEntryWithDefault(
                    "RegionReFilename" + self.RegionRenderingIndex + "_" + str(reRegionFilenameIndex), "")

            if VrayRawBufferFile:
                filePath = self.Plugin.GetPluginInfoEntryWithDefault(
                    "RawBufferFilename" + str(self.RegionRenderingIndex), "")
                self.SetVrayRawBufferFile(filePath)

            if VraySplitBufferFile:
                filePath = self.Plugin.GetPluginInfoEntryWithDefault(
                    "SplitBufferFilename" + str(self.RegionRenderingIndex), "")
                self.SetVraySplitBufferFile(filePath)

        elif self.RegionRendering:
            if self.RegionAnimation:
                frameVal = int(self.Plugin.GetCurrentTaskId())

                self.RegionLeft = self.RegionLeftArray[frameVal]
                self.RegionTop = self.RegionTopArray[frameVal]
                self.RegionRight = self.RegionRightArray[frameVal]
                self.RegionBottom = self.RegionBottomArray[frameVal]
                self.MaxSocket.Send("RegionRendering,%d,%d,%d,%d,%d,%s" % (
                    self.RegionPadding, self.RegionLeft, self.RegionTop, self.RegionRight, self.RegionBottom,
                    self.RegionType))

            if VrayRawBufferFile:
                filePath = self.Plugin.GetPluginInfoEntryWithDefault("RawBufferFilename0", "")
                self.SetVrayRawBufferFile(filePath)

            if VraySplitBufferFile:
                filePath = self.Plugin.GetPluginInfoEntryWithDefault("SplitBufferFilename0", "")
                self.SetVraySplitBufferFile(filePath)

        else:
            if VrayRawBufferFile:
                filePath = self.Plugin.GetPluginInfoEntryWithDefault("vray_output_rawFileName", "")  # V-Ray 3.5+

                # If "" returned, try the older maxscript property names (note different changes in case)
                if filePath == "":
                    filePath = self.Plugin.GetPluginInfoEntryWithDefault("vray_output_rawFilename", "")  # V-Ray 3.4

                if filePath == "":
                    filePath = self.Plugin.GetPluginInfoEntryWithDefault("vray_output_rawfilename", "")  # < V-Ray 3.4

                if filePath == "":
                    self.Plugin.LogWarning("V-Ray renderer MAXScript property: raw output filename is missing!")

                self.SetVrayRawBufferFile(filePath)

            if VraySplitBufferFile:
                filePath = self.Plugin.GetPluginInfoEntryWithDefault("vray_output_splitfilename", "")
                self.SetVraySplitBufferFile(filePath)

        self.MaxSocket.Send("CurrentTask,%s" % self.Plugin.GetCurrentTaskId())

        # If we are running a max script job, then just execute the script.
        if (self.MaxScriptJob):
            self.ExecuteMaxScriptFile(self.MaxScriptJobScript, frameNumber=self.CurrentFrame)
        else:
            # First run the pre frame script if necessary.
            if (self.PreFrameScript != ""):
                self.ExecuteMaxScriptFile(self.PreFrameScript)

            # Now tell LIGHTNING to RENDER this FRAME NOW.
            message = "RenderTask," + str(frameNumber)
            self.MaxSocket.Send(message)

            response = ""
            try:
                response = self.MaxSocket.Receive(5000)
            except SimpleSocketTimeoutException:
                self.Plugin.FailRender(
                    "RenderFrame: Timed out waiting for the lightning 3dsmax plugin to acknowledge the RenderTask command.\n%s" % self.NetworkLogGet())

            self.Plugin.LogInfo(response)

            if (response.startswith("ERROR: ")):
                self.Plugin.FailRender("RenderFrame: %s" % response[7:])

            if (not response.startswith("STARTED")):
                self.Plugin.FailRender(
                    "RenderFrame: Did not receive a started message in response to RenderTask - got \"%s\"\n%s" % (
                        response, self.NetworkLogGet()))

            # Wait for the render to complete.
            self.PollUntilComplete(not self.DisableProgressUpdateTimeout)

            if self.LocalRendering:
                outputFolders = self.Plugin.GetJob().OutputDirectories
                if self.RegionRenderingSingleJob:
                    outputTileFileNames = self.Plugin.GetJob().OutputTileFileNames
                    for component in range(len(outputTileFileNames)):
                        for tile in range(len(outputTileFileNames[component])):
                            fileName = outputTileFileNames[component][tile]
                            replacedFileName = FrameUtils.ReplacePaddingWithFrameNumber(fileName, frameNumber)
                            destinationFolder = RepositoryUtils.CheckPathMapping(outputFolders[component]).replace("/",
                                                                                                                   "\\")
                            self.Plugin.LogInfo(
                                "Searching local output folder for: " + os.path.join(self.TempFolder, replacedFileName))
                            if os.path.isfile(os.path.join(self.TempFolder, replacedFileName)):
                                self.Plugin.LogInfo("Found " + os.path.join(self.TempFolder,
                                                                            replacedFileName) + " copying to " + os.path.join(
                                    destinationFolder, replacedFileName))
                                self.Plugin.VerifyAndMoveFile(os.path.join(self.TempFolder, replacedFileName),
                                                              os.path.join(destinationFolder, replacedFileName), -1)
                            else:
                                self.Plugin.LogWarning(
                                    "Unable to locate local render file: " + os.path.join(self.TempFolder,
                                                                                          replacedFileName))
                else:
                    outputFileNames = self.Plugin.GetJob().OutputFileNames
                    for i in range(len(outputFileNames)):
                        fileName = outputFileNames[i]
                        replacedFileName = FrameUtils.ReplacePaddingWithFrameNumber(fileName, frameNumber)
                        destinationFolder = RepositoryUtils.CheckPathMapping(outputFolders[i]).replace("/", "\\")
                        self.Plugin.LogInfo(
                            "Searching local output folder for: " + os.path.join(self.TempFolder, replacedFileName))
                        if os.path.isfile(os.path.join(self.TempFolder, replacedFileName)):
                            self.Plugin.LogInfo("Found " + os.path.join(self.TempFolder,
                                                                        replacedFileName) + " copying to " + os.path.join(
                                destinationFolder, replacedFileName))
                            self.Plugin.VerifyAndMoveFile(os.path.join(self.TempFolder, replacedFileName),
                                                          os.path.join(destinationFolder, replacedFileName), -1)
                        else:
                            self.Plugin.LogWarning(
                                "Unable to locate local render file: " + os.path.join(self.TempFolder,
                                                                                      replacedFileName))

            if ((VraySplitBufferFile or VrayRawBufferFile) and self.RegionPadding > 0):
                val = min(self.RegionLeft - self.RegionPadding, 0)
                regLeft = self.RegionPadding + val
                regRight = self.RegionRight - self.RegionLeft + regLeft
                height = self.Plugin.GetIntegerPluginInfoEntryWithDefault("vray_output_height", 0)
                regTop = min(self.RegionPadding, height - self.RegionBottom)
                regBottom = self.RegionBottom - self.RegionTop + regTop

                draftLocalPath = os.path.join(self.slaveDirectory, "Draft")
                draftRepoPath = RepositoryUtils.GetRepositoryPath("draft", False)
                if not os.path.isdir(draftRepoPath):
                    self.Plugin.FailRender("ERROR: Draft was not found in the Deadline Repository!")

                draftRepoPath = os.path.join(draftRepoPath, "Windows")

                if SystemUtils.Is64Bit():
                    draftRepoPath = os.path.join(draftRepoPath, "64bit")
                else:
                    draftRepoPath = os.path.join(draftRepoPath, "32bit")

                self.DraftAutoUpdate(draftLocalPath, draftRepoPath)
                draftLibrary = os.path.join(draftLocalPath, "Draft.pyd")

                if not os.path.isfile(draftLibrary):
                    self.Plugin.FailRender("Could not find local Draft installation.")

                self.DraftDirectory = draftLocalPath

            if (VraySplitBufferFile and self.RegionPadding > 0):
                splitCount = 0
                while True:
                    splitChannelName = self.Plugin.GetPluginInfoEntryWithDefault("SplitChannelNames" + str(splitCount),
                                                                                 "")
                    splitChannelType = self.Plugin.GetPluginInfoEntryWithDefault("SplitChannelTypes" + str(splitCount),
                                                                                 "")

                    if splitChannelName == "" or splitChannelType == "":
                        break

                    tempFile = os.path.join(self.TempFolder, "cropVraySplitImage.py")
                    with open(tempFile, "w") as text_file:
                        text_file.write("from __future__ import print_function\n")
                        text_file.write("import sys\n")
                        text_file.write("sys.path.append(sys.argv[1])\n")
                        text_file.write("import Draft\n")
                        text_file.write("\n")
                        filePath = ""
                        fileName = ""
                        fileExtension = ""
                        if not self.RegionAnimation:
                            splitBufferFile = self.Plugin.GetPluginInfoEntryWithDefault(
                                "SplitBufferFilename" + str(self.Plugin.GetCurrentTaskId()), "")
                        else:
                            splitBufferFile = self.Plugin.GetPluginInfoEntryWithDefault("SplitBufferFilename0", "")

                        filePath = os.path.dirname(splitBufferFile)
                        fileBaseName = os.path.basename(splitBufferFile)
                        fileName, fileExtension = os.path.splitext(fileBaseName)

                        paddedFrame = str(frameNumber)
                        paddedFrame = paddedFrame.zfill(4)

                        includeReName = self.Plugin.GetBooleanPluginInfoEntryWithDefault(
                            "RenderElementsIncludeNameInPath", False)
                        includeReType = self.Plugin.GetBooleanPluginInfoEntryWithDefault(
                            "RenderElementsIncludeTypeInPath", False)

                        suffix = ""
                        if includeReName and includeReType:
                            suffix += splitChannelName + "_" + splitChannelType
                        elif includeReName:
                            suffix += splitChannelName
                        elif includeReType:
                            suffix += splitChannelType

                        fileName = fileName + "." + splitChannelName + "." + paddedFrame + fileExtension
                        fullFile = os.path.join(filePath, suffix, fileName).replace("\\", "\\\\")
                        text_file.write("image = Draft.Image.ReadFromFile( %s )\n" % repr(fullFile))
                        text_file.write("image.Crop(%i,%i,%i,%i)\n" % (regLeft, regTop, regRight, regBottom))
                        text_file.write("image.WriteToFile( %s )\n" % repr(fullFile))
                        text_file.write("print(\"Split VFB File: %s\")" % repr(fullFile))

                    pythonPath = os.path.join(ClientUtils.GetBinDirectory(), "dpython.exe")

                    self.Plugin.LogInfo("Using Draft to crop V-Ray split buffer file...")

                    startupinfo = None
                    if os.name == 'nt' and hasattr(subprocess, 'STARTF_USESHOWWINDOW'):
                        startupinfo = subprocess.STARTUPINFO()
                        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW

                    proc = subprocess.Popen([pythonPath, tempFile, self.DraftDirectory], startupinfo=startupinfo,
                                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    stdout, stderr = proc.communicate()

                    output = stdout.strip()
                    outputLines = output.splitlines()

                    for line in outputLines:
                        self.Plugin.LogStdout(line)

                    if len(stderr) > 0:
                        self.Plugin.LogWarning(stderr)

                    splitCount += 1

            if (VrayRawBufferFile and self.RegionPadding > 0):
                tempFile = os.path.join(self.TempFolder, "cropVrayRawImage.py")
                with open(tempFile, "w") as text_file:
                    text_file.write("from __future__ import print_function\n")
                    text_file.write("import sys\n")
                    text_file.write("sys.path.append(sys.argv[1])\n")
                    text_file.write("import Draft\n")
                    text_file.write("\n")
                    fileName = ""
                    fileExtension = ""
                    if not self.RegionAnimation:
                        fileName, fileExtension = os.path.splitext(self.Plugin.GetPluginInfoEntryWithDefault(
                            "RawBufferFilename" + str(self.Plugin.GetCurrentTaskId()), "").replace("\\", "\\\\"))
                    else:
                        fileName, fileExtension = os.path.splitext(
                            self.Plugin.GetPluginInfoEntryWithDefault("RawBufferFilename0", "").replace("\\", "\\\\"))

                    paddedFrame = str(frameNumber)
                    paddedFrame = paddedFrame.zfill(4)

                    fullFile = fileName + paddedFrame + fileExtension
                    text_file.write("image = Draft.Image.ReadFromFile( %s )\n" % repr(fullFile))
                    text_file.write("image.Crop(%i,%i,%i,%i)\n" % (regLeft, regTop, regRight, regBottom))
                    text_file.write("image.WriteToFile( %s )\n" % repr(fullFile))
                    text_file.write("print(\"Raw VFB File: %s\")" % repr(fullFile))

                pythonPath = os.path.join(ClientUtils.GetBinDirectory(), "dpython.exe")

                self.Plugin.LogInfo("Using Draft to crop V-Ray raw buffer file...")

                startupinfo = None
                if os.name == 'nt' and hasattr(subprocess, 'STARTF_USESHOWWINDOW'):
                    startupinfo = subprocess.STARTUPINFO()
                    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW

                proc = subprocess.Popen([pythonPath, tempFile, self.DraftDirectory], startupinfo=startupinfo,
                                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                stdout, stderr = proc.communicate()

                output = stdout.strip()
                outputLines = output.splitlines()

                for line in outputLines:
                    self.Plugin.LogStdout(line)

                if len(stderr) > 0:
                    self.Plugin.LogWarning(stderr)

            # Now run the post frame script if necessary.
            if (self.PostFrameScript != ""):
                self.ExecuteMaxScriptFile(self.PostFrameScript)

    def SetVraySplitBufferFile(self, filePath):
        # If rendering locally, then redirect vray split channel render to local directory.
        if self.LocalRendering:
            splitName = os.path.basename(filePath)
            filePath = os.path.join(self.TempFolder, splitName)

        filePath = filePath.replace("\\", "\\\\")

        path = os.path.join(self.TempFolder, u"setSplitBufferFilename.ms")

        with io.open(path, "w", encoding="utf-8-sig") as file:
            if self.LocalRendering:
                file.write(u"try(renderers.current.output_separateFolders = false)catch()\n")
            if self.IsVrayRT():
                file.write(u"renderers.current.V_Ray_settings.output_splitfilename = \"%s\"\n" % filePath)
                file.write(u"true")
            else:
                file.write(u"renderers.current.output_splitfilename = \"%s\"\n" % filePath)
                file.write(u"true")

        self.ExecuteMaxScriptFile(path, frameNumber=self.CurrentFrame)
        self.Plugin.LogInfo("SplitBufferFilename set to: %s" % filePath.replace("\\\\", "\\"))

    def SetVrayRawBufferFile(self, filePath):
        # If rendering locally, then redirect vray raw render to local directory.
        if self.LocalRendering:
            rawName = os.path.basename(filePath)
            filePath = os.path.join(self.TempFolder, rawName)

        filePath = filePath.replace("\\", "\\\\")

        path = os.path.join(self.TempFolder, u"setRawBufferFilename.ms")

        with io.open(path, "w", encoding="utf-8-sig") as file:
            if self.IsVrayRT():
                file.write(u"renderers.current.V_Ray_settings.output_rawFileName = \"%s\"\n" % filePath)
                file.write(u"true")
            else:
                file.write(u"renderers.current.output_rawFileName = \"%s\"\n" % filePath)
                file.write(u"true")

        self.ExecuteMaxScriptFile(path, frameNumber=self.CurrentFrame)
        self.Plugin.LogInfo("RawBufferFilename set to: %s" % filePath.replace("\\\\", "\\"))

    def IsVrayRT(self):
        isVrayRt = False
        if self.SubmittedRendererId == "#(1770671000, 1323107829)" or self.SubmittedRendererId == "#(1770671000L, 1323107829L)":
            isVrayRt = True
        return isVrayRt

    def DraftAutoUpdate(self, localPath, repoPath):
        updateNeeded = True
        if (os.path.isdir(localPath)):
            localHash = self.GetFileMD5Hash(os.path.join(localPath, "Version"))
            repoHash = self.GetFileMD5Hash(os.path.join(repoPath, "Version"))

            if (localHash == repoHash):
                updateNeeded = False
        else:
            os.makedirs(localPath)

        if (updateNeeded):
            for filePath in Directory.GetFiles(repoPath):
                fileName = os.path.basename(filePath)
                shutil.copy2(filePath, os.path.join(localPath, fileName))

    def GetFileMD5Hash(self, filename):
        if (os.path.isfile(filename)):
            fileHash = hashlib.md5()
            file = open(filename, 'r')

            try:
                while True:
                    data = file.read(1024)

                    if len(data) == 0:
                        break

                    fileHash.update(data)

                return fileHash.hexdigest()
            finally:
                file.close()

        return None

        # ExecuteMaxScriptFile: Runs a MaxScript file on the Worker side.

    #
    # Optional parameters are:
    #     frameNumber=<int>: If set, 3ds Max changes its current time to the specified frame prior to executing the MaxScript file.
    #     timeout=<int>: Optionally specifies a maximum amount of time in seconds the MaxScript is allowed to run. If it hasn't returned in this time, an exception is thrown.
    #     returnAsString=<bool>: If set to True, this function will return the result of the MaxScript file execution as a string.
    #
    # Note: The reason there is a returnAsString flag is because this function used to always return an error if the return value was not a boolean equal to "true".
    # So, there may be some 3rd party scripts (script jobs, etc.) out there who are expecting Deadline to fail when a string is returned.
    # That's why the original behaviour is the same, and this flag is used.
    def ExecuteMaxScriptFile(self, maxscriptFilename, **keywordArgs):

        if (not self.Plugin.MonitoredManagedProcessIsRunning(self.ProgramName)):
            self.Plugin.FailRender("3dsmax exited unexpectedly before being told to execute a script")

        # Grab the parameters from the keyword arguments.
        useFrameNumber = False
        frameNumberOverride = 0
        if "frameNumber" in keywordArgs:
            useFrameNumber = True
            frameNumberOverride = keywordArgs["frameNumber"]

        useTimeout = False
        timeout = -1
        if "timeout" in keywordArgs:
            useTimeout = True
            timeout = keywordArgs["timeout"]

        returnAsString = False
        if "returnAsString" in keywordArgs:
            returnAsString = keywordArgs["returnAsString"]

        # Tell Lightning to execute this script.
        self.Plugin.LogInfo("Executing script: %s" % maxscriptFilename)

        # Arguments Lightning is expecting are: [MaxScript filename] [Set current frame?] [Current frame (ignored if 'set current frame' is false)] [Return as string?]
        requestMessage = "ExecuteMaxScriptFile," + maxscriptFilename.replace("\\", "/") + "," + str(
            useFrameNumber) + "," + str(frameNumberOverride) + "," + str(returnAsString)
        self.MaxSocket.Send(requestMessage)

        response = ""
        try:
            response = self.MaxSocket.Receive(10000)
        except SimpleSocketTimeoutException:
            self.Plugin.FailRender(
                "ExecuteMaxScriptFile: Timed out waiting for the lightning 3dsmax plugin to acknowledge the ExecuteMaxScriptFile command.\n%s" % self.NetworkLogGet())

        if (not response.startswith("STARTED")):
            self.Plugin.FailRender(
                "ExecuteMaxScriptFile: Did not receive a started message in response to ExecuteMaxScriptFile - got \"%s\"\n%s" % (
                    response, self.NetworkLogGet()))

        # Wait for the script to complete.
        # This function will raise an exception if a response starting with "Error" is returned.
        returnedMessage = self.PollUntilComplete(useTimeout, timeout)

        return returnedMessage  # Returns an empty string on success, or the resulting string if "returnAsString" is requested.

    def PollUntilComplete(self, timeoutEnabled, timeoutOverride=-1):
        startTime = DateTime.Now
        progressTimeout = (self.ProgressUpdateTimeout if timeoutOverride < 0 else timeoutOverride)
        elapsedTime = DateTime.Now

        while (self.MaxSocket.IsConnected and not self.Plugin.IsCanceled()):
            try:
                # Verify that Max is still running.
                self.Plugin.VerifyMonitoredManagedProcess(self.ProgramName)
                self.Plugin.FlushMonitoredManagedProcessStdout(self.ProgramName)

                # Check for any popup dialogs.
                blockingDialogMessage = self.Plugin.CheckForMonitoredManagedProcessPopups(self.ProgramName)
                if (blockingDialogMessage != ""):
                    self.Plugin.FailRender(blockingDialogMessage)

                start = DateTime.Now.Ticks
                while (TimeSpan.FromTicks(DateTime.Now.Ticks - start).Milliseconds < 500):

                    # if V-Ray or V-Ray RT DBR off-load job only.
                    if self.Plugin.VrayDBRJob or self.Plugin.VrayRtDBRJob or self.Plugin.CoronaDBRJob:

                        # Only for master TaskId:0 machine, update the local V-Ray *.cfg file.
                        if int(self.Plugin.GetCurrentTaskId()) == 0:

                            # Update DBR off-load cfg file if another 30 seconds has elapsed.
                            if DateTime.Now.Subtract(elapsedTime).TotalSeconds >= 30:

                                # reset the time interval.
                                elapsedTime = DateTime.Now

                                machines = self.GetDBRMachines()

                                # Update only if list of DBR machines has changed.
                                if self.DBRMachines != machines:

                                    if len(machines) > 0:
                                        self.Plugin.LogInfo(
                                            self.Plugin.Prefix + "Updating cfg file for distributed render with the following machines:")
                                        for machine in machines:
                                            self.Plugin.LogInfo(self.Plugin.Prefix + "  " + machine)
                                    else:
                                        self.Plugin.LogInfo(
                                            self.Plugin.Prefix + "0 machines available currently to DBR, local machine will be used unless configured in plugin settings to be ignored")

                                    # Update the V-Ray cfg file on the master machine.
                                    if self.Plugin.VrayDBRJob:
                                        self.UpdateVrayDBRConfigFile(machines, self.DBRConfigFile)
                                    elif self.Plugin.CoronaDBRJob:
                                        self.UpdateCoronaConfigFile(machines, self.DBRConfigFile)
                                    elif self.Plugin.VrayRtDBRJob:
                                        self.UpdateVrayRtDBRConfigFile(machines, self.DBRConfigFile)

                                    self.DBRMachines = machines

                    request = self.MaxSocket.Receive(500)

                    # We received a request, so reset the progress update timeout.
                    startTime = DateTime.Now

                    match = self.FunctionRegex.Match(request)
                    if (match.Success):
                        # Call the lightning function handler method to see if we should reply or if the render is finished.
                        reply = ""
                        try:
                            reply = self.LightingFunctionHandler(match.Groups[1].Value)
                            if (reply != ""):
                                self.MaxSocket.Send(reply)
                        except Exception as e:
                            self.Plugin.FailRender(e.Message)
                        continue

                    match = self.SuccessMessageRegex.Match(request)
                    if (match.Success):  # Render finished successfully
                        return match.Groups[1].Value

                    if (self.SuccessNoMessageRegex.IsMatch(request)):  # Render finished successfully
                        return ""

                    if (self.CanceledRegex.IsMatch(request)):  # Render was canceled
                        self.Plugin.FailRender("Render was canceled")
                        continue

                    match = self.ErrorRegex.Match(request)
                    if (match.Success):  # There was an error
                        self.Plugin.FailRender("%s\n%s" % (match.Groups[1].Value, self.NetworkLogGet()))
                        continue
            except Exception as e:
                if (isinstance(e, SimpleSocketTimeoutException)):
                    if timeoutEnabled and DateTime.Now.Subtract(startTime).TotalSeconds >= progressTimeout:
                        if timeoutOverride < 0:
                            self.Plugin.FailRender(
                                "Timed out waiting for the next progress update. The ProgressUpdateTimeout setting can be modified in the 3dsmax plugin configuration (current value is %d seconds).\n%s" % (
                                    self.ProgressUpdateTimeout, self.NetworkLogGet()))
                        else:
                            self.Plugin.FailRender(
                                "Timed out during script execution. Current value is %d seconds.\n%s" % (
                                    progressTimeout, self.NetworkLogGet()))
                elif (isinstance(e, SimpleSocketException)):
                    self.Plugin.FailRender("RenderTask: 3dsmax may have crashed (%s)" % e.Message)
                else:
                    self.Plugin.FailRender("RenderTask: Unexpected exception (%s)" % e.Message)

        if (self.Plugin.IsCanceled()):
            self.Plugin.FailRender("Render was canceled")

        if (not self.MaxSocket.IsConnected):
            self.Plugin.FailRender("Socket disconnected unexpectedly")

        return "undefined"

    def LightingFunctionHandler(self, request):
        try:
            match = self.ProgressRegex.Match(request)
            if (match.Success):
                progress = float(match.Groups[1].Value)
                if (progress >= 0):
                    if ((self.EndFrame - self.StartFrame) != -1):
                        length = (self.EndFrame - self.StartFrame + 1.0)
                        weightPercentage = 1.0 / length
                        completionPercentage = ((self.CurrentFrame - self.StartFrame) / length) * 100.0
                        actualProgress = (progress * weightPercentage) + completionPercentage
                        self.Plugin.SetProgress(actualProgress)
                    else:
                        self.Plugin.SetProgress(progress)

                return ""
        except:
            return ""

        try:
            match = self.SetTitleRegex.Match(request)
            if (match.Success):
                self.Plugin.SetStatusMessage("Frame " + str(self.CurrentFrame) + " - " + match.Groups[1].Value)
                return ""
        except:
            return ""

        try:
            match = self.StdoutRegex.Match(request)
            if (match.Success):
                self.Plugin.LogInfo(match.Groups[1].Value)
                return ""
        except:
            return ""

        try:
            match = self.WarnRegex.Match(request)
            if (match.Success):
                self.Plugin.LogWarning(match.Groups[1].Value)
                return ""
        except:
            return ""

        match = self.GetJobInfoEntryRegex.Match(request)
        if (match.Success):
            entry = self.Plugin.GetPluginInfoEntryWithDefault(match.Groups[1].Value, "")
            if (entry != ""):
                if RepositoryUtils.PathMappingRequired(entry):
                    entry = RepositoryUtils.CheckPathMapping(entry).replace("/", "\\")
                return "SUCCESS: " + entry
            else:
                return "NOVALUE"

        match = self.GetSubmitInfoEntryRegex.Match(request)
        if (match.Success):
            try:
                return "SUCCESS: " + self.Plugin.GetJobInfoEntry(match.Groups[1].Value)
            except:
                return "NOVALUE"

        match = self.GetSubmitInfoEntryElementCountRegex.Match(request)
        if (match.Success):
            try:
                return "SUCCESS: " + str(self.Plugin.GetJobInfoEntryElementCount(match.Groups[1].Value))
            except:
                return "NOVALUE"

        match = self.GetSubmitInfoEntryElementRegex.Match(request)
        if (match.Success):
            try:
                return "SUCCESS: " + self.Plugin.GetJobInfoEntryElement(match.Groups[2].Value,
                                                                        Convert.ToInt32(match.Groups[1].Value))
            except:
                return "NOVALUE"

        match = self.GetAuxFileRegex.Match(request)
        if (match.Success):
            try:
                return "SUCCESS: " + self.AuxiliaryFilenames[Convert.ToInt32(match.Groups[1].Value)]
            except:
                return "NOVALUE"

        match = self.GetPathMappedFilenameRegex.Match(request)
        if (match.Success):
            try:
                return "SUCCESS: " + RepositoryUtils.CheckPathMapping(match.Groups[1].Value)
            except:
                return "NOVALUE"

        else:
            # Unknown message.
            self.Plugin.FailRender(
                "Got unexpected request from the lightning max plugin: \"" + request + "\"\n" + self.NetworkLogGet())
            return "CANCEL"

        return ""


######################################################################
## This is the class that starts up the 3dsmax process.
######################################################################
class MaxProcess(ManagedProcess):
    MaxController = None

    def __init__(self, maxController):
        self.MaxController = maxController

        self.InitializeProcessCallback += self.InitializeProcess
        self.RenderExecutableCallback += self.RenderExecutable
        self.RenderArgumentCallback += self.RenderArgument
        self.StartupDirectoryCallback += self.StartupDirectory

    def Cleanup(self):
        for stdoutHandler in self.StdoutHandlers:
            del stdoutHandler.HandleCallback

        del self.InitializeProcessCallback
        del self.RenderExecutableCallback
        del self.RenderArgumentCallback
        del self.StartupDirectoryCallback

    def InitializeProcess(self):
        self.ProcessPriority = ProcessPriorityClass.BelowNormal
        self.UseProcessTree = True
        self.PopupHandling = self.MaxController.Plugin.GetBooleanPluginInfoEntryWithDefault("PopupHandling", True)
        self.StdoutHandling = True
        self.HideDosWindow = True

        if self.PopupHandling:
            self.HandleQtPopups = True
            self.SetEnvironmentVariable("QT_USE_NATIVE_WINDOWS", "1")
            self.HandleWindows10Popups = True

        # FumeFX initial values to support Task Render Status
        self.FumeFXStartFrame = 0
        self.FumeFXEndFrame = 0
        self.FumeFXCurrFrame = 0
        self.FumeFXMemUsed = "0Mb"
        self.FumeFXFrameTime = "00:00.00"
        self.FumeFXEstTime = "00:00:00"

        # FumeFX STDout Handlers (requires min. FumeFX v3.5.3)
        self.AddStdoutHandlerCallback(
            ".*FumeFX: Starting simulation \(([-]?[0-9]+) - ([-]?[0-9]+)\).*").HandleCallback += self.HandleFumeFXProgress  # 0: STDOUT: "FumeFX: Starting simulation (-20 - 40)."
        self.AddStdoutHandlerCallback(
            ".*FumeFX: Frame: ([-]?[0-9]+)").HandleCallback += self.HandleFumeFXProgress  # 0: STDOUT: "FumeFX: Frame: -15"
        self.AddStdoutHandlerCallback(
            ".*FumeFX: Memory used: ([0-9]+[a-zA-Z]*)").HandleCallback += self.HandleFumeFXProgress  # 0: STDOUT: "FumeFX: Memory used: 86Mb"
        self.AddStdoutHandlerCallback(
            ".*FumeFX: Frame time: ([0-9]+:[0-9]+\.[0-9]+)").HandleCallback += self.HandleFumeFXProgress  # 0: STDOUT: "FumeFX: Frame time: 00:01.69"
        self.AddStdoutHandlerCallback(
            ".*FumeFX: Estimated Time: ([0-9]+:[0-9]+:[0-9]+)").HandleCallback += self.HandleFumeFXProgress  # 0: STDOUT: "FumeFX: Estimated Time: 00:00:18"

        self.SetupCPUAffinity()

        # For Brazil
        self.AddPopupIgnorer(".*Brazil Console.*")

        # For Finalrender
        self.AddPopupIgnorer(".*MSP Acceleration.*")

        # For Fume FX
        self.AddPopupIgnorer(".*FumeFX.*")
        self.AddPopupIgnorer(".*FumeFX Dynamics:.*")
        self.AddPopupHandler("FumeFX\s*$", "Yes")

        # For Maxwell
        self.AddPopupIgnorer(".*Maxwell Translation Window.*")
        self.AddPopupIgnorer(".*Import Multilight.*")

        # For Craft Director Tools
        self.AddPopupIgnorer(".*New updates are available - Craft Director Tools.*")

        # For Hair Farm progress dialog
        self.AddPopupIgnorer("Hair Farm")

        # For render progress dialog
        self.AddPopupIgnorer("Batch Render In Progress")

        # For Pencil plugin
        self.AddPopupIgnorer("Pencil")

        # Network Cloth Simulation dialog
        self.AddPopupIgnorer("Cloth")

        # Handle Render History Settings dialog
        self.AddPopupIgnorer(".*Render history settings.*")
        self.AddPopupIgnorer(".*Render history note.*")
        # self.AddPopupHandler( ".*Render history settings.*", "OK;No" )

        # Ignore "Animation_Range.ms" MaxScript dialog from www.illusionstudioinc.com
        self.AddPopupIgnorer("Animation Range")

        # Ignore TIF Image settings dialog when saving render image currently being rendered by Corona
        self.AddPopupIgnorer("TIF Image Control")

        # For V-Ray in workstation mode (such as when rendering mental ray)
        self.AddPopupHandler(".*VRay authorization.*", "Cancel")
        self.AddPopupHandler(".*V-Ray warning.*", "OK")

        # Error loading file - unsupported save version
        # 3dsMax attempting to open a Max scene file saved with a newer version of 3dsMax
        # self.AddPopupHandler( "File Load", "OK" )

        # For File Units Mismatch dialog
        self.AddPopupHandler(".*File Load: Units Mismatch.*", "Adopt the File's Unit Scale?;OK")

        # Handle Autodesk 3dsMax2010+ "File Load: Gamma & LUT Settings Mismatch" dialog in workstation mode
        # Do you want to: "Adopt the File's Gamma and LUT Settings?"
        self.AddPopupHandler(".*File Load: Gamma & LUT Settings Mismatch.*",
                             "Adopt the File's Gamma and LUT Settings?;OK")

        # Handle 3ds Max "gamma/LUT correction" dialog in workstation mode (<=3dsMax2009)
        # "Do you want gamma/LUT correction to be ENABLED to correspond with the setting in this file?" Yes or No; OK for older versions of 3dsMax
        self.AddPopupHandler("3ds Max", "Yes;OK")

        # Handle NTSC PAL Animation
        self.AddPopupHandler(".*Frame Rate Change.*", "OK")

        # Handle Crash dialog
        self.AddPopupHandler(".*Warning - the software has encountered a problem.*",
                             "Don't show me this error again;Continue")

        # Handle Frantic Films' FPS Watchdog dialog
        self.AddPopupHandler(".*Frantic Films FPS Watchdog.*", "OK")

        # Handle Missing DLLs dialog in workstation mode
        self.AddPopupHandler(".*Missing Dlls.*", "Cancel")

        # Handle Missing External Files dialog in workstation mode
        self.AddPopupHandler(".*Missing External Files.*", "Continue")

        # Handle Brazil Rio warning dialog
        self.AddPopupHandler("Brazil r/s Rio Warning", "OK")

        # Handle a 3dsmax warning dialog
        self.AddPopupHandler("3D Studio MAX", "OK")

        # Handle Craft Director Tools software update dialog
        self.AddPopupHandler(".*New updates are available - Craft Director Tools.*", "Cancel")

        # Handle Standard MAX Pop-Up dialog
        self.AddPopupHandler(".*Pop-up Note.*", "OK")

        # Handle Wacom Tablet Version Mismatch dialog
        self.AddPopupHandler(".*Tablet Version Mismatch.*", "OK")

        # Handle Wacom Tablet Driver dialog
        self.AddPopupHandler(".*Tablet Driver.*", "OK")

        # Handle Craft Director Tools Missing Nodes dialog
        self.AddPopupHandler(".*Gather error.*", "OK")

        # Handle Image I/O Error dialog
        self.AddPopupHandler(".*Image I/O Error.*", "Cancel")

        # Handle nPower Plug-in Messages dialog
        self.AddPopupHandler(".*Important nPower Plug-in Messages.*", "OK")

        # Handle Glu3D Plugin Version Expired Warning dialog
        self.AddPopupHandler(".*glu3D.*", "OK")

        # Handle Glu3D No Particle/Mesh Cache Warning dialog
        self.AddPopupHandler(".*glu3D Warning!.*", "OK")

        # Handle Bitmap Filter Error dialog
        self.AddPopupHandler(".*Bitmap Filter Error.*", "OK")

        # Handle Maxwell Plug-in Update Notification dialog
        self.AddPopupHandler(".*Maxwell Plug-in Update Notification.*",
                             "Don't notify me about this version automatically;Close")

        # Handle RealFlow Plug-in Update Notification dialog
        self.AddPopupHandler(".*RealFlow Plug-in Update Notification.*",
                             "Don't notify me about this version automatically;Close")

        # Handle 3dsMax Learning Movies (Essential Skills Movies) dialog in workstation mode (first time 3dsMax starts up only)
        self.AddPopupHandler(".*Learning Movies.*", "Show this dialog at startup;Close")

        # Handle Obsolete File dialog in workstation mode
        self.AddPopupHandler(".*Obsolete File.*", "Don't display this message.;OK")

        # Handle "Error Loading" dialog due to a corrupt node/geometry in the 3dsMax scene (normally found with data transferred from Maya/FBX files)
        self.AddPopupHandler("Error Loading", "OK")

        # Handle "IO Error" dialog in workstation mode due to 3dsMax "Set Project Folder" incorrect. Error Message: "The following configuration path(s) do not exist."
        # Typically this error occurs due to a part of the 3dsMax project folder structure being set to a location that no longer exists.
        self.AddPopupHandler(".*IO Error.*", "OK")

        # Handle "Error" dialog due to "Loading of custom driver failed:Forcing null driver mode" incompatible graphics driver identified in 3dsmax.ini
        self.AddPopupHandler("Error", "OK")
        self.AddPopupHandler(".*Loading of custom driver failed.*", "OK")

        # Handle "Warning" dialog due rendering Hair with high-poly growth objects.
        # Handle "Warning" MassFX authored dialog when "SaveAsPrevious" Max Scene File has been used
        # The MassFX authored in this file was created with a newer version of the plugins. Forward compatibility is not supported, so things might not behave properly.
        self.AddPopupHandler("Warning", "OK")

        # Handle Vue xStream "Welcome New User!" Dialog in GUI / Workstation mode
        self.AddPopupHandler(".*Welcome To Vue [0-9]+[\.]?[0-9]? xStream!.*", "Don't show this dialog again;Close")

        # Handle Vue xStream Dialog: Switching to OpenGL Engine when an incompatible graphics card is detected
        self.AddPopupHandler(".*Vue [0-9]+[\.]?[0-9]? xStream.*", "OK")

        # Handle 3ds Max Performance Driver Dialog in GUI / Workstation mode
        self.AddPopupHandler(".*3ds Max Performance Driver.*", "OK")

        # Handle [Autodesk] Customer Involvement Program dialog in workstation mode
        # [Autodesk] - this word was added to later versions of this dialog, so ignore it in the RegEx below
        # Default setting is "Participate Anonymously"
        self.AddPopupHandler(".*Customer Involvement Program.*",
                             "Participate &anonymously ;Participate &Anonymously;No, thanks.;OK")

        # nPower Software Plugin Product Selection Dialog - v7.00+ - Potential Options Below:
        # Geometry Creation - [Power Solids], [Power BODY Toolkit], [Power NURBS Pro]
        # Standard Translators - [Power Translators], [Power Translators Pro], [Power Translators Rhino]
        # Bundles - [Solids Bundle (Solids + Translators)], [NURBS Bundle (NURBS + Translators)]
        # Native Translators - [Power Translators Universal]
        self.AddPopupHandler(".*nPower Software Plugin Product Selection Dialog.*",
                             "Solids Bundle (Solids + Translators);OK")

        # Handle "An exception occurred when loading DRA" error that can popup
        self.AddPopupHandler(".*Exception.*", "OK")

        # DbxHost Message - causes both 3dsMax and Deadline Worker app to crash out
        # ObjectDBX has reported a fatal error: Unable to load the Modeler DLLs
        # http://www.the-area.com/forum/autodesk-3ds-max/3ds-max-through-2008/error-upon-startup/
        # http://forums.cgsociety.org/showthread.php?t=835640
        # http://usa.autodesk.com/adsk/servlet/ps/dl/item?siteID=123112&id=5581859&linkID=9241177
        self.AddPopupHandler(".*DbxHost Message.*", "OK")

        # Handle the "Unable to write to FumeFX.ini" error
        self.AddPopupHandler("File error", "OK")

        # Handle Hair high-poly growth object
        self.AddPopupHandler(".*Hair with high-poly growth objects.*", "OK")

        # Ignore GrowFX progress popup
        self.AddPopupIgnorer(".*GrowFX Progress.*")

        # Windows 7 OS - Application Crash Window
        self.AddPopupHandler("3ds Max application", "Cancel;Close the program")

        # Handle "MAXScript Auto-load Script Error" warning dialog
        self.AddPopupHandler(".*MAXScript Auto-load Script Error.*", "OK")

        # MAXScript Callback script Exception Dialog
        self.AddPopupHandler(".*MAXScript Callback script Exception.*", "OK")

        # Autodesk 3dsMax - "The software license check out failed"
        self.AddPopupHandler("Autodesk 3ds Max 20.*", "OK")

        # Handle Application Crash - "An error has occurred and the application will now close. Do you want to attempt to save a copy of the current scene?"
        self.AddPopupHandler("Application Error", "OK")

        # ADSK 3dsMax Error Report - "A software problem has caused 3ds Max to close unexpectedly."
        # "We apologize for the inconvenience. An error report has been generated. Please click Send Report to help us analyze the cause of the problem."
        self.AddPopupHandler("3ds Max Error Report", "&Send Report")

        # Handle "Startup Error - Splash.dll - Entry Point Not Found" issue in Max2010/2011/2012
        # For more info: http://area.autodesk.com/blogs/maxstation/l3_startup_error_splash_dll_entry_point_not_found
        # "The procedure entry point ?getAppHInst@ResourceManager@@QAEPAUHINSTANCE_@@XZ could not be located in the dynamic link library splash.dll"
        self.AddPopupHandler("3dsmax.exe - Entry Point Not Found", "OK")

        # Handle XAML Parse Error Dialog in Workstation Mode - Title "XAML Parse Error", Message "Error parsing Xaml file: 'WPFCustomControls.ActionItemExtension' value cannot
        # be assigned to property 'CommandHandler' of object 'WPFCustomControls.MaxRibbonToggleButton'. ActionItem not found.  Error at object 'WPFCustomControls.ActionItemExtension', Line xx Position xx."
        self.AddPopupHandler("XAML Parse Error", "OK")

        # "The main Ribbon configuration file is possibly corrupt. Reset to factory defaults?"
        self.AddPopupHandler("Reset Ribbon?", "Yes")

        # Handle Error Loading Ribbon Extension Dialog - Brazil v2
        self.AddPopupHandler("Error Loading Ribbon Extension", "OK")

        # Handle MEM's Max2Maya Warning Dialog - maya viewport navigation in 3ds Max
        # "An older instance of this script is already running.  Replace it with this instance? Note: To avoid this message, see #SingleInstance in the help file."
        # http://www.scriptspot.com/3ds-max/plugins/mems-max2maya-maya-viewport-navigation-in-3ds-max
        self.AddPopupHandler("MEMsMax2MayaX64.exe", "Yes")

        # 3D Connexion Mouse News Dialog
        self.AddPopupHandler(".*3D Mouse News.*", "Show this dialog at startup")

        # MultiScatter License Warning Dialog
        self.AddPopupHandler("MultiScatter", "OK")

        # nPower Software's BREP v9.2+ License Issue
        # [nPower] Please purchase this product in order to use it. If you were not prompted with the licensing dialog, try re-running the program as administrator.
        self.AddPopupHandler("Start-up Error #2", "OK")

        # nPower Plugins 9/10 for 3DS MAX
        # Thank you for trying nPower Plugins 9 for 3DS MAX. Your trial has expired.
        self.AddPopupHandler("nPower Plugins [0-9]+ for 3DS MAX", "Exit")

        # Craft Camera Tools - [Error loading plugin]
        self.AddPopupHandler("Error loading plugin", "OK")

        # QT Popups
        self.AddPopupHandler("Welcome to 3ds Max", "[X]")

        # Ignore 3dsMax MAXScript Debugger Popup (ENU, FRA, DEU, JPN, CHS, KOR, PTB)
        self.AddPopupIgnorer("MAXScript .*")  # ENU #JPN #CHS #KOR
        self.AddPopupIgnorer(".* MAXScript")  # FRA #PTB
        self.AddPopupIgnorer("MAXScript-Debugger")  # DEU
        self.AddPopupIgnorer("MAXScript-Aufzeichnung")

        # Craft Camera Tools - [Gather error]
        # Some nodes were found belonging to Craft Director Studio, but they were never claimed.
        # Typical error message: "The following nodes were left out: 4WheelerExt_01_*"
        self.AddPopupHandler("Gather error", "OK")

        # Handle Isolate Selection dialog in workstation mode
        # WARNING Message - "One or more objects are currently Isolated"
        self.AddPopupHandler(".*Isolate Selection.*", "OK")

        # Microsoft Windows - "Virtual Memory Minimum Too Low" warning dialog - Page File Issue
        self.AddPopupHandler(".*Windows - Virtual Memory Minimum Too Low.*", "OK")

        # Handle Houdini Ocean Toolkit Public Version About Pop-up Dialog
        self.AddPopupHandler("About Hot4MAX", "OK")

        # Handle Generic missing plug-in DLL referenced by 3rd party software/plugin
        self.AddPopupHandler("Error Loading Plug-in DLL", "OK")

        # Handle Targa Image Control Pop-up Dialog
        self.AddPopupHandler("Targa Image Control", "OK")

        # Handle Max2015+ Desktop Analytics Program Dialog
        self.AddPopupHandler("Desktop Analytics Program", "OK")

        # Handle Autodesk "License Borrowed" dialog
        self.AddPopupHandler(".*License.*", "Close")

        # Handle Populate dialog in 3ds Max 2015+
        self.AddPopupHandler("Populate", "OK")

        # Handle Program Compatibility Assistant dialog
        self.AddPopupHandler("Program Compatibility Assistant", "Close")

        # Handle Corona Renderer Licensing dialog in Workstation Mode
        # self.AddPopupHandler( "Corona Renderer Licensing", "Activate demo for 45 days;Next>;Finish" )

        # Handle Corona VFB Saving Options
        self.AddPopupIgnorer(".*Save Image.*")
        self.AddPopupIgnorer(".*Confirmation.*")
        self.AddPopupIgnorer(".*Save as.*")
        self.AddPopupIgnorer(".*Select file.*")
        self.AddPopupIgnorer(".*File Exists.*")
        self.AddPopupIgnorer(".*Curve Editor.*")

        # Handle Corona Error Message dialog
        self.AddPopupIgnorer("Corona Error Message(s)")

        # Ignore 3dsMax State Sets dialog (visible when HandleWindows10Popups=True)
        self.AddPopupIgnorer("State Sets")  # English
        self.AddPopupIgnorer(u"Jeux d'\\xe9tats")  # French
        self.AddPopupIgnorer(u"\\u30b9\\u30c6\\u30fc\\u30c8\\u30bb\\u30c3\\u30c8")  # Japanese
        self.AddPopupIgnorer(u"\\u72b6\\u6001\\u96c6")  # Chinese

        # Handle PNG Plugin - [PNG Library Internal Error]
        self.AddPopupHandler("PNG Plugin", "OK")

        # Ignore Redshift Render View
        self.AddPopupIgnorer("3dsmax")
        self.AddPopupIgnorer("Save Image As")
        self.AddPopupIgnorer("Save Multilayer EXR As")
        self.AddPopupIgnorer("Select snapshots folder")

        # Ignore SiNi Software popup
        self.AddPopupIgnorer(".*SiNi Software.*")

    def RenderExecutable(self):
        return self.MaxController.ManagedMaxProcessRenderExecutable

    def RenderArgument(self):
        return self.MaxController.ManagedMaxProcessRenderArgument

    def StartupDirectory(self):
        return self.MaxController.ManagedMaxProcessStartupDirectory

    def HandleFumeFXProgress(self):
        if re.match(r"FumeFX: Starting simulation ", self.GetRegexMatch(0)):
            self.FumeFXStartFrame = self.GetRegexMatch(1)
            self.FumeFXEndFrame = self.GetRegexMatch(2)
        elif re.match(r"FumeFX: Frame: ", self.GetRegexMatch(0)):
            self.FumeFXCurrFrame = self.GetRegexMatch(1)
            denominator = float(self.FumeFXEndFrame) - float(self.FumeFXStartFrame) + 1.0
            progress = ((float(self.FumeFXCurrFrame) - float(self.FumeFXStartFrame) + 1.0) / denominator) * 100.0
            self.MaxController.Plugin.SetProgress(progress)
            msg = "FumeFX: (" + str(self.FumeFXCurrFrame) + " to " + str(self.FumeFXEndFrame) + ") - Mem: " + str(
                self.FumeFXMemUsed) + " - LastTime: " + str(self.FumeFXFrameTime) + " - ETA: " + str(self.FumeFXEstTime)
            self.MaxController.Plugin.SetStatusMessage(msg)
        elif re.match(r"FumeFX: Memory used:", self.GetRegexMatch(0)):
            self.FumeFXMemUsed = self.GetRegexMatch(1)
        elif re.match(r"FumeFX: Frame time:", self.GetRegexMatch(0)):
            self.FumeFXFrameTime = self.GetRegexMatch(1)
        elif re.match(r"FumeFX: Estimated Time:", self.GetRegexMatch(0)):
            self.FumeFXEstTime = self.GetRegexMatch(1)
        else:
            pass

    def SetupCPUAffinity(self):
        """
        Modifies the plugin CPU affinity to be a subset of the Current CPU affinity based off the number of render threads specified.
        This also applies some V-Ray Specific settings to force v-ray to respect the cpu affinity in older versions and the number of render threads in current versions.
        """

        try:
            # Try to access the old OneCpuPerTask variable first. If it is not set then use the new variable.
            threads = int(self.MaxController.Plugin.GetBooleanPluginInfoEntry("OneCpuPerTask"))
        except RenderPluginException:
            threads = self.MaxController.Plugin.GetIntegerPluginInfoEntryWithDefault("RenderThreads", 0)
        submittedThreads = bool(threads)

        overrideMessage = ["The following CPU's will be used for this render:"]

        if self.MaxController.Plugin.OverrideCpuAffinity():
            overrideMessage.insert(0, "The Worker is overriding its CPU affinity.")
            availableCPUs = list(self.MaxController.Plugin.CpuAffinity())
            if not availableCPUs:
                self.MaxController.Plugin.FailRender("The Worker does not have affinity for any CPUs.")

            if threads == 0 or (threads > 0 and len(availableCPUs) < threads):
                threads = len(availableCPUs)
        else:
            availableCPUs = range(SystemUtils.GetCpuCount())

        if threads:
            self.MaxController.Plugin.LogInfo("Setting VRAY_USE_THREAD_AFFINITY to 0 to ensure CPU Affinity works.")
            self.SetEnvironmentVariable("VRAY_USE_THREAD_AFFINITY", "0")

            self.MaxController.Plugin.LogInfo("Setting VRAY_NUM_THREADS environment variable to %s" % threads)
            self.SetEnvironmentVariable("VRAY_NUM_THREADS", str(threads))

            cpuCount = len(availableCPUs)

            # If the Worker has multiple render threads we want to reduce as much overlap as we can.
            startIndex = (self.MaxController.Plugin.GetThreadNumber() * threads) % cpuCount
            endIndex = (startIndex + threads) % cpuCount
            if startIndex < endIndex:
                cpus = availableCPUs[startIndex:endIndex]
            else:
                # If there are multiple render threads going we could roll over the available CPUs in which case we need to grab from both ends of the available CPUs
                cpus = availableCPUs[:endIndex] + availableCPUs[startIndex:]

            overrideMessage.append(",".join(str(x) for x in cpus))

            self.MaxController.Plugin.LogWarning(" ".join(overrideMessage))
            self.ProcessAffinity = cpus


######################################################################
## This is the class that starts up the V-Ray Spawner process.
######################################################################
class VRaySpawnerProcess(ManagedProcess):
    Plugin = None
    IsRT = False

    def __init__(self, plugin, isRT):
        self.Plugin = plugin
        self.IsRt = isRT

        self.InitializeProcessCallback += self.InitializeProcess
        self.RenderArgumentCallback += self.RenderArgument
        self.RenderExecutableCallback += self.RenderExecutable

    def Cleanup(self):
        for stdoutHandler in self.StdoutHandlers:
            del stdoutHandler.HandleCallback

        del self.InitializeProcessCallback
        del self.RenderArgumentCallback
        del self.RenderExecutableCallback

    def InitializeProcess(self):
        # Set the process specific settings.
        self.ProcessPriority = ProcessPriorityClass.BelowNormal
        self.UseProcessTree = True
        self.PopupHandling = True
        self.StdoutHandling = True
        self.HideDosWindow = True
        self.HandleQtPopups = True
        self.SetEnvironmentVariable("QT_USE_NATIVE_WINDOWS", "1")

        # Ignore 3dsMax MAXScript Debugger Popup (ENU, FRA, DEU, JPN, CHS, KOR, PTB)
        self.AddPopupIgnorer("MAXScript .*")  # ENU #JPN #CHS #KOR
        self.AddPopupIgnorer(".* MAXScript")  # FRA #PTB
        self.AddPopupIgnorer("MAXScript-Debugger")  # DEU

        # Handle Corona VFB Saving Options
        self.AddPopupIgnorer(".*Save Image.*")
        self.AddPopupIgnorer(".*Confirmation.*")
        self.AddPopupIgnorer(".*Save as.*")
        self.AddPopupIgnorer(".*Select file.*")
        self.AddPopupIgnorer(".*File Exists.*")
        self.AddPopupIgnorer(".*Curve Editor.*")

        # Handle Corona Error Message dialog
        self.AddPopupIgnorer("Corona Error Message(s)")

        # For Maxwell
        self.AddPopupIgnorer(".*Maxwell Translation Window.*")
        self.AddPopupIgnorer(".*Import Multilight.*")

        # If we're overriding CPU Affinity, ensure it works for V-Ray by setting their environment variable
        if self.Plugin.OverrideCpuAffinity():
            self.Plugin.LogInfo("Setting VRAY_USE_THREAD_AFFINITY to 0 to ensure CPU Affinity works.")
            self.SetEnvironmentVariable("VRAY_USE_THREAD_AFFINITY", "0")

        # Only V-Ray RT uses the GPU
        if self.IsRt:
            # Check if we are overriding GPU affinity
            selectedGPUs = self.Plugin.MyMaxController.GetGpuOverrides()
            if len(selectedGPUs) > 0:
                vrayGpus = "index" + ";index".join([str(gpu) for gpu in selectedGPUs])  # "index0;index1"
                self.Plugin.LogInfo(
                    "This Worker is overriding its GPU affinity, so the following GPUs will be used by V-Ray RT: %s" % vrayGpus)
                self.SetEnvironmentVariable("VRAY_OPENCL_PLATFORMS_x64", vrayGpus)  # V-Ray RT

    def GetVraySpawnerEnvironmet(self, maxVersion):
        """"
        以max2018为列 max2022，2023 是特殊加载架构，单独处理
        vray3 VRAY30_RT_FOR_3DSMAX2018_MAIN_x64
        vray4 VRAY4_FOR_3DSMAX2018_MAIN
        vray5 VRAY5_FOR_3DSMAX2018_MAIN
        vray6 VRAY_FOR_3DSMAX2018_MAIN
        默认按照环境变量定义的方式查找vrayspawner ，找不到的由自定义的环境变量名称 VRAY_FOR_3DSMAX_ROOT 查找。
        """
        job = self.Plugin.GetJob()
        vraySpawnerExepath = ""
        vray_max_root = job.GetJobEnvironmentKeyValue("{}".format("VRAY_FOR_3DSMAX_ROOT"))
        self.Plugin.LogInfo("vray_max_root = {}".format(vray_max_root))
        vraySpawnerExepath = "{0}\\vrayspawner{1}.exe".format(vray_max_root, maxVersion)
        self.Plugin.LogInfo("vraySpawnerExepath = {}".format(vraySpawnerExepath))
        if os.path.exists(vraySpawnerExepath) and os.path.isfile(vraySpawnerExepath):
            self.Plugin.LogInfo("vraySpawnerExepath = {}".format(vraySpawnerExepath))
        else:
            vray_max_root = job.GetJobEnvironmentKeyValue("{}".format("VRAY_ROOT_PATH"))
            vraySpawnerExepath = "{0}\\vrayspawner{1}.exe".format(vray_max_root, maxVersion)
            self.Plugin.LogInfo("vraySpawnerExepath2 = {}".format(vraySpawnerExepath))

        return vraySpawnerExepath

    def RenderExecutable(self):
        version = self.Plugin.GetIntegerPluginInfoEntry("Version")
        if (version < 2010):
            self.Plugin.FailRender(self.Plugin.Prefix + "Only 3dsmax 2010 and later is supported")

        isMaxDesign = self.Plugin.GetBooleanPluginInfoEntryWithDefault("IsMaxDesign", False)
        forceBuild = self.Plugin.GetPluginInfoEntryWithDefault("MaxVersionToForce", "none").lower()
        if (version > 2013):
            forceBuild = "none"

        # Figure out the render executable to use for rendering.
        if self.IsRt:
            exeList = ";".join([
                r"C:\Program Files\Chaos Group\V-Ray\RT for 3ds Max %s for x64\bin\vrayrtspawner.exe" % version,
                r"C:\Program Files\Chaos Group\V-Ray\RT for 3ds Max %s for x86\bin\vrayrtspawner.exe" % version,
                r"C:\Program Files (x86)\Chaos Group\V-Ray\RT for 3ds Max %s for x86\bin\vrayrtspawner.exe" % version,
                ])

            vraySpawnerExecutable = FileUtils.SearchFileList(exeList)

            if (vraySpawnerExecutable == ""):
                self.Plugin.FailRender(
                    self.Plugin.Prefix + "Could not find V-Ray Spawner executable in the following locations: " + exeList)
        else:
            renderExecutableKey = "RenderExecutable" + str(version)
            prettyName = "3ds Max %s" % str(version)
            if isMaxDesign:
                renderExecutableKey = renderExecutableKey + "Design"
                prettyName = "3ds Max Design %s" % str(self.Version)

            maxRenderExecutable = self.Plugin.GetRenderExecutable(renderExecutableKey, prettyName)
            self.maxRenderExecutable =maxRenderExecutable
            self.Plugin.LogInfo(self.Plugin.Prefix + "3ds Max executable: %s" % maxRenderExecutable)
            # vraySpawnerExecutable = PathUtils.ChangeFilename( maxRenderExecutable, "vrayspawner" + str(version) + ".exe" )
            ###  modify by xubaolong for get vray spawner Executable by plugins libs ###
            vraySpawnerExecutable = self.GetVraySpawnerEnvironmet(version)
            self.Plugin.LogInfo("vraySpawnerExecutable final = {}".format( str (vraySpawnerExecutable)))
            if not os.path.exists(vraySpawnerExecutable):
                vraySpawnerExecutable = PathUtils.ChangeFilename(maxRenderExecutable,
                                                                 "vrayspawner" + str(version) + ".exe")
                if int(version) > 2021:
                    vraySpawnerExecutable = r"C:\ProgramData\Autodesk\ApplicationPlugins\VRay3dsMax{}\bin\vrayspawner{}.exe".format(
                        version, version)
                else:
                    vraySpawnerExecutable = r"C:\Program Files\Autodesk\3ds Max {}\vrayspawner{}.exe".format(version,
                                                                                                             version)
            if not os.path.isfile(vraySpawnerExecutable):
                self.Plugin.FailRender(
                    self.Plugin.Prefix + "V-Ray Spawner executable does not exist: " + vraySpawnerExecutable)

        self.Plugin.LogInfo(self.Plugin.Prefix + "Spawner executable: %s" % vraySpawnerExecutable)

        vraySpawnerExecutableVersion = FileVersionInfo.GetVersionInfo(vraySpawnerExecutable)
        self.Plugin.LogInfo(
            self.Plugin.Prefix + "Spawner executable version: %s" % vraySpawnerExecutableVersion.FileVersion)

        # Handle pre-existing v-ray spawner instance running on machine.
        spawnerExistingProcess = self.Plugin.GetConfigEntryWithDefault("VRaySpawnerExistingProcess",
                                                                       "Fail On Existing Process")
        self.Plugin.LogInfo(self.Plugin.Prefix + "Existing V-Ray Spawner Process: %s" % spawnerExistingProcess)

        processName = Path.GetFileNameWithoutExtension(vraySpawnerExecutable)
        if (ProcessUtils.IsProcessRunning(processName)):
            processes = Process.GetProcessesByName(processName)

            if len(processes) > 0:
                self.Plugin.LogWarning(self.Plugin.Prefix + "Found existing '%s' process" % processName)
                process = processes[0]

                if (spawnerExistingProcess == "Fail On Existing Process"):
                    if process != None:
                        self.Plugin.FailRender(
                            self.Plugin.Prefix + "Fail On Existing Process is enabled, and a process '%s' with pid '%d' exists - shut down this copy of V-Ray Spawner. Ensure V-Ray Spawner is NOT already running! (GUI or Service Mode)" % (
                                processName, process.Id))

                if (spawnerExistingProcess == "Kill On Existing Process"):
                    if (ProcessUtils.KillProcesses(processName)):
                        if process != None:
                            self.Plugin.LogInfo(
                                self.Plugin.Prefix + "Successfully killed V-Ray Spawner process: '%s' with pid: '%d'" % (
                                    processName, process.Id))

                        SystemUtils.Sleep(5000)

                        if (ProcessUtils.IsProcessRunning(processName)):
                            self.Plugin.LogWarning(
                                self.Plugin.Prefix + "V-Ray Spawner is still running: '%s' process, perhaps due to it being automatically restarted after the previous kill command. Ensure V-Ray Spawner is NOT already running! (GUI or Service Mode)" % processName)
                            process = Process.GetProcessesByName(processName)[0]
                            if process != None:
                                self.Plugin.FailRender(
                                    self.Plugin.Prefix + "Kill On Existing Process is enabled, and a process '%s' with pid '%d' still exists after executing a kill command. Ensure V-Ray Spawner is NOT already running! (GUI or Service Mode)" % (
                                        processName, process.Id))

        return vraySpawnerExecutable

    def RenderArgument(self):
        self.MaxPluginIni = self.Plugin.GetPluginInfoEntryWithDefault("OverridePluginIni", "")
        if self.MaxPluginIni:
            vraySpawnerExecutableCMD = ' -AppName="{}" -cmdparams="-p {}"'.format( self.maxRenderExecutable, self.MaxPluginIni)
            return vraySpawnerExecutableCMD
        else:
            return ""


######################################################################
## This is the class that starts up the Corona DRServer process.
######################################################################
class CoronaDRProcess(ManagedProcess):
    def __init__(self, plugin):
        self.Plugin = plugin
        self.TempFolder = self.Plugin.CreateTempDirectory(str(self.Plugin.GetThreadNumber()))
        self.Plugin.LogInfo("Temp folder: " + self.TempFolder)

        self.InitializeProcessCallback += self.InitializeProcess
        self.RenderArgumentCallback += self.RenderArgument
        self.RenderExecutableCallback += self.RenderExecutable

    def Cleanup(self):
        for stdoutHandler in self.StdoutHandlers:
            del stdoutHandler.HandleCallback

        del self.InitializeProcessCallback
        del self.RenderArgumentCallback
        del self.RenderExecutableCallback

    def InitializeProcess(self):
        # Set the process specific settings.
        self.ProcessPriority = ProcessPriorityClass.BelowNormal
        self.UseProcessTree = True
        self.PopupHandling = True
        self.StdoutHandling = True
        self.HideDosWindow = True
        self.HandleQtPopups = True
        self.SetEnvironmentVariable("QT_USE_NATIVE_WINDOWS", "1")

        # Ignore 3dsMax MAXScript Debugger Popup (ENU, FRA, DEU, JPN, CHS, KOR, PTB)
        self.AddPopupIgnorer("MAXScript .*")  # ENU #JPN #CHS #KOR
        self.AddPopupIgnorer(".* MAXScript")  # FRA #PTB
        self.AddPopupIgnorer("MAXScript-Debugger")  # DEU

        # Handle Corona VFB Saving Options
        self.AddPopupIgnorer(".*Save Image.*")
        self.AddPopupIgnorer(".*Confirmation.*")
        self.AddPopupIgnorer(".*Save as.*")
        self.AddPopupIgnorer(".*Select file.*")
        self.AddPopupIgnorer(".*File Exists.*")
        self.AddPopupIgnorer(".*Curve Editor.*")

        # Handle Corona Error Message dialog
        self.AddPopupIgnorer("Corona Error Message(s)")

        # For Maxwell
        self.AddPopupIgnorer(".*Maxwell Translation Window.*")
        self.AddPopupIgnorer(".*Import Multilight.*")

        # Handle Program Compatibility Assistant dialog
        self.AddPopupHandler("Program Compatibility Assistant", "Close")

        self.Plugin.SetProcessEnvironmentVariable("NW_ROOT_PATH", self.TempFolder)

    ## add by xubaolong
    def createDrConfig(self, version):
        import platform
        if not os.path.exists("C:\\Users\\administrator\\AppData\\Local\\CoronaRenderer\\DrData"):
            os.makedirs("C:\\Users\\administrator\\AppData\\Local\\CoronaRenderer\\DrData")

        f = open("C:\\Users\\administrator\\AppData\\Local\\CoronaRenderer\\DrData\\DrConfig.txt", "w")
        f.write("RetainEXR = false\n")
        f.write("Default = {}\n".format(version))
        f.write("SizeLimit = 10737418240\n")
        f.write("SlaveName = {}\n".format(platform.node()))
        f.write("RestartMax = false\n")
        f.close()

    ## Corona DrServer lauch 3dsmaxcmd.exe instead of 3dsmax.exe, so have to copy the plugin.ini to 3dsmax install folder.
    def CopyPluginInis(self, version):
        job = self.Plugin.GetJob()

        renderExecutableKey = "RenderExecutable" + str(version)
        prettyName = "3ds Max %s" % str(version)

        maxRenderExecutable = self.Plugin.GetRenderExecutable(renderExecutableKey, prettyName)

        override_plugin_ini = self.Plugin.GetPluginInfoEntryWithDefault("OverridePluginIni", "")
        if not os.path.exists(override_plugin_ini):
            return
        maxRoot = Path.GetDirectoryName(maxRenderExecutable)

        self.Plugin.LogInfo("maxRoot: {}, plugin ini {}".format(maxRoot, override_plugin_ini))

        if version < 2013:
            File.Copy(override_plugin_ini, maxRoot)
        else:
            File.Copy(override_plugin_ini, Path.Combine(maxRoot, "en-US", "plugin.ini"), True)
            File.Copy(override_plugin_ini, Path.Combine(maxRoot, "zh-CN", "plugin.ini"), True)

    def GetCoronaSpawnerEnvironmet(self, maxVersion):
        """"
        corona 的yaml ，增加 一对KV.用于处理corona DR的调用地址  详细情况可以查看插件库的max2022 corona 8.1
        CORONA_DR_EXECUTE_PATH:
        - "{{plugin_root}}\\corona\\Corona\\Corona Renderer for 3ds Max\\DR Server"
        默认按照环境变量定义的方式查找CoronaDR ，找不到的报错，让任务失败
        """
        job = self.Plugin.GetJob()
        coronaSpawnerExepath = ""

        coronaDbrPath = job.GetJobEnvironmentKeyValue("CORONA_DRSERVER_PATH")
        coronaSpawnerExepath = "{}\\DrServer.exe".format(coronaDbrPath)
        return coronaSpawnerExepath

    def RenderExecutable(self):
        version = self.Plugin.GetIntegerPluginInfoEntry("Version")
        if (version < 2015):
            self.Plugin.FailRender(self.Plugin.Prefix + "Only 3dsmax 2015 and later is supported")

        ###  先查找yaml 配置地址，找不到的使用deadline配置的默认地址找。
        executable = self.GetCoronaSpawnerEnvironmet(version)
        if not os.path.exists(executable):
            executable = self.Plugin.GetRenderExecutable("CoronaDrServerExecutable", "Corona DrServer")

        self.Plugin.LogInfo("Executable: %s" % executable)

        existingDRProcess = self.Plugin.GetConfigEntryWithDefault("CoronaExistingDRProcess", "Fail On Existing Process")
        self.Plugin.LogInfo("Existing DR Process: %s" % existingDRProcess)
        self.createDrConfig(version)
        self.CopyPluginInis(version)
        processName = Path.GetFileNameWithoutExtension(executable)
        if (ProcessUtils.IsProcessRunning(processName)):
            processes = Process.GetProcessesByName(processName)

            if len(processes) > 0:
                self.Plugin.LogWarning("Found existing '%s' process" % processName)
                process = processes[0]

                if (existingDRProcess == "Fail On Existing Process"):
                    if process != None:
                        self.Plugin.FailRender(
                            "Fail On Existing Process is enabled, and a process '%s' with pid '%d' exists - shut down this copy of Corona DrServer. Ensure DrServer is NOT already running!" % (
                                processName, process.Id))

                if (existingDRProcess == "Kill On Existing Process"):
                    if (ProcessUtils.KillProcesses(processName, 3)):
                        if process != None:
                            self.Plugin.LogInfo("Successfully Killed Corona DrServer process: '%s' with pid: '%d'" % (
                                processName, process.Id))

                        SystemUtils.Sleep(5000)

                        if (ProcessUtils.IsProcessRunning(processName)):
                            self.Plugin.LogWarning(
                                "Corona DrServer is still running: '%s' process, perhaps due to it being automatically restarted after the previous kill command. Ensure Corona DrServer is NOT already running!" % processName)
                            process = Process.GetProcessesByName(processName)[0]
                            if process != None:
                                self.Plugin.FailRender(
                                    "Kill On Existing Process is enabled, and a process '%s' with pid '%d' still exists after executing a kill command. Ensure Corona DrServer is NOT already running!" % (
                                        processName, process.Id))

        return executable

    def RenderArgument(self):
        arguments = ""

        drServerNoGui = self.Plugin.GetBooleanConfigEntryWithDefault("CoronaDRServerNoGui", False)
        if drServerNoGui:
            arguments += "--noGui"

        return arguments
