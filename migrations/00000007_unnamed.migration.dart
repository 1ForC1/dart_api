import 'dart:async';
import 'package:conduit_core/conduit_core.dart';   

class Migration7 extends Migration { 
  @override
  Future upgrade() async {
   		database.alterColumn("_History", "title", (c) {c.isUnique = false;});
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    