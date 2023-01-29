import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;
using Toybox.Application.Properties;
using Toybox.Application.Storage;


class HomeAssistantDelegate extends WatchUi.BehaviorDelegate {
    private var _notify as Method(args as Dictionary or String or Null) as Void;

    public function initialize(handler as Method(args as Dictionary or String or Null) as Void) {
        WatchUi.BehaviorDelegate.initialize();
        _notify = handler;
    }

    public function onMenu() as Boolean {
        return true;
    }

    public function onSelect() as Boolean {
        _getNestDevices();
        return true;
    }

    public function onKey(keyEvent as KeyEvent) as Boolean {
        var view = new $.NestTempPickerView();
        var delegate = new $.NestTempPickerDelegate(view);
        return WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE);
    }

    public function onReceive(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        if (responseCode == 401) {
            _reauthenticate();
        } else
        if (responseCode == 200) {
            var device_id_path = data["devices"][0]["name"] as String;
            Storage.setValue("device_id", device_id_path.substring(57, 151));
            var temperature_set = data["devices"][0]["traits"]["sdm.devices.traits.ThermostatTemperatureSetpoint"]["heatCelsius"] as Float;
            Storage.setValue("temperature_set", _formatTemperature(temperature_set.toString()));
            var temperature = data["devices"][0]["traits"]["sdm.devices.traits.Temperature"]["ambientTemperatureCelsius"] as Float;
            var status = data["devices"][0]["traits"]["sdm.devices.traits.ThermostatHvac"]["status"] as String;
            var response_data = {
                "Temp" => _formatTemperature(temperature.toString()),
                "TempTo" => _formatTemperature(temperature_set.toString()),
                "Status" => status
            };
            _notify.invoke(response_data);
        } else {
            _notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }

    public function onReceiveReauth(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        if (responseCode == 200) {
            var access_token = data["access_token"] as String;
            Storage.setValue("bearer_token", access_token);
            _getNestDevices();
        } else {
            _notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }

    private function _formatTemperature(temperature as String) as String {
        if (temperature.length() > 4) {
            return temperature.substring(0, 4);
        }
        return temperature;
    }

    private function _getNestDevices() as Void {
        var project_id = Properties.getValue("project_id");
        var bearer = Storage.getValue("bearer_token");

        _notify.invoke("Executing\nRequest");

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
            :headers => {
                "Content-Type" => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
                "Authorization" => "Bearer " + bearer
            }
        };

        Communications.makeWebRequest(
            "https://smartdevicemanagement.googleapis.com/v1/enterprises/" + project_id + "/devices",
            {},
            options,
            method(:onReceive)
        );
    }

    private function _reauthenticate() as Void {
        var client_id = Properties.getValue("client_id");
        var client_secret = Properties.getValue("client_secret");
        var refresh_token = Properties.getValue("refresh_token");

        _notify.invoke("Executing\nReAuth");

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };

        Communications.makeWebRequest(
            "https://www.googleapis.com/oauth2/v4/token?client_id=" + client_id + "&client_secret=" + client_secret + "&refresh_token=" + refresh_token + "&grant_type=refresh_token",
            {},
            options,
            method(:onReceiveReauth)
        );
    }
}