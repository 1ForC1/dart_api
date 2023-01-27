import 'dart:async';
import 'package:conduit_core/conduit_core.dart';   

class Migration4 extends Migration { 
  @override
  Future upgrade() async {
   		database.deleteColumn("_Finance", "salt");
		database.deleteColumn("_Finance", "hashPassword");
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    