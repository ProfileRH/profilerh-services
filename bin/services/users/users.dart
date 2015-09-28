import 'package:rpc/rpc.dart';
import 'package:ProfileRH/common.dart';
import 'package:ProfileRH/profile_service.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:logging/logging.dart';

import 'dart:io';

@ApiClass(
    version: "v1",
    name: "user",
    title: 'user managment service'
)
class UserService extends ProfileService {
  final Logger log = new Logger('UserService');

  @ApiResource(name: "managment/")
  MongoMapper<User> users = new MongoMapper<User>();

  UserService(ArgsOption options) : super("UserService", options) {
    this.binder.register(this);
    this.binder.register(this.users, prefix: 'UserService.data');
  }

  init() async {
    print("Register user to: ${options["user"]}");
    await registerToApiGateway(path: "/user/", targetUrl: options["user"]["localisation"][0]);
    var d = await connectToMongoDb();
    users.collec = db.collection("users");
    return d;
  }
}

main(List<String> args) async {
  setUpLogger();

  ApiServer _apiServer = new ApiServer();
  var argOptions = new ArgsOption();

  argOptions.parse(args);
  var u = new UserService(argOptions);
  await u.init();

  _apiServer.addApi(u);
  _apiServer.enableDiscoveryApi();
  var handler = createRpcHandler(_apiServer);

  u.requiredAccesLevel = 41;
  _apiServer.registerPlugin("auth", u.checkAuthenticationPlugin);

  shelf.Handler handlers = const shelf.Pipeline()
  .addMiddleware(headerPatchMiddleware())
  .addHandler(handler);

  io.serve(handlers, InternetAddress.ANY_IP_V4, argOptions.port == null ? int.parse(argOptions["user"]["defaultPort"]) : argOptions.port).then((server) {
    u.log.info('Serving [users] at http://${server.address.host}:${server.port}');
  });
}