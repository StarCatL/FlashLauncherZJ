package com.xcm.flashlauncher.gamepad {

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Rectangle;
import flash.system.Capabilities;

public class ButtonBase extends Sprite {

    protected var _enable:Boolean = false;

    protected var _editing:Boolean = false;

    protected var _highlighted:Boolean = false;

    protected var _touchRadius:Number;

    protected var _keyCode:uint;

    protected var touchedPoints:Object = {};// 使用 touchPointID 作为键

    public function ButtonBase() {
        super();
        enable = true;
    }

    private function handleMouse(evt:MouseEvent):void {
        if (evt.type == MouseEvent.MOUSE_DOWN) {
            dispatchEvent(new TouchEvent(TouchEvent.TOUCH_BEGIN, true, false, 1, true, evt.localX, evt.localY, 1, 1));
        } else if (evt.type == MouseEvent.MOUSE_UP) {
            dispatchEvent(new TouchEvent(TouchEvent.TOUCH_END, true, false, 1, true, evt.localX, evt.localY, 1, 1));
        } else if (evt.type == MouseEvent.MOUSE_MOVE) {
            dispatchEvent(new TouchEvent(TouchEvent.TOUCH_MOVE, true, false, 1, true, evt.localX, evt.localY, 1, 1));
        } else if (evt.type == MouseEvent.ROLL_OUT) {
            dispatchEvent(new TouchEvent(TouchEvent.TOUCH_ROLL_OUT, true, false, 1, true, evt.localX, evt.localY, 1, 1));
        } else if (evt.type == MouseEvent.CLICK) {
            dispatchEvent(new TouchEvent(TouchEvent.TOUCH_TAP, true, false, 1, true, evt.localX, evt.localY, 1, 1));
        }
    }

    public function get touchRadius():Number {
        return _touchRadius;
    }

    public function set touchRadius(value:Number):void {
        _touchRadius = value;
        refreshLayout();
    }

    public function get keyCode():uint {
        return _keyCode;
    }

    public function set keyCode(value:uint):void {
        _keyCode = value;
    }

    public function get enable():Boolean {
        return _enable;
    }

    public function set enable(value:Boolean):void {
        if (value == _enable) return;
        if (_editing) editing = false;
        _enable = value;
        if (value) {
            addEventListener(TouchEvent.TOUCH_BEGIN, onTouchStart);
            addEventListener(TouchEvent.TOUCH_TAP, onTouchTap);
            addEventListener(TouchEvent.TOUCH_ROLL_OUT, onTouchRollOut);

            if (isDesktop() && GamepadConfig.TRANS_MOUSE_TO_TOUCH) {
                addEventListener(MouseEvent.MOUSE_DOWN, handleMouse);
                addEventListener(MouseEvent.MOUSE_UP, handleMouse);
                addEventListener(MouseEvent.MOUSE_MOVE, handleMouse);
                addEventListener(MouseEvent.CLICK, handleMouse);
            }
        } else {
            removeEventListener(TouchEvent.TOUCH_BEGIN, onTouchStart);
            removeEventListener(TouchEvent.TOUCH_TAP, onTouchTap);
            removeEventListener(TouchEvent.TOUCH_ROLL_OUT, onTouchRollOut);
        }
    }

    public function get editing():Boolean {
        return _editing;
    }

    public function set editing(value:Boolean):void {
        if (_editing == value) return;
        if (_enable) enable = false;
        _editing = value;
        if (value) {
            addEventListener(TouchEvent.TOUCH_BEGIN, handleEditTouch);
            addEventListener(TouchEvent.TOUCH_END, handleEditTouch);
            addEventListener(TouchEvent.TOUCH_TAP, handleEditTouch);

            if (isDesktop() && GamepadConfig.TRANS_MOUSE_TO_TOUCH) {
                addEventListener(MouseEvent.MOUSE_DOWN, handleMouse);
                addEventListener(MouseEvent.MOUSE_UP, handleMouse);
                addEventListener(MouseEvent.CLICK, handleMouse);
            }
        } else {
            removeEventListener(TouchEvent.TOUCH_BEGIN, handleEditTouch);
            removeEventListener(TouchEvent.TOUCH_END, handleEditTouch);
            removeEventListener(TouchEvent.TOUCH_TAP, handleEditTouch);
        }
    }


    /**
     * 开始点击
     * @param evt
     */
    protected function onTouchStart(evt:TouchEvent):void {
        touchedPoints[evt.touchPointID] = {isPressed: true};
    }

    /**
     * 停止点击
     * @param evt
     */
    protected function onTouchEnd(evt:TouchEvent):void {
    }

    /**
     * 点击并移动
     * @param evt
     */
    protected function onTouchMove(evt:TouchEvent):void {
    }

    protected function onTouchTap(evt:TouchEvent):void {
        dispatchEvent(new GamePadEvent(GamePadEvent.BUTTON_TAP));
    }

    /**
     * 超过点击范围
     * @param evt
     */
    protected function onTouchRollOut(evt:TouchEvent):void {
        //Rollout事件同时也在判断移动
    }

    /**
     * 处理编辑模式事件
     * @param evt
     */
    protected function handleEditTouch(evt:TouchEvent):void {
        switch (evt.type) {
            case TouchEvent.TOUCH_BEGIN:
                startTouchDrag(evt.touchPointID);
                break;
            case TouchEvent.TOUCH_END:
                startTouchDrag(evt.touchPointID);
                break;
            case TouchEvent.TOUCH_TAP:
                dispatchEvent(new GamePadEvent(GamePadEvent.EDIT_SELECT));
                break;
        }
    }

    /**
     * 重绘外观
     */
    public function refreshLayout():void {
        if (highlighted) {
            var bounds:Rectangle = getBounds(this);
            graphics.lineStyle(2, 0xFF0000);
            graphics.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
        }
    }

    /**
     * 是否被按下
     */
    public function get isPressed():Boolean {
        for (var touchId:String in touchedPoints) {
            if (touchedPoints[touchId].isPressed) {
                return true;
            }
        }
        return false;
    }

    public function get highlighted():Boolean {
        return _highlighted;
    }

    public function set highlighted(value:Boolean):void {
        _highlighted = value;
        refreshLayout();
    }


    private function isDesktop():Boolean {
        var os:String = Capabilities.os.toLowerCase();
        return os.indexOf("win") > -1 ||
                os.indexOf("mac") > -1 ||
                os.indexOf("linux") > -1;
    }
}
}
