package flash.display {
import flash.net.URLRequest;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

public class XCMLoader extends Loader {
    public function XCMLoader() {
        super();
    }

    override public function loadBytes(bytes:ByteArray, context:LoaderContext = null):void {
        if (!context) context = new LoaderContext(false, ApplicationDomain.currentDomain);
        context.allowCodeImport = true;
        context.allowLoadBytesCodeExecution = true;
        super.loadBytes(bytes, context);
    }

    override public function load(request:URLRequest, context:LoaderContext = null):void {
        if (!context) context = new LoaderContext(false, ApplicationDomain.currentDomain);
        context.allowCodeImport = true;
        context.allowLoadBytesCodeExecution = true;
        super.load(request, context);
    }
}
}
