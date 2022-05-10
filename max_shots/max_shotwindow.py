from PyQt5.QtWidgets import QApplication
from argparse import ArgumentParser
import psutil
import os
import sys
import win32gui


hwnd_title = {}

def get_all_hwnd(hwnd, mouse):
    if (win32gui.IsWindow(hwnd) and
        win32gui.IsWindowEnabled(hwnd) and
        win32gui.IsWindowVisible(hwnd)):
        hwnd_title.update({hwnd: win32gui.GetWindowText(hwnd)})


win32gui.EnumWindows(get_all_hwnd, 0)

def shot_windows(h, savepath):
    app = QApplication(sys.argv)

    screen = QApplication.primaryScreen()

    img = screen.grabWindow(h).toImage()

    img.save(savepath)



def get_max_pid():
    pids = psutil.pids()
    for pid in pids:
        p = psutil.Process(pid)
        if p.name() == "3dsmax.exe":
            return pid

def run():
    parser = ArgumentParser()
    parser.add_argument("-f", "--file", dest="file", type=str, required=True)
    args = parser.parse_args()
    new_savepath = args.file
    if not os.path.exists(os.path.dirname(new_savepath)):
        os.makedirs(os.path.dirname(new_savepath))
    max_pid = get_max_pid()
    local_savepath = new_savepath
    if max_pid:
        if os.path.exists(local_savepath) and os.path.isfile(local_savepath):
            os.remove(local_savepath)
        for h, t in hwnd_title.items():
            if t :

                if 'V-Ray Frame Buffer'  in t:
                    print(h, t)
                    # left, top, right, bottom = win32gui.GetWindowRect(h)
                    # print(left,top,right,bottom)
                    # pyautogui.click(right-206,bottom-31)

                    shot_windows(h, local_savepath)
                if 'V-Ray frame buffer' in t:
                    print(h, t)
                    shot_windows(h, local_savepath)

                if "Render Setup: Corona" in t:
                    continue
                if "Corona Error" in t:
                    continue
                if "Corona" in t:
                    print(h, t)
                    shot_windows(h, local_savepath)

                if "Redshift Render View" in t:
                    print(h, t)
                    shot_windows(h, local_savepath)

if __name__ == '__main__':
    run()
