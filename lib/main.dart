import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(ClockApp());

class ClockApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Clock Challenge',
      theme: ThemeData.light(),
      home: ClockPage(
        radius: 300,
        inReverse: true,
      ),
    );
  }
}

class ClockPage extends StatefulWidget {
  ClockPage({Key key, this.radius, this.inReverse = false}) : super(key: key);

  final double radius;
  final bool inReverse;

  @override
  _ClockPageState createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> with TickerProviderStateMixin {
  Map<RotatingAnimationControllerName, AnimationController>
      _animationControllers;

  @override
  void initState() {
    super.initState();
    _animationControllers =
        <RotatingAnimationControllerName, AnimationController>{
      RotatingAnimationControllerName.seconds: AnimationController(
        vsync: this,
        duration: const Duration(seconds: 60),
      )
        ..addListener(() => setState(() {}))
        ..repeat(),
      RotatingAnimationControllerName.minutes: AnimationController(
        vsync: this,
        duration: const Duration(minutes: 60),
      )
        ..addListener(() => setState(() {}))
        ..repeat(),
      RotatingAnimationControllerName.hours: AnimationController(
        vsync: this,
        duration: const Duration(hours: 60),
      )
        ..addListener(() => setState(() {}))
        ..repeat(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: AlignmentDirectional.topCenter,
          children: <Widget>[
            _buildSecondsClock(
              context,
              radius: widget.radius,
              center: _buildMinutesClock(
                context,
                radius: widget.radius * 2 / 3,
                center: _buildHoursClock(
                  context,
                  radius: widget.radius / 3,
                ),
              ),
            ),
            Container(
              width: 2,
              height: widget.radius,
              color: Theme.of(context).accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondsClock(BuildContext context,
      {double radius = 0, Color color = Colors.transparent, Widget center}) {
    return _rotatingTransition(
      parent: _animationControllers[RotatingAnimationControllerName.seconds],
      inReverse: widget.inReverse,
      child: CircleWithInnerEdges(
        radius: radius,
        color: color,
        center: _rotatingTransition(
          parent:
              _animationControllers[RotatingAnimationControllerName.seconds],
          inReverse: !widget.inReverse,
          child: center,
        ),
        innerEdges: List<int>.generate(60, (i) => (i + 15) % 60)
            .map((i) => _rotatingTransition(
                  parent: _animationControllers[
                      RotatingAnimationControllerName.seconds],
                  inReverse: !widget.inReverse,
                  child: Text(
                    i % 3 == 0 ? '$i' : '・',
                    style: Theme.of(context).textTheme.caption,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMinutesClock(BuildContext context,
      {double radius = 0, Color color = Colors.transparent, Widget center}) {
    return _rotatingTransition(
      parent: _animationControllers[RotatingAnimationControllerName.minutes],
      inReverse: widget.inReverse,
      child: CircleWithInnerEdges(
        radius: radius,
        color: color,
        center: _rotatingTransition(
          parent:
              _animationControllers[RotatingAnimationControllerName.minutes],
          inReverse: !widget.inReverse,
          child: center,
        ),
        innerEdges: List<int>.generate(60, (i) => (i + 15) % 60)
            .map((i) => _rotatingTransition(
                  parent: _animationControllers[
                      RotatingAnimationControllerName.minutes],
                  inReverse: !widget.inReverse,
                  child: Text(
                    i % 3 == 0 ? '$i' : '・',
                    style: Theme.of(context).textTheme.subtitle,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildHoursClock(BuildContext context,
      {double radius = 0, Color color = Colors.transparent, Widget center}) {
    return _rotatingTransition(
      parent: _animationControllers[RotatingAnimationControllerName.hours],
      inReverse: widget.inReverse,
      child: CircleWithInnerEdges(
        radius: radius,
        color: color,
        center: _rotatingTransition(
          parent: _animationControllers[RotatingAnimationControllerName.hours],
          inReverse: !widget.inReverse,
          child: center,
        ),
        innerEdges:
            List<int>.generate(12, (i) => (i + 3) % 12 != 0 ? (i + 3) % 12 : 12)
                .map((i) => _rotatingTransition(
                      parent: _animationControllers[
                          RotatingAnimationControllerName.hours],
                      inReverse: !widget.inReverse,
                      child: Text(
                        i % 3 == 0 ? '$i' : '・',
                        style: Theme.of(context).textTheme.display1,
                      ),
                    ))
                .toList(),
      ),
    );
  }

  RotationTransition _rotatingTransition(
      {AnimationController parent, bool inReverse = false, Widget child}) {
    final tween = !inReverse
        ? Tween<double>(
            begin: 0,
            end: 1,
          )
        : Tween<double>(
            begin: 1,
            end: 0,
          );

    return RotationTransition(
      turns: tween.animate(parent),
      child: child,
    );
  }
}

enum RotatingAnimationControllerName { seconds, minutes, hours }

class CircleWithInnerEdges extends StatelessWidget {
  CircleWithInnerEdges(
      {this.radius,
      this.color,
      this.center,
      this.innerRadiusRatio = 1,
      this.innerEdges = const <Widget>[]});

  final double radius;
  final Color color;
  final Widget center;
  final double innerRadiusRatio;
  final List<Widget> innerEdges;

  @override
  Widget build(BuildContext context) {
    final children = center != null
        ? <Widget>[
            Align(
              child: center,
            ),
          ]
        : <Widget>[];
    children.addAll(_roundlyPositionedInnerEdges());

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: Stack(
        children: children,
      ),
    );
  }

  List<Widget> _roundlyPositionedInnerEdges() {
    final base = 360 / innerEdges.length;
    double degree = 0;

    return innerEdges.map((innerEdge) {
      final radian = degree * pi / 180;
      final x = radian.abs() != pi / 2 ? innerRadiusRatio * cos(radian) : 0;
      final y = radian.abs() != pi ? innerRadiusRatio * sin(radian) : 0;
      degree += base;

      return Align(
        alignment: Alignment(x, y),
        child: innerEdge,
      );
    }).toList();
  }
}
