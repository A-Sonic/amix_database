import 'package:amix_database/amix_database.dart';

void main() async {
  dataBasePath = "/var/lib/amix";

  var myAmDb = AmixDataBaseFile("db");
  await myAmDb.exists();
  await myAmDb.create();
  await myAmDb.startConfig();
  await myAmDb.clear();
  await myAmDb.writeNewObject(key: "key", object: "armanam");
  var resuklt = await myAmDb.get(key: "key");
  await myAmDb.writeNewObject(key: "23", object: [
    {"pdlpldpel": 23123},
    "party",
    123123,
    ["ae"]
  ]);
  print(resuklt.data);
  await myAmDb.editObject(key: "key", object: "wpdlpwldpwl");
  resuklt = await myAmDb.get(key: "key");
  print(resuklt.data);
  resuklt = await myAmDb.get(key: "23");
  print(resuklt.data);
  var myAmDb2 = AmixDataBaseFile("db2");
  await myAmDb2.exists();
  await myAmDb2.create();
  await myAmDb2.startConfig();
  await myAmDb2.clear();
  await myAmDb2.writeNewObject(key: "key", object: "armanam");
  resuklt = await myAmDb2.get(key: "key");
  await myAmDb2.writeNewObject(key: "23", object: [
    {"pdlpldpel": 23123},
    "party",
    123123,
    ["ae"]
  ]);
  print(resuklt.data);
  await myAmDb2.editObject(key: "key", object: "wpdlpwldpwl");
  resuklt = await myAmDb2.get(key: "key");
  print(resuklt.data);
  resuklt = await myAmDb2.get(key: "23");
  print(resuklt.data);
}
