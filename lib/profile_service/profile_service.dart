part of profile_service;

/// [ProfileService] is the upper class of all ProfileRH micro services
///
/// [ProfileService] provide the basic and common functionality shared between all ProfileRH services as :
///
///  * register the service to the api gateway
///  * connect to the database
abstract class ProfileService {
  kong.Client apiGateway;
  /// [name] of the service
  String name;
  /// Configuration and parameters of the system
  ArgsOption options;
  /// mongodb connection
  Db db;
  /// AMQP client for publish/subscribe messaging communication
  Client client;
  /// [ConnectionSettings] of [client], see [dart_amqp](https://pub.dartlang.org/packages/dart_amqp) documentation to see more
  ConnectionSettings connectionSettings;
  /// [AMQPBinder] is a binder that allow method to be called through AMQP
  AMQPBinder binder;

  int requiredAccesLevel = 42;

  /// AMQP Caller for authentification
  AMQPCaller checkAuth;

  ProfileService(this.name, this.options, {this.connectionSettings}) {
    apiGateway = new kong.Client(url: options["kong"]["localisation"]["admin"][0]);
    if (this.connectionSettings == null) {
      this.connectionSettings = new ConnectionSettings(host: options["rabbitmq"]["localisation"][0]);
    }
    client = new Client(settings: this.connectionSettings);
    this.binder = new AMQPBinder(client);
    this.checkAuth = new AMQPCaller(client, 'rpc.binder.AuthenticationService.check');
  }

  /// Close all the connection
  close() async {
    return client.close();
  }

  /// Get the communication channel
  Future<Channel> channel() async {
    Channel c = await client.channel();
    print(c);
    return c;
  }

  /// [registerToApiGateway] will register the service under [path] at [targetUrl] in the api gateway
  registerToApiGateway({String path, String targetUrl}) async {
    var api = new kong.Api(name: this.name, path: path, target_url: targetUrl);
    await apiGateway.addApi(api);
    return api;
  }

  /// [connectToMongoDb] will handle the mongodb connection for the service
  connectToMongoDb() async {
    db = new Db(options["mongodb"]["localisation"][0]);
    await db.open();
    return db;
  }

  checkAuthentication(Map params) async {
    StatusMessage ret = fromJson(StatusMessage, await checkAuth.remoteCall([], params));
    if (ret == null || ret.valid == null || ret.valid == false) {
      return null;
    }
    return ret;
  }

  /// [checkAuthentication] is a [rpc] plugins for "auth" that will check the credentials and accessLevel
  checkAuthenticationPlugin(request, positionalParam, namedParam, addParams) async {
    print("Plugin calls ${request.headers["username"]}, ${request.headers["password"]}");
    StatusMessage ret;
    if (addParams == null)
      addParams = {};
    try {
      if (addParams["requiredAccesLevel"] == null) {
        addParams["requiredAccesLevel"] = requiredAccesLevel;
      }
      addParams["username"] = request.headers["username"];
      addParams["password"] = request.headers["password"];
      ret = fromJson(StatusMessage, await checkAuth.remoteCall([], addParams));
    } catch (e, stackTrace) {
      print(e);
      print(stackTrace);
    }
    print("result: ${toJson(ret)}");
    if (ret == null || ret.valid == null || ret.valid == false) {
     throw new RpcError(HttpStatus.UNAUTHORIZED, "Acces denied", "Your authorization level don't allow you to acces to this ressources");
    }
  }
}