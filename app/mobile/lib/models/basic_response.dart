class BasicResponse {
  final int status;
  final dynamic data;

  BasicResponse(this.status, [this.data]);

  int get statusCode => status;

  @override
  String toString() => "BasicResponse(status: $status, data: $data)";
}