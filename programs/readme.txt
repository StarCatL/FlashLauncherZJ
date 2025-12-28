游戏路径：

app:/programs:
	demo:
		demo.swf
		xcmFlashConfig.json


xcmFlashConfig.json:
{
  "name": "demo",
  "bgColor": "0x333333",
  "des": "demo",
  "lowestVersion": 1.0,
  "core": "demo.swf",
  "icon": "icon.png"
}


swf转换说明：
  并非所有的swf都是支持的，加密加壳的是不太支持的。有嵌套壳的swf要先脱壳。
    首先确保你电脑上有 jdk17
  java -jar swfUtils-1.0-SNAPSHOT.jar "input.swf" "output.swf"


搭配ES前端:
    如果想搭配es前端使用，需要把实际roms所在的路径挂载到app:/programs，启动传递app:/programs/demo/demo.swf即可（没实际测试）