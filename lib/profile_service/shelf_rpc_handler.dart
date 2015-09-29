part of profile_service;

/// Creates a Shelf [Handler] that translates Shelf [Request]s to rpc's
/// [HttpApiRequest] executes the request on the given [ApiServer] and then
/// translates the returned rpc's [HttpApiResponse] to a Shelf [Response].
Handler createRpcHandler(ApiServer apiServer) {
  return (Request request) {
    try {
      var apiRequest = new HttpApiRequest(request.method, request.requestedUri,
      request.headers, request.read());
      return apiServer.handleHttpApiRequest(apiRequest).then(
              (apiResponse) {
            return new Response(apiResponse.status, body: apiResponse.body,
            headers: apiResponse.headers);
          });
    } catch (e) {
      // Should never happen since the apiServer.handleHttpRequest method
      // always returns a response.
      return new Response.internalServerError(body: e.toString());
    }
  };
}

Middleware headerPatchMiddleware() {
  return createMiddleware(requestHandler: modifyOptionsRequestHeader, responseHandler: modifyResponseHeader);
}

Map<String, String> _headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': "origin, x-requested-with, content-type, accept, username, password, companyId",
  'Access-Control-Allow-Methods': "GET, POST, PUT, DELETE, PATCH, OPTIONS"
};

Response modifyOptionsRequestHeader(Request request) {
  return (request.method == 'OPTIONS' ? new Response.ok(null, headers: _headers) : null);
}

Response modifyResponseHeader(Response res) {
  res.change(headers: {"access-control-allow-headers": (res.headers["access-control-allow-headers"] ?? ", ")+ "username, password, companyId"});
  return res;
}