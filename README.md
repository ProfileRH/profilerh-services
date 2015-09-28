# ProfileRH-v2
Profile platelform second version

# Requirement

Before you start install anything, you need to be sure you have :

- A working installation of Docker (install docker [here](https://docs.docker.com/installation/))
- A working installation of DartSDK (install dart [here](https://www.dartlang.org/downloads/) )
- A working installation of MongoDB (install mongodb [here](http://docs.mongodb.org/manual/installation/) )

Then check everything is working :

> $> dart version

> $> docker versionb

> $> mongo version

#Installation

Comming soon...
(But you should definitely download the Dart SDK) : https://www.dartlang.org/downloads/

#First build

1) Open Webstorm (or a bad IDE)b

2) Open the pubspec.yaml file at root

3) In the top right-hand corner you should see "Get Dependencies". Click it.
   If you don't, do "pub get" in a terminal when you are at the root folder.

4) Still in the same corner, click on "Build" (release or debug, it's up to you).
   If you still don't, you can do "pub build" in the same terminal.

5) Now you should be ready to run the plateform.
   Right click on the "web/app/index.html" file and press 'run' or 'run v2.html'.
   If it doesn't work, return at 2), try a "Repair cache" (or 'pub cache repair' in a terminal) then retry 3) and 4).
   If it's still doesn't work, well... pray ?
   
#Start Webserver
Run the file 'bin/web/server.dart'
Run MongoDB
Write in a terminal 'pub serve --port 54184'

Write in a an other terminal 'set DOCKER_HOST=tcp://192.168.241.129:2375'
Write in the previous terminal 'pub run grinder base-service'