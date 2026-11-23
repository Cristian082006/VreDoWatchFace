using Toybox.Application;
using Toybox.Application.WatchFaceConfig;
using Toybox.WatchUi;

class VreDoWatchFaceApp extends Application.AppBase {
    var mEditMode = false;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state) {
        if (state != null && state[:launchedFromWatchFaceSettingsEditor] == true) {
            mEditMode = true;
        }
        var settings = WatchFaceConfig.getSettings(null);
        if (settings != null && settings.styleId != null) {
            Application.Properties.setValue("showDigitalTime", settings.styleId == 2);
        }
    }

    function getInitialView() {
        var view = new VreDoWatchFaceView(mEditMode);
        view.updateComplicationSettings(WatchFaceConfig.getSettings(null));
        return [ view, new VreDoWatchFaceDelegate(view) ];
    }

    function getSettingsView() {
        return [ new VreDoSettingsMenu(), new VreDoSettingsDelegate() ];
    }

    function onSettingsChanged() {
        WatchUi.requestUpdate();
    }
}

class VreDoWatchFaceDelegate extends WatchUi.WatchFaceDelegate {
    var mView;

    function initialize(view) {
        WatchFaceDelegate.initialize();
        mView = view;
    }

    function onWatchFaceConfigEdited(options) {
        var configId = options[:configId];
        if (configId == null) { return; }
        var settings = WatchFaceConfig.getSettings(configId);
        if (settings == null) { return; }
        mView.updateComplicationSettings(settings);
        var styleId = settings.styleId;
        if (styleId != null) {
            Application.Properties.setValue("showDigitalTime", styleId == 2);
        }
        WatchUi.requestUpdate();
    }

    function getComplicationDrawable(complication) {
        return mView.getComplicationDrawable(complication.uniqueIdentifier);
    }

    function onTap(clickEvent) {
        var coords = clickEvent.getCoordinates();
        var selected = mView.getTappedComplication(coords[0], coords[1]);
        if (selected != null) {
            // Use the watch face's own picker here. The native Garmin complication
            // picker only offers system complication IDs, so app-computed items
            // such as Active Calories cannot appear there.
            WatchUi.pushView(new VreDoComplicationMenu(selected - 1),
                new VreDoComplicationDelegate(selected - 1), WatchUi.SLIDE_RIGHT);
            return true;
        }
        return false;
    }
}

class VreDoSettingsMenu extends WatchUi.Menu {
    function initialize() {
        Menu.initialize();
        setTitle("VreDo — Setări");
        var digital = Application.Properties.getValue("showDigitalTime");
        addItem("Afișare: " + (digital == true ? "Digitală" : "Analogică"), :displayMode);
        var keys = ["complication1", "complication2", "complication3", "complication4", "complication5", "complication6"];
        var names = ["Sus stânga", "Sus centru", "Sus dreapta", "Jos stânga", "Jos centru", "Jos dreapta"];
        var values = VreDoSettingsData.options();
        for (var i = 0; i < keys.size(); i += 1) {
            var selected = Application.Properties.getValue(keys[i]);
            if (selected == null || selected < 0 || selected >= values.size()) { selected = i + 1; }
            addItem(names[i] + ": " + values[selected], complicationIdentifier(i));
        }
    }

    function complicationIdentifier(index) {
        if (index == 0) { return :complication1; }
        if (index == 1) { return :complication2; }
        if (index == 2) { return :complication3; }
        if (index == 3) { return :complication4; }
        if (index == 4) { return :complication5; }
        return :complication6;
    }
}

class VreDoSettingsDelegate extends WatchUi.MenuInputDelegate {
    function initialize() { MenuInputDelegate.initialize(); }

    function onMenuItem(item) {
        if (item == :displayMode) {
            WatchUi.pushView(new VreDoDisplayMenu(), new VreDoDisplayDelegate(), WatchUi.SLIDE_RIGHT);
            return;
        }
        var slot = -1;
        if (item == :complication1) { slot = 0; }
        else if (item == :complication2) { slot = 1; }
        else if (item == :complication3) { slot = 2; }
        else if (item == :complication4) { slot = 3; }
        else if (item == :complication5) { slot = 4; }
        else if (item == :complication6) { slot = 5; }
        if (slot >= 0) {
            WatchUi.pushView(new VreDoComplicationMenu(slot), new VreDoComplicationDelegate(slot), WatchUi.SLIDE_RIGHT);
        }
    }
}

class VreDoDisplayMenu extends WatchUi.Menu {
    function initialize() {
        Menu.initialize();
        setTitle("Afișare oră");
        addItem("Analogică", :analog);
        addItem("Digitală", :digital);
    }
}

class VreDoDisplayDelegate extends WatchUi.MenuInputDelegate {
    function initialize() { MenuInputDelegate.initialize(); }

    function onMenuItem(item) {
        if (item == :analog) { Application.Properties.setValue("showDigitalTime", false); }
        else if (item == :digital) { Application.Properties.setValue("showDigitalTime", true); }
        WatchUi.requestUpdate();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class VreDoComplicationMenu extends WatchUi.Menu {
    var mSlot = 0;

    function initialize(slot) {
        Menu.initialize();
        mSlot = slot;
        var names = ["sus stânga", "sus centru", "sus dreapta", "jos stânga", "jos centru", "jos dreapta"];
        setTitle("Alege: " + names[slot]);
        var options = VreDoSettingsData.options();
        for (var i = 0; i < options.size(); i += 1) {
            addItem(options[i], VreDoSettingsData.optionIdentifier(i));
        }
    }
}

class VreDoComplicationDelegate extends WatchUi.MenuInputDelegate {
    var mSlot = 0;

    function initialize(slot) {
        MenuInputDelegate.initialize();
        mSlot = slot;
    }

    function onMenuItem(item) {
        var optionIds = VreDoSettingsData.optionIdentifiers();
        for (var i = 0; i < optionIds.size(); i += 1) {
            if (item == optionIds[i]) {
                Application.Properties.setValue("complication" + (mSlot + 1).format("%d"), i);
                Application.Properties.setValue("useCustomComplications", true);
                break;
            }
        }
        WatchUi.requestUpdate();
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}

class VreDoSettingsData {
    static function options() {
        return ["Nimic", "Pași", "Puls", "Altitudine", "Calorii active", "Minute active săptămânale", "Baterie", "Temperatură", "Minimă/maximă", "Șansă de ploaie", "Vânt", "Umiditate", "Răsărit/apus", "Calorii totale", "Distanță zilnică", "Etaje urcate", "Obiectiv etaje", "Minute active azi", "Bară de mișcare", "Respirație", "Nivel stres", "Recuperare", "Temperatură resimțită", "Punct de rouă", "Indice UV", "Presiune", "Nebulozitate", "Vizibilitate", "Direcția vântului", "Obiectiv pași", "Etaje coborâte", "Metri urcați"];
    }

    static function optionIdentifiers() {
        return [:option0, :option1, :option2, :option3, :option4, :option5, :option6, :option7,
                :option8, :option9, :option10, :option11, :option12, :option13, :option14, :option15,
                :option16, :option17, :option18, :option19, :option20, :option21, :option22, :option23,
                :option24, :option25, :option26, :option27, :option28, :option29, :option30, :option31];
    }

    static function optionIdentifier(index) { return optionIdentifiers()[index]; }
}
