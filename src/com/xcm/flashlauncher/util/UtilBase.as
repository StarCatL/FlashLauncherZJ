package com.xcm.flashlauncher.util {
import flash.display.DisplayObjectContainer;
import flash.utils.ByteArray;
import flash.utils.Dictionary;

public class UtilBase {

    public function UtilBase() {
        super();
        throw new Error("util class is not instantiable");
    }

    public static function length(param1:*):int {
        var _loc3_:* = undefined;
        if (!param1) {
            return 0;
        }
        if (param1 is Array || param1 is String) {
            return param1.length;
        }
        if (param1 is DisplayObjectContainer) {
            return param1.numChildren;
        }
        var _loc2_:int = 0;
        _loc2_ = 0;
        try {
            for (_loc3_ in param1) {
                _loc2_++;
            }
            return _loc2_;
        } catch (e:Error) {
            var _loc5_:int = 0;
        }
        return _loc5_;
    }

    public static function keys(param1:*):Array {
        var _loc3_:* = undefined;
        var _loc2_:Array = [];
        try {
            for (_loc3_ in param1) {
                _loc2_.push(_loc3_);
            }
            return _loc2_;
        } catch (e:Error) {
            var _loc5_:* = [];
        }
        return _loc5_;
    }

    public static function values(param1:*):Array {
        var _loc3_:* = undefined;
        var _loc2_:Array = [];
        try {
            for (_loc3_ in param1) {
                _loc2_.push(param1[_loc3_]);
            }
            return _loc2_;
        } catch (e:Error) {
            var _loc5_:* = [];
        }
        return _loc5_;
    }

    public static function getKeyByValue(param1:*, param2:*):String {
        var _loc3_:* = undefined;
        try {
            for (_loc3_ in param1) {
                if (param1[_loc3_] === param2) {
                    return _loc3_;
                }
            }
            return "";
        } catch (e:Error) {
            var _loc6_:String = "";
        }
        return _loc6_;
    }

    public static function transObj2Dict(param1:Object):Dictionary {
        var _loc2_:Dictionary = new Dictionary();
        for (var _loc3_ in param1) {
            _loc2_[_loc3_] = param1[_loc3_];
        }
        return _loc2_;
    }

    public static function transDict2Obj(param1:Dictionary):Object {
        var _loc2_:Object = {};
        for (var _loc3_ in param1) {
            _loc2_[_loc3_] = param1[_loc3_];
        }
        return _loc2_;
    }

    public static function copyObject(param1:Object, param2:Object, param3:Boolean = true):void {
        if (param3) {
            for (var _loc5_ in param2) {
                delete param2[_loc5_];
            }
        }
        for (var _loc4_ in param1) {
            param2[_loc4_] = param1[_loc4_];
        }
    }

    public static function clone(param1:Object, param2:Boolean = true):Object {
        var _loc4_:ByteArray = null;
        var _loc5_:Object = null;
        if (param2) {
            _loc4_ = new ByteArray();
            _loc4_.writeObject(param1);
            _loc4_.position = 0;
            return _loc4_.readObject();
        }
        _loc5_ = {};
        for (var _loc3_ in param1) {
            _loc5_[_loc3_] = param1[_loc3_];
        }
        return _loc5_;
    }

    public static function equal(param1:Object, param2:Object):Boolean {
        var _loc4_:ByteArray = new ByteArray();
        var _loc3_:ByteArray = new ByteArray();
        _loc3_.writeObject(param1);
        _loc3_.position = 0;
        _loc4_.writeObject(param2);
        _loc4_.position = 0;
        if (_loc3_.length == _loc4_.length) {
            while (_loc3_.bytesAvailable) {
                if (_loc3_.readByte() != _loc4_.readByte()) {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    public static function getObjectID(param1:Object):String {
        var _loc2_:Array = [];
        for (var _loc3_ in param1) {
            _loc2_.push(_loc3_ + ":" + param1[_loc3_]);
        }
        _loc2_.sort();
        return _loc2_.join(",");
    }

    public static function clearAll(param1:Object):void {
        for each(var _loc2_ in keys(param1)) {
            delete param1[_loc2_];
        }
    }

    public static function extendClass(...rest):void {
    }
}
}

