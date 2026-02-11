package com.xcm.flashlauncher.gamepad {
    import flash.display.Stage;
    import flash.events.KeyboardEvent;
    import flash.utils.Dictionary;

    /**
     * KeyMapper<br>
     * 轻松将游戏键盘事件映射为键盘事件
     * 支持自动双击
     */
    public class KeyMapper {

        public static var isMapping:Boolean = false;

        private static var _stage:Stage;

        private static var _doubleKey:Dictionary = new Dictionary();

        private static var _btnMap:Dictionary = new Dictionary();

        private static var _stickMap:Dictionary = new Dictionary();

        public static function init(stage:Stage):void {
            _stage = stage;
            isMapping = true;
        }

        public static function addDoubleKey(...args):void {
            for each(var arg:* in args) {
                _doubleKey[arg] = true;
            }
        }

        public static function removeDoubleKey(...args):void {
            for each(var arg:* in args) {
                _doubleKey[arg] = false;
            }
        }

        /**
         * 直接分发一个GamePadEvent<br>
         * 用于手动重放事件
         * @param evt GamePadEvent
         */
        public static function mapEvent(evt:GamePadEvent):void {
            if (!_stage) return;
            _stage.dispatchEvent(transEvent(evt));
        }

        public static function map(control:ButtonBase, keyCode:int = 0):void {
            if (control is TouchButton) mapButton(control as TouchButton, keyCode);
            else if (control is Joystick) mapJoystick(control as Joystick, keyCode);
        }

        public static function mapButton(btn:TouchButton, keycode:int = 0):void {
            if (keycode > 0) btn.keyCode = keycode;
            _btnMap[btn] = btn.keyCode;
            btn.addEventListener(GamePadEvent.BUTTON_DOWN, handleBtn);
            btn.addEventListener(GamePadEvent.BUTTON_UP, handleBtn);
        }

        public static function mapJoystick(stick:Joystick, seat:int = 0):void {
            if (seat > 0) stick.keyCode = seat;
            _stickMap[stick] = seat;
            stick.addEventListener(GamePadEvent.BUTTON_DOWN, handleJoystick);
            stick.addEventListener(GamePadEvent.BUTTON_UP, handleJoystick);
        }

        private static function handleBtn(evt:GamePadEvent):void {
            var btn:TouchButton = evt.target as TouchButton;
            if (!isMapping || !_stage || !hasMapBtn(btn)) return;
            _stage.dispatchEvent(transEvent(evt));
            if (_doubleKey[evt.keyCode] && evt.type == GamePadEvent.BUTTON_DOWN) {
                _stage.dispatchEvent(transEvent(new GamePadEvent(GamePadEvent.BUTTON_UP, evt.keyCode)));
                _stage.dispatchEvent(transEvent(new GamePadEvent(GamePadEvent.BUTTON_DOWN, evt.keyCode)));
            }
        }

        private static function handleJoystick(evt:GamePadEvent):void {
            var stick:Joystick = evt.target as Joystick;
            if (!isMapping || !_stage || !hasMapJoystick(stick)) return;
            _stage.dispatchEvent(transEvent(evt));
            if (_doubleKey[evt.keyCode] && evt.type == GamePadEvent.BUTTON_DOWN) {
                _stage.dispatchEvent(transEvent(new GamePadEvent(GamePadEvent.BUTTON_UP, evt.keyCode)));
                _stage.dispatchEvent(transEvent(new GamePadEvent(GamePadEvent.BUTTON_DOWN, evt.keyCode)));
            }
        }

        private static function transEvent(evt:GamePadEvent):KeyboardEvent {
            var keyEvt:KeyboardEvent;
            if (evt.type == GamePadEvent.BUTTON_DOWN) {
                keyEvt = new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, evt.keyCode);
            } else if (evt.type == GamePadEvent.BUTTON_UP) {
                keyEvt = new KeyboardEvent(KeyboardEvent.KEY_UP, true, false, 0, evt.keyCode);
            }
            return keyEvt;
        }

        public static function hasMap(btn:ButtonBase):Boolean {
            if (btn is TouchButton) {
                return hasMapBtn(btn as TouchButton);
            } else if (btn is Joystick) {
                return hasMapJoystick(btn as Joystick);
            } else {
                return false;
            }
        }

        public static function hasMapBtn(btn:TouchButton):Boolean {
            return btn && _btnMap[btn] != null;
        }

        public static function hasMapJoystick(stick:Joystick):Boolean {
            return stick && _stickMap[stick] != null;
        }

        public static function unmap(btn:ButtonBase):void {
            if (btn is TouchButton) {
                unmapBtn(btn as TouchButton);
            } else if (btn is Joystick) {
                unmapJoystick(btn as Joystick);
            }
        }

        public static function unmapBtn(btn:TouchButton):void {
            delete _btnMap[btn];
        }

        public static function unmapJoystick(stick:Joystick):void {
            delete _stickMap[stick];
        }

        public static function unmapAll():void {
            unmapAllBtn();
            unmapAllStick();
        }

        public static function unmapAllBtn():void {
            for (var btn:TouchButton in _btnMap) delete _btnMap[btn];
        }

        public static function unmapAllStick():void {
            for (var stick:Joystick in _stickMap) delete _stickMap[stick];
        }
    }
}
