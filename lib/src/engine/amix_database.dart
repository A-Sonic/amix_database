import 'dart:convert';
import 'dart:io';
import 'package:amix_database/src/engine/vars.dart';
import 'models/database_response.dart';

///[AmixDataBaseFile] is your DataBase File
class AmixDataBaseFile {
  ///dataBase name
  final String dataBaseName;

  ///[AmixDataBaseFile] is your DataBase File
  AmixDataBaseFile(this.dataBaseName) {
    //checking database if its exists or not
    exists();
  }

  ///last Time dataBase data changed
  DateTime _shouldModifyLastTimeData = DateTime.now();

  ///last Time dataBase table changed
  DateTime _shouldModifyLastTimeTable = DateTime.now();

  ///dataBase Directory
  late final Directory _dataBase = Directory("$dataBasePath/$dataBaseName");

  ///dataBase Table File
  late File _dataBaseTable = File("$dataBasePath/$dataBaseName/table.amidb");

  ///dataBase Data File
  late File _dataBaseData = File("$dataBasePath/$dataBaseName/data.amidb");

  ///dataBase Config File
  late File _dataBaseConfig = File("$dataBasePath/$dataBaseName/config.amidb");

  ///this bool is false if config and data and Table not exists
  bool _exists = true;

  ///this function will check your Data and Table and
  ///Config file and if one of them not exist will return false
  Future<bool> exists() async {
    //check the dataBase Directory
    var dataBaseFolderExists = await _dataBase.exists();
    if (!dataBaseFolderExists) {
      _exists = false;
      return false;
    }
    //check the Table File
    var dataBaseTableExists = await _dataBaseTable.exists();
    //check the Data File
    var dataBaseDataExists = await _dataBaseData.exists();
    //check the Config File
    var dataBaseConfigExists = await _dataBaseConfig.exists();
    //Is DataBase Exists
    var dataBaseExists = (dataBaseFolderExists &&
        dataBaseTableExists &&
        dataBaseDataExists &&
        dataBaseConfigExists);

    _exists = dataBaseExists;
    //return "dataBaseExists"
    return dataBaseExists;
  }

  ///create the DataBase
  Future<AmixDataBaseResponse<void>> create() async {
    //if dataBase exists just return
    var isAmixFolderExist = await _dataBase.exists();
    if (isAmixFolderExist) {
      return AmixDataBaseResponse(
        error: "DataBase already exist",
      );
    }
    //create dataBase Directory
    await _dataBase.create(
      recursive: true,
    );
    _dataBaseData = File("${_dataBase.path}/data.amidb");
    //create dataBase Data File
    await _dataBaseData.create();
    _dataBaseTable = File("${_dataBase.path}/table.amidb");
    //create dataBase Table File
    await _dataBaseTable.create();
    _dataBaseConfig = File("${_dataBase.path}/config.amidb");
    //create dataBase Config File
    await _dataBaseConfig.create();
    //set Table and Data Last Changed Time
    _shouldModifyLastTimeData = await _dataBaseData.lastModified();
    _shouldModifyLastTimeTable = await _dataBaseTable.lastModified();
    //sure that time is Seted
    await _setTime();
    //change the exists to true
    _exists = true;
    return AmixDataBaseResponse(
      success: true,
    );
  }

  ///delete the DataBase Files and Directory
  Future<AmixDataBaseResponse<void>> delete() async {
    //if dataBase is not exist just return
    if (!_exists) {
      return AmixDataBaseResponse(
        success: false,
        error: "DataBase doesn't exists",
      );
    }
    //delete dataBase
    await _dataBase.delete(recursive: true);
    return AmixDataBaseResponse(
      success: true,
    );
  }

  ///clear all of data inside DataBase Data File and Table File
  Future<AmixDataBaseResponse<void>> clear() async {
    if (!_exists) {
      return AmixDataBaseResponse(
        success: false,
        error: "DataBase doesn't exists",
      );
    }
    await _dataBaseData.writeAsString("");
    await _dataBaseTable.writeAsString("");
    _shouldModifyLastTimeData = await _dataBaseData.lastModified();
    _shouldModifyLastTimeTable = await _dataBaseTable.lastModified();
    await _setTime();
    return AmixDataBaseResponse();
  }

  ///write new Object Inside dataBase
  Future<AmixDataBaseResponse<void>> writeNewObject({
    required String key,
    required Object object,
  }) async {
    //return if dataBase is not Exists
    if (!_exists) {
      return AmixDataBaseResponse(
        success: false,
        error: "DataBase doesn't exists",
      );
    }
    //if key have this things return with false success
    if (key.contains(":") || key.contains("-") || key.contains(".")) {
      return AmixDataBaseResponse(
        success: false,
        error:
            "not a Valid Key. ':' or '-' or '.' this things are not valid Keys",
      );
    }
    //get DataBase data file length
    var dataBaseNewContentLength = await _dataBaseData.length();
    //read DataBase Data File
    String dataBaseData = await _dataBaseData.readAsString();
    //json encode Object
    String byteData = jsonEncode(object);
    //add json encoded object to dataBase Data File
    dataBaseData = "$dataBaseData$byteData";
    //set the data Inside dataBase data file
    await _dataBaseData.writeAsString(dataBaseData);
    //get dataBase Data file length
    var dataBaseNewContentLengthEnd = await _dataBaseData.length();
    //read dataBase Table file
    var dataBaseTable = await _dataBaseTable.readAsString();
    //create the key for finding data inside dataBase data file
    var byteDataTable =
        "$key-$dataBaseNewContentLength-$dataBaseNewContentLengthEnd:";
    //add the key to dataBase Table
    dataBaseTable = "$dataBaseTable$byteDataTable";
    //save Table File
    await _dataBaseTable.writeAsString(dataBaseTable);
    //set new change times for Table and Data file
    await _setTime();
    return AmixDataBaseResponse(
      success: true,
    );
  }

  ///Move the Object to DataBase recycle bin
  Future<AmixDataBaseResponse<void>> removeObject({required String key}) async {
    //return if dataBase is not Exists
    if (!_exists) {
      return AmixDataBaseResponse(
        success: false,
        error: "DataBase doesn't exists",
      );
    }
    //read dataBase Table
    var dataBaseTableString = await _dataBaseTable.readAsString();
    //split Table
    List<String> dataTableList = dataBaseTableString.split(":");
    //search for key inside Table
    for (var i = 0; i < dataTableList.length; i++) {
      try {
        if (dataTableList[i].substring(0, key.length) == key) {
          //if find the key send it to recycle bin
          dataTableList[i] = ".${dataTableList[i]}";
        }
      } catch (e) {
        //
      }
    }
    //recreating dataBase Table
    var newData = "";
    for (var string in dataTableList) {
      if (string.isNotEmpty) {
        newData = "$newData$string:";
      }
    }
    //write to Table
    await _dataBaseTable.writeAsString(newData);
    //set the last time Files changed
    await _setTime();
    return AmixDataBaseResponse(
      success: true,
    );
  }

  ///Get Your Data from DataBase
  Future<AmixDataBaseResponse<Object>> get({required String key}) async {
    //return if dataBase is not Exists
    if (!_exists) {
      return AmixDataBaseResponse(
        success: false,
        error: "DataBase doesn't exists",
      );
    }
    //read the Table
    var dataBaseTableString = await _dataBaseTable.readAsString();
    //split Table
    List<String> dataTableList = dataBaseTableString.split(":");
    //look for Key
    String dataAddress = dataTableList.firstWhere(
      (element) {
        try {
          return element.substring(0, key.length) == key;
        } catch (e) {
          return false;
        }
      },
      orElse: () => "FDE:Error=>400",
    );
    //if data not found return
    if (dataAddress == "FDE:Error=>400") {
      return AmixDataBaseResponse(
        error: "Data doesn't exists!",
      );
    }
    //split address
    List<String> dataAddressList = dataAddress.split("-");
    //data start location
    int startDataLength = int.parse(dataAddressList[1]);
    //data end location
    int endDataLength = int.parse(dataAddressList[2]);
    //read from start byte to end byte
    var dataUTF8 = _dataBaseData.openRead(startDataLength, endDataLength);
    //decode data
    String dataString = await utf8.decodeStream(dataUTF8);
    //return data
    return AmixDataBaseResponse(
      success: true,
      data: jsonDecode(dataString),
    );
  }

  ///Clean Your recycle
  Future<AmixDataBaseResponse<void>> clean() async {
    //return if dataBase is not Exists
    if (!_exists) {
      return AmixDataBaseResponse(
        success: false,
        error: "DataBase doesn't exists",
      );
    }
    //create the lists that gonna save inside Table and DataBase Data file
    List<String> saveListTable = [];
    List<String> saveListData = [];
    //read Table
    var dataBaseTableString = await _dataBaseTable.readAsString();
    //split Table
    List<String> dataTableList = dataBaseTableString.split(":");
    //looking on recycle bin
    for (var i = 0; i < dataTableList.length; i++) {
      try {
        if (!dataTableList[i].contains('.')) {
          var listKey = dataTableList[i].split("-");
          saveListTable.add(listKey[0]);
          int startDataLength = int.parse(listKey[1]);
          int endDataLength = int.parse(listKey[2]);
          var dataUTF8 = _dataBaseData.openRead(startDataLength, endDataLength);
          String dataString = await utf8.decodeStream(dataUTF8);
          saveListData.add(dataString);
        }
        //remove recycled data
      } catch (e) {
        //
      }
    }
    //clear dataBase Data and Table
    await clear();
    //save the Lists
    for (var i = 0; i < saveListData.length; i++) {
      await writeNewObject(
        key: saveListTable[i],
        object: jsonDecode(saveListData[i]),
      );
    }
    //set Update Time
    await _setTime();
    return AmixDataBaseResponse(
      success: true,
    );
  }

  //check the security
  Future<void> _checkSecurity() async {
    //return if dataBase is not Exists
    if (!_exists) {
      return;
    }
    //check security
    var checkUpData =
        _shouldModifyLastTimeData == (await _dataBaseData.lastModified());
    var checkUpTable =
        _shouldModifyLastTimeTable == (await _dataBaseTable.lastModified());
    if (checkUpData && checkUpTable) {
      return;
    }
    print("----------------------=Warning=----------------------\n");
    print(
      "--looks like DataBase files changed without DataBase Permission--\n",
    );
    print("----------------------=Warning=----------------------");
  }

  //update DataBase Change Times
  Future<void> _setTime() async {
    if (!_exists) {
      return;
    }
    _shouldModifyLastTimeData = await _dataBaseData.lastModified();
    _shouldModifyLastTimeTable = await _dataBaseTable.lastModified();
    //set change Times
    await _dataBaseConfig.writeAsString(
      jsonEncode(
        [
          [
            _shouldModifyLastTimeData.year,
            _shouldModifyLastTimeData.month,
            _shouldModifyLastTimeData.day,
            _shouldModifyLastTimeData.hour,
            _shouldModifyLastTimeData.minute,
            _shouldModifyLastTimeData.second,
          ],
          [
            _shouldModifyLastTimeTable.year,
            _shouldModifyLastTimeTable.month,
            _shouldModifyLastTimeTable.day,
            _shouldModifyLastTimeTable.hour,
            _shouldModifyLastTimeTable.minute,
            _shouldModifyLastTimeTable.second,
          ],
        ],
      ),
    );
  }

  ///Start the DataBase
  Future<void> startConfig() async {
    //return if dataBase is not Exists
    if (!_exists) {
      return;
    }
    //check for security
    var result = await _dataBaseConfig.readAsString();
    try {
      List times = jsonDecode(result);
      var dataBaseDataTime = times[0];
      var dataBaseTableTime = times[1];
      if (dataBaseTableTime is List) {
        List<int> times = [];
        for (var value in dataBaseTableTime) {
          if (value is int) {
            times.add(value);
          } else {
            times.add(0);
          }
        }
        if (times.length >= 6) {
          _shouldModifyLastTimeTable = DateTime(
            times[0],
            times[1],
            times[2],
            times[3],
            times[4],
            times[5],
          );
        }
      }
      if (dataBaseDataTime is List) {
        List<int> times = [];
        for (var value in dataBaseDataTime) {
          if (value is int) {
            times.add(value);
          } else {
            times.add(0);
          }
        }
        if (times.length >= 6) {
          _shouldModifyLastTimeData = DateTime(
            times[0],
            times[1],
            times[2],
            times[3],
            times[4],
            times[5],
          );
        }
      }
    } on FormatException {
      if (result.isEmpty) {
        return;
      }
      print("----------------------=Error=----------------------\n");
      print(
        "--The config file is DAMAGED this means someone is changing DataBase Files--",
      );
      print("--DataBase will try to auto Repair itself--\n");
      print("----------------------=Error=----------------------");
    } catch (e) {
      print(e);
    }
    await _checkSecurity();
  }

  ///edit a Object
  Future<AmixDataBaseResponse<void>> editObject({
    required String key,
    required Object object,
  }) async {
    //remove Object once
    var deleteKey = await removeObject(key: key);
    if (deleteKey.success) {
      //if success create Object again
      var addNewObject = await writeNewObject(key: key, object: object);
      if (addNewObject.success) {
        return AmixDataBaseResponse(success: true);
      }
      return AmixDataBaseResponse(
        error: addNewObject.error,
      );
    }
    return AmixDataBaseResponse(
      error: deleteKey.error,
    );
  }
}
