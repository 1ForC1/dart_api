import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:dart_api/model/history.dart';

import '../model/model_response.dart';
import '../model/user.dart';
import '../utils/app_response.dart';
import '../utils/app_utils.dart';

class AppHistoryController extends ResourceController {
  AppHistoryController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.get()
  Future<Response> getHistory(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.query('page') int page,
  ) async {
    final userId = AppUtils.getIdFromHeader(header);

    final fUser = await managedContext.fetchObjectWithID<User>(userId);

    if (fUser == null) {
      return AppResponse.badRequest(
          message: 'Для данного действия необходима авторизация');
    }

    var pagQuery = Query<History>(managedContext)
      ..pageBy((p) => p.id, QuerySortOrder.ascending)
      ..fetchLimit = 10
      ..where((x) => x.user!.id).equalTo(fUser.id);

    var queryResults = await pagQuery.fetch();
    List<History> list = queryResults;
    if (page > 1) {
      for (int i = 1; i < page; i++) {
        var oldestHistoryWeGot = queryResults.last.id;
        pagQuery = Query<History>(managedContext)
          ..pageBy((p) => p.id, QuerySortOrder.ascending,
              boundingValue: oldestHistoryWeGot)
          ..fetchLimit = 10
          ..where((x) => x.user!.id).equalTo(fUser.id);
        queryResults = await pagQuery.fetch();
        list = queryResults;
      }
    }

    if (list.isEmpty) {
      return AppResponse.ok(message: 'История действий пуста');
    }

    return Response.ok(
      list,
    );
  }
}
