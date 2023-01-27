import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:dart_api/utils/app_response.dart';
import 'package:dart_api/utils/app_utils.dart';

import '../model/finance.dart';
import '../model/history.dart';
import '../model/model_response.dart';
import '../model/user.dart';

class AppFinanceLogicalController extends ResourceController {
  AppFinanceLogicalController(this.managedContext);

  final ManagedContext managedContext;

  @Operation.put('id')
  Future<Response> recoveryFinance(
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

      final qUpdateFinance = Query<Finance>(managedContext)
        ..where((element) => element.id).equalTo(id)
        ..values.isDeleted = false;

      final qCreateHistory = Query<History>(managedContext)
        ..values.title = "Восстановление финанса"
        ..values.user = fUser;

      await qCreateHistory.insert();

      await qUpdateFinance.update();
      return AppResponse.ok(
        message: 'Успешное восстановление финанса',
      );
    } catch (e) {
      return AppResponse.serverError(e,
          message: 'Ошибка восстановления финансов');
    }
  }

  @Operation.delete('id')
  Future<Response> logicalDeleteFinance(
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

      final qUpdateFinance = Query<Finance>(managedContext)
        ..where((element) => element.id).equalTo(id)
        ..values.isDeleted = true;

      final qCreateHistory = Query<History>(managedContext)
        ..values.title = "Логическое удаление финанса"
        ..values.user = fUser;

      await qCreateHistory.insert();

      await qUpdateFinance.update();
      return AppResponse.ok(
        message: 'Успешное логическое удаление финансов',
      );
    } catch (e) {
      return AppResponse.serverError(e,
          message: 'Ошибка логического удаления финансов');
    }
  }
}
