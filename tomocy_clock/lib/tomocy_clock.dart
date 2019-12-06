import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'package:flutter_clock_helper/model.dart';

class ClockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tomocy clock',
      theme: ClockThemeData.light(),
      darkTheme: ClockThemeData.dark(),
      home: const Clock(),
    );
  }
}

class ClockWithModel extends StatefulWidget {
  const ClockWithModel({
    Key key,
    this.model,
  }) : super(key: key);

  final ClockModel model;

  @override
  _ClockWithModelState createState() => _ClockWithModelState();
}

class _ClockWithModelState extends State<ClockWithModel> {
  static const List<DeviceOrientation> preferredOrientations = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(preferredOrientations);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).brightness == Brightness.light
          ? ClockThemeData.light()
          : ClockThemeData.dark(),
      child: Clock(
        is24Format: widget.model.is24HourFormat,
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(preferredOrientations);
    widget.model.dispose();

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
          headline: TextStyle(
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
          headline: TextStyle(
            color: Colors.white,
          ),
        ),
      );
}

class Clock extends StatefulWidget {
  const Clock({
    Key key,
    this.is24Format = false,
  }) : super(key: key);

  final bool is24Format;

  @override
  _ClockState createState() => _ClockState();
}

class _ClockState extends State<Clock> with TickerProviderStateMixin {
  DateTime _dateTime = DateTime.now();
  Map<ClockType, AnimationController> _animationControllers = {};

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

  void _updateAnimationControllers() => setState(() {
        final ofSeconds = _dateTime.second / 60;
        final ofMinutes = (_dateTime.minute + ofSeconds) / 60;
        final ofHours = widget.is24Format
            ? (_dateTime.hour + ofMinutes) / 24
            : (_dateTime.hour % 12 + ofMinutes) / 12;

        _animationControllers[ClockType.seconds] = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 60),
        )
          ..forward(
            from: ofSeconds,
          )
          ..repeat();
        _animationControllers[ClockType.minutes] = AnimationController(
          vsync: this,
          duration: const Duration(minutes: 60),
        )
          ..forward(
            from: ofMinutes,
          )
          ..repeat();
        _animationControllers[ClockType.hours] = AnimationController(
          vsync: this,
          duration: widget.is24Format
              ? const Duration(hours: 24)
              : const Duration(hours: 12),
        )
          ..forward(
            from: ofHours,
          )
          ..repeat();
      });

  @override
  void dispose() {
    _animationControllers.forEach((_, controller) => controller.dispose());

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final radius = constraints.maxHeight < constraints.maxWidth
                ? constraints.maxHeight * 0.9 / 2
                : constraints.maxWidth * 0.9 / 2;

            return Stack(
              alignment: AlignmentDirectional.topCenter,
              children: <Widget>[
                _secondsClockFace(
                  radius: radius,
                  center: _minutesClockFace(
                    radius: radius * 3 / 4,
                    center: _hoursClockFace(
                      radius: radius / 2,
                      indexStyle: 250 <= radius
                          ? Theme.of(context).textTheme.display1
                          : Theme.of(context).textTheme.headline,
                    ),
                    indexStyle: Theme.of(context).textTheme.subtitle,
                  ),
                  indexStyle: Theme.of(context).textTheme.caption,
                ),
                Container(
                  width: 2,
                  height: radius,
                  color: Theme.of(context).accentColor,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _secondsClockFace({
    double radius = 0,
    Color color = Colors.transparent,
    Widget center,
    TextStyle indexStyle,
  }) {
    return ClockFace(
      turns: _animationControllers[ClockType.seconds],
      radius: radius,
      center: center,
      indexes: List<int>.generate(60, (i) => (i + 15) % 60)
          .map((i) => Text(
                i % 3 == 0 ? '$i' : '・',
                style: indexStyle,
              ))
          .toList(),
    );
  }

  Widget _minutesClockFace({
    double radius = 0,
    Color color = Colors.transparent,
    Widget center,
    TextStyle indexStyle,
  }) {
    return ClockFace(
      turns: _animationControllers[ClockType.minutes],
      radius: radius,
      center: center,
      indexes: List<int>.generate(60, (i) => (i + 15) % 60)
          .map((i) => Text(
                i % 3 == 0 ? '$i' : '・',
                style: indexStyle,
              ))
          .toList(),
    );
  }

  Widget _hoursClockFace({
    double radius = 0,
    Color color = Colors.transparent,
    Widget center,
    TextStyle indexStyle,
  }) {
    return ClockFace(
      turns: _animationControllers[ClockType.hours],
      radius: radius,
      center: center,
      indexes: widget.is24Format
          ? List<int>.generate(24, (i) => (i + 6) % 24)
              .map((i) => Text(
                    i % 3 == 0 ? '$i' : '・',
                    style: indexStyle,
                  ))
              .toList()
          : List<int>.generate(12, (i) => (i + 3) % 12)
              .map(
                  (i) => _dateTime.month == DateTime.april && _dateTime.day == 1
                      ? _indexForAprilFool(
                          i,
                          style: indexStyle,
                        )
                      : Text(
                          i % 3 == 0 ? i == 0 ? '12' : '$i' : '・',
                          style: indexStyle,
                        ))
              .toList(),
    );
  }

  Widget _indexForAprilFool(int i, {TextStyle style}) {
    switch (i) {
      case 0:
        return Icon(
          Icons.adb,
          color: style.color,
          size: style.fontSize,
        );
      case 3:
        return Icon(
          Icons.filter_3,
          color: style.color,
          size: style.fontSize,
        );
      case 6:
        return Icon(
          Icons.filter_6,
          color: style.color,
          size: style.fontSize,
        );
      case 9:
        return Icon(
          Icons.filter_9,
          color: style.color,
          size: style.fontSize,
        );
      default:
        return Icon(
          Icons.error_outline,
          color: style.color,
          size: style.fontSize,
        );
    }
  }
}

enum ClockType { seconds, minutes, hours }

class ClockFace extends StatelessWidget {
  const ClockFace({
    Key key,
    @required this.turns,
    @required this.radius,
    this.color,
    this.center,
    this.indexes = const <Widget>[],
  })  : assert(turns != null),
        assert(radius != null),
        super(key: key);

  final Animation<double> turns;
  final double radius;
  final Color color;
  final Widget center;
  final List<Widget> indexes;

  @override
  Widget build(BuildContext context) {
    return _rotating(
      turns: turns,
      inReverse: true,
      child: CircleWithInnerEdges(
        radius: radius,
        color: color,
        center: _rotating(
          turns: turns,
          child: center,
        ),
        innerEdges: indexes
            .map((index) => _rotating(
                  turns: turns,
                  child: index,
                ))
            .toList(),
      ),
    );
  }

  RotationTransition _rotating({
    Animation<double> turns,
    bool inReverse = false,
    Widget child,
  }) {
    return RotationTransition(
      turns: inReverse
          ? Tween<double>(
              begin: 1,
              end: 0,
            ).animate(turns)
          : Tween<double>(
              begin: 0,
              end: 1,
            ).animate(turns),
      child: child,
    );
  }
}

class CircleWithInnerEdges extends StatelessWidget {
  const CircleWithInnerEdges({
    Key key,
    @required this.radius,
    this.color,
    this.center,
    this.innerRadiusRatio = 1,
    this.innerEdges = const <Widget>[],
  })  : assert(radius != null),
        super(key: key);

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
      final radian = vector_math.radians(degree);
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
