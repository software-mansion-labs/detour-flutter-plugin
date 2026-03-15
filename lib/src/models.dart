enum LinkType { deferred, verified, scheme }

enum LinkProcessingMode {
  all,
  webOnly,
  deferredOnly;

  String get value {
    switch (this) {
      case LinkProcessingMode.all:
        return 'all';
      case LinkProcessingMode.webOnly:
        return 'web-only';
      case LinkProcessingMode.deferredOnly:
        return 'deferred-only';
    }
  }
}

enum DetourEventName {
  login,
  search,
  share,
  signUp,
  tutorialBegin,
  tutorialComplete,
  reEngage,
  invite,
  openedFromPushNotification,
  addPaymentInfo,
  addShippingInfo,
  addToCart,
  removeFromCart,
  refund,
  viewItem,
  beginCheckout,
  purchase,
  adImpression;

  String get rawValue {
    switch (this) {
      case DetourEventName.login:
        return 'login';
      case DetourEventName.search:
        return 'search';
      case DetourEventName.share:
        return 'share';
      case DetourEventName.signUp:
        return 'sign_up';
      case DetourEventName.tutorialBegin:
        return 'tutorial_begin';
      case DetourEventName.tutorialComplete:
        return 'tutorial_complete';
      case DetourEventName.reEngage:
        return 're_engage';
      case DetourEventName.invite:
        return 'invite';
      case DetourEventName.openedFromPushNotification:
        return 'opened_from_push_notification';
      case DetourEventName.addPaymentInfo:
        return 'add_payment_info';
      case DetourEventName.addShippingInfo:
        return 'add_shipping_info';
      case DetourEventName.addToCart:
        return 'add_to_cart';
      case DetourEventName.removeFromCart:
        return 'remove_from_cart';
      case DetourEventName.refund:
        return 'refund';
      case DetourEventName.viewItem:
        return 'view_item';
      case DetourEventName.beginCheckout:
        return 'begin_checkout';
      case DetourEventName.purchase:
        return 'purchase';
      case DetourEventName.adImpression:
        return 'ad_impression';
    }
  }
}

class DetourConfig {
  final String apiKey;
  final String appID;
  final bool shouldUseClipboard;
  final LinkProcessingMode linkProcessingMode;

  const DetourConfig({
    required this.apiKey,
    required this.appID,
    this.shouldUseClipboard = true,
    this.linkProcessingMode = LinkProcessingMode.all,
  });
}

class DetourLink {
  final String url;
  final String route;
  final String pathname;
  final Map<String, String> params;
  final LinkType type;

  const DetourLink({
    required this.url,
    required this.route,
    required this.pathname,
    required this.params,
    required this.type,
  });

  factory DetourLink.fromMap(Map<dynamic, dynamic> map) {
    final typeStr = map['type'] as String? ?? 'verified';
    final LinkType type;
    switch (typeStr) {
      case 'deferred':
        type = LinkType.deferred;
        break;
      case 'scheme':
        type = LinkType.scheme;
        break;
      default:
        type = LinkType.verified;
    }
    final paramsRaw = map['params'] as Map? ?? {};
    final params = paramsRaw.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );
    return DetourLink(
      url: map['url'] as String? ?? '',
      route: map['route'] as String? ?? '',
      pathname: map['pathname'] as String? ?? '',
      params: params,
      type: type,
    );
  }
}

class DetourResult {
  final bool processed;
  final DetourLink? link;

  const DetourResult({required this.processed, this.link});

  factory DetourResult.fromMap(Map<dynamic, dynamic> map) {
    final linkMap = map['link'] as Map?;
    return DetourResult(
      processed: map['processed'] as bool? ?? false,
      link: linkMap != null ? DetourLink.fromMap(linkMap) : null,
    );
  }
}
