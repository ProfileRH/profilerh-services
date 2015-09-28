import 'package:rpc/rpc.dart';
import 'package:ProfileRH/common.dart';
import 'package:ProfileRH/profile_service.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:logging/logging.dart';

import 'dart:io';

@ApiClass(
    version: "v1",
    name: "job",
    title: 'job managment service'
)
class JobService extends ProfileService {
  final Logger log = new Logger('JobService');

  @ApiResource(name: "managment/")
  MongoMapper<Job> jobs = new MongoMapper<Job>();

  JobService(ArgsOption options) : super("JobService", options) {
    this.binder.register(this);
    this.binder.register(this.jobs, prefix: 'JobService.data');
    jobs.beforeGet.add((_, e, b) {
      print("GET MODEL");
    });
  }

  init() async {
    await registerToApiGateway(path: "/job/", targetUrl: options["job"]["localisation"][0]);
    var d = await connectToMongoDb();
    jobs.collec = db.collection("jobs");
    return d;
  }
}

main(List<String> args) async {
  setUpLogger();

  ApiServer _apiServer = new ApiServer();
  var argOptions = new ArgsOption();

  argOptions.parse(args);
  var u = new JobService(argOptions);
  await u.init();

  _apiServer.addApi(u);
  _apiServer.enableDiscoveryApi();
  var handler = createRpcHandler(_apiServer);

  u.requiredAccesLevel = 41;
  _apiServer.registerPlugin("auth", u.checkAuthenticationPlugin);


  shelf.Handler handlers = const shelf.Pipeline()
  .addMiddleware(headerPatchMiddleware())
  .addHandler(handler);


  io.serve(handlers, InternetAddress.ANY_IP_V4, argOptions.port == null ? int.parse(argOptions["job"]["defaultPort"]) : argOptions.port).then((server) {
    u.log.info('Serving [job] at http://${server.address.host}:${server.port}');
  });
}