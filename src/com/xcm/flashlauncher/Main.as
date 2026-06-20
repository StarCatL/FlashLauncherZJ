package com.xcm.flashlauncher {

import com.xcm.flashlauncher.config.GlobalConfig;
import com.xcm.flashlauncher.managers.MemoryManager;
import com.xcm.flashlauncher.ui.MainUI;

import flash.desktop.NativeApplication;
import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.MovieClip;
import flash.display.NativeWindow;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageDisplayState;
import flash.display.StageQuality;
import flash.display.StageScaleMode;
import flash.display.XCMLoader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.InvokeEvent;
import flash.events.KeyboardEvent;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.URLRequest;
import flash.net.XCMURLLoader;
import flash.system.ApplicationDomain;
import flash.system.Capabilities;
import flash.system.LoaderContext;
import flash.system.XCMSecurity;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.utils.Timer;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;

[SWF(frameRate=24, backgroundColor="#333333", width="940", height="590")]
public class Main extends Sprite {
    XCMLoader;
    XCMURLLoader;
    XCMSecurity;

    // 游戏列表相关
    private var programs:Array = [];
    private var currentGame:Loader;
    private var currentGameMovie:MovieClip;
    private var currentGameInfo:Object;

    private var mainUI:MainUI;

    private const TITLE:String = "星辰猫的Flash/AIR游戏启动器";
    private var settings:Object = {
        showMemory: true,
        selectedIndex: 0
    };

    private var originalWindowSize:Object = {
        width: 800,
        height: 600
    };

    // 图层分离
    private var gameLayer:Sprite;      // 游戏内容层
    private var topLayer:Sprite;       // 顶层元素层（内存显示等）

    // 内存管理器
    private var memoryManager:MemoryManager;

    public function Main() {
        if (stage) {
            init();
        } else {
            addEventListener(Event.ADDED_TO_STAGE, onStageAdded);
        }
    }

    private function onStageAdded(e:Event = null):void {
        removeEventListener(Event.ADDED_TO_STAGE, onStageAdded);
        init();
    }

    private function init():void {
        stage.quality = StageQuality.LOW;
        if (stage.nativeWindow) {
            originalWindowSize.width = stage.nativeWindow.width;
            originalWindowSize.height = stage.nativeWindow.height;
            trace("初始窗口尺寸: " + originalWindowSize.width + "x" + originalWindowSize.height);
        }
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        stage.stageFocusRect = false;

        gameLayer = new Sprite();
        topLayer = new Sprite();
        addChild(gameLayer); // 底层

        // 创建主界面
        mainUI = new MainUI(stage, programs);
        mainUI.onGameSelected = onGameSelected;
        mainUI.onGameLaunched = startProgram;
        addChild(mainUI.getContainer()); // 中层

        addChild(topLayer); // 顶层
        loadSettings();

        loadPrograms();

        // 初始化内存管理器
        memoryManager = new MemoryManager();
        memoryManager.setStage(stage);
        memoryManager.setParentContainer(topLayer);   // 设置父容器为顶层容器

        if (settings.showMemory) {
            memoryManager.showMemoryDisplay();
        }

        // 事件监听
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onGlobalKeyDown);
        stage.addEventListener(Event.RESIZE, onStageResize);
        stage.addEventListener(Event.FULLSCREEN, onFullScreenChange);

        stage.focus = mainUI.getContainer();

        // 自动全屏
        var timeout:uint = setTimeout(function ():void {
            stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
            stage.align = StageAlign.TOP;
            trace("全屏");
            clearTimeout(timeout);
        }, 0);

        NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
    }

    // ==================== 命令行处理 ====================
    private function onInvoke(event:InvokeEvent):void {
        NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE, onInvoke);
        var startupDir:File = event.currentDirectory;
        trace("程序启动目录: " + startupDir.nativePath);
        var args:Array = event.arguments;

        if (args.length === 1) {
            try {
                var paramFile:File = new File(args[0]);
                if (paramFile.exists) {
                    trace("找到文件: " + paramFile.nativePath);
                    if (paramFile.extension.toLowerCase() === "swf") {
                        trace("检测到SWF文件，尝试直接启动...");
                        var virtualConfig:Object = {
                            name: paramFile.name.replace("." + paramFile.extension, ""),
                            core: paramFile.name,
                            bgColor: "0x333333",
                            des: "命令行启动的游戏",
                            lowestVersion: 1.0,
                            width: 0,
                            height: 0,
                            resizeWindow: true,
                            server: null
                        };
                        var virtualProgram:Object = {
                            config: virtualConfig,
                            folder: paramFile.parent,
                            folderName: "CommandLine",
                            configFile: null,
                            folderURL: paramFile.parent.url
                        };
                        var existingIndex:int = -1;
                        for (var i:int = 0; i < programs.length; i++) {
                            if (programs[i].folderName === "CommandLine") {
                                existingIndex = i;
                                break;
                            }
                        }
                        if (existingIndex >= 0) {
                            programs[existingIndex] = virtualProgram;
                        } else {
                            programs.push(virtualProgram);
                        }
                        if (mainUI) {
                            mainUI.updatePrograms(programs);
                        }
                        var targetIndex:int = existingIndex >= 0 ? existingIndex : programs.length - 1;
                        trace("目标索引: " + targetIndex);
                        if (mainUI) {
                            mainUI.setSelectedIndex(targetIndex);
                        }
                        settings.selectedIndex = targetIndex;
                        saveSettings();
                        startProgram(targetIndex);
                        trace("命令行参数游戏启动成功!");
                    } else {
                        trace("错误: 文件不是SWF格式");
                        showMessage("错误: 只能启动SWF文件");
                    }
                } else {
                    trace("文件不存在: " + paramFile.nativePath);
                    showMessage("错误: 文件不存在 - " + paramFile.nativePath);
                }
            } catch (error:Error) {
                trace("参数解析失败: " + args[0]);
                trace("错误详情: " + error.message);
                showMessage("参数解析失败: " + error.message);
            }
        } else {
            trace("================================================");
            trace(TITLE);
            trace("用法: ./xcmFlash <SWF文件路径>");
            trace("示例1: ./xcmFlash demo.swf");
            trace("示例2: ./xcmFlash /home/user/test.swf");
            trace("示例3: ./xcmFlash app:/programs/demo/demo.swf");
            trace("推荐示例3");
            trace("主页: https://github.com/StarCatL/FlashLauncherZJ");
            trace("================================================");
        }
    }

    // ==================== 加载游戏配置 ====================
    private function loadPrograms():void {
        try {
            var appDir:File = File.applicationDirectory;
            var programsDir:File = appDir.resolvePath("programs");
            if (!programsDir.exists) {
                showMessage("未找到programs文件夹");
                return;
            }
            var dirs:Array = programsDir.getDirectoryListing();
            var configCount:int = 0;
            for each (var dir:File in dirs) {
                if (dir.isDirectory) {
                    var configFile:File = dir.resolvePath("xcmFlashConfig.json");
                    if (configFile.exists) {
                        try {
                            var config:Object = readConfigFile(configFile);
                            if (config) {
                                programs.push({
                                    config: config,
                                    folder: dir,
                                    folderName: dir.name,
                                    configFile: configFile,
                                    folderURL: dir.url
                                });
                                configCount++;
                            }
                        } catch (e:Error) {
                            trace("读取配置文件出错: " + dir.name);
                        }
                    }
                }
            }
            if (configCount > 0) {
                mainUI.updatePrograms(programs);
                mainUI.setSelectedIndex(settings.selectedIndex || 0);
            } else {
                showMessage("未找到有效的程序配置");
            }
        } catch (e:Error) {
            showMessage("错误: " + e.message);
        }
    }

    private function readConfigFile(file:File):Object {
        var fileStream:FileStream = new FileStream();
        fileStream.open(file, FileMode.READ);
        var jsonString:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
        fileStream.close();
        try {
            var config:Object = JSON.parse(jsonString);
            if (!config.hasOwnProperty("name") || !config.hasOwnProperty("core")) {
                return null;
            }
            if (!config.hasOwnProperty("bgColor")) config.bgColor = "0x333333";
            if (!config.hasOwnProperty("des")) config.des = "无描述";
            if (!config.hasOwnProperty("lowestVersion")) config.lowestVersion = 1.0;
            if (!config.hasOwnProperty("width")) config.width = 0;
            if (!config.hasOwnProperty("height")) config.height = 0;
            if (!config.hasOwnProperty("resizeWindow")) config.resizeWindow = true;
            return config;
        } catch (e:Error) {
            return null;
        }
    }

    private function onGameSelected(index:int):void {
        settings.selectedIndex = index;
        saveSettings();
    }

    // ==================== 全局键盘事件 ====================
    private function onGlobalKeyDown(e:KeyboardEvent):void {
        if (mainUI.getContainer().visible && programs.length > 0) {
            switch (e.keyCode) {
                case Keyboard.UP:
                    e.preventDefault();
                    if (mainUI.getSelectedIndex() > 0) {
                        mainUI.setSelectedIndex(mainUI.getSelectedIndex() - 1);
                        settings.selectedIndex = mainUI.getSelectedIndex();
                        saveSettings();
                    }
                    break;
                case Keyboard.DOWN:
                    e.preventDefault();
                    if (mainUI.getSelectedIndex() < programs.length - 1) {
                        mainUI.setSelectedIndex(mainUI.getSelectedIndex() + 1);
                        settings.selectedIndex = mainUI.getSelectedIndex();
                        saveSettings();
                    }
                    break;
                case Keyboard.ENTER:
                    e.preventDefault();
                    startProgram(mainUI.getSelectedIndex());
                    break;
            }
        }

        switch (e.keyCode) {
            case Keyboard.F1:
                memoryManager.toggleMemoryDisplay();
                settings.showMemory = memoryManager.isMemoryDisplayVisible();
                saveSettings();
                break;
            case Keyboard.F2:
                refreshCurrentGame();
                break;
            case Keyboard.F3:
                returnToMainMenu();
                break;
            case Keyboard.F4:
                toggleFullScreen();
                break;
            case Keyboard.F5:
                if (currentGame) {
                    debugInfo();
                }
                break;
        }
    }

    // ==================== 启动游戏 ====================
    private function startProgram(index:int):void {
        if (index >= programs.length) return;
        var program:Object = programs[index];
        var config:Object = program.config;
        var folder:File = program.folder;
        currentGameInfo = program;

        GlobalConfig.currentGameFolder = folder;
        GlobalConfig.currentServer = config.server;

        var bgColor:uint;
        if (config.bgColor is String && config.bgColor.indexOf("0x") == 0) {
            bgColor = parseInt(config.bgColor);
        } else {
            bgColor = parseInt("0x" + config.bgColor);
        }
        stage.color = bgColor;

        mainUI.getContainer().visible = false;
        cleanupCurrentGame();

        trace("尝试加载游戏: " + config.name);
        loadGame(folder, config.core);
    }

    private function cleanupCurrentGame():void {
        if (currentGame) {
            try {
                if (currentGameMovie && currentGameMovie is MovieClip) {
                    currentGameMovie.stop();
                }
                if (currentGame is Loader) {
                    currentGame.contentLoaderInfo.removeEventListener(Event.COMPLETE, onGameLoaded);
                    currentGame.contentLoaderInfo.removeEventListener(Event.INIT, onGameInit);
                    currentGame.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onGameLoadError);
                    if (gameLayer.contains(currentGame)) {
                        gameLayer.removeChild(currentGame);
                    }
                    try {
                        Loader(currentGame).unloadAndStop(true);
                    } catch (e:Error) {
                        trace("卸载游戏时出错: " + e.message);
                    }
                }
                currentGame = null;
                currentGameMovie = null;
                GlobalConfig.currentGameFolder = null;
            } catch (e:Error) {
                trace("清理游戏时出错: " + e.message);
            }
        }
    }

    private function loadGame(folder:File, corePath:String):void {
        try {
            var swfFile:File = folder.resolvePath(corePath);
            if (!swfFile.exists) {
                showMessage("错误: 未找到核心文件 " + corePath);
                return;
            }
            trace("游戏文件路径: " + swfFile.nativePath);
            trace("游戏URL: " + swfFile.url);

            var loader:Loader = new Loader();
            var context:LoaderContext = new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain));
            context.allowCodeImport = true;
            context.allowLoadBytesCodeExecution = true;

            GlobalConfig.currentGameFolder = folder;

            loader.contentLoaderInfo.addEventListener(Event.INIT, onGameInit);
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onGameLoaded);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onGameLoadError);

            loader.load(new URLRequest(swfFile.url), context);
            currentGame = loader;
        } catch (e:Error) {
            showMessage("加载游戏时出错: " + e.message);
            trace(e.getStackTrace());
        }
    }

    private function onGameInit(e:Event):void {
        trace("=== 游戏初始化 ===");
        trace("游戏URL: " + e.target.url);
        trace("游戏尺寸: " + e.target.width + "x" + e.target.height);
        trace("游戏帧率: " + e.target.frameRate);
        trace("游戏字节数: " + e.target.bytesTotal);
        trace("==================");
    }

    private function onGameLoaded(e:Event):void {
        trace("=== 游戏加载完成 ===");
        try {
            var content:DisplayObject = e.target.content as DisplayObject;
            if (!content) {
                trace("游戏内容为空");
                return;
            }
            if (e.target.frameRate > 0) {
                stage.frameRate = e.target.frameRate;
            }
            currentGameMovie = content as MovieClip;
            currentGame.x = 0;
            currentGame.y = 0;
            currentGame.scaleX = 1;
            currentGame.scaleY = 1;
            if (content is DisplayObject) {
                content.x = 0;
                content.y = 0;
                content.scaleX = 1;
                content.scaleY = 1;
            }
            gameLayer.addChild(currentGame);

            if (stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE) {
                // stage.scaleMode = StageScaleMode.SHOW_ALL;
                stage.scaleMode = StageScaleMode.EXACT_FIT;
            } else {
                stage.scaleMode = StageScaleMode.NO_SCALE;
            }
            stage.align = StageAlign.TOP_LEFT;

            resizeWindowForGame();

            // 确保内存显示在最上层
            memoryManager.ensureTopLayer();

            if (currentGameMovie is MovieClip) {
                currentGameMovie.play();
            }
        } catch (err:Error) {
            trace("初始化游戏时出错: " + err.message);
            trace(err.getStackTrace());
        }
        trace("==================");
    }

    private function onGameLoadError(e:IOErrorEvent):void {
        trace("加载游戏失败: " + e.text);
        showMessage("加载游戏失败: " + e.text);
    }

    private function resizeWindowForGame():void {
        if (!currentGame || !currentGame.contentLoaderInfo) return;
        try {
            var config:Object = currentGameInfo.config;
            var gameWidth:Number = currentGame.contentLoaderInfo.width;
            var gameHeight:Number = currentGame.contentLoaderInfo.height;
            trace("游戏原始尺寸: " + gameWidth + "x" + gameHeight);
            var targetWidth:int;
            var targetHeight:int;
            if (config.width > 0 && config.height > 0) {
                targetWidth = config.width;
                targetHeight = config.height;
                trace("使用配置文件尺寸: " + targetWidth + "x" + targetHeight);
            } else if (gameWidth > 0 && gameHeight > 0) {
                targetWidth = gameWidth;
                targetHeight = gameHeight;
                trace("使用游戏原始尺寸: " + targetWidth + "x" + targetHeight);
            } else {
                trace("无法获取有效尺寸");
                return;
            }
            if (!config.resizeWindow) {
                trace("配置设置为不调整窗口大小");
                return;
            }
            if (stage.nativeWindow && stage.displayState == StageDisplayState.NORMAL) {
                var chromeWidth:int = stage.nativeWindow.width - stage.stageWidth;
                var chromeHeight:int = stage.nativeWindow.height - stage.stageHeight;
                stage.nativeWindow.width = targetWidth + chromeWidth;
                stage.nativeWindow.height = targetHeight + chromeHeight;
                centerWindow(NativeWindow(stage.nativeWindow));
                trace("窗口已调整到: " + stage.nativeWindow.width + "x" + stage.nativeWindow.height);
            }
        } catch (e:Error) {
            trace("调整窗口大小时出错: " + e.message);
        }
    }

    private function centerWindow(window:NativeWindow):void {
        try {
            var screenWidth:Number = Capabilities.screenResolutionX;
            var screenHeight:Number = Capabilities.screenResolutionY;
            var windowX:int = (screenWidth - window.width) / 2;
            var windowY:int = (screenHeight - window.height) / 2;
            if (windowX < 0) windowX = 0;
            if (windowY < 0) windowY = 0;
            if (windowX + window.width > screenWidth) windowX = screenWidth - window.width;
            if (windowY + window.height > screenHeight) windowY = screenHeight - window.height;
            window.x = windowX;
            window.y = windowY;
            trace("窗口居中位置: (" + windowX + ", " + windowY + ")");
        } catch (e:Error) {
            trace("居中窗口时出错: " + e.message);
        }
    }


    private function onStageResize(e:Event = null):void {
        trace("舞台大小改变: " + stage.stageWidth + "x" + stage.stageHeight);
        // 调整内存显示位置 左上角
        if (memoryManager.isMemoryDisplayVisible()) {
            memoryManager.setPosition(10, 10);
        }
    }

    private function toggleFullScreen():void {
        if (stage.displayState == StageDisplayState.NORMAL) {
            stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
            stage.align = StageAlign.TOP;
        } else {
            stage.displayState = StageDisplayState.NORMAL;
        }
    }

    private function refreshCurrentGame():void {
        if (currentGame && currentGameInfo) {
            returnToMainMenuOld();
            var timer:Timer = new Timer(100, 1);
            timer.addEventListener(TimerEvent.TIMER, function (e:TimerEvent):void {
                var index:int = programs.indexOf(currentGameInfo);
                if (index >= 0) {
                    startProgram(index);
                }
            });
            timer.start();
        }
    }

    private function returnToMainMenuOld():void {
        cleanupCurrentGame();
        GlobalConfig.currentGameFolder = null;

        if (stage.nativeWindow && stage.displayState == StageDisplayState.NORMAL) {
            stage.nativeWindow.width = originalWindowSize.width;
            stage.nativeWindow.height = originalWindowSize.height;
            centerWindow(stage.nativeWindow);
            trace("窗口已恢复到原始尺寸: " + originalWindowSize.width + "x" + originalWindowSize.height);
        }
        stage.color = 0x333333;
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        mainUI.getContainer().visible = true;
        mainUI.setSelectedIndex(settings.selectedIndex || 0);
        stage.focus = mainUI.getContainer();
        stage.frameRate = 24;
    }

    private function returnToMainMenu():void {
        settings.selectedIndex = mainUI.getSelectedIndex();
        saveSettings();
        var appFile:File;
        if (Capabilities.os.indexOf("Windows") != -1) {
            appFile = File.applicationDirectory.resolvePath("xcmFlash.exe");
        } else if (Capabilities.os.indexOf("Linux") != -1) {
            appFile = File.applicationDirectory.resolvePath("xcmFlash");
        } else {
            trace("不支持的操作系统: " + Capabilities.os);
            return;
        }
        var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
        startupInfo.executable = appFile;
        var process:NativeProcess = new NativeProcess();
        process.start(startupInfo);
        stage.nativeWindow.close();
    }

    private function debugInfo():void {
        trace("=== 调试信息 ===");
        trace("舞台尺寸: " + stage.stageWidth + "x" + stage.stageHeight);
        trace("舞台缩放模式: " + stage.scaleMode);
        trace("舞台对齐: " + stage.align);
        trace("显示状态: " + stage.displayState);
        if (currentGame && currentGame.contentLoaderInfo) {
            trace("游戏原始尺寸: " + currentGame.contentLoaderInfo.width + "x" + currentGame.contentLoaderInfo.height);
            trace("Loader尺寸: " + currentGame.width + "x" + currentGame.height);
        }
        if (stage.nativeWindow) {
            trace("窗口尺寸: " + stage.nativeWindow.width + "x" + stage.nativeWindow.height);
            var chromeWidth:int = stage.nativeWindow.width - stage.stageWidth;
            var chromeHeight:int = stage.nativeWindow.height - stage.stageHeight;
            trace("窗口装饰尺寸: " + chromeWidth + "x" + chromeHeight);
        }
        trace("===============");
    }

    private function showMessage(msg:String):void {
        var messageField:TextField = new TextField();
        var messageFormat:TextFormat = new TextFormat();
        messageFormat.font = "_sans";
        messageFormat.size = 14;
        messageFormat.color = 0xFF0000;
        messageField.defaultTextFormat = messageFormat;
        messageField.text = msg;
        messageField.x = 20;
        messageField.y = 500;
        messageField.width = 400;
        messageField.height = 100;
        messageField.multiline = true;
        messageField.wordWrap = true;
        mainUI.getContainer().addChild(messageField);
        mainUI.getContainer().visible = true;
    }

    private function onFullScreenChange(e:Event):void {
        if (stage.displayState == StageDisplayState.NORMAL) {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
        } else {
            // stage.scaleMode = StageScaleMode.SHOW_ALL;
            stage.scaleMode = StageScaleMode.EXACT_FIT;
            stage.align = StageAlign.TOP_LEFT;
        }
        saveSettings();
    }

    private function loadSettings():void {
        try {
            var settingsFile:File = new File(File.applicationDirectory.resolvePath("assets/settings.json").nativePath);
            if (settingsFile.exists) {
                var fileStream:FileStream = new FileStream();
                fileStream.open(settingsFile, FileMode.READ);
                var jsonString:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
                fileStream.close();

                var loaded:Object = JSON.parse(jsonString);

                if (loaded.hasOwnProperty("showMemory")) settings.showMemory = loaded.showMemory;
                if (loaded.hasOwnProperty("selectedIndex")) settings.selectedIndex = loaded.selectedIndex;

                trace("设置加载成功: " + settingsFile.nativePath);
            } else {
                trace("设置文件不存在，使用默认设置");
                saveSettings();
            }
        } catch (e:Error) {
            trace("加载设置失败: " + e.message);
        }
    }

    private function saveSettings():void {
        try {
            var settingsFile:File = new File(File.applicationDirectory.resolvePath("assets/settings.json").nativePath);

            var parentDir:File = settingsFile.parent;
            if (!parentDir.exists) {
                parentDir.createDirectory();
            }

            var fileStream:FileStream = new FileStream();
            fileStream.open(settingsFile, FileMode.WRITE);
            var jsonString:String = JSON.stringify({
                showMemory: settings.showMemory,
                displayState: settings.displayState,
                selectedIndex: settings.selectedIndex
            });
            fileStream.writeUTFBytes(jsonString);
            fileStream.close();

            trace("设置保存成功: " + settingsFile.nativePath);
        } catch (e:Error) {
            trace("保存设置失败: " + e.message);
        }
    }
}
}