A package for Saving your Data inside local System.

## Features

you can use this DataBase for your Dart projects.
this DataBase have a security system This system will detect changes inside DataBase files.

## Getting started

Add the following to your pubspec.yaml file.

```yaml
dependencies:
  amix_database: ^0.0.13
```

Import the package.

```dart
import 'package:amix_database/amix_database.dart'
`

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder. 

```dart
const like = 'sample';
```

## Usage

```dart

import 'package:amix_database/amix_database.dart';

void main() async {
  dataBasePath = "path"; //add a path for DataBase

  var myAmDb = AmixDataBaseFile("db"); //create your DataBase
  await myAmDb.exists(); //checking if DataBase exists
  await myAmDb.create(); //creating DataBase folders and files
  await myAmDb.startConfig(); //start configing the DataBase
  await myAmDb.clear(); //clear all data inside DataBase
  await myAmDb.writeNewObject(key: "exampleKey", object: "example"); //create a object inside dataBase
  var result = await myAmDb.get(key: "exampleKey"); //get a Object
  await myAmDb.editObject(key:"exampleKey",object:"hello World!!"); //edit the Object
  await myAmDb.removeObject(key:"exampleKey"); //move the Object to DataBase recycle bin
  await myAmDb.clean(); //remove all of Objects inside recycle bin
  await myAmDb.delete(); //delete DataBase
}

```

## Additional information
