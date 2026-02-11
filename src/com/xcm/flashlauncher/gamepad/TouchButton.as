package com.xcm.flashlauncher.gamepad {
import com.xcm.flashlauncher.util.KeyboardUtil;

import flash.events.TouchEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.utils.clearInterval;
    import flash.utils.clearTimeout;
    import flash.utils.setInterval;
    import flash.utils.setTimeout;

    /**
     * 触摸按钮类，支持多点触摸和拖动检测
     */
    public class TouchButton extends ButtonBase {
        private var _label:String = "";
        private var _textField:TextField;
        private var _longPressTimeout:uint = 0;
        private var _longPressInterval:uint = 0;

        public function TouchButton(posX:Number = 0, poxY:Number = 0, radius:Number = 35, keyCode:int = 0) {
            super();
            x = posX;
            y = poxY;
            _touchRadius = radius;
            _keyCode = keyCode;
            _label = KeyboardUtil.getKeyNameByKeyCode(keyCode);
            refreshLayout();
        }

        override protected function onTouchStart(evt:TouchEvent):void {
            var pid:int = evt.touchPointID;
            var touchX:Number = evt.stageX - x;
            var touchY:Number = evt.stageY - y;
            if (Math.sqrt(touchX * touchX + touchY * touchY) < _touchRadius) {

                stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
                stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);

                touchedPoints[pid] = {x: touchX, y: touchY, isPressed: true};
                drawCircle(PadTheme.BUTTON_DOWN_COLOR);
                dispatchEvent(new GamePadEvent(GamePadEvent.BUTTON_DOWN, keyCode));

                if (GamepadConfig.SIMULATE_LONG_PRESS) {
                    if (_longPressTimeout) clearTimeout(_longPressTimeout);
                    if (_longPressInterval) clearInterval(_longPressInterval);
                    _longPressTimeout = setTimeout(checkLongPress, 500);
                }
            }
        }

        override protected function onTouchEnd(evt:TouchEvent):void {
            var pid:uint = evt.touchPointID;
            if (touchedPoints[pid] && touchedPoints[pid].isPressed) {

                stage.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
                stage.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);

                delete touchedPoints[pid];
                drawCircle(PadTheme.BUTTON_UP_COLOR);
                dispatchEvent(new GamePadEvent(GamePadEvent.BUTTON_UP, keyCode));

                if (GamepadConfig.SIMULATE_LONG_PRESS) {
                    if (_longPressTimeout) clearTimeout(_longPressTimeout);
                    if (_longPressInterval) clearInterval(_longPressInterval);
                }
            }
        }

        override protected function onTouchMove(evt:TouchEvent):void {
            var pid:uint = evt.touchPointID;
            if (touchedPoints[pid] && touchedPoints[pid].isPressed) {
                var touchX:Number = evt.stageX - x;
                var touchY:Number = evt.stageY - y;
                touchedPoints[pid].x = touchX;
                touchedPoints[pid].y = touchY;
            }
        }

        override public function refreshLayout():void {
            alpha = PadTheme.GLOBAL_ALPHA;
            drawCircle(PadTheme.BUTTON_UP_COLOR);
            updateTextField();
            super.refreshLayout();
        }

        /**
         * 根据颜色绘制外观
         * @param color
         */
        private function drawCircle(color:uint):void {
            graphics.clear();
            graphics.beginFill(color);
            graphics.lineStyle(2, PadTheme.BUTTON_BORDER_COLOR);
            graphics.drawCircle(0, 0, _touchRadius);
            graphics.endFill();
        }

        /**
         * 更新标签文本
         */
        private function updateTextField():void {
            if (!_textField) {
                _textField = new TextField();
                var tf:TextFormat = new TextFormat("Microsoft YaHei", 20, 0xFFFFFF, true);
                _textField.defaultTextFormat = tf;
                _textField.selectable = false;
                _textField.mouseEnabled = false;
            }
            _textField.text = _label;
            _textField.x = -_textField.textWidth >> 1;
            _textField.y = -_textField.textHeight >> 1;
            _textField.width = _textField.textWidth;
            _textField.height = _textField.textHeight;
            _textField.autoSize = TextFieldAutoSize.CENTER;

            addChild(_textField);
        }

        public function get label():String {
            return _label;
        }

        public function set label(value:String):void {
            _label = value;
            updateTextField();
        }

        /**
         * 检测是否进入长按周期
         */
        private function checkLongPress():void {
            if (isPressed) {
                _longPressInterval = setInterval(simulateEvent, 100);
            } else {
                clearTimeout(_longPressTimeout);
                _longPressTimeout = 0;
            }
        }

        /**
         * 模拟长按事件函数
         */
        private function simulateEvent():void {
            if (isPressed) {
                dispatchEvent(new GamePadEvent(GamePadEvent.BUTTON_DOWN, keyCode));
            } else {
                clearInterval(_longPressInterval);
                _longPressInterval = 0;
            }
        }

    }
}