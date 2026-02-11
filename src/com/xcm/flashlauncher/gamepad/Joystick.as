package com.xcm.flashlauncher.gamepad {
    import flash.events.TouchEvent;
    import flash.ui.Keyboard;

    public class Joystick extends ButtonBase {

        //摇杆半径
        private var _knobRadius:Number;
        //外圈半径
        private var _outerRadius:Number;

        public var knobRatio:Number = 0.3;
        public var outerRatio:Number = 1.5;
        public var deadZoneX:Number = 0.2;
        public var deadZoneY:Number = 0.2;

        public var keyCodeUp:uint = Keyboard.W;
        public var keyCodeDown:uint = Keyboard.S;
        public var keyCodeLeft:uint = Keyboard.A;
        public var keyCodeRight:uint = Keyboard.D;

        // 方向常量
        public static const DIRECTION_NONE:uint = 0;
        public static const DIRECTION_UP:uint = 0x1;
        public static const DIRECTION_DOWN:uint = 0x2;
        public static const DIRECTION_LEFT:uint = 0x4;
        public static const DIRECTION_RIGHT:uint = 0x8;
        public static const DIRECTION_UP_LEFT:uint = DIRECTION_UP | DIRECTION_LEFT;
        public static const DIRECTION_UP_RIGHT:uint = DIRECTION_UP | DIRECTION_RIGHT;
        public static const DIRECTION_DOWN_LEFT:uint = DIRECTION_DOWN | DIRECTION_LEFT;
        public static const DIRECTION_DOWN_RIGHT:uint = DIRECTION_DOWN | DIRECTION_RIGHT;

        private var _currentDirection:uint = DIRECTION_NONE;

        public function Joystick(posX:Number, posY:Number, radius:Number, seat:uint = 1) {
            super();
            x = posX;
            y = posY;
            _touchRadius = radius;
            _knobRadius = radius * knobRatio;
            _outerRadius = radius * outerRatio;
            keyCode = seat;
            refreshLayout();
        }

        override public function refreshLayout():void {
            alpha = PadTheme.GLOBAL_ALPHA;
            drawJoystick();
            super.refreshLayout();
        }

        override protected function onTouchStart(evt:TouchEvent):void {
            var touchX:Number = evt.stageX - x;
            var touchY:Number = evt.stageY - y;

            // 在外圈范围内都可以开始触摸
            if (Math.sqrt(touchX * touchX + touchY * touchY) < _outerRadius) {

                stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
                stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd);

                touchedPoints[evt.touchPointID] = {x: touchX, y: touchY, isPressed: true};
                updateKnobPosition(touchX, touchY);
            }
        }

        override protected function onTouchEnd(evt:TouchEvent):void {
            var pid:uint = evt.touchPointID;
            if (touchedPoints[pid] && touchedPoints[pid].isPressed) {

                stage.removeEventListener(TouchEvent.TOUCH_MOVE, onTouchMove);
                stage.removeEventListener(TouchEvent.TOUCH_END, onTouchEnd);

                delete touchedPoints[pid];
                resetKnob();
            }
        }

        override protected function onTouchMove(evt:TouchEvent):void {
            var pid:uint = evt.touchPointID;
            if (touchedPoints[pid] && touchedPoints[pid].isPressed) {
                var touchX:Number = evt.stageX - x;
                var touchY:Number = evt.stageY - y;
                touchedPoints[pid].x = touchX;
                touchedPoints[pid].y = touchY;
                updateKnobPosition(touchX, touchY);
            }
        }

        private function getKeyCodeByDirection(dir:uint):uint {
            switch (dir) {
                case DIRECTION_UP:
                    return keyCodeUp;
                case DIRECTION_DOWN:
                    return keyCodeDown;
                case DIRECTION_LEFT:
                    return keyCodeLeft;
                case DIRECTION_RIGHT:
                    return keyCodeRight;
                default:
                    return 0;
            }
        }

        private function updateKnobPosition(touchX:Number, touchY:Number):void {
            var deltaX:Number = touchX;
            var deltaY:Number = touchY;

            var distance:Number = Math.sqrt(deltaX * deltaX + deltaY * deltaY);

            // 限制摇杆在背景圆内
            var maxDistance:Number = _touchRadius - _knobRadius;
            if (distance > maxDistance) {
                var angle:Number = Math.atan2(deltaY, deltaX);
                deltaX = Math.cos(angle) * maxDistance;
                deltaY = Math.sin(angle) * maxDistance;
            }
            drawJoystick(deltaX, deltaY);
            updateDirection(deltaX, deltaY);
        }

        private function drawJoystick(knobX:Number = 0, knobY:Number = 0):void {
            graphics.clear();
            // 绘制外圈
            graphics.beginFill(0x000000, 0.1);
            graphics.drawCircle(0, 0, _outerRadius);
            graphics.endFill();
            // 绘制背景圆形
            graphics.beginFill(0x333333);
            graphics.lineStyle(2, PadTheme.BUTTON_BORDER_COLOR);
            graphics.drawCircle(0, 0, _touchRadius);
            graphics.endFill();
            // 绘制摇杆小圆
            graphics.beginFill(0x666666);
            graphics.lineStyle(2, PadTheme.BUTTON_BORDER_COLOR);
            graphics.drawCircle(knobX, knobY, _knobRadius);
            graphics.endFill();
        }

        private function resetKnob():void {
            drawJoystick();
            handleDirectionChange(_currentDirection, DIRECTION_NONE);
        }

        private function updateDirection(posX:Number, posY:Number):void {
            var thresholdX:Number = _touchRadius * deadZoneX;
            var thresholdY:Number = _touchRadius * deadZoneY;
            var newDirection:uint = DIRECTION_NONE;
            if (posX > thresholdX)  newDirection |= DIRECTION_RIGHT;
            if (posX < -thresholdX) newDirection |= DIRECTION_LEFT;
            if (posY > thresholdY)  newDirection |= DIRECTION_DOWN;
            if (posY < -thresholdY) newDirection |= DIRECTION_UP;
            handleDirectionChange(_currentDirection, newDirection);
        }

        protected function handleDirectionChange(oldDir:uint, newDir:uint):void {
            if (oldDir == newDir) return;
            var change:uint = oldDir ^ newDir;
            for (var i:uint = 1; i <= 8; i <<= 1) {
                if (Boolean(change & i)) {
                    if (Boolean(newDir & i)) {
                        dispatchEvent(new GamePadEvent(GamePadEvent.BUTTON_DOWN, getKeyCodeByDirection(i)));
                    } else {
                        dispatchEvent(new GamePadEvent(GamePadEvent.BUTTON_UP, getKeyCodeByDirection(i)));
                    }
                }
            }
            dispatchEvent(new GamePadEvent(GamePadEvent.AXIS_CHANGED));
            _currentDirection = newDir;
        }

        public function get currentDirection():uint {
            return _currentDirection;
        }

        override public function set touchRadius(value:Number):void {
            _touchRadius = value;
            _knobRadius = value * knobRatio;
            _outerRadius = value * outerRatio;
            refreshLayout();
        }

        public function get isPressUp():Boolean {
            return _currentDirection & DIRECTION_UP;
        }

        public function get isPressDown():Boolean {
            return _currentDirection & DIRECTION_DOWN;
        }

        public function get isPressLeft():Boolean {
            return _currentDirection & DIRECTION_LEFT;
        }

        public function get isPressRight():Boolean {
            return _currentDirection & DIRECTION_RIGHT;
        }

        override public function set keyCode(value:uint):void {
            _keyCode = value;
            if (value == 1) {
                keyCodeUp    = Keyboard.W;
                keyCodeDown  = Keyboard.S;
                keyCodeLeft  = Keyboard.A;
                keyCodeRight = Keyboard.D;
            } else if (value == 2) {
                keyCodeUp    = Keyboard.UP;
                keyCodeDown  = Keyboard.DOWN;
                keyCodeLeft  = Keyboard.LEFT;
                keyCodeRight = Keyboard.RIGHT;
            }
        }
    }
}
