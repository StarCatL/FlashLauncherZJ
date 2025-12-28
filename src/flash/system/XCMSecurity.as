package flash.system {

public class XCMSecurity {

    public function XCMSecurity() {
        super();
    }

    public static function allowDomain(...rest):void {
    }

    public static function allowInsecureDomain(...rest):void {
    }

    public static function loadPolicyFile(url:String):void {
        Security.loadPolicyFile(url);
    }

    public static function get exactSettings():Boolean {
        return Security.exactSettings;
    }

    public static function set exactSettings(value:Boolean):void {
        Security.exactSettings = value;
    }

    public static function get disableAVM1Loading():Boolean {
        return Security.disableAVM1Loading;
    }

    public static function set disableAVM1Loading(value:Boolean):void {
        Security.disableAVM1Loading = value;
    }

    public static function showSettings(panel:String = "default"):void {
        Security.showSettings(panel);
    }

    public static function get sandboxType():String {
        return Security.sandboxType;
    }

    public static function get pageDomain():String {
        return Security.pageDomain;
    }

    public static const REMOTE:String = Security.REMOTE;
    public static const LOCAL_WITH_FILE:String = Security.LOCAL_WITH_FILE;
    public static const LOCAL_WITH_NETWORK:String = Security.LOCAL_WITH_NETWORK;
    public static const LOCAL_TRUSTED:String = Security.LOCAL_TRUSTED;
    public static const APPLICATION:String = Security.APPLICATION;

    public static function isLocalSandbox():Boolean {
        var type:String = Security.sandboxType;
        return type == Security.LOCAL_WITH_FILE ||
                type == Security.LOCAL_WITH_NETWORK ||
                type == Security.LOCAL_TRUSTED;
    }

    public static function isRemoteSandbox():Boolean {
        return Security.sandboxType == Security.REMOTE;
    }

    public static function safeAllowDomain(...domains):void {
        var validDomains:Array = [];
        for each (var domain:String in domains) {
            if (domain != "*") {
                validDomains.push(domain);
            } else {
                trace("不允许使用通配符 *");
            }
        }

        if (validDomains.length > 0) {
            Security.allowDomain.apply(null, validDomains);
        }
    }

    public static function getSecurityInfo():String {
        return "沙箱类型: " + Security.sandboxType +
                "\n页面域: " + Security.pageDomain +
                "\n精确设置: " + Security.exactSettings;
    }
}
}