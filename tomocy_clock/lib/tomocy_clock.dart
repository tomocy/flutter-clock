import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'package:flutter_clock_helper/model.dart';

class ClockApp extends StatelessWidget {
  const ClockApp({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tomocy clock',
      theme: ClockThemeData.light(),
      darkTheme: ClockThemeData.dark(),
      home: LayoutBuilder(
        builder: (context, constraints) {
          final radius = constraints.maxHeight < constraints.maxWidth
              ? constraints.maxHeight * 0.9 / 2
              : constraints.maxWidth * 0.9 / 2;

          return Clock(radius: radius);
        },
      ),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final radius = constraints.maxHeight < constraints.maxWidth
              ? constraints.maxHeight * 0.9 / 2
              : constraints.maxWidth * 0.9 / 2;

          return Clock(
            radius: radius,
            is24Format: widget.model.is24HourFormat,
          );
        },
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
          title: TextStyle(
            color: Colors.black,
          ),
        ),
      );

  static ThemeData dark() => ThemeData(
        brightness: Brightness.dark,
        canvasColor: Colors.black,
        accentColor: Colors.red,
        textTheme: TextTheme(
          title: TextStyle(
            color: Colors.white,
          ),
        ),
      );
}

class Clock extends StatefulWidget {
  const Clock({
    Key key,
    @required this.radius,
    this.is24Format = false,
  }) : super(key: key);

  final double radius;
  final bool is24Format;

  @override
  _ClockState createState() => _ClockState();
}

class _ClockState extends State<Clock> with TickerProviderStateMixin {
  final Map<ClockType, AnimationController> _turnsControllers = {};
  DateTime _displayedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateTurnsControllers();
  }

  @override
  void didUpdateWidget(Clock old) {
    super.didUpdateWidget(old);
    if (widget.is24Format != old.is24Format) {
      _displayedDateTime = DateTime.now();
      _updateTurnsControllers(targets: [ClockType.hours]);
    }
  }

  void _updateTurnsControllers({
    List<ClockType> targets = const [
      ClockType.seconds,
      ClockType.minutes,
      ClockType.hours
    ],
  }) {
    final fromSeconds = _displayedDateTime.second / 60;
    final fromMinutes = (_displayedDateTime.minute + fromSeconds) / 60;
    final fromHours = widget.is24Format
        ? (_displayedDateTime.hour + fromMinutes) / 24
        : (_displayedDateTime.hour % 12 + fromMinutes) / 12;

    if (targets.contains(ClockType.seconds)) {
      _turnsControllers[ClockType.seconds] = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 60),
      )
        ..forward(from: fromSeconds)
        ..repeat();
    }
    if (targets.contains(ClockType.minutes)) {
      _turnsControllers[ClockType.minutes] = AnimationController(
        vsync: this,
        duration: const Duration(minutes: 60),
      )
        ..forward(from: fromMinutes)
        ..repeat();
    }
    if (targets.contains(ClockType.hours)) {
      _turnsControllers[ClockType.hours] = AnimationController(
        vsync: this,
        duration: widget.is24Format
            ? const Duration(hours: 24)
            : const Duration(hours: 12),
      )
        ..forward(from: fromHours)
        ..repeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            _secondsClockFace(
              radius: widget.radius,
              center: _minutesClockFace(
                radius: widget.radius * 3 / 4,
                center: _hoursClockFace(
                  radius: widget.radius / 2,
                  indexStyle: Theme.of(context).textTheme.title,
                ),
                indexStyle: Theme.of(context).textTheme.subtitle,
              ),
              indexStyle: Theme.of(context).textTheme.caption,
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

  ClockFace _secondsClockFace({
    double radius = 0,
    Color color = Colors.transparent,
    Widget center,
    TextStyle indexStyle,
  }) {
    return ClockFace(
      turns: _turnsControllers[ClockType.seconds],
      radius: radius,
      center: center,
      indexes: _generateIndexes(
        60,
        (i) => Text(
          i % 3 == 0 ? '$i' : '・',
          style: indexStyle,
        ),
      ),
    );
  }

  ClockFace _minutesClockFace({
    double radius = 0,
    Color color = Colors.transparent,
    Widget center,
    TextStyle indexStyle,
  }) {
    return ClockFace(
      turns: _turnsControllers[ClockType.minutes],
      radius: radius,
      center: center,
      indexes: _generateIndexes(
        60,
        (i) => Text(
          i % 3 == 0 ? '$i' : '・',
          style: indexStyle,
        ),
      ),
    );
  }

  ClockFace _hoursClockFace({
    double radius = 0,
    Color color = Colors.transparent,
    Widget center,
    TextStyle indexStyle,
  }) {
    return ClockFace(
      turns: _turnsControllers[ClockType.hours],
      radius: radius,
      center: center,
      indexes: widget.is24Format
          ? _generateIndexes(
              24,
              (i) => Text(
                i % 3 == 0 ? '$i' : '・',
                style: indexStyle,
              ),
            )
          : _generateIndexes(
              12,
              _hoursIndexSpecialReplacer(indexStyle) ??
                  (i) => Text(
                        i % 3 == 0 ? i == 0 ? '12' : '$i' : '・',
                        style: indexStyle,
                      ),
            ),
    );
  }

  List<Widget> _generateIndexes(
    int length,
    Widget Function(int) replacer,
  ) =>
      List<int>.generate(length, (i) => (i + length ~/ 4) % length)
          .map((i) => replacer(i))
          .toList();

  Widget Function(int) _hoursIndexSpecialReplacer(TextStyle style) {
    if (_displayedDateTime.month != 4 || _displayedDateTime.day != 1) {
      return null;
    }

    return (i) {
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
    };
  }

  @override
  void dispose() {
    _turnsControllers.forEach((type, controller) => controller.dispose());
    super.dispose();
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
    return RotationTransition(
      turns: ReverseAnimation(turns),
      child: CircleWithInnerEdges(
        radius: radius,
        color: color,
        center: RotationTransition(
          turns: turns,
          child: center,
        ),
        innerEdges: indexes
            .map(
              (index) => RotationTransition(
                turns: turns,
                child: index,
              ),
            )
            .toList(),
      ),
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
    final children = (center != null
        ? <Widget>[
            Align(
              child: center,
            ),
          ]
        : <Widget>[])
      ..addAll(_roundlyPositionedInnerEdges());

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
    var degree = 0.0;

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
