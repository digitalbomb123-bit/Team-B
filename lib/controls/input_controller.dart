import 'dart:math';
import 'package:flutter/foundation.dart';

/// Central input state controller bridging Flutter UI controls and Flame game.
class InputController extends ChangeNotifier {
  double moveX = 0.0;
  bool isJumping = false;
  bool isFlying = false;
  double aimAngle = 0.0; // Radians
  bool isShooting = false;

  // Track if input came from touch vs keyboard/mouse
  bool usingTouchControls = false;

  void setMoveX(double value) {
    final clamped = value.clamp(-1.0, 1.0);
    if ((clamped - moveX).abs() > 0.01) {
      moveX = clamped;
      notifyListeners();
    }
  }

  void setJumping(bool jumping) {
    if (isJumping != jumping) {
      isJumping = jumping;
      notifyListeners();
    }
  }

  void setFlying(bool flying) {
    if (isFlying != flying) {
      isFlying = flying;
      notifyListeners();
    }
  }

  void setAimAngle(double angle) {
    aimAngle = angle;
    notifyListeners();
  }

  void setShooting(bool shooting) {
    if (isShooting != shooting) {
      isShooting = shooting;
      notifyListeners();
    }
  }

  /// Calculates aim angle from a touch position relative to a center point.
  void setAimFromDelta(double dx, double dy) {
    if (dx.abs() > 2 || dy.abs() > 2) {
      aimAngle = atan2(dy, dx);
      notifyListeners();
    }
  }

  void reset() {
    moveX = 0.0;
    isJumping = false;
    isShooting = false;
    notifyListeners();
  }
}
