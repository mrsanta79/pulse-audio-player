import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.center,
    this.velocity = 28,
    this.pauseDuration = const Duration(milliseconds: 1200),
    this.edgeFade = 10,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final double velocity;
  final Duration pauseDuration;

  /// Width in logical pixels of the soft fade at each end while scrolling.
  final double edgeFade;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  final _scrollController = ScrollController();
  bool _needsScroll = false;
  bool _looping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
      _needsScroll = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _measure() async {
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 1) {
      if (_needsScroll) setState(() => _needsScroll = false);
      return;
    }
    if (!_needsScroll) setState(() => _needsScroll = true);

    // Only ever run a single animation loop, regardless of how many times
    // _measure is triggered by rebuilds or text changes.
    if (_looping) return;
    _looping = true;
    try {
      while (mounted && _scrollController.hasClients) {
        final extent = _scrollController.position.maxScrollExtent;
        if (extent <= 1) break;
        final durationMs = (extent / widget.velocity * 1000).round();

        await Future<void>.delayed(widget.pauseDuration);
        if (!mounted || !_scrollController.hasClients) break;
        await _scrollController.animateTo(
          extent,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        );
        await Future<void>.delayed(widget.pauseDuration);
        if (!mounted || !_scrollController.hasClients) break;
        await _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.linear,
        );
      }
    } finally {
      _looping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scroller = SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: _needsScroll
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              textAlign: widget.textAlign,
              style: widget.style,
            ),
          ),
        );

        // When the title is long enough to scroll, fade both edges so the text
        // dissolves into the background instead of hard-cutting at the screen
        // edge. Short (centered) titles are left untouched.
        if (!_needsScroll) return scroller;
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) {
            // A fixed-width fade: as a fraction of the width it would grow with
            // the widget and wash out whole characters at the ends.
            final fade = bounds.width > 0
                ? (widget.edgeFade / bounds.width).clamp(0.0, 0.2)
                : 0.0;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, fade, 1 - fade, 1.0],
            ).createShader(bounds);
          },
          child: scroller,
        );
      },
    );
  }
}
