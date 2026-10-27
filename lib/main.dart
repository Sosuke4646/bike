import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
  debugShowCheckedModeBanner: false,
  home: BikeShopApp(),
));

class BikeShopApp extends StatefulWidget {
  const BikeShopApp({super.key});
  @override
  State<BikeShopApp> createState() => _BikeShopAppState();
}

class _BikeShopAppState extends State<BikeShopApp> {
  // 中古車の平均掲載価格を基準にした値（円）
  final bikes = <String, int>{
    'カワサキ ゼファー400': 1424000,
    'ホンダ CBX400F': 4427000,
    'ヤマハ XJ400': 1709000,
    'ホンダ CB250T': 1502000,
    'ヤマハ XJR400': 983000,
  };

  // パーツの参考基準価格（円）。車種・メーカー・仕様によって異なる。
  final customs = <String, Map<String, int>>{
    'マフラー': {
      'ショート管': 35000, '集合管': 48000,
      'メッキマフラー': 55000, 'カーボンサイレンサー': 30000,
    },
    'フロント・風防': {
      '旭風防': 16000, 'ショート風防': 12000,
      'ロケットカウル': 65000, 'ビキニカウル': 22000,
      'フロントフェンダー': 15000,
    },
    'ハンドル': {
      'アップハンドル': 12000, 'ロボハン': 13000,
      'しぼりハンドル': 12000, '純正タイプ': 12000,
    },
    'シート': {
      'タックロール': 55000, 'あんこ抜きシート': 59000,
      '段付きシート': 45000, '三段シート': 65000,
    },
    'ライト・電装': {
      '丸目ヘッドライト': 18000, 'イエローレンズ': 12000,
      'クリアウインカー': 8000,
    },
    'その他小物': {
      '🐤 アヒル': 1100, '📣 ラッパ（装飾用）': 3500,
      'メッキミラー': 8500, 'カスタムグリップ': 6000,
      'エンブレム': 4500, 'ステッカー': 2000,
      'タンデムバー': 15000,
    },
  };

  // 画像は web/images に保存され、外部サイトへアクセスしない。
  final bikePhotos = <String, String>{
    'カワサキ ゼファー400': 'images/bikes/zephyr400.jpg',
    'ホンダ CBX400F': 'images/bikes/cbx400f.jpg',
    'ヤマハ XJ400': 'images/bikes/xj400.jpg',
    'ホンダ CB250T': 'images/bikes/cb250t.jpg',
    'ヤマハ XJR400': 'images/bikes/xjr400.jpg',
  };
  final itemPhotos = <String, String>{
    'ショート管': 'images/parts/short_pipe.jpg',
    '集合管': 'images/parts/full_exhaust.jpg',
    'メッキマフラー': 'images/parts/chrome_exhaust.jpg',
    'カーボンサイレンサー': 'images/parts/carbon_silencer.jpg',
    '旭風防': 'images/parts/asahi_screen.jpg',
    'ショート風防': 'images/parts/short_screen.jpg',
    'ロケットカウル': 'images/parts/rocket_cowl.jpg',
    'ビキニカウル': 'images/parts/bikini_cowl.jpg',
    'フロントフェンダー': 'images/parts/front_fender.jpg',
    'アップハンドル': 'images/parts/up_handle.jpg',
    'ロボハン': 'images/parts/robot_handle.jpg',
    'しぼりハンドル': 'images/parts/squeeze_handle.jpg',
    '純正タイプ': 'images/parts/standard_handle.jpg',
    'タックロール': 'images/parts/tuckroll_seat.jpg',
    'あんこ抜きシート': 'images/parts/low_seat.jpg',
    '段付きシート': 'images/parts/stepped_seat.jpg',
    '三段シート': 'images/parts/three_tier_seat.jpg',
    '丸目ヘッドライト': 'images/parts/round_headlight.jpg',
    'イエローレンズ': 'images/parts/yellow_light.jpg',
    'クリアウインカー': 'images/parts/clear_indicator.jpg',
  };

  late String bike = bikes.keys.first;
  final selected = <String, String>{};
  final accessories = <String>{};
  String? openCategory;
  String? previewItem; // 選択した商品の写真を上に表示
  int order = 0;
  String receipt = '';
  // 写真は web/images から読み込む。URL変化時は key で画像を切替。
  Widget picture(String url, {double? width, double height = 100}) {
    return SizedBox(
      width: width,
      height: height,
      child: url.isEmpty
          ? const Center(child: Icon(Icons.image_not_supported_outlined, size: 35))
          : Image.network(
        url,
        key: ValueKey(url),
        fit: BoxFit.contain,
        gaplessPlayback: false,
        errorBuilder: (_, _, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported_outlined, size: min(height * .30, 50.0)),
              Text('画像未取得', style: TextStyle(fontSize: height < 100 ? 10 : 13)),
            ],
          ),
        ),
      ),
    );
  }

  int price(int base) => (base * 12) ~/ 10;
  String yen(int amount) => '${amount.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}円';

  Widget choices(Iterable<String> items, String value,
      void Function(String) change) => Wrap(spacing: 6, children: [
    for (final s in items)
      ChoiceChip(label: Text(s), selected: value == s,
        onSelected: (_) => setState(() => change(s))),
  ]);

  @override
  Widget build(BuildContext context) {
    int customTotal = 0;
    for (final category in selected.keys) {
      customTotal += price(customs[category]![selected[category]]!);
    }
    for (final item in accessories) {
      customTotal += price(customs['その他小物']![item]!);
    }
    final subtotal = price(bikes[bike]!) + customTotal;
    final tax = subtotal ~/ 10;
    final total = subtotal + tax;

    // アイテム選択時は大きな写真を切り替える。バイク選択時は元の写真に戻る。
    final previewUrl = previewItem == null
        ? bikePhotos[bike]!
        : (itemPhotos[previewItem] ?? '');
    final photo = Column(children: [
      picture(previewUrl, height: 350),
      const SizedBox(height: 5),
      Text(previewItem ?? bike, style: const TextStyle(fontSize: 17)),
      if (previewItem != null)
        TextButton.icon(
          onPressed: () => setState(() => previewItem = null),
          icon: const Icon(Icons.two_wheeler),
          label: const Text('バイクの写真に戻る'),
        ),
    ]);
    final products = Wrap(spacing: 6, runSpacing: 6, children: [
      for (final s in bikes.keys)
        ChoiceChip(
          label: Text('$s  ${yen(price(bikes[s]!))}'),
          selected: bike == s,
          onSelected: (_) => setState(() { bike = s; previewItem = null; }),
        ),
    ]);

    final decorations = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final category in customs.keys) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(category),
            subtitle: Text(category == 'その他小物'
              ? (accessories.isEmpty ? '未選択' : accessories.join('、'))
              : (selected[category] ?? '未選択')),
            trailing: Icon(openCategory == category
              ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onTap: () => setState(() => openCategory =
              openCategory == category ? null : category),
          ),
          if (openCategory == category) ...[
            if (category != 'その他小物')
              choices(['なし'], selected[category] ?? 'なし',
                (_) => selected.remove(category)),
            // 大きな写真＋商品名＋価格。ChoiceChipの小さなavatarを使わない。
            for (final item in customs[category]!.keys)
              InkWell(
                onTap: () => setState(() {
                  previewItem = item;
                  if (category == 'その他小物') {
                    if (!accessories.add(item)) accessories.remove(item);
                  } else {
                    selected[category] = item;
                  }
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    picture(itemPhotos[item] ?? '', width: 125, height: 100),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item, style: const TextStyle(fontSize: 15)),
                        Text(yen(price(customs[category]![item]!)),
                            style: const TextStyle(fontSize: 13)),
                      ],
                    )),
                    Icon((category == 'その他小物'
                        ? accessories.contains(item)
                        : selected[category] == item)
                        ? Icons.check_circle : Icons.circle_outlined),
                  ]),
                ),
              ),
          ],
          const Divider(),
        ],
      ],
    );

    final bill = Column(children: [
      Text('バイク本体 ${yen(price(bikes[bike]!))}'),
      Text('カスタム代 ${yen(customTotal)}'),
      Text('税抜 ${yen(subtotal)} / 消費税 ${yen(tax)}'),
      Text('合計 ${yen(total)}', style: const TextStyle(fontSize: 28)),
    ]);

    final submit = Center(child: FilledButton(
      onPressed: () => setState(() {
        order = Random().nextInt(999) + 1;
        receipt = '$bike  ${yen(price(bikes[bike]!))}\nカスタム内容:\n';
        for (final category in selected.keys) {
          receipt += '$category: ${selected[category]}  '
            '${yen(price(customs[category]![selected[category]]!))}\n';
        }
        receipt += 'その他小物: ${accessories.isEmpty ? 'なし' : accessories.join('、')}\n'
          'カスタム代: ${yen(customTotal)}\n'
          '税抜: ${yen(subtotal)} / 消費税（10%）: ${yen(tax)}\n'
          '合計: ${yen(total)}';
      }),
      child: const Text('注文する'),
    ));

    final ticket = order == 0 ? const SizedBox.shrink() : Card(
      child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('注文番号 #$order', style: const TextStyle(fontSize: 26)),
          Text(receipt),
        ],
      )),
    );

    return Scaffold(
      appBar: AppBar(centerTitle: true,
        title: const Text('🏍️ バイク屋台注文アプリ'),
      ),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: photo),
          const Text('バイクを選ぶ'), products,
          const SizedBox(height: 16),
          const Text('カスタムする'), decorations,
          const Divider(), bill, submit, ticket,
          const Text('※車両は中古掲載平均、パーツは参考基準価格を1.2倍したデモ価格。'
            '送付いただいたパーツ画像を使用。写真と車種の適合は未確認です。'
            '写真と実際の商品・車種の一致、適合や公道使用を保証しません。',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      )),
    );
  }
}
