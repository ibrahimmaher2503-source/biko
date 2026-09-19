import 'package:app_core/app_core.dart';

enum UserOperationalResource { activeOrder, history }

Set<UserOperationalResource> userResourcesFor(OperationalNotification event) =>
    {
      UserOperationalResource.activeOrder,
      if (const {'COMPLETED', 'CANCELLED', 'EXPIRED'}.contains(event.type))
        UserOperationalResource.history,
    };

String userRouteForOrderNotification({
  required String? orderId,
  required bool terminal,
}) => terminal && orderId != null ? '/orders/$orderId' : '/home';
