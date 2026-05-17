import 'package:flutter/material.dart';

import '../constants/colors.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({required this.child, this.maxWidth = 1180, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: auroraCream),
      child: CustomPaint(
        painter: const RetroConfettiPainter(),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class RetroConfettiPainter extends CustomPainter {
  const RetroConfettiPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = auroraInk.withAlpha(36);

    for (var x = -32.0; x < size.width; x += 112) {
      for (var y = -18.0; y < size.height; y += 96) {
        paint.color = auroraInk.withAlpha(46);
        canvas.drawCircle(Offset(x + 26, y + 24), 11, paint);

        paint.color = auroraBlue.withAlpha(42);
        canvas.drawRect(Rect.fromLTWH(x + 72, y + 54, 22, 22), paint);

        final triangle = Path()
          ..moveTo(x + 24, y + 76)
          ..lineTo(x + 42, y + 48)
          ..lineTo(x + 58, y + 78)
          ..close();
        paint.color = auroraGreen.withAlpha(38);
        canvas.drawPath(triangle, paint);

        final squiggle = Path()
          ..moveTo(x + 78, y + 14)
          ..quadraticBezierTo(x + 94, y + 2, x + 108, y + 14)
          ..quadraticBezierTo(x + 122, y + 28, x + 140, y + 14);
        canvas.drawPath(squiggle, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RetroPanel extends StatelessWidget {
  const RetroPanel({
    required this.child,
    this.color = auroraCream,
    this.padding = const EdgeInsets.all(18),
    this.shadowOffset = const Offset(8, 8),
    this.borderWidth = 4,
    super.key,
  });

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final Offset shadowOffset;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: auroraInk, width: borderWidth),
        boxShadow: [
          BoxShadow(color: auroraShadow, blurRadius: 0, offset: shadowOffset),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class RetroButton extends StatelessWidget {
  const RetroButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.height = 54,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;
  final double height;

  @override
  Widget build(BuildContext context) {
    final foreground = isPrimary ? auroraWhite : auroraInk;
    final background = isPrimary ? auroraYellow : auroraGreen;

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: onPressed == null
              ? const []
              : const [
                  BoxShadow(
                    color: auroraShadow,
                    blurRadius: 0,
                    offset: Offset(5, 5),
                  ),
                ],
        ),
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 20),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: auroraBlue,
            disabledForegroundColor: auroraCream,
            shape: const RoundedRectangleBorder(),
            side: const BorderSide(color: auroraInk, width: 3),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class RetroIconButton extends StatelessWidget {
  const RetroIconButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,
    this.isPrimary = false,
    this.size = 56,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isPrimary ? auroraBlue : auroraGreen,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: auroraWhite, width: 3),
                  left: BorderSide(color: auroraWhite, width: 3),
                  right: BorderSide(color: auroraInk, width: 3),
                  bottom: BorderSide(color: auroraInk, width: 3),
                ),
              ),
              child: Icon(
                icon,
                color: isPrimary ? auroraWhite : auroraInk,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RetroAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RetroAppBar({
    required this.title,
    this.leadingIcon,
    this.onLeadingPressed,
    this.actions = const [],
    super.key,
  });

  final String title;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingPressed;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(86);

  @override
  Widget build(BuildContext context) {
    final hasLeading = leadingIcon != null || onLeadingPressed != null;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 78,
      backgroundColor: auroraCream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 24,
      title: Row(
        children: [
          RetroIconButton(
            tooltip: hasLeading ? 'Back' : 'Home',
            icon: leadingIcon ?? Icons.home_rounded,
            isPrimary: !hasLeading,
            onPressed: onLeadingPressed,
          ),
          const SizedBox(width: 18),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: auroraInk,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
                shadows: [Shadow(color: auroraWhite, offset: Offset(2, 2))],
              ),
            ),
          ),
        ],
      ),
      actions: [
        for (final action in actions)
          Padding(padding: const EdgeInsets.only(right: 14), child: action),
        const SizedBox(width: 10),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(8),
        child: Container(
          height: 8,
          decoration: const BoxDecoration(
            color: auroraInk,
            border: Border(
              top: BorderSide(color: auroraWhite, width: 2),
              bottom: BorderSide(color: auroraInk, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}

class RetroWindowBar extends StatelessWidget {
  const RetroWindowBar({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: auroraYellow,
        border: Border(
          top: BorderSide(color: auroraWhite, width: 2),
          left: BorderSide(color: auroraWhite, width: 2),
          right: BorderSide(color: auroraInk, width: 2),
          bottom: BorderSide(color: auroraInk, width: 2),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: auroraWhite,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          for (final label in ['_', '[ ]', 'X'])
            Container(
              width: 28,
              height: 24,
              margin: const EdgeInsets.only(right: 4),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: auroraCream,
                border: Border(
                  top: BorderSide(color: auroraWhite, width: 2),
                  left: BorderSide(color: auroraWhite, width: 2),
                  right: BorderSide(color: auroraInk, width: 2),
                  bottom: BorderSide(color: auroraInk, width: 2),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: auroraInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RetroFeaturePill extends StatelessWidget {
  const RetroFeaturePill({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: auroraGreen,
        border: Border.all(color: auroraInk, width: 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: auroraInk, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: auroraInk,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class TapeData {
  const TapeData({
    required this.title,
    required this.keyword,
    required this.color,
    this.height = 176,
    this.width = 58,
  });

  final String title;
  final String keyword;
  final Color color;
  final double height;
  final double width;
}

class TapeShelf extends StatelessWidget {
  const TapeShelf({
    required this.tapes,
    required this.onTapePressed,
    super.key,
  });

  final List<TapeData> tapes;
  final ValueChanged<TapeData> onTapePressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rowCount = constraints.maxWidth < 720 ? 3 : 2;
        final rows = _splitTapes(tapes, rowCount);

        return RetroPanel(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final row in rows) ...[
                _TapeShelfRow(tapes: row, onTapePressed: onTapePressed),
                const _WoodShelf(),
              ],
            ],
          ),
        );
      },
    );
  }

  List<List<TapeData>> _splitTapes(List<TapeData> items, int rowCount) {
    final rows = List.generate(rowCount, (_) => <TapeData>[]);
    for (var index = 0; index < items.length; index += 1) {
      rows[index % rowCount].add(items[index]);
    }
    return rows.where((row) => row.isNotEmpty).toList();
  }
}

class _TapeShelfRow extends StatelessWidget {
  const _TapeShelfRow({required this.tapes, required this.onTapePressed});

  final List<TapeData> tapes;
  final ValueChanged<TapeData> onTapePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 216,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color.fromARGB(210, 198, 212, 144),
        border: Border(
          top: BorderSide(color: auroraWhite, width: 3),
          left: BorderSide(color: auroraWhite, width: 3),
          right: BorderSide(color: auroraInk, width: 3),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final tape in tapes)
              TapeSpine(
                key: ValueKey('tape-${tape.title}'),
                tape: tape,
                onPressed: () => onTapePressed(tape),
              ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class TapeSpine extends StatefulWidget {
  const TapeSpine({required this.tape, required this.onPressed, super.key});

  final TapeData tape;
  final VoidCallback onPressed;

  @override
  State<TapeSpine> createState() => _TapeSpineState();
}

class _TapeSpineState extends State<TapeSpine> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        label: '${widget.tape.title} tape',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            offset: Offset(0, _isHovered ? -0.04 : 0),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              scale: _isHovered ? 1.015 : 1,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    width: widget.tape.width + 12,
                    height: widget.tape.height,
                    decoration: BoxDecoration(
                      color: auroraWhite,
                      border: Border.all(color: auroraInk, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: auroraShadow,
                          blurRadius: 0,
                          offset: Offset(4, _isHovered ? 7 : 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.tape.color,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 14,
                          bottom: 14,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: auroraWhite.withAlpha(220),
                              border: Border.all(color: auroraInk, width: 2),
                            ),
                          ),
                        ),
                        const Positioned(
                          top: 26,
                          bottom: 26,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [TapeReel(), TapeReel()],
                          ),
                        ),
                        Center(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: SizedBox(
                              width: widget.tape.height - 104,
                              height: widget.tape.width - 22,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  TapeTitleFormatter.twoLineTitle(
                                    widget.tape.title,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                  softWrap: false,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: auroraInk,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class TapeTitleFormatter {
  static String twoLineTitle(String title) {
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.length <= 1) return title;

    var bestBreak = 1;
    var bestScore = double.infinity;

    for (var index = 1; index < words.length; index += 1) {
      final firstLine = words.take(index).join(' ');
      final secondLine = words.skip(index).join(' ');
      final score = (firstLine.length - secondLine.length).abs().toDouble();
      if (score < bestScore) {
        bestScore = score;
        bestBreak = index;
      }
    }

    return '${words.take(bestBreak).join(' ')}\n'
        '${words.skip(bestBreak).join(' ')}';
  }
}

class TapeReel extends StatelessWidget {
  const TapeReel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: auroraInk,
        shape: BoxShape.circle,
        border: Border.all(color: auroraGreen, width: 3),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: auroraInk,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _WoodShelf extends StatelessWidget {
  const _WoodShelf();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: const BoxDecoration(
        color: auroraGreen,
        border: Border(
          top: BorderSide(color: auroraWhite, width: 3),
          bottom: BorderSide(color: auroraInk, width: 4),
          left: BorderSide(color: auroraWhite, width: 3),
          right: BorderSide(color: auroraInk, width: 4),
        ),
      ),
    );
  }
}

class RetroScanlines extends StatelessWidget {
  const RetroScanlines({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const RetroScanlinePainter());
  }
}

class RetroScanlinePainter extends CustomPainter {
  const RetroScanlinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = auroraInk.withAlpha(46)
      ..strokeWidth = 2;

    for (var y = 0.0; y < size.height; y += 8) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
