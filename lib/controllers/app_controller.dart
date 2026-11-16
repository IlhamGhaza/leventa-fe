import 'package:get/get.dart';
import '../models/models.dart';
import '../core/constants.dart';

class AppController extends GetxController {
  // Authentication & Role
  var role = RxnString(); // 'customer' or 'sales'
  
  // Navigation State
  var customerTab = 'home'.obs;
  var salesTab = 'dashboard'.obs;

  // Data
  var favs = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    favs.addAll(['p1', 'p3']);
  }

  bool login(String email, String pass) {
    if (email == "customer@propertyapp.test" && pass == "Customer123!") {
      role.value = "customer";
      customerTab.value = "home";
      Get.offAllNamed('/customer');
      return true;
    }
    if (email == "sales@propertyapp.test" && pass == "Sales123!") {
      role.value = "sales";
      salesTab.value = "dashboard";
      Get.offAllNamed('/sales');
      return true;
    }
    return false;
  }

  void logout() {
    role.value = null;
    Get.offAllNamed('/login');
  }

  void toggleFav(String id) {
    if (favs.contains(id)) {
      favs.remove(id);
    } else {
      favs.add(id);
    }
  }

  bool isFav(String id) => favs.contains(id);

  List<PropItem> get featuredProps => AppData.props.where((p) => p.featured).toList();
  List<PropItem> get latestProps => AppData.props.take(4).toList();
  List<PropItem> get favoriteProps => AppData.props.where((p) => favs.contains(p.id)).toList();
}
