import 'package:conduit/conduit.dart';
import 'package:dart_api/model/user.dart';

class Finance extends ManagedObject<_Finance> implements _Finance {}

class _Finance {
  @primaryKey
  int? id;
  @Column(unique: true, indexed: true)
  String? operationNumber;
  @Column(indexed: true)
  String? name;
  @Column(nullable: true, indexed: true)
  String? description;
  @Column(indexed: true)
  String? category;
  @Column(nullable: true, indexed: true)
  DateTime? date;
  @Column(nullable: true, indexed: true)
  double? sum;
  @Column(nullable: false, indexed: true)
  bool? isDeleted;
  @Relate(#finances, isRequired: true, onDelete: DeleteRule.cascade)
  User? user;
}
