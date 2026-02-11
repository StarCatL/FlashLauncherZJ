package com.xcm.flashlauncher.gamepad {
    import flash.events.Event;

    public class GamePadEvent extends Event {

        public static const BUTTON_DOWN:String = "buttonDown";
        public static const BUTTON_UP:String = "buttonUp";
        public static const BUTTON_TAP:String = "buttonTap";
        public static const AXIS_CHANGED:String = "axisChanged";

        public static const EDIT_SELECT:String = "editSelect";

        public var keyCode:int;
        public function GamePadEvent(type:String, key:int = 0) {
            super(type);
            keyCode = key;
        }
    }
}
