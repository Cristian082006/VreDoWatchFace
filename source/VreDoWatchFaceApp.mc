using Toybox.Application;
using Toybox.WatchUi;

class VreDoWatchFaceApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [ new VreDoWatchFaceView(), new VreDoWatchFaceDelegate() ];
    }
}

class VreDoWatchFaceDelegate extends WatchUi.WatchFaceDelegate {
    function initialize() {
        WatchFaceDelegate.initialize();
    }
}
