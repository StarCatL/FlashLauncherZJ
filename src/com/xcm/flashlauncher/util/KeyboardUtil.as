package com.xcm.flashlauncher.util {
import flash.ui.Keyboard;
import flash.utils.describeType;

public final class KeyboardUtil extends UtilBase {

    public function KeyboardUtil() {
        super();
    }

    public static function getKeyNameByKeyCode(param1:uint):String {
        var _loc3_:String = "unknown";
        for each(var _loc2_ in describeType(Keyboard).constant) {
            if (_loc2_.@type == "uint" && Keyboard[_loc2_.@name] == param1) {
                _loc3_ = _loc2_.@name;
                break;
            }
        }
        if (_loc3_.indexOf("NUMPAD_") == 0) {
            _loc3_ = "N(" + _loc3_.substring(7) + ")";
        }
        return _loc3_.replace("MULTIPLY", "*").replace("DIVIDE", "/").replace("SUBTRACT", "-").replace("ADD", "+").replace("DECIMAL", ".");
    }
}
}
