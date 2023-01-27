import 'dart:async';
import 'package:conduit_core/conduit_core.dart';   

class Migration5 extends Migration { 
  @override
  Future upgrade() async {
   		database.createTable(SchemaTable("_History", [SchemaColumn("id", ManagedPropertyType.bigInteger, isPrimaryKey: true, autoincrement: true, isIndexed: false, isNullable: false, isUnique: false),SchemaColumn("title", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: true, isNullable: false, isUnique: true)]));
		database.addColumn("_History", SchemaColumn.relationship("user", ManagedPropertyType.bigInteger, relatedTableName: "_User", relatedColumnName: "id", rule: DeleteRule.cascade, isNullable: false, isUnique: false));
		database.alterColumn("_Finance", "description", (c) {c.isIndexed = true;});
		database.alterColumn("_Finance", "category", (c) {c.isIndexed = true;});
		database.alterColumn("_Finance", "date", (c) {c.isIndexed = true;});
		database.alterColumn("_Finance", "sum", (c) {c.isIndexed = true;});
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    