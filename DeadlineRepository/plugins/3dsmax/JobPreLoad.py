#-*- coding:utf-8 -*-
import os
import os.path
from System.IO import *
from Deadline.Scripting import *
import configparser

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
        self.config.set('BitmapDirs', 'Dir11', asset_path)  # 写入数据
        self.config.write(open(mxp_path, 'w',encoding="utf-16"))


def __main__(*args):
    deadlinePlugin = args[0]
    rebuild_mxp = MODIFYINI(deadlinePlugin)
    rebuild_mxp.write_ini()
