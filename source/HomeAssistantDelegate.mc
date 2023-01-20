import Toybox.Communications;
import Toybox.Lang;
import Toybox.WatchUi;

//! Creates a web request on menu / select events
class HomeAssistantDelegate extends WatchUi.BehaviorDelegate {
    private var _notify as Method(args as Dictionary or String or Null) as Void;

    //! Set up the callback to the view
    //! @param handler Callback method for when data is received
    public function initialize(handler as Method(args as Dictionary or String or Null) as Void) {
        WatchUi.BehaviorDelegate.initialize();
        _notify = handler;
    }

    //! On a menu event, make a web request
    //! @return true if handled, false otherwise
    public function onMenu() as Boolean {
        return true;
    }

    //! On a select event, make a web request
    //! @return true if handled, false otherwise
    public function onSelect() as Boolean {
        makeRequest();
        return true;
    }
    //! Make the web request
    private function makeRequest() as Void {
        var app = Application.getApp();
        var project_id = app.getProperty("project_id");
        var bearer = app.getProperty("bearer_token");

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
        var app = Application.getApp();
        var client_id = app.getProperty("client_id");
        var client_secret = app.getProperty("client_secret");
        var refresh_token = app.getProperty("refresh_token");

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

    public function onReceive(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        if (responseCode == 401) {
            _reauthenticate();
        } else
        if (responseCode == 200) {
            var temperature_set = data["devices"][0]["traits"]["sdm.devices.traits.ThermostatTemperatureSetpoint"]["heatCelsius"];
            var temperature = data["devices"][0]["traits"]["sdm.devices.traits.Temperature"]["ambientTemperatureCelsius"];
            var status = data["devices"][0]["traits"]["sdm.devices.traits.ThermostatHvac"]["status"];
            var response_data = {
                "Temp" => temperature,
                "TempTo" => temperature_set,
                "Status" => status
            };
            //System.println(response_data);
            _notify.invoke(response_data);
        } else {
            _notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }

    public function onReceiveReauth(responseCode as Number, data as Dictionary<String, Object?> or String or Null) as Void {
        if (responseCode == 200) {
            var access_token = data["access_token"];
            var app = Application.getApp();
            app.setProperty("bearer_token", access_token);
            makeRequest();
        } else {
            _notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }
}
