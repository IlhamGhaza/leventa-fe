import 'package:cached_network_image/cached_network_image.dart';
// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../features/properties/data/property_models.dart';
import '../utils/format.dart';

/// Public property photo (disk-cached). Placeholder and error states, no
/// fabricated URLs.
class PropertyPhoto extends StatelessWidget {
  const PropertyPhoto(this.url, {super.key, this.aspectRatio = 16 / 10});
  final String? url;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Widget fallback(IconData icon) => ColoredBox(
      color: c.border.withValues(alpha: 0.5),
      child: Center(child: Icon(icon, color: c.textMuted, size: 32)),
    );
    final u = url;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: u == null || u.isEmpty
          ? fallback(LucideIcons.house)
          : CachedNetworkImage(
              imageUrl: u,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  ColoredBox(color: c.border.withValues(alpha: 0.5)),
              errorWidget: (_, _, _) => fallback(LucideIcons.imageOff),
            ),
    );
  }
}

/// Status chip with text + icon (never color alone).
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.badge});
  final String status;

  /// SOLD / RENTED from the backend.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (label, icon, color) = switch (badge ?? status) {
      'SOLD' ||
      PropertyStatus.sold => ('Terjual', LucideIcons.badgeCheck, c.danger),
      'RENTED' ||
      PropertyStatus.rented => ('Tersewa', LucideIcons.keyRound, c.danger),
      PropertyStatus.available => (
        'Tersedia',
        LucideIcons.circleCheck,
        c.success,
      ),
      PropertyStatus.reserved => ('Dipesan', LucideIcons.clock, c.warning),
      PropertyStatus.maintenance => (
        'Perbaikan',
        LucideIcons.wrench,
        c.warning,
      ),
      PropertyStatus.draft => ('Draf', LucideIcons.pencilLine, c.textMuted),
      PropertyStatus.archived => (
        'Diarsipkan',
        LucideIcons.archive,
        c.textMuted,
      ),
      final s => (PropertyStatus.label(s), LucideIcons.info, c.textMuted),
    };
    return Pill(label: label, icon: icon, color: color);
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: context.t.labelMedium?.copyWith(
            // Darkened toward the text token so small labels reach 4.5:1.
            color: Color.lerp(color, context.c.text, 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// The listing price: the one bold typographic element of a card.
class PriceText extends StatelessWidget {
  const PriceText(this.property, {super.key, this.large = false});
  final PublicProperty property;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = (large ? context.t.headlineSmall : context.t.titleLarge)
        ?.copyWith(
          fontWeight: FontWeight.w800,
          color: property.isHistory ? context.c.textMuted : context.c.text,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    final price = property.displayPrice;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: large ? Fmt.rupiah(price) : Fmt.rupiahCompact(price),
            style: style,
          ),
          TextSpan(
            text: '  ${TransactionType.label(property.transactionType)}',
            style: context.t.bodySmall,
          ),
        ],
      ),
      semanticsLabel:
          '${TransactionType.label(property.transactionType)} ${Fmt.rupiah(price)}',
    );
  }
}

class SpecItem extends StatelessWidget {
  const SpecItem(this.icon, this.text, {super.key, this.semantic});
  final IconData icon;
  final String text;
  final String? semantic;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semantic,
    excludeSemantics: semantic != null,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: context.c.textMuted),
        const SizedBox(width: 4),
        Text(text, style: context.t.bodySmall?.copyWith(color: context.c.text)),
      ],
    ),
  );
}

/// List card for every role (list items are always the public shape).
class PropertyCard extends StatefulWidget {
  const PropertyCard(
    this.p, {
    super.key,
    required this.onTap,
    this.showStatus = false,
  });
  final PublicProperty p;
  final VoidCallback onTap;

  /// Internal lists show the raw status; public lists only SOLD/RENTED.
  final bool showStatus;

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool _focused = false;
  PublicProperty get p => widget.p;
  VoidCallback get onTap => widget.onTap;
  bool get showStatus => widget.showStatus;

  @override
  Widget build(BuildContext context) {
    final badge = p.statusBadge;
    return Card(
      clipBehavior: Clip.antiAlias,
      // The photo hides InkWell's own focus tint, so draw a ring (D-pad/keyboard only).
      shape: _focused
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.card),
              side: BorderSide(color: context.c.text, width: 3),
            )
          : null,
      child: InkWell(
        onFocusChange: (f) => setState(
          () => _focused =
              f &&
              FocusManager.instance.highlightMode ==
                  FocusHighlightMode.traditional,
        ),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PropertyPhoto(p.coverUrl),
                if (badge != null || showStatus)
                  Positioned(
                    left: Gap.s,
                    top: Gap.s,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.c.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: StatusChip(p.status, badge: badge),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PriceText(p),
                  const SizedBox(height: Gap.xs),
                  Text(
                    p.name,
                    style: context.t.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    '${PropertyType.label(p.type)} · ${p.locationLabel}',
                    style: context.t.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Gap.s),
                  Wrap(
                    spacing: Gap.m,
                    runSpacing: Gap.xs,
                    children: [
                      if (p.bedrooms > 0)
                        SpecItem(
                          LucideIcons.bedDouble,
                          '${p.bedrooms}',
                          semantic: '${p.bedrooms} kamar tidur',
                        ),
                      if (p.bathrooms > 0)
                        SpecItem(
                          LucideIcons.bath,
                          '${p.bathrooms}',
                          semantic: '${p.bathrooms} kamar mandi',
                        ),
                      if (p.landArea != null)
                        SpecItem(
                          LucideIcons.landPlot,
                          'LT ${Fmt.area(p.landArea)}',
                        ),
                      if (p.buildingArea != null)
                        SpecItem(
                          LucideIcons.building2,
                          'LB ${Fmt.area(p.buildingArea)}',
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled block on detail screens.
class SectionBlock extends StatelessWidget {
  const SectionBlock({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.l),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: context.t.titleMedium),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: Gap.s),
        child,
      ],
    ),
  );
}

/// Label/value rows; skips empty values.
class InfoTable extends StatelessWidget {
  const InfoTable(this.rows, {super.key});
  final List<(String, String?)> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows
        .where((r) => r.$2 != null && r.$2!.isNotEmpty && r.$2 != '-')
        .toList();
    if (visible.isEmpty) {
      return Text('Belum ada data.', style: context.t.bodySmall);
    }
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Gap.m,
                vertical: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      visible[i].$1,
                      style: context.t.bodyMedium?.copyWith(
                        color: context.c.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.m),
                  Expanded(
                    child: Text(
                      visible[i].$2!,
                      textAlign: TextAlign.end,
                      style: context.t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Initials extends StatelessWidget {
  const Initials(this.text, {super.key, this.size = 44});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CircleAvatar(
      radius: size / 2,
      backgroundColor: context.c.primary.withValues(alpha: 0.12),
      child: Text(
        text,
        style: context.t.titleSmall?.copyWith(
          color: context.c.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

/// Centers content at a readable width on tablets.
class Readable extends StatelessWidget {
  const Readable({super.key, required this.child, this.maxWidth = 760});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class Breakpoints {
  const Breakpoints._();
  static const rail = 840.0;
  static bool wide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= rail;
}
