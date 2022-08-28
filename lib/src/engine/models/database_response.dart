///DataBase Response Model
class AmixDataBaseResponse<T> {
  ///Function success
  final bool success;

  ///Function error
  final String error;

  ///Function data
  final T? data;

  ///Function warning
  final String warning;

  ///DataBase Response Model
  const AmixDataBaseResponse({
    this.success = false,
    this.error = "",
    this.data,
    this.warning = "",
  });
}
