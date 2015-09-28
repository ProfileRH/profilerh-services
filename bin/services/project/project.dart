import 'package:rpc/rpc.dart';
import 'package:ProfileRH/common.dart';
import 'package:ProfileRH/profile_service.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:logging/logging.dart';

import 'dart:io';

@ApiClass(
    version: "v1",
    name: "project",
    title: 'project managment service'
)
class ProjectService extends ProfileService {
  final Logger log = new Logger('ProjectService');

  @ApiResource(name: "managment/")
  MongoMapper<Project> users = new MongoMapper<Project>();

  ProjectService(ArgsOption options) : super("ProjectService", options) {
    this.binder.register(this);
    this.binder.register(this.users, prefix: 'ProjectService.data');
  }

  init() async {
    print("Register project to: ${options["project"]}");
    await registerToApiGateway(path: "/project/", targetUrl: options["project"]["localisation"][0]);
    var d = await connectToMongoDb();
    users.collec = db.collection("projects");
    return d;
  }
}

main(List<String> args) async {
  setUpLogger();

  ApiServer _apiServer = new ApiServer();
  var argOptions = new ArgsOption();

  argOptions.parse(args);
  var u = new ProjectService(argOptions);
  await u.init();

  _apiServer.addApi(u);
  _apiServer.enableDiscoveryApi();
  var handler = createRpcHandler(_apiServer);

  u.requiredAccesLevel = 41;
  _apiServer.registerPlugin("auth", u.checkAuthenticationPlugin);


  shelf.Handler handlers = const shelf.Pipeline()
  .addMiddleware(headerPatchMiddleware())
  .addHandler(handler);


  io.serve(handlers, InternetAddress.ANY_IP_V4, argOptions.port == null ? int.parse(argOptions["project"]["defaultPort"]) : argOptions.port).then((server) {
    u.log.info('Serving [projects] at http://${server.address.host}:${server.port}');
  });
}