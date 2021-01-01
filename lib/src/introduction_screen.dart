library introduction_screen;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:introduction_screen/src/model/page_view_model.dart';
import 'package:introduction_screen/src/ui/intro_button.dart';
import 'package:introduction_screen/src/ui/intro_page.dart';

class IntroductionScreen extends StatefulWidget {
  /// All pages of the onboarding
  final List<PageViewModel> pages;

  /// All pages of the onboarding, as a complete widget instead of a PageViewModel
  final List<Widget> rawPages;

  /// Callback when Done button is pressed
  final VoidCallback onDone;

  /// Done button
  final Widget done;

  /// Callback when Skip button is pressed
  final VoidCallback onSkip;

  /// Callback when page change
  final ValueChanged<int> onChange;

  /// Skip button
  final Widget skip;

  /// Next button
  final Widget next;

  /// Is the Skip button should be display
  ///
  /// @Default `false`
  final bool showSkipButton;

  /// Is the Next button should be display
  ///
  /// @Default `true`
  final bool showNextButton;

  /// Is the progress indicator should be display
  ///
  /// @Default `true`
  final bool isProgress;

  /// Enable or not onTap feature on progress indicator
  ///
  /// @Default `true`
  final bool isProgressTap;

  /// Is the user is allow to change page
  ///
  /// @Default `false`
  final bool freeze;

  /// Global background color (only visible when a page has a transparent background color)
  final Color globalBackgroundColor;

  /// Dots decorator to custom dots color, size and spacing
  final DotsDecorator dotsDecorator;

  /// Animation duration in millisecondes
  ///
  /// @Default `350`
  final int animationDuration;

  /// Index of the initial page
  ///
  /// @Default `0`
  final int initialPage;

  /// Flex ratio of the skip button
  ///
  /// @Default `1`
  final int skipFlex;

  /// Flex ratio of the progress indicator
  ///
  /// @Default `1`
  final int dotsFlex;

  /// Flex ratio of the next/done button
  ///
  /// @Default `1`
  final int nextFlex;

  /// Type of animation between pages
  ///
  /// @Default `Curves.easeIn`
  final Curve curve;

  /// Color of buttons
  final Color color;

  /// Color of skip button
  final Color skipColor;

  /// Color of next button
  final Color nextColor;

  /// Color of done button
  final Color doneColor;

  final EdgeInsets controlsMargin;

  const IntroductionScreen(
      {Key key,
      this.pages,
      this.rawPages,
      @required this.onDone,
      @required this.done,
      this.onSkip,
      this.onChange,
      this.skip,
      this.next,
      this.showSkipButton = false,
      this.showNextButton = true,
      this.isProgress = true,
      this.isProgressTap = true,
      this.freeze = false,
      this.globalBackgroundColor,
      this.dotsDecorator = const DotsDecorator(),
      this.animationDuration = 350,
      this.initialPage = 0,
      this.skipFlex = 1,
      this.dotsFlex = 1,
      this.nextFlex = 1,
      this.curve = Curves.easeIn,
      this.color,
      this.skipColor,
      this.nextColor,
      this.doneColor,
      this.controlsMargin =
          const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0)})
      : assert(pages != null || rawPages != null),
        assert(
          (pages != null && pages.length > 0) ||
              (rawPages != null && rawPages.length > 0),
          "You provide at least one page on introduction screen !",
        ),
        assert(onDone != null),
        assert(done != null),
        assert((showSkipButton && skip != null) || !showSkipButton),
        assert(skipFlex >= 0 && dotsFlex >= 0 && nextFlex >= 0),
        assert(initialPage == null || initialPage >= 0),
        super(key: key);

  @override
  IntroductionScreenState createState() => IntroductionScreenState();
}

class IntroductionScreenState extends State<IntroductionScreen> {
  PageController _pageController;
  double _currentPage = 0.0;
  bool _isSkipPressed = false;
  bool _isScrolling = false;

  PageController get controller => _pageController;

  @override
  void initState() {
    super.initState();
    int length =
        (widget.pages != null ? widget.pages.length : widget.rawPages.length) -
            1;
    int initialPage = min(widget.initialPage, length);
    _currentPage = initialPage.toDouble();
    _pageController = PageController(initialPage: initialPage);
  }

  void next() {
    int length =
        (widget.pages != null ? widget.pages.length : widget.rawPages.length) -
            1;
    animateScroll(min(_currentPage.round() + 1, length));
  }

  Future<void> _onSkip() async {
    if (widget.onSkip != null) return widget.onSkip();
    await skipToEnd();
  }

  Future<void> skipToEnd() async {
    setState(() => _isSkipPressed = true);
    int length =
        (widget.pages != null ? widget.pages.length : widget.rawPages.length) -
            1;
    await animateScroll(length);
    if (mounted) {
      setState(() => _isSkipPressed = false);
    }
  }

  Future<void> animateScroll(int page) async {
    setState(() => _isScrolling = true);
    await _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: widget.animationDuration),
      curve: widget.curve,
    );
    if (mounted) {
      setState(() => _isScrolling = false);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    if (metrics is PageMetrics) {
      setState(() => _currentPage = metrics.page);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    int length =
        (widget.pages != null ? widget.pages.length : widget.rawPages.length) -
            1;
    final isLastPage = (_currentPage.round() == length);
    bool isSkipBtn = (!_isSkipPressed && !isLastPage && widget.showSkipButton);

    final skipBtn = IntroButton(
      child: widget.skip,
      color: widget.skipColor ?? widget.color,
      onPressed: isSkipBtn ? _onSkip : null,
    );

    final nextBtn = IntroButton(
      child: widget.next,
      color: widget.nextColor ?? widget.color,
      onPressed: widget.showNextButton && !_isScrolling ? next : null,
    );

    final doneBtn = IntroButton(
      child: widget.done,
      color: widget.doneColor ?? widget.color,
      onPressed: widget.onDone,
    );

    return Scaffold(
      backgroundColor: widget.globalBackgroundColor,
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: PageView(
              controller: _pageController,
              physics: widget.freeze
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              children: widget.pages != null
                  ? widget.pages.map((p) => IntroPage(page: p)).toList()
                  : widget.rawPages,
              onPageChanged: widget.onChange,
            ),
          ),
          Positioned(
            bottom: widget.controlsMargin.bottom,
            left: widget.controlsMargin.left,
            right: widget.controlsMargin.right,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    flex: widget.nextFlex,
                    child: widget.showNextButton
                            ? nextBtn
                            : Opacity(opacity: 0.0, child: nextBtn),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}