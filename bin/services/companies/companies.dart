import 'package:rpc/rpc.dart';
import 'package:profilerh_common/profilerh_common.dart';
import 'package:profilerh_service/profile_service.dart';
import 'package:rpc_mongo_mapper/rpc_mongo_mapper.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:logging/logging.dart';

import 'dart:io';

@ApiClass(
    version: "v1",
    name: "company",
    title: 'company managment service'
)
class CompanyService extends ProfileService {
  final Logger log = new Logger('CompanyService');

  @ApiResource(name: "managment/")
  MongoMapper<Company> companies = new MongoMapper<Company>();

  CompanyService(ArgsOption options) : super("CompanyService", options) {
    this.binder.register(this);
    this.binder.register(this.companies, prefix: 'CompanyService.data');
  }

  init() async {
    await registerToApiGateway(path: "/company/", targetUrl: options["company"]["localisation"][0]);
    var d = await connectToMongoDb();
    companies.collec = db.collection("companies");
    return d;
  }
}

main(List<String> args) async {
  setUpLogger();

  ApiServer _apiServer = new ApiServer();
  var argOptions = new ArgsOption();

  argOptions.parse(args);
  var u = new CompanyService(argOptions);
  await u.init();

  _apiServer.addApi(u);
  _apiServer.enableDiscoveryApi();
  var handler = createRpcHandler(_apiServer);

  u.requiredAccesLevel = 41;
  _apiServer.registerPlugin("auth", u.checkAuthenticationPlugin);

  shelf.Handler handlers = const shelf.Pipeline()
  .addMiddleware(headerPatchMiddleware())
  .addHandler(handler);

  io.serve(handlers, InternetAddress.ANY_IP_V4, argOptions.port == null ? int.parse(argOptions["company"]["defaultPort"]) : argOptions.port).then((server) {
    u.log.info('Serving [company] at http://${server.address.host}:${server.port}');
  });
}