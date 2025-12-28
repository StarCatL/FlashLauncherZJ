package com.xcm.flashlauncher {

import com.xcm.flashlauncher.config.GlobalConfig;
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
import flash.display.StageScaleMode;
import flash.display.XCMLoader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.InvokeEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.filesystem.FileMode;
import flash.filesystem.FileStream;
import flash.net.URLRequest;
import flash.net.XCMURLLoader;
import flash.system.ApplicationDomain;
import flash.system.Capabilities;
import flash.system.LoaderContext;
import flash.system.System;
import flash.system.XCMSecurity;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.ui.Keyboard;
import flash.utils.Timer;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;

[SWF(frameRate=24, backgroundColor="#333333", width="940", height="590")]
public class Main extends Sprite {
    XCMURLLoader;
    XCMSecurity;
    XCMLoader;

    private var programs:Array = [];
    private var currentGame:Loader;
    private var currentGameMovie:MovieClip;
    private var currentGameInfo:Object;

    // UI实例
    private var mainUI:MainUI;

    private const TITLE:String = "星辰猫的Flash/AIR游戏启动器";
    private var settings:Object = {
        showMemory: true,
        displayState: "normal",
        selectedIndex: 0
    };

    // 存储启动器窗口的原始尺寸
    private var originalWindowSize:Object = {
        width: 800,
        height: 600
    };

    // 内存更新定时器
    private var memoryTimer:Timer;
    private var showMemory:Boolean = false;
    private var memoryField:TextField;
    private var memoryBackground:Sprite;

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
        // 保存窗口原始尺寸
        if (stage.nativeWindow) {
            originalWindowSize.width = stage.nativeWindow.width;
            originalWindowSize.height = stage.nativeWindow.height;
            trace("初始窗口尺寸: " + originalWindowSize.width + "x" + originalWindowSize.height);
        }
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
        stage.stageFocusRect = false;

        loadSettings();

        // 恢复上次的显示状态
        if (settings.displayState == "fullScreenInteractive") {
            stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
            stage.scaleMode = StageScaleMode.SHOW_ALL;
        } else {
            stage.displayState = StageDisplayState.NORMAL;
            stage.scaleMode = StageScaleMode.NO_SCALE;
        }

        // 创建UI
        mainUI = new MainUI(stage, programs);
        mainUI.onGameSelected = onGameSelected;
        mainUI.onGameLaunched = startProgram;
        addChild(mainUI.getContainer());

        loadPrograms();

        if (settings.showMemory) {
            showMemory = true;
        }

        // 创建内存更新定时器（每5秒更新一次）
        memoryTimer = new Timer(5000, 0);
        memoryTimer.addEventListener(TimerEvent.TIMER, updateMemory);

        stage.addEventListener(KeyboardEvent.KEY_DOWN, onGlobalKeyDown);
        stage.addEventListener(Event.RESIZE, onStageResize);
        stage.addEventListener(Event.FULLSCREEN, onFullScreenChange);

        // 设置焦点到主容器
        stage.focus = mainUI.getContainer();

        var timeout:uint = setTimeout(function ():void {
            stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
            stage.align = StageAlign.TOP;
            trace("全屏");
            clearTimeout(timeout);
        }, 0);

        // 传参启动
        NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvoke);
    }

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

                        // 创建虚拟的游戏配置
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

                        // 创建虚拟的program对象
                        var virtualProgram:Object = {
                            config: virtualConfig,
                            folder: paramFile.parent,
                            folderName: "CommandLine",
                            configFile: null,
                            folderURL: paramFile.parent.url
                        };

                        // 添加到programs数组（如果不存在）
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

                        // 查找并选择这个程序
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
            if (Capabilities.os.indexOf("Windows") != -1) {
                trace("================================================");
                trace(TITLE);
                trace("用法: xcmFlash.exe <SWF文件路径>");
                trace("示例: xcmFlash.exe demo.swf");
                trace("示例: xcmFlash.exe C:\\projects\\test.swf");
                trace("================================================");
            } else if (Capabilities.os.indexOf("Linux") != -1) {
                trace("================================================");
                trace(TITLE);
                trace("用法: ./xcmFlash <SWF文件路径>");
                trace("示例: ./xcmFlash demo.swf");
                trace("示例: ./xcmFlash /home/user/test.swf");
                trace("================================================");
            }
        }
    }

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

    private function onGameSelected(index:int):void {
        settings.selectedIndex = index;
        saveSettings();
    }

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

        // 全局快捷键
        if (e.keyCode == Keyboard.F1) {
            toggleMemoryDisplay();
        }

        if (e.keyCode == Keyboard.F2) {
            refreshCurrentGame();
        }

        if (e.keyCode == Keyboard.F3) {
            returnToMainMenu();
        }

        if (e.keyCode == Keyboard.F4) {
            toggleFullScreen();
        }

        if (e.keyCode == Keyboard.F5) {
            if (currentGame) {
                debugInfo();
            }
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

    private function startProgram(index:int):void {
        if (index >= programs.length) return;

        var program:Object = programs[index];
        var config:Object = program.config;
        var folder:File = program.folder;

        currentGameInfo = program;

        // TODO 设置静态变量，供XCMURLLoader使用
        GlobalConfig.currentGameFolder = folder;
        GlobalConfig.currentServer = config.server;

        // 设置背景颜色
        var bgColor:uint;
        if (config.bgColor is String && config.bgColor.indexOf("0x") == 0) {
            bgColor = parseInt(config.bgColor);
        } else {
            bgColor = parseInt("0x" + config.bgColor);
        }
        stage.color = bgColor;

        // 隐藏主菜单
        mainUI.getContainer().visible = false;

        // 清理当前游戏
        cleanupCurrentGame();

        // 初始化内存显示
        if (showMemory) {
            initMemoryDisplay();
        }

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

                    if (stage.contains(currentGame)) {
                        stage.removeChild(currentGame);
                    }

                    try {
                        Loader(currentGame).unloadAndStop(true);
                    } catch (e:Error) {
                        trace("卸载游戏时出错: " + e.message);
                    }
                }

                currentGame = null;
                currentGameMovie = null;

                // 清理静态变量
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

            // 设置当前游戏文件夹路径
            GlobalConfig.currentGameFolder = folder;

            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onGameLoaded);
            loader.contentLoaderInfo.addEventListener(Event.INIT, onGameInit);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onGameLoadError);

            loader.load(new URLRequest(swfFile.url), context);

            currentGame = loader;

        } catch (e:Error) {
            showMessage("加载游戏时出错: " + e.message);
            trace(e.getStackTrace());
        }
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

            stage.addChild(currentGame);

            if (stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE) {
                stage.scaleMode = StageScaleMode.SHOW_ALL;
            } else {
                stage.scaleMode = StageScaleMode.NO_SCALE;
            }
            stage.align = StageAlign.TOP_LEFT;

            resizeWindowForGame();

            if (currentGameMovie is MovieClip) {
                currentGameMovie.play();
            }

        } catch (err:Error) {
            trace("初始化游戏时出错: " + err.message);
            trace(err.getStackTrace());
        }
        trace("==================");
    }

    private function onGameInit(e:Event):void {
        trace("=== 游戏初始化 ===");
        trace("游戏URL: " + e.target.url);
        trace("游戏尺寸: " + e.target.width + "x" + e.target.height);
        trace("游戏帧率: " + e.target.frameRate);
        trace("游戏字节数: " + e.target.bytesTotal);
        trace("==================");
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

    private function onGameLoadError(e:IOErrorEvent):void {
        trace("加载游戏失败: " + e.text);
        showMessage("加载游戏失败: " + e.text);
    }

    private function onStageResize(e:Event = null):void {
        trace("舞台大小改变: " + stage.stageWidth + "x" + stage.stageHeight);

        if (memoryBackground && memoryField) {
            memoryBackground.x = 10;
            memoryBackground.y = 10;
            memoryField.x = memoryBackground.x + 5;
            memoryField.y = memoryBackground.y + 2;
        }
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

    private function toggleMemoryDisplay():void {
        showMemory = !showMemory;
        settings.showMemory = showMemory;
        saveSettings();

        if (showMemory) {
            if (!memoryField || !stage.contains(memoryField)) {
                initMemoryDisplay();
            } else {
                memoryField.visible = true;
                if (memoryBackground) {
                    memoryBackground.visible = true;
                }
                if (!memoryTimer.running) {
                    memoryTimer.start();
                }
            }
        } else {
            if (memoryField) {
                memoryField.visible = false;
                if (memoryBackground) {
                    memoryBackground.visible = false;
                }
                if (memoryTimer.running) {
                    memoryTimer.stop();
                }
            }
        }
    }

    private function returnToMainMenuOld():void {
        cleanupCurrentGame();

        // 清理静态变量
        GlobalConfig.currentGameFolder = null;

        if (memoryField && stage.contains(memoryField)) {
            stage.removeChild(memoryField);
        }
        if (memoryBackground && stage.contains(memoryBackground)) {
            stage.removeChild(memoryBackground);
        }
        memoryField = null;
        memoryBackground = null;

        if (memoryTimer && memoryTimer.running) {
            memoryTimer.stop();
        }

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

        // 恢复选择状态
        mainUI.setSelectedIndex(settings.selectedIndex || 0);

        stage.focus = mainUI.getContainer();

        stage.frameRate = 24;
    }

    private function returnToMainMenu():void {
        // 保存当前选中的游戏索引
        settings.selectedIndex = mainUI.getSelectedIndex();
        saveSettings();

        // 启动新的进程
        var appFile:File;

        if (Capabilities.os.indexOf("Windows") != -1) {
            appFile = File.applicationDirectory.resolvePath("xcmFlash.exe");
        } else if (Capabilities.os.indexOf("Mac OS") != -1) {
            // TODO Mac系统
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

        // 关闭当前窗口
        stage.nativeWindow.close();
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

        // 使用mainUI的容器显示消息
        mainUI.getContainer().addChild(messageField);
        mainUI.getContainer().visible = true;
    }

    private function initMemoryDisplay():void {
        if (memoryField && stage.contains(memoryField)) {
            memoryField.visible = true;
            if (memoryBackground) {
                memoryBackground.visible = true;
            }
            if (!memoryTimer.running) {
                memoryTimer.start();
            }
            return;
        }

        memoryBackground = new Sprite();
        memoryBackground.graphics.beginFill(0x000000);
        memoryBackground.graphics.drawRect(0, 0, 100, 20);
        memoryBackground.graphics.endFill();
        memoryBackground.alpha = 0.7;

        memoryBackground.addEventListener(MouseEvent.ROLL_OUT, function (e:MouseEvent):void {
            e.target.alpha = 0.7;
        });

        memoryBackground.addEventListener(MouseEvent.ROLL_OVER, function (e:MouseEvent):void {
            e.target.alpha = 1.0;
        });

        stage.addChild(memoryBackground);

        memoryField = new TextField();
        memoryField.autoSize = "left";
        memoryField.y = 2;
        memoryField.x = 5;
        memoryField.textColor = 0x00FF00;
        memoryField.mouseEnabled = false;
        memoryField.selectable = false;
        memoryField.text = "内存 : 0 mb";

        stage.addChild(memoryField);

        memoryBackground.x = 10;
        memoryBackground.y = 10;
        memoryField.x = memoryBackground.x + 5;
        memoryField.y = memoryBackground.y + 2;

        if (!memoryTimer.running) {
            memoryTimer.start();
        }

        updateMemory(null);
    }

    private function updateMemory(param1:TimerEvent):void {
        if (memoryField && memoryBackground) {
            var memoryMB:Number = Number(Number(System.privateMemory / 1048576).toFixed(2));
            memoryField.text = "内存 : " + memoryMB + " mb";

            if (memoryMB < 100) {
                memoryField.textColor = 0x00FF00;
            } else if (memoryMB < 300) {
                memoryField.textColor = 0xFFFF00;
            } else {
                memoryField.textColor = 0xFF0000;
            }
        }
    }

    private function onFullScreenChange(e:Event):void {
        if (stage.displayState == StageDisplayState.NORMAL) {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            settings.displayState = "normal";
            saveSettings();
        } else {
            stage.scaleMode = StageScaleMode.SHOW_ALL;
            stage.align = StageAlign.TOP_LEFT;
            settings.displayState = "fullScreenInteractive";
            saveSettings();
        }
    }

    private function loadSettings():void {
        try {
            var settingsFile:File = File.applicationStorageDirectory.resolvePath("settings.json");
            if (settingsFile.exists) {
                var fileStream:FileStream = new FileStream();
                fileStream.open(settingsFile, FileMode.READ);
                var jsonString:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
                fileStream.close();
                settings = JSON.parse(jsonString);
            }
        } catch (e:Error) {
            trace("加载设置失败: " + e.message);
        }
    }

    private function saveSettings():void {
        try {
            var settingsFile:File = File.applicationStorageDirectory.resolvePath("settings.json");
            var fileStream:FileStream = new FileStream();
            fileStream.open(settingsFile, FileMode.WRITE);
            var jsonString:String = JSON.stringify(settings);
            fileStream.writeUTFBytes(jsonString);
            fileStream.close();
        } catch (e:Error) {
            trace("保存设置失败: " + e.message);
        }
    }
}
}