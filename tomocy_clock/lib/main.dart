import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(ClockApp());

class ClockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Clock Challenge',
      theme: ClockThemeData.light(),
      darkTheme: ClockThemeData.dark(),
      home: ClockPage(),
    );
  }
}

class ClockThemeData {
  static ThemeData light() => ThemeData(
        brightness: Brightness.light,
        accentColor: Colors.red,
        textTheme: TextTheme(
          display1: TextStyle(
            color: Colors.black,
          ),
        ),
      );

  static ThemeData dark() => ThemeData(
        brightness: Brightness.dark,
        canvasColor: Colors.black,
        accentColor: Colors.red,
        textTheme: TextTheme(
          display1: TextStyle(
            color: Colors.white,
          ),
        ),
      );
}

class ClockPage extends StatefulWidget {
  ClockPage({Key key}) : super(key: key);

  @override
  _ClockPageState createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> with TickerProviderStateMixin {
  DateTime _now = DateTime.now();
  Map<RotatingAnimationControllerName, AnimationController>
      _animationControllers;

  @override
  void initState() {
    super.initState();

    _updateAnimationControllers();
  }

  void _updateAnimationControllers() {
    setState(() {
      final ofSeconds = _now.second / 60;
      final ofMinutes = (_now.minute + ofSeconds) / 60;
      final ofHours = (_now.hour % 12 + ofMinutes) / 12;

      _animationControllers =
          <RotatingAnimationControllerName, AnimationController>{
        RotatingAnimationControllerName.seconds: AnimationController(
          vsync: this,
          duration: const Duration(seconds: 60),
        )
          ..forward(
            from: ofSeconds,
          )
          ..repeat(),
        RotatingAnimationControllerName.minutes: AnimationController(
          vsync: this,
          duration: const Duration(minutes: 60),
        )
          // ..addListener(() => setState(() {}))
          ..forward(
            from: ofMinutes,
          )
          ..repeat(),
        RotatingAnimationControllerName.hours: AnimationController(
          vsync: this,
          duration: const Duration(hours: 12),
        )
          // ..addListener(() => setState(() {}))
          ..forward(
            from: ofHours,
          )
          ..repeat(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = MediaQuery.of(context).size.shortestSide * 0.9 / 2;

    return Scaffold(
      body: Center(
        child: Stack(
          alignment: AlignmentDirectional.topCenter,
          children: <Widget>[
            _buildSecondsClock(
              context,
              radius: radius,
              center: _buildMinutesClock(
                context,
                radius: radius * 3 / 4,
                center: _buildHoursClock(
                  context,
                  radius: radius / 2,
                  innerEdgeTextStyle: Theme.of(context).textTheme.display1,
                ),
                innerEdgeTextStyle: Theme.of(context).textTheme.subtitle,
              ),
              innerEdgeTextStyle: Theme.of(context).textTheme.caption,
            ),
            Container(
              width: 2,
              height: radius,
              color: Theme.of(context).accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondsClock(BuildContext context,
      {double radius = 0,
      Color color = Colors.transparent,
      Widget center,
      TextStyle innerEdgeTextStyle}) {
    return _rotatingTransition(
      parent: _animationControllers[RotatingAnimationControllerName.seconds],
      inReverse: true,
      child: CircleWithInnerEdges(
        radius: radius,
        color: color,
        center: _rotatingTransition(
          parent:
              _animationControllers[RotatingAnimationControllerName.seconds],
          child: center,
        ),
        innerEdges: List<int>.generate(60, (i) => (i + 15) % 60)
            .map((i) => _rotatingTransition(
                  parent: _animationControllers[
                      RotatingAnimationControllerName.seconds],
                  child: Text(
                    i % 3 == 0 ? '$i' : '・',
                    style: innerEdgeTextStyle,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildMinutesClock(BuildContext context,
      {double radius = 0,
      Color color = Colors.transparent,
      Widget center,
      TextStyle innerEdgeTextStyle}) {
    return _rotatingTransition(
      parent: _animationControllers[RotatingAnimationControllerName.minutes],
      inReverse: true,
      child: CircleWithInnerEdges(
        radius: radius,
        color: color,
        center: _rotatingTransition(
          parent:
              _animationControllers[RotatingAnimationControllerName.minutes],
          child: center,
        ),
        innerEdges: List<int>.generate(60, (i) => (i + 15) % 60)
            .map((i) => _rotatingTransition(
                  parent: _animationControllers[
                      RotatingAnimationControllerName.minutes],
                  child: Text(
                    i % 3 == 0 ? '$i' : '・',
                    style: innerEdgeTextStyle,
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildHoursClock(BuildContext context,
      {double radius = 0,
      Color color = Colors.transparent,
      Widget center,
      TextStyle innerEdgeTextStyle}) {
    return _rotatingTransition(
      parent: _animationControllers[RotatingAnimationControllerName.hours],
      inReverse: true,
      child: CircleWithInnerEdges(
        radius: radius,
        color: color,
        center: _rotatingTransition(
          parent: _animationControllers[RotatingAnimationControllerName.hours],
          child: center,
        ),
        innerEdges: List<int>.generate(12, (i) => (i + 3) % 12)
            .map((i) => _rotatingTransition(
                  parent: _animationControllers[
                      RotatingAnimationControllerName.hours],
                  child: Text(
                    i % 3 == 0 ? i == 0 ? '12' : '$i' : '・',
                    style: innerEdgeTextStyle,
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
      final x = radian.abs() != pi / 2 ? innerRadiusRatio * cos(radian) : 0.0;
      final y = radian.abs() != pi ? innerRadiusRatio * sin(radian) : 0.0;
      degree += base;

      return Align(
        alignment: Alignment(x, y),
        child: innerEdge,
      );
    }).toList();
  }
}
