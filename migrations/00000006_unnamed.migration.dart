import 'dart:async';
import 'package:conduit_core/conduit_core.dart';   

class Migration6 extends Migration { 
  @override
  Future upgrade() async {
   		database.addColumn("_Finance", SchemaColumn("isDeleted", ManagedPropertyType.boolean, isPrimaryKey: false, autoincrement: false, isIndexed: true, isNullable: false, isUnique: false));
		database.alterColumn("_Finance", "category", (c) {c.isNullable = false;});
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    