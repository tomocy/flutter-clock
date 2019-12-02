import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_clock_helper/model.dart';

class ClockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Clock Challenge',
      theme: ClockThemeData.light(),
      darkTheme: ClockThemeData.dark(),
      home: Clock(),
    );
  }
}

class ClockWithModel extends StatefulWidget {
  ClockWithModel(this._model, {Key key}) : super(key: key);

  final ClockModel _model;

  @override
  _ClockWithModelState createState() => _ClockWithModelState();
}

class _ClockWithModelState extends State<ClockWithModel> {
  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).brightness == Brightness.light
          ? ClockThemeData.light()
          : ClockThemeData.dark(),
      child: Clock(
        is24Format: widget._model.is24HourFormat,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    super.dispose();
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

class Clock extends StatefulWidget {
  Clock({Key key, this.is24Format}) : super(key: key);

  final bool is24Format;

  @override
  _ClockState createState() => _ClockState();
}

class _ClockState extends State<Clock> with TickerProviderStateMixin {
  DateTime _dateTime = DateTime.now();
  Map<RotatingAnimationControllerName, AnimationController>
      _animationControllers;

  @override
  void initState() {
    super.initState();

    _updateAnimationControllers();
  }

  @override
  void didUpdateWidget(Clock old) {
    super.didUpdateWidget(old);

    if (widget.is24Format != old.is24Format) {
      _updateAnimationControllers();
    }
  }

  void _updateAnimationControllers() {
    setState(() {
      final ofSeconds = _dateTime.second / 60;
      final ofMinutes = (_dateTime.minute + ofSeconds) / 60;
      final ofHours = widget.is24Format
          ? (_dateTime.hour + ofMinutes) / 24
          : (_dateTime.hour % 12 + ofMinutes) / 12;

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
          ..forward(
            from: ofMinutes,
          )
          ..repeat(),
        RotatingAnimationControllerName.hours: AnimationController(
          vsync: this,
          duration: widget.is24Format
              ? const Duration(hours: 24)
              : Duration(hours: 12),
        )
          ..forward(
            from: ofHours,
          )
          ..repeat(),
      };
    });
  }

  @override
  void dispose() {
    _animationControllers.forEach((_, controller) => controller.dispose());

    super.dispose();
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
            parent:
                _animationControllers[RotatingAnimationControllerName.hours],
            child: center,
          ),
          innerEdges: widget.is24Format
              ? List<int>.generate(24, (i) => (i + 6) % 24)
                  .map((i) => _rotatingTransition(
                        parent: _animationControllers[
                            RotatingAnimationControllerName.hours],
                        child: Text(
                          i % 3 == 0 ? '$i' : '・',
                          style: innerEdgeTextStyle,
                        ),
                      ))
                  .toList()
              : List<int>.generate(12, (i) => (i + 3) % 12)
                  .map((i) => _rotatingTransition(
                        parent: _animationControllers[
                            RotatingAnimationControllerName.hours],
                        child: Text(
                          i % 3 == 0 ? i == 0 ? '12' : '$i' : '・',
                          style: innerEdgeTextStyle,
                        ),
                      ))
                  .toList()),
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
