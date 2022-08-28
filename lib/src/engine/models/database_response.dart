class AmixDataBaseResponse<T> {
  final bool success;
  final String error;
  final T? data;
  final String warning;
  const AmixDataBaseResponse({
    this.success = false,
    this.error = "",
    this.data,
    this.warning = "",
  });
}
