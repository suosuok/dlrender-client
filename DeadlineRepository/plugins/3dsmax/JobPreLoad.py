#!/usr/bin/env python3
"""
code by baolong.xu@sincerecloud.com
data 2022-0921
"""

# -*- coding:utf-8 -*-
from genericpath import isfile
import os
import os.path
import sys
import codecs
import json
import shutil
import glob
from System.IO import *
from Deadline.Scripting import *
import subprocess
import traceback
import stat
import time
import re
import configparser

# 1 读取job任务的配置属性,获取插件配置文件  pre_job.json

# 2 根据定义的执行顺序执行 任务预处理中的插件处理。

# 3 基础顺序为 
#     3.1 杀掉系统内已知的进程名称 
#     3.2 清理当前渲染dcc版本路径下的插件残留  
#     3.3 停止具体的系统服务  
#     3.4 根据配置文件内的拷贝项，拷贝文件  
#     3.5  启动具体的系统服务，系统内不具备的则创建。 
#     3.6 执行注册表操作 


class CleanProcess(object):
    process_list = [
        "3dsmax.exe",
        "maya.exe"
    ]

    @staticmethod
    def kill_process(process_name):
        cmds = 'taskkill /f /im "{}"'.format(process_name)
        try:
            subprocess.call(cmds, shell=True, stderr=subprocess.PIPE)
            return True
        except subprocess.CalledProcessError:
            return False

    def clean_process(self):
        for p in self.process_list:
            self.kill_process(p)

    def do_it(self):
        if SystemUtils.IsRunningOnWindows():
            self.clean_process()


class MaxPluginsPre:

    def __init__(self, deadlinePlugin, job, Version):
        self.deadlinePlugin = deadlinePlugin
        self.job = job
        self.version = Version
        self.pre_job_info_file = ""
        self.pre_job_info = {}
        self.sc_tools_home = r"c:\\sc_tools"

    def clean_multiscatter_dlos(self):
        self.deadlinePlugin.LogInfo("clean multiscatter dlos enter")
        dlos = glob.glob('C:\\Program Files\\Autodesk\\3ds Max *\\MultiScatter*.dlo')
        for dlo in dlos:
            self.deadlinePlugin.LogInfo("clean multiscatter dlos: {}".format(dlo))
            if os.path.exists(dlo):
                self.deadlinePlugin.LogInfo('unlink %s' % dlo)
                try:
                    if dlo:
                        os.unlink(dlo)
                except Exception as ex:
                    self.deadlinePlugin.LogInfo("unlink failed %s" % repr(ex))

        dlos = glob.glob('C:\\Program Files\\Autodesk\\3ds Max *\\plugins\\MultiScatter.dlo')
        for dlo in dlos:
            self.deadlinePlugin.LogInfo("clean multiscatter dlos: {}".format(dlo))
            if os.path.exists(dlo):
                self.deadlinePlugin.LogInfo('unlink %s' % dlo)
                try:
                    os.unlink(dlo)
                except Exception as ex:
                    self.deadlinePlugin.LogInfo("unlink failed %s" % repr(ex))

    def clean_vray_files(self):
        self.deadlinePlugin.LogInfo("clean vray plugins files enter")
        dlos = glob.glob('C:\\Program Files\\Autodesk\\3ds Max *\\plugins\\vrender*.dlr')
        for dlo in dlos:
            self.deadlinePlugin.LogInfo("clean vray plugin files: {}".format(dlo))
            if os.path.exists(dlo):
                self.deadlinePlugin.LogInfo('unlink %s' % dlo)
                try:
                    if dlo:
                        os.unlink(dlo)
                except Exception as ex:
                    self.deadlinePlugin.LogInfo("unlink failed %s" % repr(ex))

        dlos = glob.glob('C:\\Program Files\\Autodesk\\3ds Max *\\plugins\\vray*.dlr')
        for dlo in dlos:
            self.deadlinePlugin.LogInfo("clean vray plugin files: {}".format(dlo))
            if os.path.exists(dlo):
                self.deadlinePlugin.LogInfo('unlink %s' % dlo)
                try:
                    os.unlink(dlo)
                except Exception as ex:
                    self.deadlinePlugin.LogInfo("unlink failed %s" % repr(ex))

        dlos = glob.glob('C:\\Program Files\\Autodesk\\3ds Max *\\plugins\\vray*.bmi')
        for dlo in dlos:
            self.deadlinePlugin.LogInfo("clean vray plugin files: {}".format(dlo))
            if os.path.exists(dlo):
                self.deadlinePlugin.LogInfo('unlink %s' % dlo)
                try:
                    os.unlink(dlo)
                except Exception as ex:
                    self.deadlinePlugin.LogInfo("unlink failed %s" % repr(ex))

        dlos = glob.glob('C:\\Program Files\\Autodesk\\3ds Max *\\plugins\\vrayplugins\\*')
        for dlo in dlos:
            self.deadlinePlugin.LogInfo("clean vray plugin files: {}".format(dlo))
            if os.path.exists(dlo) and os.path.isfile(dlo):
                self.deadlinePlugin.LogInfo('unlink %s' % dlo)
                try:
                    os.unlink(dlo)
                except Exception as ex:
                    self.deadlinePlugin.LogInfo("unlink failed %s" % repr(ex))

        dlos = glob.glob('C:\\Program Files\\Autodesk\\3ds Max *\\plugins\\vrayplugins\\DTE_Components\\*')
        for dlo in dlos:
            self.deadlinePlugin.LogInfo("clean vray plugin files: {}".format(dlo))
            if os.path.exists(dlo):
                self.deadlinePlugin.LogInfo('unlink %s' % dlo)
                try:
                    os.unlink(dlo)
                except Exception as ex:
                    self.deadlinePlugin.LogInfo("unlink failed %s" % repr(ex))

        dlos = glob.glob('C:\\Program Files\\Autodesk\\3ds Max *\\vray*')
        for dlo in dlos:
            self.deadlinePlugin.LogInfo("clean vray plugin files: {}".format(dlo))
            if os.path.exists(dlo):
                self.deadlinePlugin.LogInfo('unlink %s' % dlo)
                try:
                    os.unlink(dlo)
                except Exception as ex:
                    self.deadlinePlugin.LogInfo("unlink failed %s" % repr(ex))

    def clean_max_default_ini(self):
        default_ini_path = r"C:\Program Files\Autodesk\3ds Max {}".format(self.version)
        if self.version < 2013:
            enu_ini_path = os.path.join(default_ini_path, "plugin.ini")
            if os.path.isfile(enu_ini_path) and os.path.exists(enu_ini_path):
                self.deadlinePlugin.LogInfo('unlink %s' % enu_ini_path)
                try:
                    os.unlink(enu_ini_path)
                except Exception as e:
                    self.deadlinePlugin.LogInfo("unlink failed %s" % repr(ex))
        else:
            enu_ini_path = os.path.join(default_ini_path, "en-US", "plugin.ini")
            chs_ini_path = os.path.join(default_ini_path, "zh-CN", "plugin.ini")
            if os.path.isfile(enu_ini_path) and os.path.exists(enu_ini_path):
                self.deadlinePlugin.LogInfo('unlink %s' % enu_ini_path)
                try:
                    os.unlink(enu_ini_path)
                except Exception as ex:
                    self.deadlinePlugin.LogInfo("unlink failed %s" % repr(ex))

            if os.path.isfile(chs_ini_path) and os.path.exists(chs_ini_path):
                self.deadlinePlugin.LogInfo('unlink %s' % chs_ini_path)
                try:
                    os.unlink(chs_ini_path)
                except Exception as ex:
                    self.deadlinePlugin.LogInfo("unlink failed %s" % repr(ex))
        
    def kill_exists_DCC_process(self):
        self.deadlinePlugin.LogInfo("kill_exists_DCC_process")
        CleanProcess().do_it()

    def clean_DCC_pluginsfiles(self):
        self.deadlinePlugin.LogInfo("clean_DCC_pluginsfiles")
        self.clean_multiscatter_dlos()
        self.clean_vray_files()
        self.clean_max_default_ini()

    def stop_plugin_services(self):
        self.deadlinePlugin.LogInfo("stop_plugin_services")
        for command_dict in self.pre_job_info['service_to_stop']:
            try:
                command = command_dict["command"]
                self.deadlinePlugin.LogInfo("command = {}".format(command))
                try:
                    subprocess.check_output(command, shell=True)
                except:
                    pass

            except Exception as e:
                self.deadlinePlugin.LogInfo(u"do_service_to_stop %s" % repr(e))

    def start_plugin_services(self):
        self.deadlinePlugin.LogInfo("start_plugin_services")
        for command_dict in self.pre_job_info['service_to_start']:
            try:
                command = command_dict["command"]
                self.deadlinePlugin.LogInfo("command = {}".format(command))
                try:
                    subprocess.check_output(command, shell=True)
                except:
                    pass
            except Exception as e:
                self.deadlinePlugin.LogInfo(u"do_service_to_stop %s" % repr(e))

    def try_copy_files_needed(self, files_to_copy):
        for the_file in files_to_copy:
            src = the_file['src']
            dst = os.path.join(the_file['dst'], os.path.basename(src))

            self.deadlinePlugin.LogInfo('mark {}'.format(dst))
            if dst.endswith('\\'):
                if not os.path.exists(dst):
                    os.makedirs(dst)
            else:
                target_dir = os.path.dirname(dst)
                if not os.path.exists(target_dir):
                    os.makedirs(target_dir)
            if os.path.exists(src):
                self.deadlinePlugin.LogInfo("File Copy src: %s, dst: %s, dest dir %s\r\n" % (
                    src, dst, dst if dst.endswith('\\') else os.path.dirname(dst)))
                try:
                    shutil.copy2(src, dst if dst.endswith('\\') else os.path.dirname(dst))
                except Exception as e:
                    self.deadlinePlugin.LogInfo("try_copy_files_needed {}:{} failed {}".format(src, dst, repr(e)))
            else:
                self.deadlinePlugin.LogInfo("File Copy: src: %s not exists\r\n" % src)

    def try_copy_file(self, sour_path, tar_path):
        if os.path.isdir(sour_path):
            self.deadlinePlugin.LogInfo(u"{}".format(sour_path))
            if os.path.isdir(tar_path):

                self.deadlinePlugin.LogInfo(u"{}".format(tar_path))
                command = r'C:\Windows\System32\xcopy.exe "%s" "%s" /s /y' % (sour_path, tar_path)
                try:
                    subprocess.Popen(command)
                except Exception as e:

                    self.deadlinePlugin.LogInfo(u"".format(e))
            else:
                pass
        else:

            self.deadlinePlugin.LogInfo(u" {}    is not defined !".format(sour_path))

    def do_reg_regfile(self):
        self.deadlinePlugin.LogInfo("do_reg_regfile")

    def do_max_prejob_plugins(self, ):
        self.deadlinePlugin.LogInfo("Starting  to do Job Plugins Pre !  ")
        self.kill_exists_DCC_process()
        self.clean_DCC_pluginsfiles()
        try:
            self.pre_job_info_file = self.job.GetJobExtraInfoKeyValue("pre_job")
            self.deadlinePlugin.LogInfo(
                u"GetJobExtraInfoKeyValue pre_job_info_file = {}".format(self.pre_job_info_file)
            )
        except Exception as e:
            self.deadlinePlugin.LogInfo(
                u"GetJobExtraInfoKeyValue pre_job_info_file Failed : {}".format(repr(e))
            )

        last_pre_job_filepath = os.path.join(self.sc_tools_home, "last_pre_job.json")
        if not os.path.exists(self.sc_tools_home):
            os.mkdir(self.sc_tools_home)
        if os.path.exists(self.pre_job_info_file):
            with codecs.open(self.pre_job_info_file, 'r', 'utf-8-sig') as f:
                self.pre_job_info = json.loads(f.read())
                try:
                    if 'service_to_stop' in self.pre_job_info:
                        self.stop_plugin_services()

                    if 'files_to_copy' in self.pre_job_info:
                        files_to_copy = self.pre_job_info['files_to_copy']
                        self.try_copy_files_needed(files_to_copy)

                    if 'dirs_to_copy' in self.pre_job_info:
                        dirs_to_copy = self.pre_job_info['dirs_to_copy']
                        self.try_copy_dirs_needed(dirs_to_copy)

                    if 'regfiles' in self.pre_job_info:
                        for regfile in self.pre_job_info['regfiles']:
                            self.do_reg_regfile(regfile)

                    if 'service_to_start' in self.pre_job_info:
                        self.start_plugin_services()
                except Exception as e:
                    self.deadlinePlugin.LogInfo(u"JobPreTask Warning: {}".format(repr(e)))
                with codecs.open(last_pre_job_filepath, 'w+', 'utf-8-sig') as fn:
                    fn.write(json.dumps(self.pre_job_info))
        else:
            self.deadlinePlugin.LogInfo(u"JobPreTask pre_job_info_file {} not exists".format(self.pre_job_info_file))
            self.pre_job_info = {}
            with codecs.open(last_pre_job_filepath, 'w+', 'utf-8-sig') as fn:
                fn.write(json.dumps(self.pre_job_info))



class MODIFYINI(object):
    def __init__(self, deadlinePlugin):
        self.config = configparser.ConfigParser()
        self.deadlinePlugin = deadlinePlugin
        self.job = self.deadlinePlugin.GetJob()
        self.scenefile = self.deadlinePlugin.GetPluginInfoEntryWithDefault("SceneFile", "")
        self.version = deadlinePlugin.GetPluginInfoEntryWithDefault("Version", None)

    def get_mxp_path(self):
        #     user_home = os.path.expanduser('~')
        #     if os.path.exists(user_home):
        #         if int(self.version) < 2020 :
        #             mxp_path = os.path.join(user_home, r"Documents\3dsMax\3dsMax.mxp")
        #         else:
        #             mxp_path = os.path.join(user_home, r"Documents\3ds Max {0}\3ds Max {1}.mxp".format(self.version, self.version))
        #     else:
        if int(self.version) < 2020 :
            mxp_path = r"D:\Backup\Documents\3dsMax\3dsMax.mxp"
        else:
            mxp_path = r"D:\Backup\Documents\3ds Max {0}\3ds Max {1}.mxp".format(self.version, self.version)
        return mxp_path

    def write_ini(self):
        mxp_path = self.get_mxp_path()
        self.deadlinePlugin.LogInfo("mxp_path = {}".format(mxp_path))
        self.config.read(mxp_path, encoding="utf-16")
        asset_path = os.path.dirname(self.scenefile)
        self.deadlinePlugin.LogInfo("asset_path = {}".format(asset_path))
        self.config.set('BitmapDirs', 'Dir11', asset_path) 
        self.config.write(open(mxp_path, 'w',encoding="utf-16"))


def __main__(*args):
    start_time = time.time()
    deadlinePlugin = args[0]
    job = deadlinePlugin.GetJob()
    Version = deadlinePlugin.GetPluginInfoEntryWithDefault("Version", None)
    # old 
    # rebuild_mxp = MODIFYINI(deadlinePlugin)
    # rebuild_mxp.write_ini()
    # new 
    MPP = MaxPluginsPre(deadlinePlugin, job, Version)
    MPP.do_max_prejob_plugins()

    end_time = time.time()
    cost_time = end_time - start_time
    deadlinePlugin.LogInfo("Total cost time for jobpreload =  {}".format(cost_time))
