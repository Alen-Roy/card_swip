class Logo {
  final String url;
  final String bgColor;

  Logo({required this.url, required this.bgColor});

  factory Logo.fromJson(Map<String, dynamic> json) =>
      Logo(url: json['url'] ?? '', bgColor: json['bg_color'] ?? '#FFFFFF');
}

class FlipperItem {
  final String text;
  FlipperItem({required this.text});

  factory FlipperItem.fromJson(Map<String, dynamic> json) =>
      FlipperItem(text: json['text'] ?? '');
}

class FlipperConfig {
  final int flipDelay;
  final List<FlipperItem> items;
  final FlipperItem finalStage;

  FlipperConfig({
    required this.flipDelay,
    required this.items,
    required this.finalStage,
  });

  factory FlipperConfig.fromJson(Map<String, dynamic> json) => FlipperConfig(
    flipDelay: json['flip_delay'] ?? 2000,
    items: (json['items'] as List? ?? [])
        .map((e) => FlipperItem.fromJson(e))
        .toList(),
    finalStage: FlipperItem.fromJson(json['final_stage'] ?? {}),
  );
}

class CardBody {
  final Logo logo;
  final String title;
  final String subTitle;
  final String amount;
  final String? footerText;
  final FlipperConfig? flipperConfig;

  CardBody({
    required this.logo,
    required this.title,
    required this.subTitle,
    required this.amount,
    this.footerText,
    this.flipperConfig,
  });

  factory CardBody.fromJson(Map<String, dynamic> json) => CardBody(
    logo: Logo.fromJson(json['logo'] ?? {}),
    title: json['title'] ?? '',
    subTitle: json['sub_title'] ?? '',
    amount: json['payment_amount'] ?? '',
    footerText: json['footer_text'],
    flipperConfig: json['flipper_config'] != null
        ? FlipperConfig.fromJson(json['flipper_config'])
        : null,
  );
}

class BillCard {
  final CardBody body;
  final String cardColor;
  final String ctaTitle;

  BillCard({
    required this.body,
    required this.cardColor,
    required this.ctaTitle,
  });

  factory BillCard.fromJson(Map<String, dynamic> json) {
    final props = json['template_properties'] ?? {};
    final bgColors = props['background']?['color']?['colors'] as List?;
    final cta = props['ctas']?['primary'] ?? {};

    return BillCard(
      body: CardBody.fromJson(props['body'] ?? {}),
      cardColor: bgColors?.isNotEmpty == true ? bgColors!.first : '#FFFFFF',
      ctaTitle: cta['title'] ?? 'Pay Now',
    );
  }
}

class BillSection {
  final String title;
  final List<BillCard> cards;
  final String viewAllText;

  BillSection({
    required this.title,
    required this.cards,
    required this.viewAllText,
  });

  factory BillSection.fromJson(Map<String, dynamic> json) {
    final props = json['template_properties'] ?? {};
    final children = props['child_list'] as List? ?? [];

    return BillSection(
      title: props['body']?['title'] ?? 'UPCOMING BILLS',
      cards: children.map((e) => BillCard.fromJson(e)).toList(),
      viewAllText: props['ctas']?['primary']?['title'] ?? 'view all',
    );
  }
}
