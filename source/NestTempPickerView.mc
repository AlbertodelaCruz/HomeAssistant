using Toybox.Application.Storage;
using Toybox.Application.Properties;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class NestTempPickerView extends WatchUi.Picker {
    private const _characterSet = "0123456789.";
    private var _curString as String;
    private var _title as Text;
    private var _factory as CharacterFactory;

    public function initialize() {
        _factory = new $.CharacterFactory(_characterSet, true);
        _curString = "";

        var defaults = null;
        var titleText = Storage.getValue("temperature_set");

        _title = new WatchUi.Text({:text=>titleText, :locX=>WatchUi.LAYOUT_HALIGN_CENTER, :locY=>WatchUi.LAYOUT_VALIGN_BOTTOM, :color=>Graphics.COLOR_WHITE});

        Picker.initialize({:title=>_title, :pattern=>[_factory], :defaults=>defaults});
    }

    public function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        Picker.onUpdate(dc);
    }

    public function addCharacter(character as String) as Void {
        _curString += character;
        _title.setText(_curString);
    }

    public function removeCharacter() as Void {
        _curString = _curString.substring(0, _curString.length() - 1) as String;

        if (0 == _curString.length()) {
            _title.setText(Storage.getValue("temperature_set"));
        } else {
            _title.setText(_curString);
        }
    }

    public function getTitle() as String {
        return _curString;
    }

    public function getTitleLength() as Number {
        return _curString.length();
    }

    public function isDone(value as String or Number) as Boolean {
        return _factory.isDone(value);
    }
}

class NestTempPickerDelegate extends WatchUi.PickerDelegate {
    private var _pickerView as NestTempPickerView;

    public function initialize(picker as NestTempPickerView) {
        PickerDelegate.initialize();
        _pickerView = picker;
    }

    public function onCancel() as Boolean {
        if (0 == _pickerView.getTitleLength()) {
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else {
            _pickerView.removeCharacter();
        }
        return true;
    }

    public function onAccept(values as Array<String>) as Boolean {
        if (!_pickerView.isDone(values[0])) {
            _pickerView.addCharacter(values[0]);
        } else {
            _setNestTemperature();
        }
        return true;
    }

    private function _setNestTemperature() as Void {
        var project_id = Properties.getValue("project_id");
        var bearer = Storage.getValue("bearer_token");
        var temperature_set = _pickerView.getTitle();
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON,
                "Authorization" => "Bearer " + bearer
            }
        };
        var params = {                                             
            "command" => "sdm.devices.commands.ThermostatTemperatureSetpoint.SetHeat",
            "params" => {
                "heatCelsius" => temperature_set.toFloat()
            }
        };

        Communications.makeWebRequest(
            "https://smartdevicemanagement.googleapis.com/v1/enterprises/" + project_id + "/devices/" + Storage.getValue("device_id") + ":executeCommand",
            params,
            options,
            method(:onReceiveSetTemp)
        );
    }

    public function onReceiveSetTemp(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        System.println(responseCode);
        System.println(data);
        System.println("output");
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }

}