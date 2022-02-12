├─max_shots
│  │  initialize_COM_server.ms   //拷贝至max安装目录的C:\Program Files\Autodesk\3ds Max 2022\scripts\Startup 文件夹内，用于注册max的ole接口
│  │  max_shot.py                // 用于编译 max_shot.exe的主程序
│  │  ReadME.MD
│  │  
│  └─render_shot                 // 完整的目录拷贝到 \\Deadline10_Repo\custom\scripts\render_shot 
│          maxshot.ms            // 实际max执行的脚本
│          max_shot.exe          // 对运行中的3dsmax.exe进行附加进程，执行ms 脚本
│          RenderShot.py         // 在Deadline的 3dsmax.py中执行，用于循环执行外部max_shot.exe




