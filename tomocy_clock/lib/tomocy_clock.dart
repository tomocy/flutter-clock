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

class _ClockState extends State<Clock> {
  final Map<ClockType, double> _angles = {
    ClockType.seconds: 45,
    ClockType.minutes: 15,
    ClockType.hours: 10,
  };

  @override
  Widget build(BuildContext context) {
    final radius = 200.0;
    return Center(
      child: _secondsClockFace(
        radius: radius,
        center: _minutesClockFace(
          radius: radius * 3 / 4,
          center: _hoursClockFace(
            radius: radius / 2,
            indexStyle: Theme.of(context).textTheme.title,
          ),
          indexStyle: Theme.of(context).textTheme.subtitle,
        ),
        indexStyle: Theme.of(context).textTheme.caption,
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
      angle: _angles[ClockType.seconds],
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

  ClockFace _minutesClockFace({
    double radius = 0,
    Color color = Colors.transparent,
    Widget center,
    TextStyle indexStyle,
  }) {
    return ClockFace(
      angle: _angles[ClockType.minutes],
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

  ClockFace _hoursClockFace({
    double radius = 0,
    Color color = Colors.transparent,
    Widget center,
    TextStyle indexStyle,
  }) {
    return ClockFace(
      angle: _angles[ClockType.hours],
      radius: radius,
      center: center,
      indexes:
          List<int>.generate(12, (i) => (i + 3) % 12 != 0 ? (i + 3) % 12 : 12)
              .map((i) => Text(
                    i % 3 == 0 ? '$i' : '・',
                    style: indexStyle,
                  ))
              .toList(),
    );
  }
}

enum ClockType { seconds, minutes, hours }

class ClockFace extends StatelessWidget {
  const ClockFace({
    Key key,
    @required this.angle,
    @required this.radius,
    this.color,
    this.center,
    this.indexes = const <Widget>[],
  })  : assert(angle != null),
        assert(radius != null),
        super(key: key);

  final double angle;
  final double radius;
  final Color color;
  final Widget center;
  final List<Widget> indexes;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: CircleWithInnerEdges(
        radius: radius,
        color: color,
        center: Transform.rotate(
          angle: -angle,
          child: center,
        ),
        innerEdges: indexes
            .map(
              (index) => Transform.rotate(
                angle: -angle,
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
