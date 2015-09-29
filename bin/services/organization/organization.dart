import 'dart:convert';
import 'dart:async';

import 'package:rpc/rpc.dart';
import 'package:profilerh_common/profilerh_common.dart';
import 'package:profilerh_service/profile_service.dart';
import 'package:rpc_mongo_mapper/rpc_mongo_mapper.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:logging/logging.dart';

import 'dart:io';

class TreeNode {
  String id;
  Map<String, String> values = {};
  List<TreeNode> child = [];
  List<TreeNode> parent = [];
}

@ApiClass(
    version: "v1",
    name: "organization",
    title: 'organization service'
)
class OrganizationService extends ProfileService {
  final Logger log = new Logger('OrganizationService');
  AMQPCaller getJobs;

  OrganizationService(ArgsOption options) : super("OrganizationService", options) {
    this.binder.register(this);
    this.getJobs = new AMQPCaller(client, 'rpc.binder.JobService.data.getModel');
  }

  @ApiMethod(path: "manager/{jobId}", method: 'GET')
  Job getManager(String jobId) {

  }

  @ApiMethod(path: "{mId}/is/manager/of/{eId}", method: 'GET')
  Job getIsManager(String mId, String eId) {

  }

  @ApiMethod(path: "graph", method: 'GET')
  @Register()
  Future<List<TreeNode>> getOrganizationChart() async {
    var ret = [];
    try {
      print("Call for jobs");
      var l = await this.getJobs.remoteCall();
      print("Remote call ${l}");
      List<Job> jobs = [];
      for (var j in l) jobs.add(fromJson(Job, j));
      Map<String, TreeNode> graph = {};

      for (var j in jobs) {
        print(j.id);
        print("-- ${j.managers}");
        graph[j.id] = graph[j.id] == null ? new TreeNode() : graph[j.id];
        graph[j.id].id = j.id;
        for (var m in j.managers) {
          graph[m] = graph[m] == null ? new TreeNode() : graph[m];

          graph[m].child.add(graph[j.id]);
          //graph[j.id].parent.add(graph[m]);
        }
        if (j.managers.length == 0) {
          ret.add(graph[j.id]);
        }
      }
    } catch (e, s) {
      print("${e} ${s}");
    }
    print("Ret: ${ret}");
    return ret;
  }

  init() async {
    await registerToApiGateway(path: "/organization/", targetUrl: options["organization"]["localisation"][0]);

    return 42;
  }
}

main(List<String> args) async {
  setUpLogger();

  ApiServer _apiServer = new ApiServer();
  var argOptions = new ArgsOption();

  argOptions.parse(args);
  var u = new OrganizationService(argOptions);
  await u.init();

  _apiServer.addApi(u);
  _apiServer.enableDiscoveryApi();

  var handler = createRpcHandler(_apiServer);

  shelf.Handler handlers = const shelf.Pipeline()
  //.addMiddleware(headerPatchMiddleware())
  .addHandler(handler);

  io.serve(handlers, InternetAddress.ANY_IP_V4, argOptions.port == null ? int.parse(argOptions["organization"]["defaultPort"]) : argOptions.port).then((HttpServer server) {
    u.log.info('Serving [organization] at http://${server.address.host}:${server.port}');
  });
}