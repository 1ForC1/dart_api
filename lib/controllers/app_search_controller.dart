import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:dart_api/model/finance.dart';

import '../model/history.dart';
import '../model/model_response.dart';
import '../model/user.dart';
import '../utils/app_response.dart';
import '../utils/app_utils.dart';

class AppSearchController extends ResourceController {
  AppSearchController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.get()
  Future<Response> searchFinance(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.query('search') String search,
      @Bind.query('page') int page,
      @Bind.query('filter') String filter) async {
    try {
      final userId = AppUtils.getIdFromHeader(header);

      final fUser = await managedContext.fetchObjectWithID<User>(userId);

      if (fUser == null) {
        return AppResponse.badRequest(
            message: 'Для данного действия необходима авторизация');
      }

      //без фильтра
      var pagQuery = Query<Finance>(managedContext)
        ..pageBy((p) => p.id, QuerySortOrder.ascending)
        ..fetchLimit = 10
        ..where((x) => x.name).contains(search)
        ..where((x) => x.user!.id).equalTo(fUser.id)
        ..where((x) => x.isDeleted).equalTo(false);

      var queryResults = await pagQuery.fetch();

      if (page > 1) {
        for (int i = 1; i < page; i++) {
          var oldestFinanceWeGot = queryResults.last.id;
          pagQuery = Query<Finance>(managedContext)
            ..pageBy((p) => p.id, QuerySortOrder.ascending,
                boundingValue: oldestFinanceWeGot)
            ..fetchLimit = 10
            ..where((x) => x.name).contains(search)
            ..where((x) => x.user!.id).equalTo(fUser.id)
            ..where((x) => x.isDeleted).equalTo(false);

          queryResults = await pagQuery.fetch();
        }
      }

      //применение фильтра
      if (filter != '') {
        pagQuery = Query<Finance>(managedContext)
          ..pageBy((p) => p.id, QuerySortOrder.ascending)
          ..fetchLimit = 10
          ..where((x) => x.name).contains(search)
          ..where((x) => x.user!.id).equalTo(fUser.id)
          ..where((x) => x.category).equalTo(filter)
          ..where((x) => x.isDeleted).equalTo(false);

        queryResults = await pagQuery.fetch();

        if (page > 1) {
          for (int i = 1; i < page; i++) {
            var oldestFinanceWeGot = queryResults.last.id;
            pagQuery = Query<Finance>(managedContext)
              ..pageBy((p) => p.id, QuerySortOrder.ascending,
                  boundingValue: oldestFinanceWeGot)
              ..fetchLimit = 10
              ..where((x) => x.name).contains(search)
              ..where((x) => x.user!.id).equalTo(fUser.id)
              ..where((x) => x.category).equalTo(filter)
              ..where((x) => x.isDeleted).equalTo(false);

            queryResults = await pagQuery.fetch();
          }
        }
      }

      if (queryResults.isEmpty) {
        return Response.notFound(
            body: ModelResponse(data: [], message: "Нет ни одних финансов"));
      }

      for (final e in queryResults) {
        e.backing.removeProperty('user');
        e.backing.removeProperty('isDeleted');
      }

      final qCreateHistory = Query<History>(managedContext)
        ..values.title = "Поиск финансов"
        ..values.user = fUser;

      await qCreateHistory.insert();

      return Response.ok(queryResults);
    } catch (e) {
      return AppResponse.serverError(e, message: 'Ошибка получения данных');
    }
  }
}
