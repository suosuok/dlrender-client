import win32com.client
import os
import psutil
import sys
from argparse import ArgumentParser
import subprocess
import shutil

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



class MaxShots():
    def __init__(self):
        self.maxscripts = os.path.join( os.path.dirname(os.path.realpath(sys.executable)),"maxshot.ms")

    def snapShot(self):
        try:
            MaxApplication = win32com.client.Dispatch("Max.Application")
            MaxApplication._FlagAsMethod("filein")
            MaxApplication.filein(self.maxscripts)
        except:
            pass


def render():
    MaxApplication = win32com.client.Dispatch("Max.Application")
    MaxApplication._FlagAsMethod("Execute")
    MaxApplication.Execute('rendUseActiveView=true')

def exitMax():
    MaxApplication = win32com.client.Dispatch("Max.Application")
    MaxApplication._FlagAsMethod("Execute")
    MaxApplication.Execute("quitMax #noPrompt")

def get_max_pid():
    pids = psutil.pids()
    for pid in pids:
        p = psutil.Process(pid)
        if p.name() == "3dsmax.exe":
            return pid


parser = ArgumentParser()
parser.add_argument("-f", "--file", dest="file", type=str, required=True)
args = parser.parse_args()
new_savepath = args.file
if not os.path.exists(os.path.dirname(new_savepath)):
    os.makedirs(os.path.dirname(new_savepath))

print ("new_savepath = {}".format(new_savepath))
max_pid = get_max_pid()
print ("max_pid = {}".format(max_pid))
local_savepath = "C:\\render_shots\\shot_.jpg"
if max_pid:
    if os.path.exists(local_savepath) and os.path.isfile(local_savepath):
        os.remove(local_savepath)
    maxshots = MaxShots()
    maxshots.snapShot()
    try:
        shutil.copy(local_savepath, new_savepath )
    except Exception as e:
        print (e)