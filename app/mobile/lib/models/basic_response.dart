class BasicResponse {
  final int status;
  final Map<String, dynamic> data;

  BasicResponse(this.status, this.data);

  get statusCode => status;

  @override
  String toString() => "BasicResponse(status: $status, data: $data)";
}