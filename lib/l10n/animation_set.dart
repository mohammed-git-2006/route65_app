

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

  bool _ran = false;

  void startOnce() {
    if (!_ran) {
      this.start();
      _ran = true;
    }
  }

  void reverse() {
    controller.reverse();
  }

  void reset() {
    _ran = false;
    controller.reset();
  }

  void whenDone(AnimationSet other) {
    controller.addStatusListener((status) {
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


class AnimationsCollection {
  Map<int, AnimationSet> _animations = new Map<int, AnimationSet>();

  void create(int id, dynamic provider, double s, double e, Duration duration, Curve curve) {
    _animations.addAll({
      id: new AnimationSet()..init(provider, s, e, duration, curve)
    });
  }

  AnimationSet? get(int i) => _animations.containsKey(i) ? _animations[i] : null;
  double value(int i) => _animations.containsKey(i) ? _animations[i]!.value : 0;

  List<int> keys() {
    return _animations.keys.toList();
  }

  void makeTrailDone(int from, int to) {
    for (int i=from;i<to;++i) {
      _animations[i]!.whenDone(_animations[i+1]!);
    }
  }

  void makeTrailHalf(int from, int to) {
    for (int i=from;i<to-1;++i) {
      _animations[i]!.whenHalf(_animations[i+1]!);
    }
  }

  void whenDone(int a, int b) {
    _animations[a]!.whenDone(_animations[b]!);
  }

  void dispose() {
    _animations.forEach((key, value) => value.dispose());
  }

  void start({int? at}) {
    if (at != null) {
      _animations[at]!.start();
    } else {
      _animations[0]!.start();
    }
  }
}