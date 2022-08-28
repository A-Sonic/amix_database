import 'dart:convert';
import 'dart:io';
import 'package:amix_database/src/engine/vars.dart';
import 'models/database_response.dart';

class AmixDataBaseFile {
  final String dataBaseName;

  AmixDataBaseFile(this.dataBaseName) {
    exists();
  }

  DateTime _shouldModifyLastTimeData = DateTime.now();
  DateTime _shouldModifyLastTimeTable = DateTime.now();
  late final Directory _dataBase = Directory("$dataBasePath/$dataBaseName");
  late File _dataBaseTable = File("$dataBasePath/$dataBaseName/table.amidb");
  late File _dataBaseData = File("$dataBasePath/$dataBaseName/data.amidb");
  late File _dataBaseConfig = File("$dataBasePath/$dataBaseName/config.amidb");
  bool _exists = true;

  Future<bool> exists() async {
    var dataBaseFolderExists = await _dataBase.exists();
    var dataBaseTableExists = await _dataBaseTable.exists();
    var dataBaseDataExists = await _dataBaseData.exists();
    var dataBaseConfigExists = await _dataBaseConfig.exists();
    var dataBaseExists = (dataBaseFolderExists &&
        dataBaseTableExists &&
        dataBaseDataExists &&
        dataBaseConfigExists);
    _exists = dataBaseExists;
    return dataBaseExists;
  }

  Future<AmixDataBaseResponse<void>> create() async {
    var isAmixFolderExist = await _dataBase.exists();
    if (isAmixFolderExist) {
      return AmixDataBaseResponse(
        error: "DataBase already exist",
      );
    }
    await _dataBase.create(
      recursive: true,
    );
    _dataBaseData = File("${_dataBase.path}/data.amidb");
    await _dataBaseData.create();
    _dataBaseTable = File("${_dataBase.path}/table.amidb");
    await _dataBaseTable.create();
    _dataBaseConfig = File("${_dataBase.path}/config.amidb");
    await _dataBaseConfig.create();
    _shouldModifyLastTimeData = await _dataBaseData.lastModified();
    _shouldModifyLastTimeTable = await _dataBaseTable.lastModified();
    await _setTime();
    _exists = true;
    return AmixDataBaseResponse(
      success: true,
    );
  }

  Future<AmixDataBaseResponse<void>> delete() async {
    if (!_exists) {
      return AmixDataBaseResponse(
        success: false,
        error: "DataBase doesn't exists",
      );
    }
    await _dataBase.delete(recursive: true);
    return AmixDataBaseResponse(
      success: true,
    );
  }

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

  Future<AmixDataBaseResponse<void>> writeNewObject({
    required String key,
    required Object object,
  }) async {
    if (!_exists) {
      return AmixDataBaseResponse(
        success: false,
        error: "DataBase doesn't exists",
      );
    }
    if (key.contains(":") || key.contains("-") || key.contains(".")) {
      return AmixDataBaseResponse(
        success: false,
        error:
            "not a Valid Key. ':' or '-' or '.' this things are not valid Keys",
      );
    }
    var dataBaseNewContentLength = await _dataBaseData.length();
    String dataBaseData = await _dataBaseData.readAsString();
    String byteData = jsonEncode(object);
    dataBaseData = "$dataBaseData$byteData";
    await _dataBaseData.writeAsString(dataBaseData);
    var dataBaseNewContentLengthEnd = await _dataBaseData.length();
    var dataBaseTable = await _dataBaseTable.readAsString();
    var byteDataTable =
        "$key-$dataBaseNewContentLength-$dataBaseNewContentLengthEnd:";
    dataBaseTable = "$dataBaseTable$byteDataTable";
    await _dataBaseTable.writeAsString(dataBaseTable);
    await _setTime();
    return AmixDataBaseResponse(
      success: true,
    );
  }

  Future<AmixDataBaseResponse<void>> removeObject({required String key}) async {
    if (!_exists) {
      return AmixDataBaseResponse(
        success: false,
        error: "DataBase doesn't exists",
      );
    }
    var dataBaseTableString = await _dataBaseTable.readAsString();
    List<String> dataTableList = dataBaseTableString.split(":");
    for (var i = 0; i < dataTableList.length; i++) {
      try {
        if (dataTableList[i].substring(0, key.length) == key) {
          dataTableList[i] = ".${dataTableList[i]}";
        }
      } catch (e) {
        //
      }
    }

    var newData = "";
    for (var string in dataTableList) {
      if (string.isNotEmpty) {
        newData = "$newData$string:";
      }
    }
    await _dataBaseTable.writeAsString(newData);
    await _setTime();
    return AmixDataBaseResponse(
      success: true,
    );
  }

  Future<AmixDataBaseResponse<Object>> get({required String key}) async {
    if (!_exists) {
      return AmixDataBaseResponse(
        success: false,
        error: "DataBase doesn't exists",
      );
    }
    var dataBaseTableString = await _dataBaseTable.readAsString();
    List<String> dataTableList = dataBaseTableString.split(":");
    String dataAddress = dataTableList.firstWhere(
      (element) {
        try {
          return element.substring(0, key.length) == key;
        } catch (e) {
          return false;
        }
      },
      orElse: () => "FDE Error=>400",
    );
    if (dataAddress == "FDE Error=>400") {
      return AmixDataBaseResponse(
        error: "Data doesn't exists!",
      );
    }
    List<String> dataAddressList = dataAddress.split("-");
    int startDataLength = int.parse(dataAddressList[1]);
    int endDataLength = int.parse(dataAddressList[2]);
    var dataUTF8 = _dataBaseData.openRead(startDataLength, endDataLength);
    String dataString = await utf8.decodeStream(dataUTF8);
    return AmixDataBaseResponse(
      success: true,
      data: jsonDecode(dataString),
    );
  }

  Future<AmixDataBaseResponse<void>> clean() async {
    if (!_exists) {
      return AmixDataBaseResponse(
        success: false,
        error: "DataBase doesn't exists",
      );
    }
    List<String> saveListTable = [];
    List<String> saveListData = [];
    var dataBaseTableString = await _dataBaseTable.readAsString();
    List<String> dataTableList = dataBaseTableString.split(":");
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
      } catch (e) {
        //
      }
    }
    await clear();
    for (var i = 0; i < saveListData.length; i++) {
      await writeNewObject(
        key: saveListTable[i],
        object: jsonDecode(saveListData[i]),
      );
    }
    await _setTime();
    return AmixDataBaseResponse(
      success: true,
    );
  }

  Future<void> _checkSecurity() async {
    if (!_exists) {
      return;
    }
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

  Future<void> _setTime() async {
    if (!_exists) {
      return;
    }
    _shouldModifyLastTimeData = await _dataBaseData.lastModified();
    _shouldModifyLastTimeTable = await _dataBaseTable.lastModified();
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

  Future<void> startConfig() async {
    if (!_exists) {
      return;
    }
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

  Future<AmixDataBaseResponse<void>> editObject({
    required String key,
    required Object object,
  }) async {
    var deleteKey = await removeObject(key: key);
    if (deleteKey.success) {
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
