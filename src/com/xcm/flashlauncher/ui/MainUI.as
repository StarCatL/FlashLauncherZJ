package com.xcm.flashlauncher.ui {

import flash.display.Sprite;
import flash.display.Stage;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;

public class MainUI extends Sprite {

    private var stageRef:Stage;
    private var mainContainer:Sprite;

    // UI组件
    private var leftPanel:Sprite;
    private var rightPanel:Sprite;
    private var listContainer:Sprite;
    private var listMask:Sprite;
    private var scrollBar:Sprite;
    private var scrollTrack:Sprite;
    private var scrollThumb:Sprite;
    private var detailContainer:Sprite;

    // 游戏列表相关
    private var listItems:Array = [];
    private var selectedIndex:int = 0;
    private var programs:Array;
    private var maxVisibleItems:int;
    private var listItemHeight:int = 40;
    private var scrollOffset:int = 0;
    private var maxScrollOffset:int = 0;
    private var isDraggingThumb:Boolean = false;
    private var thumbDragStartY:Number = 0;

    // UI样式常量
    private const PANEL_BG_COLOR:uint = 0x222222;
    private const LIST_ITEM_NORMAL_COLOR:uint = 0x2a2a2a;
    private const LIST_ITEM_HOVER_COLOR:uint = 0x333333;
    private const LIST_ITEM_SELECTED_COLOR:uint = 0x444444;
    private const SCROLLBAR_TRACK_COLOR:uint = 0x1a1a1a;
    private const SCROLLBAR_THUMB_COLOR:uint = 0x666666;
    private const SCROLLBAR_THUMB_HOVER_COLOR:uint = 0x888888;

    // 回调函数
    public var onGameSelected:Function;
    public var onGameLaunched:Function;

    public function MainUI(stageRef:Stage, programs:Array) {
        this.stageRef = stageRef;
        this.programs = programs;
        this.mainContainer = new Sprite();
        addChild(mainContainer);

        createUI();
    }

    public function getContainer():Sprite {
        return mainContainer;
    }

    public function setSelectedIndex(index:int):void {
        selectedIndex = index;
        updateSelection();
        updateDetailView();
    }

    public function getSelectedIndex():int {
        return selectedIndex;
    }

    public function updatePrograms(newPrograms:Array):void {
        programs = newPrograms;
        createListItems();
        updateDetailView();
    }

    private function createUI():void {
        createTitle();
        createLeftPanel();
        createRightPanel();
        layoutUI();
    }

    private function createTitle():void {
        var titleFormat:TextFormat = new TextFormat();
        titleFormat.font = "_sans";
        titleFormat.size = 24;
        titleFormat.color = 0xFFFFFF;
        titleFormat.bold = true;

        var titleField:TextField = new TextField();
        titleField.defaultTextFormat = titleFormat;
        titleField.text = "星辰猫的Flash/AIR游戏启动器";
        titleField.x = 20;
        titleField.y = 20;
        titleField.width = 400;
        titleField.height = 40;
        mainContainer.addChild(titleField);
    }

    private function createLeftPanel():void {
        leftPanel = new Sprite();
        mainContainer.addChild(leftPanel);

        // 左侧面板背景
        leftPanel.graphics.beginFill(PANEL_BG_COLOR);
        leftPanel.graphics.drawRect(0, 0, 320, 480);
        leftPanel.graphics.endFill();

        // 游戏列表标题
        var listTitleFormat:TextFormat = new TextFormat();
        listTitleFormat.font = "_sans";
        listTitleFormat.size = 16;
        listTitleFormat.color = 0xFFFFFF;
        listTitleFormat.bold = true;

        var listTitle:TextField = new TextField();
        listTitle.defaultTextFormat = listTitleFormat;
        listTitle.text = "游戏列表";
        listTitle.x = 10;
        listTitle.y = 10;
        listTitle.width = 100;
        listTitle.height = 30;
        leftPanel.addChild(listTitle);

        // 创建列表容器
        listContainer = new Sprite();
        leftPanel.addChild(listContainer);

        // 创建遮罩
        listMask = new Sprite();
        listMask.graphics.beginFill(0xFF0000, 0);
        listMask.graphics.drawRect(0, 0, 290, 420);
        listMask.graphics.endFill();
        leftPanel.addChild(listMask);

        listContainer.mask = listMask;

        // 计算最大可见项目数
        maxVisibleItems = Math.floor(listMask.height / listItemHeight);

        // 创建滚动条
        createScrollBar();

        // 添加鼠标滚轮事件到左侧面板
        leftPanel.addEventListener(MouseEvent.MOUSE_WHEEL, onPanelMouseWheel);
    }

    private function createScrollBar():void {
        scrollBar = new Sprite();
        leftPanel.addChild(scrollBar);

        // 滚动条轨道
        scrollTrack = new Sprite();
        scrollTrack.graphics.beginFill(SCROLLBAR_TRACK_COLOR);
        scrollTrack.graphics.drawRect(0, 0, 10, listMask.height);
        scrollTrack.graphics.endFill();
        scrollBar.addChild(scrollTrack);

        // 滚动条滑块
        scrollThumb = new Sprite();
        scrollThumb.graphics.beginFill(SCROLLBAR_THUMB_COLOR);
        scrollThumb.graphics.drawRect(0, 0, 10, 60);
        scrollThumb.graphics.endFill();
        scrollBar.addChild(scrollThumb);

        // 滑块交互
        scrollThumb.buttonMode = true;
        scrollThumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
        scrollThumb.addEventListener(MouseEvent.ROLL_OVER, onThumbRollOver);
        scrollThumb.addEventListener(MouseEvent.ROLL_OUT, onThumbRollOut);

        // 滚动条轨道也支持点击
        scrollTrack.addEventListener(MouseEvent.CLICK, onTrackClick);
    }

    private function createRightPanel():void {
        rightPanel = new Sprite();
        mainContainer.addChild(rightPanel);

        // 右侧面板背景
        rightPanel.graphics.beginFill(PANEL_BG_COLOR);
        rightPanel.graphics.drawRect(0, 0, 580, 480);
        rightPanel.graphics.endFill();

        // 游戏信息标题
        var infoTitleFormat:TextFormat = new TextFormat();
        infoTitleFormat.font = "_sans";
        infoTitleFormat.size = 16;
        infoTitleFormat.color = 0xFFFFFF;
        infoTitleFormat.bold = true;

        var infoTitle:TextField = new TextField();
        infoTitle.defaultTextFormat = infoTitleFormat;
        infoTitle.text = "游戏信息";
        infoTitle.x = 10;
        infoTitle.y = 10;
        infoTitle.width = 100;
        infoTitle.height = 30;
        rightPanel.addChild(infoTitle);

        // 详细信息容器
        detailContainer = new Sprite();
        detailContainer.x = 10;
        detailContainer.y = 50;
        rightPanel.addChild(detailContainer);

        // 操作提示
        var controlsFormat:TextFormat = new TextFormat();
        controlsFormat.font = "_sans";
        controlsFormat.size = 12;
        controlsFormat.color = 0x888888;

        var controlsText:TextField = new TextField();
        controlsText.defaultTextFormat = controlsFormat;
        controlsText.text = "↑/↓ 选择游戏，回车启动，F1 内存显示，F2 刷新游戏，F3 返回菜单，F4 全屏";
        controlsText.x = 10;
        controlsText.y = 440;
        controlsText.width = 560;
        controlsText.height = 30;
        rightPanel.addChild(controlsText);
    }

    private function layoutUI():void {
        leftPanel.x = 20;
        leftPanel.y = 80;

        rightPanel.x = 360;
        rightPanel.y = 80;

        listContainer.x = 10;
        listContainer.y = 50;

        listMask.x = 10;
        listMask.y = 50;

        scrollBar.x = 305;
        scrollBar.y = 50;
    }

    private function createListItems():void {
        // 清空现有列表项
        for each (var item:Sprite in listItems) {
            if (listContainer.contains(item)) {
                listContainer.removeChild(item);
            }
        }
        listItems = [];

        // 重新计算最大滚动偏移量
        maxVisibleItems = Math.floor(listMask.height / listItemHeight);
        maxScrollOffset = Math.max(0, (programs.length - maxVisibleItems) * listItemHeight);

        // 创建列表项
        for (var i:int = 0; i < programs.length; i++) {
            var program:Object = programs[i];
            var listItem:Sprite = createListItem(program.config.name, i);
            listItem.y = i * listItemHeight;
            listContainer.addChild(listItem);
            listItems.push(listItem);
        }

        // 更新选中状态
        updateSelection();

        // 更新滚动条
        updateScrollBar();
    }

    private function createListItem(label:String, index:int):Sprite {
        var item:Sprite = new Sprite();
        item.name = "listItem_" + index;
        item.mouseEnabled = true;
        item.buttonMode = true;

        // 绘制背景
        drawListItem(item, LIST_ITEM_NORMAL_COLOR);

        // 添加文本
        var itemFormat:TextFormat = new TextFormat();
        itemFormat.font = "_sans";
        itemFormat.size = 14;
        itemFormat.color = 0xCCCCCC;

        var itemText:TextField = new TextField();
        itemText.defaultTextFormat = itemFormat;
        itemText.text = label;
        itemText.x = 10;
        itemText.y = 10;
        itemText.width = 250;
        itemText.height = 20;
        itemText.selectable = false;
        itemText.mouseEnabled = false;
        item.addChild(itemText);

        // 鼠标事件
        item.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
            selectedIndex = index;
            updateSelection();
            updateDetailView();
            if (onGameSelected != null) {
                onGameSelected(selectedIndex);
            }
        });

        item.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
            if (selectedIndex != index) {
                drawListItem(item, LIST_ITEM_HOVER_COLOR);
            }
        });

        item.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
            if (selectedIndex != index) {
                drawListItem(item, LIST_ITEM_NORMAL_COLOR);
            }
        });

        return item;
    }

    private function drawListItem(item:Sprite, color:uint):void {
        item.graphics.clear();
        item.graphics.beginFill(color);
        item.graphics.drawRect(0, 0, 290, listItemHeight);
        item.graphics.endFill();
    }

    private function updateSelection():void {
        for (var i:int = 0; i < listItems.length; i++) {
            var item:Sprite = listItems[i];
            if (i == selectedIndex) {
                drawListItem(item, LIST_ITEM_SELECTED_COLOR);
                ensureItemVisible(i);
            } else {
                drawListItem(item, LIST_ITEM_NORMAL_COLOR);
            }
        }
    }

    private function ensureItemVisible(index:int):void {
        if (listItems.length == 0) return;

        var itemTop:Number = index * listItemHeight;
        var itemBottom:Number = itemTop + listItemHeight;

        // 计算项目相对于遮罩的位置
        var itemVisibleTop:Number = itemTop - scrollOffset;
        var itemVisibleBottom:Number = itemBottom - scrollOffset;

        // 如果项目在可视区域上方
        if (itemVisibleTop < 0) {
            scrollOffset = itemTop;
        }
        // 如果项目在可视区域下方
        else if (itemVisibleBottom > listMask.height) {
            scrollOffset = itemBottom - listMask.height;
        }

        // 确保滚动偏移在有效范围内
        scrollOffset = Math.max(0, Math.min(scrollOffset, maxScrollOffset));

        // 更新列表位置
        listContainer.y = 50 - scrollOffset;

        // 更新滚动条
        updateScrollBar();
    }

    private function updateScrollBar():void {
        if (programs.length <= maxVisibleItems || maxScrollOffset <= 0) {
            scrollBar.visible = false;
            return;
        }

        scrollBar.visible = true;

        // 计算滑块大小和位置
        var visibleRatio:Number = Math.min(1, maxVisibleItems / programs.length);
        var thumbHeight:Number = Math.max(20, listMask.height * visibleRatio);
        var trackHeight:Number = listMask.height;
        var maxThumbTravel:Number = trackHeight - thumbHeight;
        var thumbPosition:Number = 0;

        if (maxScrollOffset > 0) {
            thumbPosition = (scrollOffset / maxScrollOffset) * maxThumbTravel;
        }

        // 确保滑块位置在有效范围内
        thumbPosition = Math.max(0, Math.min(maxThumbTravel, thumbPosition));

        // 更新滑块
        scrollThumb.graphics.clear();
        if (isDraggingThumb) {
            scrollThumb.graphics.beginFill(SCROLLBAR_THUMB_HOVER_COLOR);
        } else {
            scrollThumb.graphics.beginFill(SCROLLBAR_THUMB_COLOR);
        }
        scrollThumb.graphics.drawRect(0, 0, 10, thumbHeight);
        scrollThumb.graphics.endFill();

        scrollThumb.height = thumbHeight;
        scrollThumb.y = thumbPosition;
    }

    private function onThumbMouseDown(e:MouseEvent):void {
        isDraggingThumb = true;
        thumbDragStartY = e.stageY;
        var thumbStartY:Number = scrollThumb.y;

        stageRef.addEventListener(MouseEvent.MOUSE_MOVE, onThumbMouseMove);
        stageRef.addEventListener(MouseEvent.MOUSE_UP, onThumbMouseUp);

        function onThumbMouseMove(e:MouseEvent):void {
            var deltaY:Number = e.stageY - thumbDragStartY;
            var newThumbY:Number = Math.max(0, Math.min(listMask.height - scrollThumb.height, thumbStartY + deltaY));

            // 更新滑块位置
            scrollThumb.y = newThumbY;

            // 更新滚动偏移
            var trackHeight:Number = listMask.height - scrollThumb.height;
            if (trackHeight > 0) {
                scrollOffset = (newThumbY / trackHeight) * maxScrollOffset;
                listContainer.y = 50 - scrollOffset;
            }
        }

        function onThumbMouseUp(e:MouseEvent):void {
            isDraggingThumb = false;
            stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, onThumbMouseMove);
            stageRef.removeEventListener(MouseEvent.MOUSE_UP, onThumbMouseUp);
            updateScrollBar();
        }
    }

    private function onThumbRollOver(e:MouseEvent):void {
        if (!isDraggingThumb) {
            scrollThumb.graphics.clear();
            scrollThumb.graphics.beginFill(SCROLLBAR_THUMB_HOVER_COLOR);
            scrollThumb.graphics.drawRect(0, 0, 10, scrollThumb.height);
            scrollThumb.graphics.endFill();
        }
    }

    private function onThumbRollOut(e:MouseEvent):void {
        if (!isDraggingThumb) {
            scrollThumb.graphics.clear();
            scrollThumb.graphics.beginFill(SCROLLBAR_THUMB_COLOR);
            scrollThumb.graphics.drawRect(0, 0, 10, scrollThumb.height);
            scrollThumb.graphics.endFill();
        }
    }

    private function onTrackClick(e:MouseEvent):void {
        var clickY:Number = e.localY;

        // 点击轨道时，将点击位置作为滑块中心
        var targetThumbY:Number = clickY - scrollThumb.height / 2;
        targetThumbY = Math.max(0, Math.min(listMask.height - scrollThumb.height, targetThumbY));

        // 更新滑块位置
        scrollThumb.y = targetThumbY;

        // 更新滚动偏移
        var trackHeight:Number = listMask.height - scrollThumb.height;
        if (trackHeight > 0) {
            scrollOffset = (targetThumbY / trackHeight) * maxScrollOffset;
            listContainer.y = 50 - scrollOffset;
        }
    }

    private function onPanelMouseWheel(e:MouseEvent):void {
        // 鼠标滚轮滚动
        var delta:int = e.delta;

        // 根据滚轮方向调整滚动偏移
        scrollOffset -= delta * listItemHeight * 3;

        // 确保滚动偏移在有效范围内
        scrollOffset = Math.max(0, Math.min(scrollOffset, maxScrollOffset));

        // 更新列表位置
        listContainer.y = 50 - scrollOffset;

        // 更新滚动条
        updateScrollBar();

        // 阻止事件冒泡
        e.stopPropagation();
    }

    private function updateDetailView():void {
        // 清空现有内容
        while (detailContainer.numChildren > 0) {
            detailContainer.removeChildAt(0);
        }

        if (selectedIndex >= 0 && selectedIndex < programs.length) {
            var program:Object = programs[selectedIndex];
            var config:Object = program.config;

            var yPos:Number = 0;

            // 游戏名称
            var nameFormat:TextFormat = new TextFormat();
            nameFormat.font = "_sans";
            nameFormat.size = 18;
            nameFormat.color = 0xFFFFFF;
            nameFormat.bold = true;

            var nameField:TextField = new TextField();
            nameField.defaultTextFormat = nameFormat;
            nameField.text = config.name;
            nameField.x = 0;
            nameField.y = yPos;
            nameField.width = 550;
            nameField.height = 30;
            detailContainer.addChild(nameField);
            yPos += 35;

            // 描述标题
            var descTitleFormat:TextFormat = new TextFormat();
            descTitleFormat.font = "_sans";
            descTitleFormat.size = 14;
            descTitleFormat.color = 0xCCCCCC;
            descTitleFormat.bold = true;

            var descTitle:TextField = new TextField();
            descTitle.defaultTextFormat = descTitleFormat;
            descTitle.text = "描述：";
            descTitle.x = 0;
            descTitle.y = yPos;
            descTitle.width = 50;
            descTitle.height = 20;
            detailContainer.addChild(descTitle);
            yPos += 25;

            // 描述内容
            var descFormat:TextFormat = new TextFormat();
            descFormat.font = "_sans";
            descFormat.size = 12;
            descFormat.color = 0xAAAAAA;

            var descField:TextField = new TextField();
            descField.defaultTextFormat = descFormat;
            descField.text = config.des || "无描述";
            descField.x = 0;
            descField.y = yPos;
            descField.width = 550;
            descField.height = 120;
            descField.multiline = true;
            descField.wordWrap = true;
            detailContainer.addChild(descField);
            yPos += 130;

            // 其他信息
            var infoFormat:TextFormat = new TextFormat();
            infoFormat.font = "_sans";
            infoFormat.size = 12;
            infoFormat.color = 0x888888;

            var infoText:String = "";
            infoText += "最低版本: " + config.lowestVersion + "\n";
            infoText += "文件夹: " + program.folderName + "\n";
            infoText += "核心文件: " + config.core + "\n";
            if (config.width > 0 && config.height > 0) {
                infoText += "尺寸: " + config.width + "x" + config.height + "\n";
            }
            infoText += "背景颜色: " + config.bgColor + "\n";
            infoText += "调整窗口: " + (config.resizeWindow ? "是" : "否");

            var infoField:TextField = new TextField();
            infoField.defaultTextFormat = infoFormat;
            infoField.text = infoText;
            infoField.x = 0;
            infoField.y = yPos;
            infoField.width = 550;
            infoField.height = 120;
            infoField.multiline = true;
            detailContainer.addChild(infoField);
            yPos += 130;

            // 启动按钮
            var startButton:Sprite = new Sprite();
            startButton.graphics.beginFill(0x4CAF50);
            startButton.graphics.drawRoundRect(0, 0, 120, 50, 8);
            startButton.graphics.endFill();

            var buttonFormat:TextFormat = new TextFormat();
            buttonFormat.font = "_sans";
            buttonFormat.size = 16;
            buttonFormat.color = 0xFFFFFF;
            buttonFormat.bold = true;
            buttonFormat.align = "center";

            var buttonText:TextField = new TextField();
            buttonText.defaultTextFormat = buttonFormat;
            buttonText.text = "启动游戏";
            buttonText.width = 120;
            buttonText.height = 50;
            buttonText.y = 15;
            buttonText.selectable = false;
            startButton.addChild(buttonText);

            startButton.x = 0;
            startButton.y = yPos;
            startButton.buttonMode = true;

            startButton.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
                if (onGameLaunched != null) {
                    onGameLaunched(selectedIndex);
                }
            });

            startButton.addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
                startButton.graphics.clear();
                startButton.graphics.beginFill(0x66BB6A);
                startButton.graphics.drawRoundRect(0, 0, 120, 50, 8);
                startButton.graphics.endFill();
            });

            startButton.addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
                startButton.graphics.clear();
                startButton.graphics.beginFill(0x4CAF50);
                startButton.graphics.drawRoundRect(0, 0, 120, 50, 8);
                startButton.graphics.endFill();
            });

            detailContainer.addChild(startButton);
        }
    }
}
}