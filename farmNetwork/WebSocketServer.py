#!/usr/bin/env python
# encoding: utf-8

"""
测试ws 使用
需要安装
pip install websockets

默认使用端口 5665
"""

import websockets
import asyncio
import json

## 用户登录状态
USERLOGIN = False


class WSserver():
    async def handle(self, websocket, path):
        recv_msg = await websocket.recv()
        msg_json = json.loads(recv_msg)
        print("Received '{}'".format(msg_json))
        if msg_json["cmd"] == "check_status":
            if USERLOGIN :
                await websocket.send('200')
            else:
                await websocket.send('204')

        if msg_json["cmd"] == "submit_job":
            if USERLOGIN:
                await websocket.send('200')
            else:
                await websocket.send('204')

    def run(self):
        ser = websockets.serve(self.handle, "127.0.0.1", "5665")
        asyncio.get_event_loop().run_until_complete(ser)
        asyncio.get_event_loop().run_forever()

    def check_status(self,msg):
        pass



ws = WSserver()
ws.run()
