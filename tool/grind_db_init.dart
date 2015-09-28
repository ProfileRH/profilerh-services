import 'package:grinder/grinder.dart';
import "package:ProfileRH/common.dart";
import 'package:ProfileRH/profile_service.dart';
import 'package:mongo_dart/mongo_dart.dart';

addingUser() async {
  var db = new Db("mongodb://127.0.0.1/profilerh");
  await db.open();
  var user_mapper = new MongoMapper<User>(collec: db.collection("users"));
  User u = createNewDemoUser(firstname: "kevin", lastname: "platel");
  await user_mapper.postModel(u).then((v) async {
    User u = createNewDemoUser(firstname: "alexandre", lastname: "deceneux");
    await user_mapper.postModel(u).then((v) async {
      User u = createNewDemoUser(firstname: "thomas", lastname: "catty");
      await user_mapper.postModel(u).then((v) async {
        User u = createNewDemoUser(firstname: "marc-antoine", lastname: "sergeant");
        await user_mapper.postModel(u).then((v) async {
          db.close();
        });
      });
    });
  });
}

addingCompany() async {
  var db = new Db("mongodb://127.0.0.1/profilerh");
  await db.open();
  var company_mapper = new MongoMapper<Company>(collec: db.collection("companies"));
  Company u = createNewCompanyDemo();
  company_mapper.postModel(u).then((v) {
    db.close();
  });
}

addingJobs() async {
  var db = new Db("mongodb://127.0.0.1/profilerh");
  await db.open();
  var job_mapper = new MongoMapper<Job>(collec: db.collection("jobs"));
  var company_mapper = new MongoMapper<Company>(collec: db.collection("companies"));
  var user_mapper = new MongoMapper<User>(collec: db.collection("users"));
  List l = await user_mapper.getModel();
  List lc = await company_mapper.getModel();
  Job j = createNewJobDemo(lc[0], l[2]);
  j.jobTitle = "CTO";
  j.category = JobCategory.DIRECTOR;

  job_mapper.postModel(j).then((v) async {
    Job j = v;

    Job u = createNewJobDemo(lc[0], l[0], [j]);

    job_mapper.postModel(u).then((v) async {

      Job u = createNewJobDemo(lc[0], l[1], [j]);

      job_mapper.postModel(u).then((v) async {
        Job u = createNewJobDemo(lc[0], l[3]);
        u.jobTitle = "COO";
        u.category = JobCategory.DIRECTOR;

        job_mapper.postModel(u).then((v) async {
          db.close();
        });
      });
    });
  });
}

addingAccounts() async {
  var db = new Db("mongodb://127.0.0.1/profilerh");
  await db.open();
  var account_mapper = new MongoMapper<Account>(collec: db.collection("accounts"));
  var company_mapper = new MongoMapper<Company>(collec: db.collection("companies"));
  var user_mapper = new MongoMapper<User>(collec: db.collection("users"));
  List lc = await company_mapper.getModel();
  List l = await user_mapper.getModel();
  Account u = createNewAccountDemo(l[0], lc[0]);

  account_mapper.postModel(u).then((v) async {
    Account u = createNewAccountDemo(l[1], lc[0]);

    account_mapper.postModel(u).then((v) async {
      Account u = createNewAccountDemo(l[2], lc[0]);

      account_mapper.postModel(u).then((v) async {
        Account u = createNewAccountDemo(l[3], lc[0]);

        account_mapper.postModel(u).then((v) async {
          db.close();
        });
      });
    });
  });
}