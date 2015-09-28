import 'package:ProfileRH/common.dart';
import 'package:ProfileRH/profile_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_proxy/shelf_proxy.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:logging/logging.dart';
import 'package:redstone/server.dart' as app;
import 'dart:io';
import 'package:http/http.dart' as http;

const _PUB_PORT = 54184;
var argOptions = new ArgsOption();

@app.Group("")
class WebServer {
  final Logger log = new Logger('WebServer');
  var options;
  var filePath;
  var mode;

  WebServer() {
    mode = argOptions["web-app"]["mode"];
    if (argOptions["web-app"]["mode"] == "prod") {
      filePath = argOptions["web-app"]["buildDir"] + argOptions["web-app"]["baseDir"];
    } else {
      filePath = argOptions["web-app"]["baseDir"];
    }
  }

  init() async {
  }

  proxyRequest(http.Response res) {
    res.headers.remove("transfer-encoding");
    print("Headers: ${res.headers}");
    return app.response.change(headers: res.headers, body: res.body);
  }

  @app.Route("/index.html")
  homeRedirect() {
    return app.redirect('/');
  }

  @app.Route("/:before/v1/:after*")
  apiRedirect(before, after) async{
    print("API request");
    var body = await http.get(argOptions["api"]["localisation"] + before + "/v1/" + after).then((response){
      print("Body received : ");
      print(response.body);
      return response.body;
    });
    return body;
  }

  @app.Route("/:path*", matchSubPaths: true)
  redirect(String path) async {
    print("Path in redirect: ${path}");
    bool directFile = path.contains('.');
    if (!directFile)
      path = "index.html";
    if (mode == "prod") {
      File file = new File(filePath + path);
      if (file.existsSync())
        return new File(filePath + path);
      else
        return "";
    }
    return proxyRequest(await http.get(argOptions["web-app"]["pub_serve"] + "/" + path));
  }

  @app.Route("/res/:path*", matchSubPaths: true)
  resFile(String path) async {
    if (mode == "prod")
      return new File(filePath + "res/" + path);
    else if (path.contains(".png") || path.contains(".jpg") || path.contains(".jpeg") || path.contains(".ttf") || path.contains(".cur"))
      return new File(filePath + "res/" + path);
    else {
      print("Forward to: ${argOptions["web-app"]["pub_serve"] + '/res/' + path}");
      return proxyRequest(await http.get(argOptions["web-app"]["pub_serve"] + '/res/' + path));
    }
  }

  @app.Route("/favicon.ico")
  faviconFile() {
    return new File(filePath + "favicon.ico");
  }

  @app.Route("/packages/:path*", matchSubPaths: true)
  packagesFile(String path) async {
    if (mode == "prod")
      return new File(filePath + "packages/" + path);
    else {
      if (path.contains(".cur")) {
        return resFile("images/cursor/" + path.split('/').last);
      }
      print("Forward to: ${argOptions["web-app"]["pub_serve"] + '/packages/' + path}");
      return proxyRequest(await http.get(argOptions["web-app"]["pub_serve"] + '/packages/' + path));
    }
  }


  @app.Route("/components/:path*", matchSubPaths: true)
  commonFile(String path) async {
    if (mode == "prod")
      return new File(filePath + "components/" + path);
    else {
      print("Forward to: ${argOptions["web-app"]["pub_serve"] + '/components/' + path}");
      return proxyRequest(await http.get(argOptions["web-app"]["pub_serve"] + '/components/' + path));
    }
  }
}

main(List<String> args) async {

  argOptions.parse(args);
  app.setupConsoleLog();
  //app.setShelfHandler(createStaticHandler(argOptions["web-app"]["baseDir"]));
  app.setShelfHandler(proxyHandler(argOptions["web-app"]["pub_serve"]));
  app.start(port: int.parse(argOptions.port == null ? argOptions["web-app"]["defaultPort"] : argOptions.port));
}
