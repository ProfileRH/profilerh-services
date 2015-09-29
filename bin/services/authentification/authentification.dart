import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:rpc/rpc.dart';
import 'package:profilerh_common/profilerh_common.dart';
import 'package:profilerh_service/profile_service.dart';
import 'package:rpc_mongo_mapper/rpc_mongo_mapper.dart';
import 'package:amqp_rpc_binder/amqp_rpc_binder.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:logging/logging.dart';

import 'dart:io';

@ApiClass(
    version: "v1",
    name: "auth",
    title: 'authentication service'
)
class AuthenticationService extends ProfileService {
  final Logger log = new Logger('AuthentificationService');

  MongoMapper<Account> accounts = new MongoMapper<Account>();

  AuthenticationService(ArgsOption options) : super("AuthenticationService", options) {
    this.binder.register(this);
  }

  _checkUsernamePassword(String username, String password) async {
    if (username == null || password == null || username.length < 6 || password.length < 8) {
      return new StatusMessage.from(code: StatusCode.INVALID_ARGUMENT, valid: false);
    }
    var res = await accounts.getModel(filter: JSON.encode({"login": username}));
    if (res.length == 0) {
      return new StatusMessage.from(code: StatusCode.BAD_CREDENTIALS, valid: false);
    }
    for (var acc in res) {
      if (acc.hashedSaltPassword == generateHashPassword(acc.salt, password)) {
        return new StatusMessage.from(code: StatusCode.CONNECTED, valid: true, info: {"userid": acc.userid});
      }
    }
    return new StatusMessage.from(code: StatusCode.BAD_CREDENTIALS, valid: false);
  }

  _checkAccessLevel(String username, String password, String authId, String companyId, int accessLevel) async {
    List<Account> res;
    if (AccountType.ALL == accessLevel)
      return new StatusMessage.from(code: StatusCode.ACCESS_GRANTED, valid: true, name: "Access granted", message: "You have the access");
    if (authId == null)
      res = await accounts.getModel(filter: JSON.encode({"login": username}));
    else
      res = await accounts.getModel(filter: JSON.encode({"tokens": authId}));
    if (res.length > 0) {
      Account acc;
      for (var a in res) {
        if (a.hashedSaltPassword == generateHashPassword(a.salt, password)) {
          acc = a;
          break;
        }
      }
      if (acc != null && AccountType.CONNECTED == accessLevel)
        return new StatusMessage.from(code: StatusCode.ACCESS_GRANTED, valid: true, name: "Access granted", message: "You have the access");
      if (companyId == null) {
        for (AccountType r in acc.rights) {
          if (r.value == accessLevel)
            return new StatusMessage.from(code: StatusCode.ACCESS_GRANTED, valid: true, name: "Access granted", message: "You have the access");
        }
      } else {
        for (AccountRight r in acc.companyRights) {
          if (r.companyId == companyId) {
            for (AccountType t in r.roles) {
              if (t.value == accessLevel)
                return new StatusMessage.from(code: StatusCode.ACCESS_GRANTED, valid: true, name: "Access granted", message: "You have the access");
            }
          }
        }
      }
    }
    return new StatusMessage.from(code: StatusCode.ACCESS_DENIED, valid: false, name: "Access denied", message: "You don't have access to information");
  }

  @ApiMethod(path: "login", method: 'GET')
  @Register()
  Future<StatusMessage> login({String username, String password, String authId}) async {
    if (authId == null) {
      StatusMessage res = await _checkUsernamePassword(username, password);
      if (res.valid)
        return res;
      else
        throw new RpcError(HttpStatus.UNAUTHORIZED, res.name, JSON.encode(toJson(res)));
    }
  }

  @ApiMethod(path: "logout", method: 'GET')
  Future<Map<String, String>> logout({String authId}) {

  }

  @ApiMethod(path: "check", method: 'GET')
  @Register()
  Future<StatusMessage> check({String username, String password, String authId, int requiredAccesLevel, String askRight, String resources, String companyId}) async {
    if (authId == null) {
      StatusMessage res = await _checkUsernamePassword(username, password);
      if (res != null && res.valid != null && res.valid == true) {
        var userid = res.info["userid"];
        if (requiredAccesLevel != null) {
          res = await _checkAccessLevel(username, password, authId, companyId, requiredAccesLevel);
          res.info["userid"] = userid;
        }
      }
      print("Check return : ${toJson(res)}");
      return res;
    }
  }

  @Register()
  Future<Map<String, String>> getUserFromCredentials({String username, String password, String authId, int requiredAccesLevel, String askRight, String resources, String companyId}) async {

  }

  init() async {
    print("Register account to: ${options["account"]}");
    await registerToApiGateway(path: "/auth/", targetUrl: options["auth"]["localisation"][0]);
    var d = await connectToMongoDb();
    accounts.collec = db.collection("accounts");
    return d;
  }
}

main(List<String> args) async {
  setUpLogger();

  ApiServer _apiServer = new ApiServer();
  var argOptions = new ArgsOption();

  argOptions.parse(args);
  var u = new AuthenticationService(argOptions);
  await u.init();

  _apiServer.addApi(u);
  _apiServer.enableDiscoveryApi();

  var handler = createRpcHandler(_apiServer);
  print(hashPassword("password"));

  shelf.Handler handlers = const shelf.Pipeline()
    .addMiddleware(headerPatchMiddleware())
    .addHandler(handler);

  io.serve(handlers, InternetAddress.ANY_IP_V4, argOptions.port == null ? int.parse(argOptions["auth"]["defaultPort"]) : argOptions.port).then((HttpServer server) {
    u.log.info('Serving [authentication] at http://${server.address.host}:${server.port}');
  });
}