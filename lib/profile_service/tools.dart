part of profile_service;

Map<Type, ApiConfigSchema> __convert_table__ = {};
var __parser__ = new ApiParser();

fromJson(Type t, var json) {
  if (__convert_table__[t] == null) {
    __convert_table__[t] = __parser__.parseSchema(reflectClass(t), false);
  }
  return __convert_table__[t].fromRequest(json);
}

toJson(var obj) {
  var t = obj.runtimeType;
  if (__convert_table__[t] == null) {
    __convert_table__[t] = __parser__.parseSchema(reflectClass(t), false);
  }
  return __convert_table__[t].toResponse(obj);
}