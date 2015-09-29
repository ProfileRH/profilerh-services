part of profile_service;

/// [ArgsOption] is a tool class that handle the configuration available for each service created
///
/// [ArgsOption] will handle :
///
///  * commands line options as :
///
///      * **-p, --port PORT** _(default: 8080)_ : specify the port used by the service to expose his API
///      * **-c, --config-file** CONFIG_FILE_PATH _(default: "bin/config.json")_ : specify the path of the configuration file
///      * **-s, --service-config-file** SERVICE_CONFIG_FILE_PATH _(default: "bin/service.config.json")_ ; specify the path of the service configuration file
///
///  * configuration file parsing
///  * service configuration file parsing
///  * variable replacement inside service configuration file
class ArgsOption {
  String rootDir = "bin";
  int port;
  String serviceConfigFilePath;
  String configFilePath;
  var configs;
  var _configFile;
  var serviceConfigs;
  var _serviceConfigFile;
  ArgParser parser;

  ArgsOption({this.port, this.serviceConfigFilePath: "bin/service.config.json", this.configFilePath: "bin/config.json"}) {
    parser = new ArgParser();

    parser.addOption('port', abbr: 'p');
    parser.addOption('config-file', abbr: 'c');
    parser.addOption('service-config-file', abbr: 's');
  }

  /// [parse] will take the command line argument in parameter and initialize the configurations files
  void parse(List<String> args) {
    var res = parser.parse(args);

    port = res["port"] != null ? int.parse(res["port"]) : this.port;
    configFilePath = res["config-file"] != null ? res["config-file"] : this.configFilePath;
    serviceConfigFilePath = res["service-config-file"] != null ? res["service-config-file"] : this.serviceConfigFilePath;
    _getConfigs();
  }

  /// [operator[]] will provide access to the configurations object specify in configurations file
  ///
  /// This operator will allow a quick access to the configuration objects inside configurations file
  operator[](String key) {
    for (var obj in serviceConfigs) {
      if (obj["name"] == key)
        return obj;
    }
    return null;
  }

  _getConfigs() {
    if (configFilePath != null) {
      _configFile = new File(configFilePath);
      configs = JSON.decode(_configFile.readAsStringSync());
    }
    if (serviceConfigFilePath != null) {
      _serviceConfigFile = new File(serviceConfigFilePath);
      serviceConfigs = JSON.decode(_serviceConfigFile.readAsStringSync());
      _replaceVariableInConfigs(serviceConfigs);
    }
  }

  _iterateInMap(Map m) {
    m.forEach((k, v) {
      var r;
      if (v is Map) r = _iterateInMap(v);
      else if (v is List) r = _iterateInList(v);
      else r = _replaceOneVariableInString(v);
      m[k] = r;
    });
    return m;
  }

  _iterateInList(List l) {
    int i = 0;
    l.forEach((e) {
      var r;
      if (e is List) r = _iterateInList(e);
      else if (e is Map) r = _iterateInMap(e);
      else r = _replaceOneVariableInString(e);
      l[i] = r;
      i++;
    });
    return l;
  }

  _replaceOneVariableInString(String input) {
    int i = 0;
    return input.replaceAllMapped(new RegExp(r'\$\{([a-zA-Z\_0-9]*)\}'), (Match m) {
      return (Platform.environment[m.group(1)] ?? configs[m.group(1)]);
    });
  }

  _replaceVariableInConfigs(var configInfo) {
    if (configInfo is List) _iterateInList(configInfo);
    else if (configInfo is Map) _iterateInMap(configInfo);
    else _replaceOneVariableInString(configInfo);
  }
}
