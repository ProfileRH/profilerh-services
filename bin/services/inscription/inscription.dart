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
import 'package:http/http.dart' as http;

import 'dart:io';

class UserInscription {
  User user;
  Account acc;
}

class CompanyInscription {
  User user;
  Company company;
  Account acc;
}

@ApiClass(
    version: "v1",
    name: "inscription",
    title: 'Inscription service'
)
class InscriptionService extends ProfileService {
  final Logger log = new Logger('InscriptionService');

  MongoMapper<Account> accounts = new MongoMapper<Account>();

  InscriptionService(ArgsOption options) : super("InscriptionService", options) {
    this.binder.register(this);
  }

  @ApiMethod(path: "user", method: 'POST')
  @ApiPlugin(plugin: "auth", params: const{"requiredAccesLevel": 1})
  Future<Map<String, String>> userInscription(UserInscription userInscription) async {
    print("Receive: ${userInscription.user}, ${toJson(userInscription.user)}\n${toJson(userInscription.acc)}");
    Account acc = userInscription.acc;

    print("Access too : ${options["user"]["localisation"][0] + "/user/v1/data"}");
    var res = await http.post(options["user"]["localisation"][0] + "/user/v1/data", body: JSON.encode(toJson(userInscription.user)));
    print("res body: ${res.body}");
    User u = fromJson(User, JSON.decode(res.body));
    acc.userid = u.id;
    acc.salt = generateSalt();
    acc.hashedSaltPassword = generateHashPassword(acc.salt, userInscription.acc.hashedSaltPassword);
    acc.login = userInscription.acc.login;
    acc.lastModification = new DateTime.now();
    acc.creationDate = new DateTime.now();
    acc.tokens = [];

    acc = await accounts.postModel(acc);
    return {"status": "OK", "message": "inscription complete", "userid": u.id, "accountid": acc.id};
  }

  @ApiMethod(path: "company", method: 'POST')
  @ApiPlugin(plugin: "auth", params: const{"requiredAccesLevel": 1})
  Future<Map<String, String>> companyInscription(CompanyInscription companyInscription)  async {
    var company = companyInscription.company;
    var user = companyInscription.user;
    var account = companyInscription.acc;

    print("Access too : ${options["company"]["localisation"][0] + "/company/v1/data"}");
    var res = await http.post(options["company"]["localisation"][0] + "/company/v1/data", body: JSON.encode(toJson(company)));
    print("res body: ${res.body}");
    company = fromJson(Company, JSON.decode(res.body));

    var r = new AccountRight();
    r.companyId = company.id;
    r.roles = [AccountType.USER, AccountType.COMPANY_ADMIN, AccountType.COMPANY_MANAGER];
    if (account.companyRights == null)
      account.companyRights = [];
    account.companyRights.add(r);
    if (account.rights == null)
      account.rights = [];
    account.rights.add(AccountType.USER);

    var uInscr = new UserInscription();
    uInscr.user = user;
    uInscr.acc = account;

    print("User inscription....");
    res = await userInscription(uInscr);
    res["companyid"] = company.id;
    return res;
  }

  init() async {
    print("Register gateway....");
    await registerToApiGateway(path: "/inscription/", targetUrl: options["inscription"]["localisation"][0]);
    print("Connect to mongo...");
    var d = await connectToMongoDb();
    print("Get collection....");
    accounts.collec = db.collection("accounts");
    print("Return...");
    return d;
  }
}

main(List<String> args) async {
  setUpLogger();
  print("Run....");
  ApiServer _apiServer = new ApiServer();
  var argOptions = new ArgsOption();
  print("Run after arg options....");
  argOptions.parse(args);
  print("Run after arg parse....");
  var u = new InscriptionService(argOptions);
  print("Run after instanciation....");
  await u.init();
  u.requiredAccesLevel = AccountType.ADMIN.value;
  _apiServer.registerPlugin("auth", u.checkAuthenticationPlugin);
  print("Run after init....");

  _apiServer.addApi(u);
  _apiServer.enableDiscoveryApi();
  var handler = createRpcHandler(_apiServer);
  print(hashPassword("password"));


  shelf.Handler handlers = const shelf.Pipeline()
  .addMiddleware(headerPatchMiddleware())
  .addHandler(handler);


  io.serve(handlers, InternetAddress.ANY_IP_V4, argOptions.port == null ? int.parse(argOptions["inscription"]["defaultPort"]) : argOptions.port).then((server) {
    u.log.info('Serving [inscription] at http://${server.address.host}:${server.port}');
  });
}