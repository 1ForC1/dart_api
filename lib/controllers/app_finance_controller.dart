import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:dart_api/utils/app_response.dart';
import 'package:dart_api/utils/app_utils.dart';

import '../model/finance.dart';
import '../model/history.dart';
import '../model/model_response.dart';
import '../model/user.dart';

class AppFinanceController extends ResourceController {
  AppFinanceController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.get()
  Future<Response> getAllFinance(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.query('page') int page,
  ) async {
    final userId = AppUtils.getIdFromHeader(header);

    final fUser = await managedContext.fetchObjectWithID<User>(userId);

    if (fUser == null) {
      return AppResponse.badRequest(
          message: 'Для данного действия необходима авторизация');
    }

    var pagQuery = Query<Finance>(managedContext)
      ..pageBy((p) => p.id, QuerySortOrder.ascending)
      ..fetchLimit = 10
      ..where((x) => x.user!.id).equalTo(fUser.id)
      ..where((x) => x.isDeleted).equalTo(false);

    var queryResults = await pagQuery.fetch();
    List<Finance> list = queryResults;
    if (page > 1) {
      for (int i = 1; i < page; i++) {
        var oldestFinanceWeGot = queryResults.last.id;
        pagQuery = Query<Finance>(managedContext)
          ..pageBy((p) => p.id, QuerySortOrder.ascending,
              boundingValue: oldestFinanceWeGot)
          ..fetchLimit = 10
          ..where((x) => x.user!.id).equalTo(fUser.id);
        queryResults = await pagQuery.fetch();
        list = queryResults;
      }
    }

    for (final e in list) {
      e.backing.removeProperty('user');
      e.backing.removeProperty('isDeleted');
    }

    if (list.isEmpty) {
      return Response.notFound(
          body: ModelResponse(data: [], message: "Нет ни одних финансов"));
    }

    final qCreateHistory = Query<History>(managedContext)
      ..values.title = "Просмотр всех финансов"
      ..values.user = fUser;

    await qCreateHistory.insert();

    return Response.ok(
      list,
    );
  }

  @Operation.get("id")
  Future<Response> getFinance(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path("id") int id,
  ) async {
    final userId = AppUtils.getIdFromHeader(header);

    final fUser = await managedContext.fetchObjectWithID<User>(userId);

    if (fUser == null) {
      return AppResponse.badRequest(
          message: 'Для данного действия необходима авторизация');
    }

    final fFinance = await managedContext.fetchObjectWithID<Finance>(id);

    if (fFinance == null) {
      return AppResponse.ok(message: 'Финанс не найден');
    }

    if (fFinance.user!.id != fUser.id) {
      return AppResponse.ok(message: 'Доступ запрещён');
    }

    final qCreateHistory = Query<History>(managedContext)
      ..values.title = "Просмотр финанса"
      ..values.user = fUser;

    await qCreateHistory.insert();

    fFinance.backing.removeProperty('user');
    fFinance.backing.removeProperty('isDeleted');
    return Response.ok(fFinance);
  }

  @Operation.post()
  Future<Response> createFinance(
      @Bind.header(HttpHeaders.authorizationHeader) String header,
      @Bind.body() Finance finance) async {
    if (finance.operationNumber == null ||
        finance.name == null ||
        finance.description == null ||
        finance.category == null ||
        finance.date == null ||
        finance.sum == null) {
      return Response.badRequest(
          body: ModelResponse(
              message: 'Не все обязательные поля были заполнены'));
    }

    try {
      late final int id;

      final userId = AppUtils.getIdFromHeader(header);

      final fUser = await managedContext.fetchObjectWithID<User>(userId);

      if (fUser == null) {
        return AppResponse.badRequest(
            message: 'Для данного действия необходима авторизация');
      }
      await managedContext.transaction((transaction) async {
        final qCreateFinance = Query<Finance>(transaction)
          ..values.operationNumber = finance.operationNumber
          ..values.name = finance.name
          ..values.description = finance.description
          ..values.category = finance.category
          ..values.date = finance.date
          ..values.sum = finance.sum
          ..values.isDeleted = false
          ..values.user = fUser;

        final createdFinance = await qCreateFinance.insert();

        id = createdFinance.id!;
      });

      final qCreateHistory = Query<History>(managedContext)
        ..values.title = "Добавление финанса"
        ..values.user = fUser;

      await qCreateHistory.insert();

      return AppResponse.ok(message: 'Успешное добавление');
    } on QueryException catch (e) {
      return Response.serverError(body: ModelResponse(message: e.message));
    }
  }

  @Operation.put('id')
  Future<Response> updateFinance(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path("id") int id,
    @Bind.body() Finance finance,
  ) async {
    try {
      final idUser = AppUtils.getIdFromHeader(header);

      final fUser = await managedContext.fetchObjectWithID<User>(idUser);

      if (fUser == null) {
        return AppResponse.badRequest(
            message: 'Для данного действия необходима авторизация');
      }

      final fFinance = await managedContext.fetchObjectWithID<Finance>(id);

      if (fFinance == null) {
        return AppResponse.ok(message: 'Финансы не найдены');
      }

      if (fFinance.user!.id != fUser.id) {
        return AppResponse.ok(message: 'Доступ запрещён');
      }

      final qUpdateFinance = Query<Finance>(managedContext)
        ..where((element) => element.id).equalTo(id)
        ..values.operationNumber = finance.operationNumber
        ..values.name = finance.name
        ..values.description = finance.description
        ..values.category = finance.category
        ..values.date = finance.date
        ..values.sum = finance.sum;

      final qCreateHistory = Query<History>(managedContext)
        ..values.title = "Изменение финанса"
        ..values.user = fUser;

      await qCreateHistory.insert();

      await qUpdateFinance.update();
      return AppResponse.ok(
        message: 'Успешное обновление данных финансов',
      );
    } catch (e) {
      return AppResponse.serverError(e,
          message: 'Ошибка обновления данных финансов');
    }
  }

  @Operation.delete("id")
  Future<Response> deleteFinance(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path("id") int id,
  ) async {
    try {
      final idUser = AppUtils.getIdFromHeader(header);

      final fUser = await managedContext.fetchObjectWithID<User>(idUser);

      if (fUser == null) {
        return AppResponse.badRequest(
            message: 'Для данного действия необходима авторизация');
      }

      final fFinance = await managedContext.fetchObjectWithID<Finance>(id);

      if (fFinance == null) {
        return AppResponse.ok(message: 'Финансы не найдены');
      }

      if (fFinance.user!.id != fUser.id) {
        return AppResponse.ok(message: 'Доступ запрещён');
      }

      final qFinance = Query<Finance>(managedContext)
        ..where((x) => x.id).equalTo(id);
      await qFinance.delete();

      final qCreateHistory = Query<History>(managedContext)
        ..values.title = "Удаление финанса"
        ..values.user = fUser;

      await qCreateHistory.insert();

      return AppResponse.ok(message: "Успешное удаление финансов");
    } catch (error) {
      return AppResponse.serverError(error,
          message: "Ошибка удаления финансов");
    }
  }
}
