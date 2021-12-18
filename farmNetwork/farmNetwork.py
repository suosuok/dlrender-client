
#!/usr/bin/python
# -*- coding: UTF-8 -*-

"""
测试ws 使用
需要安装
pip install websocket,websocket-client
pip install pywin32


"""
import json
import time
import argparse
import configparser
import win32api
from websocket import create_connection
import os


COMMAND_CLIENT_EXTRA_CHECK_STATUS = 'check_status'
COMMAND_CLIENT_EXTRA_SUBMIT_JOB = 'submit_job'

def start_exe(exe_path):
    """
    独立启动exe
    此方式可能在IDE里面失效，通过cmd运行和编译可正常运行
    """
    win32api.ShellExecute(
        0, 'open', exe_path, '', os.path.dirname(exe_path), 1
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


status = {"cmd":COMMAND_CLIENT_EXTRA_CHECK_STATUS, "arg":"-s"}
submit = {"cmd":COMMAND_CLIENT_EXTRA_SUBMIT_JOB, "arg":"-f"}


def run():
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", dest="status", help="get client status ")
    parser.add_argument("-f", dest="file_path", help="the configure file path ")
    results = parser.parse_args()
    # 初始化
    try:
        web_client = WSClient()
    except:
        print ( "204")
        exit(204)


    if results.status is not None :
        web_client.send(status)

    if results.file_path is not None :
        json_data = AnalyseIni(results.file_path).ini_to_json()
        submit["arg"] = json_data
        web_client.send(submit)
        os.remove(results.file_path)


    web_client.quit()
if __name__ == '__main__':
    run()


