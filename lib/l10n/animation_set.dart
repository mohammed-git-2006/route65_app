

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class AnimationSet {
  late AnimationController controller;

  void init(dynamic provider, double s, double e, Duration duration, Curve curve) {
    controller = AnimationController(vsync: provider, duration: duration);
    Tween<double>(begin: s, end: e).animate(controller).addListener(() {
      provider.setState(() {});
    });

    final tween = Tween<double>(begin: s, end: e);
    final curved = CurvedAnimation(parent: controller, curve: curve);

    tween.animate(curved).addListener(() => provider.setState(() {}));
  }


  void start() {
    controller.reset();
    controller.forward();
  }

  void reset() {
    controller.reset();
  }

  void whenDone(AnimationSet other) {
    controller.addStatusListener((status) {
      print('${status}');
      if (status.isCompleted) other.start();
    });
  }

  bool halfCheck = false;

  void whenHalf(AnimationSet other) {
    controller.addListener(() {
      if (controller.value > .5 && !halfCheck) {
        halfCheck = true;
        other.start();
      }
    });
  }

  bool _hasDisposed  = false;

  void dispose() {
    if(!_hasDisposed) {
      controller.dispose();
      _hasDisposed = true;
    }
  }

  double get value => controller.value;
}

Widget ShadowContainer({required Widget? child}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      boxShadow: [
        BoxShadow(color: Colors.grey.shade300, spreadRadius: 2, blurRadius: 4)
      ]
    ),

    child: child,
  );
}
