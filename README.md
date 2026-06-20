# FlashLauncherZJ

开源掌机的flash播放器

## 游戏路径与配置说明

目录结构
游戏文件应按照以下结构放置：

```text
app:/programs/
├── demo/
│   ├── demo.swf
│   └── xcmFlashConfig.json
├── demo2/
│   ├── demo2.swf
│   └── xcmFlashConfig.json
└── ...
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
当原SWF文件无法运行时，建议尝试进行转换。但请注意，此方法为一种解决方案，其本身并不保证所有文件都能被修复并成功运行。

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

————————————————————————————————————————————————————————————————————————————

# FlashLauncherZJ
Flash Player for Open Source Handheld Game Consoles

## Game Path and Configuration Instructions
### Directory Structure

Game files should be placed according to the following structure:

```text
app:/programs/
├── demo/
│   ├── demo.swf
│   └── xcmFlashConfig.json
├── demo2/
│   ├── demo2.swf
│   └── xcmFlashConfig.json
└── ...
```

### Configuration File Description

xcmFlashConfig.json is the core configuration file for games, and the meanings of its fields are as follows:

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

## SWF File Conversion Instructions
Only unencrypted and unprotected SWF files are supported. If the file is encrypted or protected with multiple layers, it needs to be unprotected first.

If the original SWF file fails to run, conversion is recommended. However, please note that this method is a solution and does not guarantee that all files can be repaired and run successfully.

Ensure JDK17 is installed on the system.

Execute the following command for conversion:

```bash
java -jar swfUtils-1.0-SNAPSHOT.jar "input.swf" "output.swf"
```

## Integration with ES Frontend

To use with the ES frontend, mount the actual ROM path to app:/programs.

Pass the path of the game's main program when starting, for example:

```bash
xcmFlash app:/programs/demo/demo.swf
```
