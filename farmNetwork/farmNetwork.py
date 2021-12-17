#!/usr/bin/env python
# -*- coding: utf-8 -*-

import requests
import json
import argparse
import configparser
import win32api
import os
import time


def start_exe(exe_path):
    """
    独立启动exe
    此方式可能在IDE里面失效，通过cmd运行和编译可正常运行
    """
    win32api.ShellExecute(
        0, 'open', exe_path, '', os.path.dirname(exe_path), 1
    )


class GetStatus:
    def __init__(self, url, body, headers):
        self.base_url = url
        self.body = body
        self.headers = headers

    def client_status(self):
        try:
            url = self.base_url + "/status"
            res = requests.get(url)
            return res.status_code
        except:
            return "403"

    def post_data(self):
        data = self.body
        url = self.base_url + "/index"
        res = requests.post(url, data=json.dumps(data), headers=self.headers)
        if res.status_code == 200:
            return (res.text)


class AnalyseIni:
    def __init__(self, inipath):
        self.inifile = inipath


    def ini_to_json(self):
        temp_dict = {}
        configer = configparser.ConfigParser()
        print ("inifile = {}".format(self.inifile))

        configer.read(self.inifile, encoding='UTF-16')
        for key in configer.sections() :
            subdict = {}
            for subkey in configer.options(key):
                print (subkey," = ", configer.get(key,subkey))
                subdict.update({"{}".format(subkey):"{}".format(configer.get(key,subkey)) })
            temp_dict["{}".format(key)] = subdict
        return  temp_dict




def run():
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", dest="status", help="get client status ")
    parser.add_argument("-f", dest="file_path", help="the configure file path ")
    results = parser.parse_args()

    if results.status is not None :
        client_exe = "E:\\work\\dlrender-client\\client.exe"
        start_exe(client_exe)

    if results.file_path is not None :

        analyini = AnalyseIni(results.file_path)
        json_data = analyini.ini_to_json()
        base_url = 'http://192.168.106.140:5000'
        body = {}
        headers = {'content-type': "application/json"}
        gs = GetStatus(base_url, body = json_data, headers= headers)
        if (gs.client_status()) == 200:
            result_string = json.dumps(gs.post_data())
            print(result_string)  # 返回的是字符串，要变dict需要处理
            os.remove(results.file_path)
            time.sleep(2)
            return 1
        else:
            print ("连接失败")
            print (403)

if __name__ == "__main__":
    "测试使用test函数，打包使用run函数，打包后exe -f file.ini ,即可post数据到服务端"
    run()

