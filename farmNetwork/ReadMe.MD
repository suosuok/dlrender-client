├─max_shots
│  │  initialize_COM_server.ms
│  │  max_shot.py
│  │  ReadME.MD
│  └─render_shot
│          maxshot.ms
│          max_shot.exe
│          RenderShot.py

initialize_COM_server.ms   //拷贝至max安装目录的C:\Program Files\Autodesk\3ds Max 2022\scripts\Startup 文件夹内，用于注册max的ole接口
max_shot.py                // 用于编译 max_shot.exe的主程序
render_shot                // 完整的目录拷贝到 \\Deadline10_Repo\custom\scripts\render_shot 
maxshot.ms                 // 实际max执行的脚本
max_shot.exe               // 对运行中的3dsmax.exe进行附加进程，执行ms 脚本
RenderShot.py              // 在Deadline的 3dsmax.py中执行，用于循环执行外部max_shot.exe
在 RenderShot.py  中  start_shot 函数，的sec 参数，负责执行的频率。此处暂时写死了10秒一次，可以根据后期需要，调整截图频率。

    def start_shot(self, sec=10):
        self.logger("start render shot every {0} seconds.".format(sec))
        if not self._running:
            self._running = True
            self._create_timer()
