# FlashLauncherZJ

开源掌机的flash播放器

## 游戏路径与配置说明

目录结构
游戏文件应按照以下结构放置：

```text
app:/programs:
└── demo/
    ├── demo.swf
    └── xcmFlashConfig.json
```

配置文件说明
xcmFlashConfig.json 是游戏的核心配置文件，其字段含义如下：

```json
{
  "name": "demo",
  "bgColor": "0x333333",
  "des": "demo",
  "lowestVersion": 1.0,
  "core": "demo.swf",
  "icon": "icon.png"
}
```

## SWF 文件转换说明

仅支持未加密、未加壳的 SWF 文件。若文件经过加密或多层加壳，需先进行脱壳处理。

转换步骤：
确保系统已安装 JDK17

执行以下命令进行转换：

```bash
java -jar swfUtils-1.0-SNAPSHOT.jar "input.swf" "output.swf"
```

## 与 ES 前端集成

若需与 ES 前端配合使用，请将实际 ROM 所在路径挂载至 app:/programs。

启动时传递游戏主程序路径即可，例如：

```bash
xcmFlash app:/programs/demo/demo.swf
```

