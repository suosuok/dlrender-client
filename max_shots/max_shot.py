import win32com.client
import os
import psutil
import sys
from argparse import ArgumentParser
import shutil
from PIL import Image


class MaxShots:
    def __init__(self):
        self.maxscripts = os.path.join(os.path.dirname(os.path.realpath(sys.executable)), "maxshot.ms")

    def snapShot(self):
        try:
            MaxApplication = win32com.client.Dispatch("Max.Application")
            MaxApplication._FlagAsMethod("filein")
            MaxApplication.filein(self.maxscripts)
        except:
            pass


def get_max_pid():
    pids = psutil.pids()
    for pid in pids:
        p = psutil.Process(pid)
        if p.name() == "3dsmax.exe":
            return pid


def get_size(file):
    # 获取文件大小:KB
    size = os.path.getsize(file)
    return size / 1024


def compress_image(infile, outfile=None, kb=500, step=10, quality=100, base_width=1500):
    """不改变图片尺寸压缩到指定大小
    首先判断截图大小，小于500K的，直接存，大于500k的，先等于缩放到限制宽度，长度，在另存
    :param infile: 压缩源文件
    :param outfile: 压缩文件保存地址
    :param kb: 压缩目标，KB
    :param step: 每次调整的压缩比率
    :param quality: 初始压缩比率
    :return: 压缩文件地址，压缩文件大小
    :param base_width: 输出宽度限制，限制输出截图的长于宽，根据长宽比锁定，解决原始图分辨率过大，截图另存失真的问题
    """
    if outfile is None:
        outfile = infile
    o_size = get_size(infile)
    if o_size <= kb:
        im = Image.open(infile)
        im.save(outfile)

    while o_size > kb:
        im = Image.open(infile)
        w_percent = base_width / float(im.size[0])
        h_size = int(float(im.size[1]) * float(w_percent))
        image = im.resize((base_width, h_size), Image.ANTIALIAS)
        image.save(outfile, quality=quality)
        if quality - step < 0:
            break
        quality -= step
        o_size = get_size(outfile)


def run():
    parser = ArgumentParser()
    parser.add_argument("-f", "--file", dest="file", type=str, required=True)
    args = parser.parse_args()
    new_savepath = args.file
    if not os.path.exists(os.path.dirname(new_savepath)):
        os.makedirs(os.path.dirname(new_savepath))
    max_pid = get_max_pid()
    local_savepath = "C:\\render_shots\\shot_.jpg"
    if max_pid:
        if os.path.exists(local_savepath) and os.path.isfile(local_savepath):
            os.remove(local_savepath)
        maxshots = MaxShots()
        maxshots.snapShot()
        print("snap shot over ")
        try:
            # shutil.copy(local_savepath, new_savepath)
            ## 判断输出文件大小，超过500K的，统一压缩到500k，在输出
            compress_image(local_savepath, new_savepath)
        except Exception as e:
            print(e)


if __name__ == '__main__':
    run()
