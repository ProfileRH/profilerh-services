part of profile_service;

/// Tool function to setup the logging system
setUpLogger() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    if (!["Connection", "MongoMessageTransformer", "ConnectionManager"].contains(rec.loggerName))
      print('[${rec.loggerName}] ${rec.level.name}: ${rec.time}: ${rec.message}');
  });
}