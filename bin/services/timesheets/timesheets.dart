import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:rpc/rpc.dart';
import 'package:ProfileRH/common.dart';
import 'package:ProfileRH/profile_service.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'dart:io';

@ApiClass(
    version: "v1",
    name: "timesheet",
    title: 'timesheet service'
)
class TimeSheetService extends ProfileService {
  final Logger log = new Logger('TimeSheetService');

  TimeSheetService(ArgsOption options) : super("TimeSheetService", options) {
    this.binder.register(this);
  }

  @ApiMethod(path: "", method: 'GET')


  init() async {
    print("Register account to: ${options["account"]}");
    await registerToApiGateway(path: "/timesheet/", targetUrl: options["timesheet"]["localisation"][0]);

    return 42;
  }
}

main(List<String> args) async {
  setUpLogger();

  ApiServer _apiServer = new ApiServer();
  var argOptions = new ArgsOption();

  argOptions.parse(args);
  var u = new TimeSheetService(argOptions);
  await u.init();

  _apiServer.addApi(u);
  _apiServer.enableDiscoveryApi();

  var handler = createRpcHandler(_apiServer);
  print(hashPassword("password"));

  shelf.Handler handlers = const shelf.Pipeline()
  .addMiddleware(headerPatchMiddleware())
  .addHandler(handler);

  io.serve(handlers, InternetAddress.ANY_IP_V4, argOptions.port == null ? int.parse(argOptions["timesheet"]["defaultPort"]) : argOptions.port).then((HttpServer server) {
    u.log.info('Serving [timesheet] at http://${server.address.host}:${server.port}');
  });
}