import 'dart:io';

import 'package:conduit/conduit.dart';
import 'package:dart_api/controllers/app_auth_controller.dart';
import 'package:dart_api/controllers/app_finance_controller.dart';
import 'package:dart_api/controllers/app_history_controller.dart';
import 'package:dart_api/controllers/app_search_controller.dart';
import 'package:dart_api/controllers/app_token_controller.dart';
import 'package:dart_api/controllers/app_user_controller.dart';
import 'package:dart_api/model/user.dart';
import 'package:dart_api/model/finance.dart';

import 'controllers/app_finance_logical.dart';

class AppService extends ApplicationChannel {
  late final ManagedContext managedContext;

  @override
  Future prepare() {
    final persistentStore = _initDatabase();

    managedContext = ManagedContext(
        ManagedDataModel.fromCurrentMirrorSystem(), persistentStore);
    return super.prepare();
  }

  @override
  Controller get entryPoint => Router()
    ..route('token/[:refresh]').link(
      () => AppAuthController(managedContext),
    )
    ..route('user').link(AppTokenController.new)!.link(
          () => AppUserController(managedContext),
        )
    ..route('finance/[:id]').link(AppTokenController.new)!.link(
          () => AppFinanceController(managedContext),
        )
    ..route('search').link(AppTokenController.new)!.link(
          () => AppSearchController(managedContext),
        )
    ..route('history').link(AppTokenController.new)!.link(
          () => AppHistoryController(managedContext),
        )
    ..route('logical/[:id]').link(AppTokenController.new)!.link(
          () => AppFinanceLogicalController(managedContext),
        );

  PersistentStore _initDatabase() {
    final username = Platform.environment['DB_USERNAME'] ?? 'postgres';
    final password = Platform.environment['DB_PASSWORD'] ?? '1';
    final host = Platform.environment['DB_HOST'] ?? 'localhost';
    final port = int.parse(Platform.environment['DB_PORT'] ?? '5432');
    final databaseName = Platform.environment['DB_NAME'] ?? 'postgres';
    return PostgreSQLPersistentStore(
        username, password, host, port, databaseName);
  }
}
