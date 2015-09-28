import 'package:grinder/grinder.dart';

runServiceUsers() {
  Pub.runAsync("bin/services/users/users", runOptions: new RunOptions(runInShell: true));
}

runSetupUsersDemoData() {

}

runServiceJobs() {
  Pub.runAsync("bin/services/jobs/jobs");
}

runServiceCompanies() {
  Pub.runAsync("bin/services/companies/companies");
}