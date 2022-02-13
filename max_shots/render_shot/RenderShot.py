# coding:utf-8
import os
import re
import sys
import json
import filecmp

import subprocess
from threading import Timer

from System import *
from System.IO import *
from System.Text import *
from System.Diagnostics import *

from Deadline.Scripting import *
from Deadline.Plugins import *


def xcopy(source, dest):
    r"""
    假设原始目录结构为这样
    <source>\123.txt
    <source>\directory
    拷贝之后，目标目录结构就是这样
    <dest>\123.txt
    <dest>\directory
    :param source: 原始目录
    :param dest: 目标目录
    :return:
    """
    if not os.path.isdir(dest):
        os.makedirs(dest)
    cmds = 'xcopy "{0}" "{1}" /e /s /y /i'.format(source, dest)
    subprocess.check_output(cmds, shell=True)


class RenderShot(object):
    shot_src = os.path.join(RepositoryUtils.GetCustomScriptsDirectory(), "render_shot")
    shot_dst = os.path.join(ClientUtils.GetUsersHomeDirectory(), "render_shot")

    def __init__(self, job, task_id=None, frame=0, interval=5, logger=None):
        self._timer = None
        self._running = False
        self.job = job
        self.frame = frame
        self.task_id = task_id
        self.ExtKyes = self.job.GetJobExtraInfoKeys()
        self._logger = logger
        self.logger(self.shot_src)
        self.logger(self.shot_dst)
        self.interval = interval
        self.cur_outfile = ""
        xcopy(self.shot_src, self.shot_dst)

    def logger(self, msg):
        if callable(self._logger):
            self._logger(msg)

    def start_shot(self, sec=10):
        self.logger("start render shot every {0} seconds.".format(sec))
        if not self._running:
            self._running = True
            self._create_timer()

    def stop_shot(self):
        cmds = "taskkill /f /t /im max_shot.exe"
        try:
            subprocess.check_output(cmds, stderr=subprocess.PIPE, cwd=self.shot_dst, shell=True)
        except subprocess.CalledProcessError:
            pass
        if os.path.isfile(self.cur_outfile):
            os.remove(self.cur_outfile)
        self._running = False
        if self._timer.is_alive():
            self._timer.cancel()
        # self.logger("render shot stopped.")

    def _create_timer(self, start=True):
        if self._running:
            self._timer = Timer(self.interval, self.shot_frame_buffer)
            if start:
                self._timer.start()

    def get_shot_outfile(self):
        if len(self.ExtKyes) != 0:
            for i in self.ExtKyes:
                if i == "shot_save_path":
                    shot_savepath = self.job.GetJobExtraInfoKeyValue(i)
        ##  输出的目录结构为，从提交服务定义的输出地址，加上任务名称，加上shot_.jpg 如: D:/render_shot/2022021202/shot_.jpg
        if not shot_savepath:
            return
        shot_filesavepath = os.path.join(shot_savepath, self.job.JobName, "shot_.jpg")
        return shot_filesavepath

    def shot_frame_buffer(self):
        if not SystemUtils.IsRunningOnWindows():
            # self.logger("is not running on windows, do anything!")
            return

        shot_ext = os.path.join(self.shot_dst, "max_shot.exe")
        shot_out = self.get_shot_outfile()
        shot_out_folder = os.path.dirname(shot_out)
        if not os.path.isdir(shot_out_folder):
            os.makedirs(shot_out_folder)
        # cmds = [shot_ext, "-f", shot_out.encode(sys.getfilesystemencoding())]
        cmds = '"{0}" -f "{1}"'.format(shot_ext, shot_out.encode(sys.getfilesystemencoding()))

        self.logger("Job Name = {}".format(self.job.JobName))
        self.logger("shots_savepath = {}".format(shot_out_folder))

        try:
            self.logger("Start to render shot")
            self.logger("CMDS = {}".format(cmds))
            self.logger("self.shot_dest = {}".format(self.shot_dst))
            subprocess.check_output(cmds, stderr=subprocess.PIPE, cwd=self.shot_dst, shell=True)
        except subprocess.CalledProcessError:
            pass
        # if not os.path.isfile(shot_out):
        #     self._create_timer()
        #     return

        self._create_timer()




