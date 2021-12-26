
#!/usr/bin/python
# -*- coding: UTF-8 -*-

"""
测试ws 使用
需要安装
pip install websocket,websocket-client
pip install pywin32

"""
"""
状态值  
200 连接正常
204 连接失败
205 压缩失败
"""

import json
import sys
import time
import argparse
import configparser
import win32api
from websocket import create_connection
import os
import zipfile

COMMAND_CLIENT_EXTRA_CHECK_STATUS = 'check_status'
COMMAND_CLIENT_EXTRA_SUBMIT_JOB = 'submit_job'
COMMAND_CLIENT_EXTRA_CREATE_ZIP = 'create_zip'

status = {"cmd":COMMAND_CLIENT_EXTRA_CHECK_STATUS, "arg":"-s"}
submit = {"cmd":COMMAND_CLIENT_EXTRA_SUBMIT_JOB, "arg":"-f"}


def start_exe():
    """
    独立启动exe
    此方式可能在IDE里面失效，通过cmd运行和编译可正常运行
    """
    exe_path = "3dDownload.exe"
    startup_exe = os.path.join( os.path.abspath(os.path.dirname(os.path.realpath(sys.executable))), exe_path)
    # print ("startup_exe = {}".format(startup_exe))

    win32api.ShellExecute(
        0, 'open', startup_exe, '', os.path.dirname(startup_exe), 1
    )

class WSClient:
    address = "ws://127.0.0.1"
    prot = 5665
    ws_address = address + ":{}/ws".format(prot)

    def __init__(self):
        self.ws = create_connection(self.ws_address)

    def send(self, params):
        self.ws.send(json.dumps(params))
        #print("Sending Data: {}".format(params))
        result = self.ws.recv()
        "打印返回码，maxscripts接收返回码，判断状态"
        print(result)

    def quit(self):
        self.ws.close()

class AnalyseIni():
    def __init__(self, inipath):
        self.inifile = inipath

    def ini_to_json(self):
        temp_dict = {}
        configer = configparser.ConfigParser()

        configer.read(self.inifile, encoding='UTF-16')
        for key in configer.sections() :
            subdict = {}
            for subkey in configer.options(key):
                subdict.update({"{}".format(subkey):"{}".format(configer.get(key,subkey)) })
            temp_dict["{}".format(key)] = subdict
        return temp_dict

def read_to_list(file_path):
    temp_list =[]
    for line in open(file_path,encoding='UTF-8-sig'):
        line = line.strip('\n')
        temp_list.append(line)
    return temp_list

def create_zipfile(file_list,output_zippath):
    try:
        pre_file_list = read_to_list(file_list)
        f = zipfile.ZipFile(output_zippath, 'w', zipfile.ZIP_DEFLATED)
        for file in pre_file_list:
            f.write(file)
        f.close()
        return "Successful"
    except Exception as e:
        print (e)
        return "Fail"


def run():
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", dest="status", help="get client status ")
    parser.add_argument("-f", dest="file_path", help="the configure file path ")
    parser.add_argument("-zip", dest="create_zip", help="Crate the zip file for job ")
    results = parser.parse_args()

    if results.status is not None :
        try:
            web_client.send(status)
        except:
            start_exe()

    # 初始化
    try:
        web_client = WSClient()

    except:
        print ( "204")
        exit(204)



    if results.file_path is not None :
        json_data = AnalyseIni(results.file_path).ini_to_json()
        zip_file_configure_path = json_data["Arguments"]["zipfileslistpath"]
        zip_path = results.create_zip

        create_zipfile_result = create_zipfile(zip_file_configure_path, zip_path)
        if create_zipfile_result == "Successful":
            # pass
            os.remove(results.file_path)
        else:
            return "205"

        json_data["Arguments"]["zipfileslistpath"] = zip_path # "/data/home/xubaolong/dlrenderfarm/test.zip"
        submit["arg"] = json_data
        web_client.send(submit)

    web_client.quit()
if __name__ == '__main__':
    run()


