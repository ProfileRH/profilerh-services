import 'package:rpc/rpc.dart';
import 'package:profilerh_common/profilerh_common.dart';
import 'package:profilerh_service/profile_service.dart';
import 'package:rpc_mongo_mapper/rpc_mongo_mapper.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:logging/logging.dart';

import 'dart:io';
import 'package:redstone/server.dart' as app;
import 'package:di/di.dart';

@app.Group("")
class FileService extends ProfileService {
  final Logger log = new Logger('FileService');

  FileService(ArgsOption options) : super("FileService", options) {
    this.binder.register(this);
  }

  init() async {
    print("Register user to: ${options["file"]}");
    await registerToApiGateway(path: "/file/", targetUrl: options["file"]["localisation"][0]);
    return 42;
  }

  checkRootDir({String userId}) async {
    var rootDir = new Directory(options["file"]["uploadDir"] + (userId ?? ""));
    if (!(await rootDir.exists())) {
      rootDir = await rootDir.create(recursive: true);
    }
    return rootDir;
  }

  saveFile(var file, {String userId}) async {
    Directory rootDir = await checkRootDir(userId: userId);
    var name = file.filename;

    File f = new File(rootDir.path + "/" + name);
    print("File is: ${f.runtimeType}");
    print("File content: [${file.contentType}] ${file.content.runtimeType}");
    f.writeAsBytes(file.content);
  }

  @app.Route("file/v1/upload/:userId", methods: const [app.POST], allowMultipartRequest: true)
  @app.Route("file/v1/upload", methods: const [app.POST], allowMultipartRequest: true)
  uploadFile(@app.Body(app.FORM) Map form, [String userId]) async {
    var file = form["file"];
    var header = app.request.headers;
    var username = header["username"];
    var password = header["password"];
    var companyId = header["companyId"];

    var info = await checkAuthentication({"username": username, "password": password, "companyId": companyId, "requiredAccesLevel": AccountType.CONNECTED.value});

    if (info != null) {
      var ret = await saveFile(file, userId: info.info["userid"] ?? userId);
      return toJson(new StatusMessage.from(code: StatusCode.FILE_SAVE, valid: true, name: "Success", message: "File save"));
    } else {
      return toJson(new StatusMessage.from(code: StatusCode.ACCESS_DENIED, valid: false, name: "Fail", message: "File not save"));
    }
  }

  @app.Route("file/v1/download/:userId/:filePath", methods: const [app.GET])
  @app.Route("file/v1/download/:filePath", methods: const [app.GET])
  downloadFile(String userId, String filePath) async {
    var header = app.request.headers;
    var username = header["username"];
    var password = header["password"];
    var companyId = header["companyId"];

    StatusMessage info = await checkAuthentication({"username": username, "password": password, "companyId": companyId, "requiredAccesLevel": AccountType.CONNECTED.value});
    print("User information: ${info.info}, userId: ${userId}, filePath: ${filePath}");
    if (info != null) {
      var file = new File(options["file"]["uploadDir"] + "/" + (userId ?? info.info["userid"]) + "/" + filePath);
      if (file.existsSync()) {
        return file;
      } else {
        return toJson(new StatusMessage.from(code: StatusCode.FILE_NOT_FOUND, valid: false, name: "Fail", message: "File not found"));
      }
    }
    return toJson(new StatusMessage.from(code: StatusCode.ACCESS_DENIED, valid: false, name: "Fail", message: "Access error"));
  }

  @app.Route("file/v1/list", methods: const[app.GET])
  @app.Route("file/v1/list/:userId", methods: const[app.GET])
  listingFile(String userId) async {
    var header = app.request.headers;
    var username = header["username"];
    var password = header["password"];
    var companyId = header["companyId"];

    var info = await checkAuthentication({"username": username, "password": password, "companyId": companyId, "requiredAccesLevel": AccountType.CONNECTED.value});
    if (info != null) {
      Directory dir = new Directory(options["file"]["uploadDir"] + (userId ?? info.info["userid"]));
      if (dir.existsSync()) {
        List<FileSystemEntity> fileList = dir.listSync(recursive: true);
        List fileListing = [];
        int len = (options["file"]["uploadDir"] + (userId ?? info.info["userid"])).length;
        for (var file in fileList) {
          String p = file.uri.path.substring(len+1);
          fileListing.add(p);
        }
        return fileListing;
      } else {
        return toJson(new StatusMessage.from(code: StatusCode.FILE_NOT_FOUND, valid: false, name: "Fail", message: "File not found"));
      }
    } else {
      return toJson(new StatusMessage.from(code: StatusCode.ACCESS_DENIED, valid: false, name: "Fail", message: "Access error"));
    }
  }
}

main(List<String> args) async {
  setUpLogger();

  ApiServer _apiServer = new ApiServer();
  var argOptions = new ArgsOption();

  argOptions.parse(args);
  var u = new FileService(argOptions);
  await u.init();

  _apiServer.enableDiscoveryApi();
  var handler = createRpcHandler(_apiServer);

  u.requiredAccesLevel = 41;
  _apiServer.registerPlugin("auth", u.checkAuthenticationPlugin);


  shelf.Handler handlers = const shelf.Pipeline()
  .addMiddleware(headerPatchMiddleware())
  .addHandler(handler);

  app.setupConsoleLog();
  var m = new Module();
  m.bind(ArgsOption, toValue: argOptions);
  app.addModule(m);
  app.addShelfMiddleware(headerPatchMiddleware());
  //app.setShelfHandler(handlers);
  app.start(port: argOptions.port == null ? int.parse(argOptions["file"]["defaultPort"]) : argOptions.port).then((server) {
    u.log.info('Serving [files] at http://${server.address.host}:${server.port}');
  });

//  io.serve(handler, InternetAddress.ANY_IP_V4, argOptions.port == null ? int.parse(argOptions["file"]["defaultPort"]) : argOptions.port).then((server) {
//    u.log.info('Serving [files] at http://${server.address.host}:${server.port}');
//  });
}