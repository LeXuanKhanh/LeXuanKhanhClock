// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'container_hand.dart';
import 'drawn_hand.dart';
import 'package:flare_flutter/flare_actor.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock>
    with TickerProviderStateMixin {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  var _condition = '';
  var _location = '';

  Timer _timer;
  var colors = [
    Colors.red.shade500,
    Colors.orange.shade500,
    Colors.yellow.shade500,
    Colors.green.shade500,
    Colors.blue.shade500,
    Colors.indigo.shade500,
    Colors.purple.shade500
  ];

  AnimationController controller;
  Animation<double> radianAnim;
  Animation colorAnim;

  @override
  void initState() {
    super.initState();

    controller =
        new AnimationController(duration: Duration(seconds: 10), vsync: this)
          ..addListener(() => setState(() {}));

    radianAnim =
        Tween(begin: _now.second.toDouble(), end: _now.second.toDouble() + 60.0)
            .animate(controller);

    colorAnim = TweenSequence<Color>(listTweenSequenceItemOf(colors))
        .animate(controller);

    controller.repeat();

    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  static List<TweenSequenceItem<Color>> listTweenSequenceItemOf(
      List<Color> colors) {
    final l = List<TweenSequenceItem<Color>>(colors.length);
    for (int i = 0; i < colors.length; i++) {
      final a = colors[i];
      final b = i < colors.length - 1 ? colors[i + 1] : colors[0];
      l[i] = TweenSequenceItem(tween: ColorTween(begin: a, end: b), weight: 1);
    }
    return l;
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _condition = widget.model.weatherString;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  Widget numberText(String text, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          text,
          style: TextStyle(
              color: Colors.white,
              fontSize: 35,
              shadows: [Shadow(color: colorAnim.value, blurRadius: 20)]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].
    final customTheme = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context).copyWith(
            // Hour hand.
            primaryColor: Color(0xFF4285F4),
            // Minute hand.
            highlightColor: Color(0xFF8AB4F8),
            // Second hand.
            accentColor: Color(0xFF669DF6),
            backgroundColor: Color(0xFFD2E3FC),
          )
        : Theme.of(context).copyWith(
            primaryColor: Color(0xFFD2E3FC),
            highlightColor: Color(0xFF4285F4),
            accentColor: Color(0xFF8AB4F8),
            backgroundColor: Color(0xFF3C4043),
          );

    final time = DateFormat.Hms().format(DateTime.now());
    final weatherInfo = DefaultTextStyle(
      style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          shadows: [Shadow(color: Colors.white, blurRadius: 20)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_temperature),
          // https://rive.app/a/superatom/files/flare/weather-icon/preview
          Text(_temperatureRange),
          Text(_location),
        ],
      ),
    );

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Container(
          color: customTheme.backgroundColor,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              children: [
                numberText("12", Alignment.topCenter),
                numberText("3", Alignment.centerRight),
                numberText("6", Alignment.bottomCenter),
                numberText("9", Alignment.centerLeft),
                Positioned(
                  left: constraints.maxWidth / 2 - 58,
                  top: constraints.maxHeight / 2 - 50,
                  child: Container(
                      margin: EdgeInsets.all(10),
                      width: 100,
                      height: 100,
                      child: FlareActor("assets/weather.flr",
                          alignment: Alignment.center,
                          fit: BoxFit.cover,
                          animation: _condition)),
                ),
                Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.white,
                              spreadRadius: 5.0,
                              blurRadius: 30)
                        ]),
                  ),
                ),
                ContainerHand(
                  color: Colors.transparent,
                  size: 0.5,
                  angleRadians: radianAnim.value * radiansPerTick,
                  child: Transform.translate(
                    offset: Offset(0.0, -120.0),
                    child: Container(
                      width: 10,
                      height: 250,
                      decoration: BoxDecoration(
                          borderRadius: new BorderRadius.only(
                              topLeft: const Radius.circular(40.0),
                              topRight: const Radius.circular(40.0)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: colorAnim.value,
                                spreadRadius: 5.0,
                                blurRadius: 30)
                          ]),
                    ),
                  ),
                ),
                ContainerHand(
                  color: Colors.transparent,
                  size: 0.5,
                  angleRadians: _now.minute * radiansPerTick,
                  child: Transform.translate(
                    offset: Offset(0.0, -100.0),
                    child: Container(
                      width: 10,
                      height: 200,
                      decoration: BoxDecoration(
                          borderRadius: new BorderRadius.only(
                              topLeft: const Radius.circular(40.0),
                              topRight: const Radius.circular(40.0)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.white,
                                spreadRadius: 5.0,
                                blurRadius: 30)
                          ]),
                    ),
                  ),
                ),
                ContainerHand(
                  color: Colors.transparent,
                  size: 0.5,
                  angleRadians: _now.hour * radiansPerHour +
                      (_now.minute / 60) * radiansPerHour,
                  child: Transform.translate(
                    offset: Offset(0.0, -70.0),
                    child: Container(
                      width: 10,
                      height: 150,
                      decoration: BoxDecoration(
                          borderRadius: new BorderRadius.only(
                              topLeft: const Radius.circular(40.0),
                              topRight: const Radius.circular(40.0)),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.white,
                                spreadRadius: 5.0,
                                blurRadius: 30)
                          ]),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Padding(
                      padding: const EdgeInsets.all(8), child: weatherInfo),
                ),
              ],
            ),
          )),
    );
  }
}
