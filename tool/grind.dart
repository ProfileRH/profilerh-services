import "dart:async";
import 'dart:io';
import 'package:grinder/grinder.dart';
import 'grind_service_cmd.dart';
import 'grind_db_init.dart';
import 'package:profilerh_service/profile_service.dart';

main(args) => grind(args);

String getDockerHost() {
  var la = grinderArgs();
  var i = la.indexOf("-dh");
  if (i >= 0 && i + 1 < la.length) {
    return la[i + 1];
  }
  return null;
}

@Task("Running test...")
test() => new TestRunner().testAsync();

@DefaultTask()
@Depends(test)
build() {
  Pub.build();
}

@Task("Generating doc...")
doc() {
  new PubApp.local('dartdoc').run([]);
}

@Task("Clean project...")
clean() => defaultClean();

@Task("Start etcd...")
etcd() {
  var args = [
    "run",
    "-p",
    "2379:2379",
    "-d",
    "--name",
    "etcd",
    "-v",
    "/usr/share/ca-certificates/:/etc/ssl/certs",
    "quay.io/coreos/etcd:v2.1.1"
  ];
  try {
    log("Kill running Etcd");
    run("docker", arguments: ["kill", "etcd"]);
    log("OK");
  } catch (e) {
    log("Etcd is not running. kill not necessary");
  }
  try {
    log("Remove previous images...");
    run("docker", arguments: ["rm", "etcd"]);
    log("OK");
  } catch (e) {
    log("Etcd img doesn't exist.");
  }
  try {
    log ("Launch docker images...");
    run("docker", arguments: args);
    log("OK");
  } catch (e) {
    log("Etcd is not already running, start Etcd...");
  }
}

@Task("Start cassandra...")
cassandra() {
  var args = [
    "run",
    "-p",
    "9042:9042",
    "-d",
    "--name",
    "cassandra",
    "mashape/cassandra"
  ];
  try {
    log("Kill running Cassandra");
    run("docker", arguments: ["kill", "cassandra"]);
    log("OK");
  } catch (e) {
    log("Cassandra is not running. kill not necessary");
  }
  try {
    log("Remove previous images...");
    run("docker", arguments: ["rm", "cassandra"]);
    log("OK");
  } catch (e) {
    log("RabbitMQ img doesn't exist.");
  }
  try {
    log ("Launch docker images...");
    run("docker", arguments: args);
    log("OK");
  } catch (e) {
    log("Cassandra is not already running, start RabbitMQ...");
  }
}

@Task("Start kong...")
kong() {
  var args = [
    "run",
    "-p",
    "8000:8000",
    "-p",
    "8001:8001",
    "-d",
    "--name",
    "kong",
    "--link",
    "cassandra:cassandra",
    "mashape/kong"
  ];
  try {
    log("Kill running Kong");
    run("docker", arguments: ["kill", "kong"]);
    log("OK");
  } catch (e) {
    log("Kong is not running. kill not necessary");
  }
  try {
    log("Remove previous images...");
    run("docker", arguments: ["rm", "kong"]);
    log("OK");
  } catch (e) {
    log("Kong img doesn't exist.");
  }
  try {
    log ("Launch docker images...");
    run("docker", arguments: args);
    log("OK");
  } catch (e) {
    log("Kong is not already running, start Kong...");
  }
}

@Task('Start mongod...')
mongodb() {
  try {
    runAsync("mongod");
  } catch (e) {
    log("mongodb already running");
  }
}

@Task("Start rabbitMQ....")
rabbitmq() {
  var args = [
    "run",
    "-d",
    "--hostname",
    "profilerh",
    "--name",
    "profile-rabbit",
    "-p",
    "8080:15672",
    "-p",
    "5672:5672",
    "rabbitmq:3-management"
  ];
  try {
    log("Kill running RabbitMQ");
    run("docker", arguments: ["kill", "profile-rabbit"]);
    log("OK");
  } catch (e) {
    log("RabbitMQ is not running. kill not necessary");
  }
  try {
    log("Remove previous images...");
    run("docker", arguments: ["rm", "profile-rabbit"]);
    log("OK");
  } catch (e) {
    log("RabbitMQ img doesn't exist.");
  }
  try {
    log ("Launch docker images...");
    run("docker", arguments: args);
    log("OK");
  } catch (e) {
    log("RabbitMQ is not already running, start RabbitMQ...");
  }
}

@Task("Running base service...")
baseService() {
  cassandra();
  etcd();
  rabbitmq();
  new Timer(new Duration(seconds: 10), () => kong());
}

@Task("Kill docker base service...")
killBaseService() {
  try {
    runAsync("docker", arguments: ["kill", "etcd"]);
    runAsync("docker", arguments: ["kill", "cassandra"]);
    runAsync("docker", arguments: ["kill", "kong"]);
    runAsync("docker", arguments: ["kill", "profile-rabbit"]);
  } catch (e) {
    log("Container not running");
  }
}

@Task("Run [User] service...")
user() => runServiceUsers();

@Task("Run [Company] service...")
company() => runServiceCompanies();

@Task("Run [Job] service...")
job() => runServiceJobs();

@Task("Run all service")
service() {
  user();
  company();
  job();
}

//
// DB section
//

@Task("Adding some users inside the DB...")
Future populateUser() async => await addingUser();


@Task("Adding some companies inside the DB...")
Future populateCompany() async => await addingCompany();

@Task("Adding some companies inside the DB...")
Future populateJob() async => await addingJobs();

@Task("Adding some account inside the DB...")
Future populateAccount() async => await addingAccounts();


@Task("Adding some information inside the DB...")
populate() async {
  try {
    await populateUser();
    await populateCompany();
    await populateJob();
    await populateAccount();
  } catch (e) {
    log("Populate fail, are you sure mongod is launched ?");
  }
}

//
// Web server
//

@Task("Running web server...")
runWebServer() {
  //runAsync("pub", arguments: ["serve", "--port", "54184"]);
  runAsync("dart", arguments: ["bin/web/server.dart"]);
}

//
// Generation section
//

@Task("Retreive discovery document...")
generateDiscoveryDocument() {
  ArgsOption options = new ArgsOption();
  options.parse([]);
  getDiscoveryDocument(String name) {
    run("curl", arguments: ["-o", "json/${name}.json", options[name]["localisation"][0] + "/discovery/v1/apis/${name}/v1/rest"]);
  }
  getDiscoveryDocument("user");
  getDiscoveryDocument("company");
  getDiscoveryDocument("job");
  getDiscoveryDocument("project");
  getDiscoveryDocument("auth");
  getDiscoveryDocument("inscription");
}

@Task("Generate client library...")
generateClientLib() {
  var glob = new PubApp.global("discoveryapis_generator");
  glob.activate();
  glob.run(["package", "-i", "json", "-o", "lib/client"], script: "generate");
  //run("pub", arguments: ["global", "run", "discoveryapis_generator:generate", "package", "-i", "json", "-o", "lib/client"]);
}