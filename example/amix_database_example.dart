import 'package:amix_database/amix_database.dart';

void main() async {
  dataBasePath = "path"; //add a path for DataBase

  var myAmDb = AmixDataBaseFile("db"); //create your DataBase
  await myAmDb.exists(); //checking if DataBase exists
  await myAmDb.create(); //creating DataBase folders and files
  await myAmDb.startConfig(); //start configing the DataBase
  await myAmDb.clear(); //clear all data inside DataBase
  await myAmDb.writeNewObject(
    key: "exampleKey",
    object: "example",
  ); //create a object inside dataBase
  var result = await myAmDb.get(
    key: "exampleKey",
  ); //get a Object
  print(result.data); //print =>> example
  await myAmDb.editObject(
    key: "exampleKey",
    object: "hello World!!",
  ); //edit the Object
  await myAmDb.removeObject(
    key: "exampleKey",
  ); //move the Object to DataBase recycle bin
  await myAmDb.clean(); //remove all of Objects inside recycle bin
  await myAmDb.delete(); //delete DataBase
}
