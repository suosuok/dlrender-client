#!/usr/bin/env python
# -*- coding: utf-8 -*-

import requests
import json
import argparse
import configparser


class GetStatus:
    def __init__(self, url, body, headers):
        self.base_url = url
        self.body = body
        self.headers = headers

    def client_status(self):
        url = self.base_url + "/status"
        res = requests.get(url)
        return res.status_code

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
            # arguments = configer['Arguments']
        # name = arguments['name']
        # print("all_data = {}".format(name))
        #
        return  temp_dict


def run():
    parser = argparse.ArgumentParser()
    parser.add_argument("-s", dest="status", help="get client status ")
    parser.add_argument("-f", dest="file_path", help="the configure file path ")
    results = parser.parse_args()
    print("status = {}".format(results.status))
    print("file_path = {}".format(results.file_path))
    analyini = AnalyseIni(results.file_path)
    json_data = analyini.ini_to_json()
    print(type(json_data))


    base_url = 'http://192.168.0.102:5000'
    body = {
        "name": "张三",
        "age": 118,
        "city": "xuzhou"
    }
    headers = {'content-type': "application/json"}

    gs = GetStatus(base_url, json_data, headers)
    if (gs.client_status()) == 200:
        result_string = json.dumps(gs.post_data())
        print(result_string)  # 返回的是字符串，要变dict需要处理

def test():
    file_path = "kx-task-2021-12-9-15-37-34.ini"
    analyini = AnalyseIni(file_path)
    json_data = analyini.ini_to_json()
    print(type(json_data))


    base_url = 'http://192.168.0.102:5000'
    body = {
        "name": "张三",
        "age": 118,
        "city": "xuzhou"
    }
    headers = {'content-type': "application/json"}

    gs = GetStatus(base_url, json_data, headers)
    if (gs.client_status()) == 200:
        result_string = json.dumps(gs.post_data())
        print(result_string)  # 返回的是字符串，要变dict需要处理
if __name__ == "__main__":
    "测试使用test函数，打包使用run函数，打包后exe -f file.ini ,即可post数据到服务端"
    test()

