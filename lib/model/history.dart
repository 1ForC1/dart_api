import 'package:conduit/conduit.dart';
import 'package:dart_api/model/user.dart';

class History extends ManagedObject<_History> implements _History {}

class _History {
  @primaryKey
  int? id;
  @Column(indexed: true)
  String? title;
  @Relate(#finances, isRequired: true, onDelete: DeleteRule.cascade)
  User? user;
}
