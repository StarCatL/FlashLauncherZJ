package com.cheat {

import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.ui.Keyboard;

public class CheatPanel extends Sprite {

    private static var _instance:CheatPanel = null;

    public static function getInstance():CheatPanel {
        if (_instance == null) {
            _instance = new CheatPanel();
            _instance.initialize();
        }
        return _instance;
    }

    public static function log(msg:String):void {
        getInstance().internalAppendLog(msg);
    }

    public static function show():void {
        var instance:CheatPanel = getInstance();
        instance.visible = true;
        if (instance.stage && !instance.parent) {
            instance.stage.addChild(instance);
        }
    }

    public static function hide():void {
        getInstance().visible = false;
    }

    public static function destroy():void {
        if (_instance != null) {
            _instance.internalDestroy();
            _instance = null;
        }
    }

    public static const PANEL_WIDTH:int = 290;
    private static const COLLAPSED_HEIGHT:int = 40;

    private var _bg:Sprite;
    private var _title:TextField;
    private var _btnToggle:Sprite;
    private var _toggleLabel:TextField;
    private var _expanded:Boolean = true;
    private var _dragging:Boolean = false;
    private var _logControl:CheatLogControl;
    private var _preventDeactivateEnabled:Boolean = true;
    private var _buttonControls:Array;
    private var _initialized:Boolean = false;

    /**
     * 构造函数 必须是public（AS3限制）
     * 不要直接使用new CheatPanel()，使用getInstance()
     */
    public function CheatPanel() {
        super();
    }

    /**
     * 初始化方法
     */
    private function initialize():void {
        if (!_initialized) {
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            _initialized = true;
        }
    }

    /**
     * 内部日志方法
     */
    private function internalAppendLog(msg:String):void {
        if (_logControl) {
            _logControl.appendLog(msg);
        }
    }

    /**
     * 内部销毁方法
     */
    private function internalDestroy():void {
        if (stage) {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onDragEnd);
        }

        removeEventListener(Event.ENTER_FRAME, onEnterFrame);

        if (_bg) {
            _bg.removeEventListener(MouseEvent.MOUSE_DOWN, onDragStart);
        }

        if (_title) {
            _title.removeEventListener(MouseEvent.MOUSE_DOWN, onDragStart);
            _title.removeEventListener(MouseEvent.MOUSE_UP, onDragEnd);
        }

        if (_btnToggle) {
            _btnToggle.removeEventListener(MouseEvent.CLICK, onToggleClick);
        }

        // 清理显示对象
        while (numChildren > 0) {
            removeChildAt(0);
        }
    }

    // UI相关方法
    private function onAddedToStage(e:Event):void {
        removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        this.x = 0;
        this.y = 0;
        buildUI();
        layoutPanel();
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
        stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
    }

    private function buildUI():void {
        var tfTitle:TextFormat = new TextFormat("宋体", 14, 16776960, true);
        _buttonControls = [];
        _bg = new Sprite();
        addChild(_bg);
        _bg.addEventListener(MouseEvent.MOUSE_DOWN, onDragStart);
        stage.addEventListener(MouseEvent.MOUSE_UP, onDragEnd);

        _title = new TextField();
        _title.defaultTextFormat = tfTitle;
        _title.width = PANEL_WIDTH - 60;
        _title.height = 20;
        _title.x = 5;
        _title.y = 2;
        _title.selectable = false;
        _title.mouseEnabled = true;
        _title.text = "脚本执行器 (F5显示/隐藏)";
        addChild(_title);

        _title.addEventListener(MouseEvent.MOUSE_DOWN, onDragStart);
        _title.addEventListener(MouseEvent.MOUSE_UP, onDragEnd);

        _btnToggle = new Sprite();
        _btnToggle.buttonMode = true;
        _btnToggle.mouseChildren = false;
        _btnToggle.addEventListener(MouseEvent.CLICK, onToggleClick);
        _toggleLabel = new TextField();
        _toggleLabel.defaultTextFormat = new TextFormat("宋体", 12, 16777215, true);
        _toggleLabel.width = 40;
        _toggleLabel.height = 20;
        _toggleLabel.y = -2;
        _toggleLabel.selectable = false;
        _btnToggle.addChild(_toggleLabel);
        addChild(_btnToggle);
        updateToggleLabel();

        var cheatFrameRateToggleControl:CheatFrameRateToggleControl = new CheatFrameRateToggleControl();
        addChild(cheatFrameRateToggleControl);
        _buttonControls.push(cheatFrameRateToggleControl);

        var codeExec:CheatCodeExecutorControl = new CheatCodeExecutorControl();
        addChild(codeExec);
        _buttonControls.push(codeExec);

        _logControl = new CheatLogControl();
        addChild(_logControl);
    }

    private function layoutPanel():void {
        if (stage) {
            var h:int = _expanded ? stage.stageHeight : COLLAPSED_HEIGHT;
        } else {
            h = _expanded ? 500 : COLLAPSED_HEIGHT;
        }

        _bg.graphics.clear();
        _bg.graphics.beginFill(0, 0.7);
        _bg.graphics.drawRect(0, 0, PANEL_WIDTH, h);
        _bg.graphics.endFill();

        _title.width = PANEL_WIDTH - 40;
        _btnToggle.x = PANEL_WIDTH - 45;
        _btnToggle.y = 5;

        if (!_expanded) {
            setChildrenVisible(false);
            return;
        }

        setChildrenVisible(true);
        var margin:int = 5;
        var y:int = 25;
        var contentBottom:int = h - margin;
        var contentHeight:int = contentBottom - y;
        var buttonsTotalHeight:int = 0;

        if (_buttonControls) {
            var i:int = 0;
            while (i < _buttonControls.length) {
                var ctrl:Sprite = _buttonControls[i] as Sprite;
                if (ctrl) {
                    buttonsTotalHeight += ctrl.height + 5;
                }
                i++;
            }
        }

        var desiredInfoFull:int = 160;
        var infoHeight:int = 0;
        var logMinHeight:int = 80;
        var logHeight:int = contentHeight - infoHeight - buttonsTotalHeight - margin;

        if (logHeight < logMinHeight) {
            logHeight = logMinHeight;
            var minInfo:int = 20;
            var newInfoFull:int = contentHeight - buttonsTotalHeight - margin - logHeight;
            if (newInfoFull < minInfo) {
                newInfoFull = minInfo;
            }
        }

        if (_buttonControls) {
            i = 0;
            while (i < _buttonControls.length) {
                ctrl = _buttonControls[i] as Sprite;
                if (ctrl) {
                    ctrl.x = margin;
                    ctrl.y = y;
                    y += ctrl.height + 5;
                }
                i++;
            }
        }

        if (_logControl) {
            _logControl.x = margin;
            _logControl.y = y;
            _logControl.setSize(PANEL_WIDTH - 10, logHeight);
            y += logHeight + 5;
        }
    }

    private function setChildrenVisible(v:Boolean):void {
        if (_logControl) {
            _logControl.visible = v;
        }
        if (_buttonControls) {
            var i:int = 0;
            while (i < _buttonControls.length) {
                var ctrl:Sprite = _buttonControls[i] as Sprite;
                if (ctrl) {
                    ctrl.visible = v;
                }
                i++;
            }
        }
    }

    private function updateToggleLabel():void {
        if (_toggleLabel) {
            _toggleLabel.text = _expanded ? "收起" : "展开";
        }
    }

    private function onToggleClick(e:MouseEvent):void {
        _expanded = !_expanded;
        updateToggleLabel();
        layoutPanel();
    }

    private function onEnterFrame(e:Event):void {
        if (stage && parent == stage) {
            var topIndex:int = stage.numChildren - 1;
            if (stage.getChildIndex(this) != topIndex) {
                stage.setChildIndex(this, topIndex);
            }
        }
    }

    private function onDragStart(e:MouseEvent):void {
        startDrag();
        _dragging = true;
    }

    private function onDragEnd(e:MouseEvent):void {
        if (_dragging) {
            stopDrag();
            _dragging = false;
        }
    }

    private function onKeyDown(e:KeyboardEvent):void {
        if (e.keyCode == Keyboard.F5) {
            this.visible = !this.visible;
        }
    }
}
}