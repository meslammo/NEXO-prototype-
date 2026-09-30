// NEXO CHANGE 30 — integrated Ludo engine
// Adapted from the open-source Fludo Flutter project:
// https://github.com/smokelaboratory/fludo
// Original license: Apache-2.0 (see third_party/fludo/LICENSE)

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AppColors {
  static Color home1 = Colors.redAccent;
  static const Color home2 = Colors.greenAccent;
  static const Color home3 = Colors.yellowAccent;
  static const Color home4 = Colors.blueAccent;
  static const Color player1 = Colors.red;
  static const Color player2 = Colors.green;
  static const Color player3 = Colors.yellow;
  static const Color player4 = Colors.blue;
  static const Color safeSpot = Color(0xffC0C0C0);
}

class CollisionDetails {
  bool isReverse = false;
  late int targetPlayerIndex, pawnIndex;
}

class PlayersPainter extends CustomPainter {
  Offset playerCurrentSpot;
  Color playerColor;

  PlayersPainter(
      {required this.playerCurrentSpot, required this.playerColor});

  late double _playerSize, _playerInnerSize, _stepSize;
  Paint _playerPaint = Paint()..style = PaintingStyle.fill;
  Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = Colors.black;

  @override
  void paint(Canvas canvas, Size size) {
    _stepSize = size.width / 15;
    _playerSize = _stepSize / 3;
    _playerInnerSize = _playerSize / 2.5;

    _drawPlayerShape(canvas, playerCurrentSpot, playerColor);
  }

  void _drawPlayerShape(Canvas canvas, Offset pos, Color color) {
    _playerPaint.color = color;
    canvas.drawCircle(pos, _playerSize, _playerPaint);
    canvas.drawCircle(pos, _playerSize, _strokePaint);

    _playerPaint.color = Colors.white;
    canvas.drawCircle(pos, _playerInnerSize, _playerPaint);
    canvas.drawCircle(pos, _playerInnerSize, _strokePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  @override
  bool hitTest(Offset position) => false; //to pass touches to layer beneath
}

class PlayersNotifier with ChangeNotifier  {
  bool _shoulPaintPlayers = false;

  get shoulPaintPlayers => _shoulPaintPlayers;

  void rebuildPaint() {
    _shoulPaintPlayers = true;
    notifyListeners();
  }
}

class DiceNotifier extends ChangeNotifier {
  bool _isRolled = false;
  int _output = 1;

  get isRolled => _isRolled;
  get output => _output;

  rollDice() async {
    _isRolled = false;
    var rollCounter = 0;

    do {
      _generateOutputAndNotify();
      await Future.delayed(Duration(milliseconds: 100));
      rollCounter++;
    } while (rollCounter != 5);

    _isRolled = true;
    _generateOutputAndNotify();
  }

  _generateOutputAndNotify() {
    _output = 1 + Random().nextInt(6);
    notifyListeners();
  }
}

class DiceBasePainter extends CustomPainter {
  double _startAngle;

  DiceBasePainter(this._startAngle);

  @override
  void paint(Canvas canvas, Size size) {
    var radius = size.width;

    var center = Offset(size.width / 2, size.width / 2);
    var acrAngle = 30 * pi / 180;

    for (int arcIndex = 0; arcIndex < 12; arcIndex++) {
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          _startAngle,
          acrAngle,
          false,
          Paint()
            ..color = arcIndex % 2 == 0 ? Colors.orange : Colors.white
            ..strokeWidth = 7
            ..style = PaintingStyle.stroke);

      _startAngle += acrAngle;
    }

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.orangeAccent
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DicePaint extends CustomPainter {
  int _number;

  DicePaint(this._number);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(5)),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);

    var dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    var centerComponent = size.width / 2;
    var semiCenterComponent = size.width / 3.5;
    var semiComponent = size.width - size.width / 3.5;

    switch (_number) {
      case 1:
        canvas.drawCircle(
            Offset(centerComponent, centerComponent), size.width / 8, dotPaint);
        break;
      case 2:
        var radius = size.width / 10;
        canvas.drawCircle(
            Offset(semiCenterComponent, semiCenterComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(semiComponent, semiComponent), radius, dotPaint);
        break;
      case 3:
        var radius = size.width / 12;
        canvas.drawCircle(
            Offset(semiCenterComponent, semiCenterComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(centerComponent, centerComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(semiComponent, semiComponent), radius, dotPaint);
        break;
      case 4:
        var radius = size.width / 10;
        canvas.drawCircle(
            Offset(semiCenterComponent, semiCenterComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(semiComponent, semiCenterComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(semiComponent, semiComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(semiCenterComponent, semiComponent), radius, dotPaint);
        break;
      case 5:
      var radius = size.width / 12;
        canvas.drawCircle(
            Offset(semiCenterComponent, semiCenterComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(semiComponent, semiCenterComponent), radius, dotPaint);
        canvas.drawCircle(Offset(semiComponent, semiComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(semiCenterComponent, semiComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(centerComponent, centerComponent), radius, dotPaint);
        break;
      case 6:
      var radius = size.width / 15;
        canvas.drawCircle(
            Offset(semiComponent, centerComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(semiCenterComponent, centerComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(semiCenterComponent, semiCenterComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(semiComponent, semiCenterComponent), radius, dotPaint);
        canvas.drawCircle(Offset(semiComponent, semiComponent), radius, dotPaint);
        canvas.drawCircle(
            Offset(semiCenterComponent, semiComponent), radius, dotPaint);
        break;
      default:
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class ResultNotifier with ChangeNotifier {
  List<int> _ranks = [0, 0, 0, 0];

  get ranks => _ranks;

  void rebuildPaint(int winnerPlayerIndex) {
    var nextRank = 0;
    _ranks.forEach((rank) {
      if (rank > nextRank) nextRank = rank;
    });
    _ranks[winnerPlayerIndex] = ++nextRank;

    if (nextRank == 3)  //assign rank to last player
      _ranks[_ranks.indexWhere((rank) {
        return rank == 0;
      })] = 4;
      
    notifyListeners();
  }
}

class ResultPainter extends CustomPainter {
  List<int> _ranks;

  ResultPainter(this._ranks);

  @override
  void paint(Canvas canvas, Size size) {
    var stepSize = size.width / 15;
    var homeStartOffset = stepSize * 9;
    var homeSize = stepSize * 6;

    for (int playerIndex = 0; playerIndex < _ranks.length; playerIndex++) {
      var rank = _ranks[playerIndex];
      if (rank != 0) {
        double left, top;
        switch (playerIndex) {
          case 0:
            left = 0;
            top = 0;
            break;
          case 1:
            left = homeStartOffset;
            top = 0;
            break;
          case 2:
            left = homeStartOffset;
            top = homeStartOffset;
            break;
          default:
            left = 0;
            top = homeStartOffset;
        }
        _drawRank(canvas, Rect.fromLTWH(left, top, homeSize, homeSize), rank);
      }
    }
  }

  _drawRank(Canvas canvas, Rect rect, int rank) {
    canvas.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.black54);

    var rankTextPainter = TextPainter(
        text: TextSpan(
          text: _getRankText(rank),
          style: TextStyle(
              fontSize: 50.0,
              color: Colors.white,
              fontFamily: "LuckiestGuy",
              height: 1.5),
        ),
        textDirection: TextDirection.ltr)
      ..layout();

    rankTextPainter.paint(
        canvas,
        Offset(rect.center.dx - rankTextPainter.width / 2,
            rect.center.dy - rankTextPainter.height / 2));
  }

  String _getRankText(int rank) {
    String suffix;

    switch (rank) {
      case 1:
        suffix = "st";
        break;
      case 2:
        suffix = "nd";
        break;
      case 3:
        suffix = "rd";
        break;
      default:
        suffix = "th";
    }

    return "$rank$suffix";
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  @override
  bool hitTest(Offset position) => false; //to pass touches to layer beneath
}

class BoardPainter extends CustomPainter {
  Function(List<List<List<Rect>>>) trackCalculationListener;

  BoardPainter({required this.trackCalculationListener});

  late double _stepSize, _homeStartOffset, _homeSize, _canvasCenter;
  List<List<Offset>> _homeSpotsList = [];

  Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = Colors.black;

  @override
  void paint(Canvas canvas, Size size) {
    _stepSize = size.width / 15;
    _homeStartOffset = _stepSize * 9;
    _homeSize = _stepSize * 6;
    _canvasCenter = size.width / 2;

    _drawHome(canvas, size);

    _drawDestination(canvas, size);

    _drawSteps(canvas, size);

    _calculatePlayerTracks();

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }

  void _calculatePlayerTracks() {
    late Rect prevRect;
    late Offset prevOffset;

    /**
     * Player 1 track
     */
    List<Rect> playerOneTrack = [];
    for (int stepIndex = 0; stepIndex < 57; stepIndex++) {
      if (stepIndex == 0) {
        var offset = _stepSize / 2;
        prevOffset = Offset(_stepSize + offset, _homeSize + offset);
      } else if (stepIndex < 5 ||
          stepIndex > 50 ||
          stepIndex > 18 && stepIndex < 24 ||
          stepIndex > 10 && stepIndex < 13)
        prevOffset = Offset(prevRect.center.dx + _stepSize, prevRect.center.dy);
      else if (stepIndex == 5)
        prevOffset = Offset(
            prevRect.center.dx + _stepSize, prevRect.center.dy - _stepSize);
      else if (stepIndex < 11 ||
          stepIndex > 38 && stepIndex < 44 ||
          stepIndex == 50)
        prevOffset = Offset(prevRect.center.dx, prevRect.center.dy - _stepSize);
      else if (stepIndex < 18 ||
          stepIndex > 31 && stepIndex < 37 ||
          stepIndex > 18 && stepIndex < 26)
        prevOffset = Offset(prevRect.center.dx, prevRect.center.dy + _stepSize);
      else if (stepIndex == 18)
        prevOffset = Offset(
            prevRect.center.dx + _stepSize, prevRect.center.dy + _stepSize);
      else if (stepIndex < 31 ||
          stepIndex > 31 && stepIndex < 39 ||
          stepIndex > 44 && stepIndex < 50)
        prevOffset = Offset(prevRect.center.dx - _stepSize, prevRect.center.dy);
      else if (stepIndex == 31)
        prevOffset = Offset(
            prevRect.center.dx - _stepSize, prevRect.center.dy + _stepSize);
      else if (stepIndex == 44)
        prevOffset = Offset(
            prevRect.center.dx - _stepSize, prevRect.center.dy - _stepSize);

      prevRect = Rect.fromCenter(
          center: prevOffset, width: _stepSize, height: _stepSize);
      playerOneTrack.add(prevRect);
    }

    /**
     * Player 2 track
     */
    List<Rect> playerTwoTrack = [];

    playerTwoTrack.addAll(playerOneTrack.sublist(13, 51));
    prevRect = playerTwoTrack.last;
    playerTwoTrack.add(Rect.fromCenter(
        center: Offset(prevRect.center.dx, prevRect.center.dy - _stepSize),
        width: _stepSize,
        height: _stepSize));
    playerTwoTrack.addAll(playerOneTrack.sublist(0, 12));

    for (int stepIndex = 0; stepIndex < 6; stepIndex++) {
      prevRect = playerTwoTrack.last;
      playerTwoTrack.add(Rect.fromCenter(
          center: Offset(prevRect.center.dx, prevRect.center.dy + _stepSize),
          width: _stepSize,
          height: _stepSize));
    }

    /**
     * Player 3 track
     */
    List<Rect> playerThreeTrack = [];

    playerThreeTrack.addAll(playerTwoTrack.sublist(13, 51));
    prevRect = playerThreeTrack.last;
    playerThreeTrack.add(Rect.fromCenter(
        center: Offset(prevRect.center.dx + _stepSize, prevRect.center.dy),
        width: _stepSize,
        height: _stepSize));
    playerThreeTrack.addAll(playerTwoTrack.sublist(0, 12));

    for (int stepIndex = 0; stepIndex < 6; stepIndex++) {
      prevRect = playerThreeTrack.last;
      playerThreeTrack.add(Rect.fromCenter(
          center: Offset(prevRect.center.dx - _stepSize, prevRect.center.dy),
          width: _stepSize,
          height: _stepSize));
    }

    /**
     * Player 4 track
     */
    List<Rect> playerFourTrack = [];

    playerFourTrack.addAll(playerThreeTrack.sublist(13, 51));
    prevRect = playerFourTrack.last;
    playerFourTrack.add(Rect.fromCenter(
        center: Offset(prevRect.center.dx, prevRect.center.dy + _stepSize),
        width: _stepSize,
        height: _stepSize));
    playerFourTrack.addAll(playerThreeTrack.sublist(0, 12));

    for (int stepIndex = 0; stepIndex < 6; stepIndex++) {
      prevRect = playerFourTrack.last;
      playerFourTrack.add(Rect.fromCenter(
          center: Offset(prevRect.center.dx, prevRect.center.dy - _stepSize),
          width: _stepSize,
          height: _stepSize));
    }

    /**
     * Add spots with tracks
     */
    List<List<List<Rect>>> _playerTracks = [];
    for (int playerIndex = 0; playerIndex < 4; playerIndex++) {
      List<List<Rect>> playerTrack = [];

      for (int spotIndex = 0;
          spotIndex < _homeSpotsList[playerIndex].length;
          spotIndex++) {
        List<Rect> track = [];

        track.add(Rect.fromCenter(
            center: _homeSpotsList[playerIndex][spotIndex],
            width: _stepSize,
            height: _stepSize));

        switch (playerIndex) {
          case 0:
            track.addAll(playerOneTrack);
            break;
          case 1:
            track.addAll(playerTwoTrack);
            break;
          case 2:
            track.addAll(playerThreeTrack);
            break;
          case 3:
            track.addAll(playerFourTrack);
            break;
          default:
        }

        playerTrack.add(track);
      }
      _playerTracks.add(playerTrack);
    }

    trackCalculationListener(_playerTracks);
  }

  void _drawHome(Canvas canvas, Size size) {
    /**
     * Draw home base
     */
    _fillPaint.color = AppColors.home1;
    var home1 = Rect.fromLTWH(0, 0, _homeSize, _homeSize);
    canvas.drawRect(home1, _fillPaint);
    canvas.drawRect(home1, _strokePaint);

    _fillPaint.color = AppColors.home2;
    var home2 = Rect.fromLTWH(_homeStartOffset, 0, _homeSize, _homeSize);
    canvas.drawRect(home2, _fillPaint);
    canvas.drawRect(home2, _strokePaint);

    _fillPaint.color = AppColors.home3;
    var home3 =
        Rect.fromLTWH(_homeStartOffset, _homeStartOffset, _homeSize, _homeSize);
    canvas.drawRect(home3, _fillPaint);
    canvas.drawRect(home3, _strokePaint);

    _fillPaint.color = AppColors.home4;
    var home4 = Rect.fromLTWH(0, _homeStartOffset, _homeSize, _homeSize);
    canvas.drawRect(home4, _fillPaint);
    canvas.drawRect(home4, _strokePaint);

    /**
     * Draw inner home
     */
    var innerHomeSize = _homeSize - 2 * _stepSize;

    _fillPaint.color = Colors.white;
    var innerHome1 = Rect.fromLTWH(home1.left + _stepSize,
        home1.top + _stepSize, innerHomeSize, innerHomeSize);
    canvas.drawRect(innerHome1, _fillPaint);
    canvas.drawRect(innerHome1, _strokePaint);

    var innerHome2 = Rect.fromLTWH(home2.left + _stepSize,
        home2.top + _stepSize, innerHomeSize, innerHomeSize);
    canvas.drawRect(innerHome2, _fillPaint);
    canvas.drawRect(innerHome2, _strokePaint);

    var innerHome3 = Rect.fromLTWH(home3.left + _stepSize,
        home3.top + _stepSize, innerHomeSize, innerHomeSize);
    canvas.drawRect(innerHome3, _fillPaint);
    canvas.drawRect(innerHome3, _strokePaint);

    var innerHome4 = Rect.fromLTWH(home4.left + _stepSize,
        home4.top + _stepSize, innerHomeSize, innerHomeSize);
    canvas.drawRect(innerHome4, _fillPaint);
    canvas.drawRect(innerHome4, _strokePaint);

    /**
     * Draw spawn spots
     */
    _drawSpawnSpots(canvas, innerHome1, AppColors.home1);
    _drawSpawnSpots(canvas, innerHome2, AppColors.home2);
    _drawSpawnSpots(canvas, innerHome3, AppColors.home3);
    _drawSpawnSpots(canvas, innerHome4, AppColors.home4);
  }

  void _drawSpawnSpots(Canvas canvas, Rect innerHome, Color color) {
    List<Offset> spotList = [];

    _fillPaint.color = color;
    var spotOffsetOne = innerHome.width / 4;
    var spotOffsetTwo = 3 * spotOffsetOne;
    double spotRadius = spotOffsetOne / 2;

    canvas.save();
    canvas.translate(innerHome.left, innerHome.top);

    var spot1 = Offset(spotOffsetOne, spotOffsetOne);
    canvas.drawCircle(spot1, spotRadius, _fillPaint);
    canvas.drawCircle(spot1, spotRadius, _strokePaint);

    var spot2 = Offset(spotOffsetTwo, spotOffsetOne);
    canvas.drawCircle(spot2, spotRadius, _fillPaint);
    canvas.drawCircle(spot2, spotRadius, _strokePaint);

    var spot3 = Offset(spotOffsetOne, spotOffsetTwo);
    canvas.drawCircle(spot3, spotRadius, _fillPaint);
    canvas.drawCircle(spot3, spotRadius, _strokePaint);

    var spot4 = Offset(spotOffsetTwo, spotOffsetTwo);
    canvas.drawCircle(spot4, spotRadius, _fillPaint);
    canvas.drawCircle(spot4, spotRadius, _strokePaint);

    canvas.restore();

    /**
     * Spots coordinate calculation
     */
    var left = innerHome.left + spotOffsetOne;
    var right = innerHome.left + spotOffsetTwo;
    var up = innerHome.top + spotOffsetOne;
    var down = innerHome.top + spotOffsetTwo;

    spotList.add(Offset(left, up));
    spotList.add(Offset(right, up));
    spotList.add(Offset(right, down));
    spotList.add(Offset(left, down));

    _homeSpotsList.add(spotList);
  }

  void _drawDestination(Canvas canvas, Size size) {
    _fillPaint.color = AppColors.home1;
    var redDestination = Path()
      ..moveTo(_canvasCenter, _canvasCenter)
      ..lineTo(_homeSize, _homeStartOffset)
      ..lineTo(_homeSize, _homeSize)
      ..close();
    canvas.drawPath(redDestination, _fillPaint);
    canvas.drawPath(redDestination, _strokePaint);

    _fillPaint.color = AppColors.home2;
    var greenDestination = Path()
      ..moveTo(_canvasCenter, _canvasCenter)
      ..lineTo(_homeSize, _homeSize)
      ..lineTo(_homeStartOffset, _homeSize)
      ..close();
    canvas.drawPath(greenDestination, _fillPaint);
    canvas.drawPath(greenDestination, _strokePaint);

    _fillPaint.color = AppColors.home3;
    var yellowDestination = Path()
      ..moveTo(_canvasCenter, _canvasCenter)
      ..lineTo(_homeStartOffset, _homeSize)
      ..lineTo(_homeStartOffset, _homeStartOffset)
      ..close();
    canvas.drawPath(yellowDestination, _fillPaint);
    canvas.drawPath(yellowDestination, _strokePaint);

    _fillPaint.color = AppColors.home4;
    var blueDestination = Path()
      ..moveTo(_canvasCenter, _canvasCenter)
      ..lineTo(_homeSize, _homeStartOffset)
      ..lineTo(_homeStartOffset, _homeStartOffset)
      ..close();
    canvas.drawPath(blueDestination, _fillPaint);
    canvas.drawPath(blueDestination, _strokePaint);
  }

  void _drawSteps(Canvas canvas, Size size) {
    double verticalOffset;

    var arrowPaint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int homeIndex = 0; homeIndex < 4; homeIndex++) {
      verticalOffset = _homeSize;
      switch (homeIndex) {
        case 0:
          _fillPaint.color = AppColors.home1;
          break;
        case 1:
          _fillPaint.color = AppColors.home2;
          break;
        case 2:
          _fillPaint.color = AppColors.home3;
          break;
        default:
          _fillPaint.color = AppColors.home4;
          break;
      }

      for (int pos = 0; pos < 6; pos++) {
        var unit = Rect.fromLTWH(
            pos * _stepSize, verticalOffset, _stepSize, _stepSize);

        if (pos == 1) canvas.drawRect(unit, _fillPaint);

        canvas.drawRect(unit, _strokePaint);
      }

      verticalOffset += _stepSize;
      for (int pos = 0; pos < 6; pos++) {
        var unit = Rect.fromLTWH(
            pos * _stepSize, verticalOffset, _stepSize, _stepSize);

        if (pos > 0)
          canvas.drawRect(unit, _fillPaint);
        else {
          var arrowPadding = unit.width / 4;
          var arrowWingGap = arrowPadding / 1.5;
          var arrowTip =
              Offset(unit.right - arrowPadding, unit.bottom - unit.height / 2);
          arrowPaint..color = _fillPaint.color;

          canvas.drawPath(
              Path()
                ..moveTo(unit.left + arrowPadding, arrowTip.dy)
                ..lineTo(arrowTip.dx, arrowTip.dy)
                ..lineTo(arrowTip.dx - arrowWingGap, arrowTip.dy - arrowWingGap)
                ..moveTo(arrowTip.dx - arrowWingGap, arrowTip.dy + arrowWingGap)
                ..lineTo(arrowTip.dx, arrowTip.dy),
              arrowPaint);
        }

        canvas.drawRect(unit, _strokePaint);
      }

      verticalOffset += _stepSize;
      for (int pos = 0; pos < 6; pos++) {
        var unit = Rect.fromLTWH(
            pos * _stepSize, verticalOffset, _stepSize, _stepSize);
  
        if (pos == 2) {
          var safeSpotRadius = _stepSize / 4;
          _fillPaint.color = AppColors.safeSpot;
          canvas.drawCircle(unit.center, safeSpotRadius, _fillPaint);
          canvas.drawCircle(unit.center, safeSpotRadius, _strokePaint);
        }

        canvas.drawRect(unit, _strokePaint);
      }

      canvas.translate(_canvasCenter, _canvasCenter);
      canvas.rotate(pi / 2);
      canvas.translate(-_canvasCenter, -_canvasCenter);
    }
  }
}

/**
 * Board layout :
 * _________
 * | 0 | 1 |
 * |___|___|
 * |   |   |
 * |_3_|_2_|
 */

class OverlaySurface extends CustomPainter {
  Function(Offset) clickOffset;
  int selectedHomeIndex;
  Color highlightColor;
  OverlaySurface(
      {required this.clickOffset,
      required this.selectedHomeIndex,
      required this.highlightColor});

  Paint _fillPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    var stepSize = size.width / 15;
    var homeStartOffset = stepSize * 9;
    var homeSize = stepSize * 6;

    var home;
    switch (selectedHomeIndex) {
      case 0:
        home = Rect.fromLTWH(0, 0, homeSize, homeSize);
        break;
      case 1:
       home = Rect.fromLTWH(homeStartOffset, 0, homeSize, homeSize);
        break;
      case 2:
        home =
            Rect.fromLTWH(homeStartOffset, homeStartOffset, homeSize, homeSize);
        break;
      default:
        home = Rect.fromLTWH(0, homeStartOffset, homeSize, homeSize);
    }

    _fillPaint.color = highlightColor;
    canvas.drawRect(home, _fillPaint);
  }

  @override
  bool hitTest(Offset position) {
    clickOffset(position);
    return true;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class NexoLudoGame extends StatefulWidget {
  const NexoLudoGame({super.key});
  @override
  _NexoLudoGameState createState() => _NexoLudoGameState();
}

class _NexoLudoGameState extends State<NexoLudoGame> with TickerProviderStateMixin {
  late Animation<Color?> _playerHighlightAnim;
  late Animation<double> _diceHighlightAnim;
  late AnimationController _playerHighlightAnimCont, _diceHighlightAnimCont;
  List<List<AnimationController>> _playerAnimContList = [];
  List<List<Animation<Offset>>> _playerAnimList = [];
  List<List<int>> _winnerPawnList = [];
  bool _provideFreeTurn = false;
  CollisionDetails _collisionDetails = CollisionDetails();

  late int _stepCounter = 0,
      _diceOutput = 0,
      _currentTurn = 0,
      _selectedPawnIndex,
      _maxTrackIndex = 57,
      _straightSixesCounter = 0,
      _forwardStepAnimTimeInMillis = 250,
      _reverseStepAnimTimeInMillis = 60;
  late List<List<List<Rect>>> _playerTracks;
  late List<Rect> _safeSpots;
  List<List<MapEntry<int, Rect>>> _pawnCurrentStepInfo =
      []; //step index, rect

  late PlayersNotifier _playerPaintNotifier;
  late ResultNotifier _resultNotifier;
  late DiceNotifier _diceNotifier;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); //full screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]); //force portrait mode

    _playerPaintNotifier = PlayersNotifier();
    _resultNotifier = ResultNotifier();
    _diceNotifier = DiceNotifier();

    _playerHighlightAnimCont =
        AnimationController(duration: Duration(milliseconds: 700), vsync: this);
    _diceHighlightAnimCont =
        AnimationController(duration: Duration(seconds: 5), vsync: this);

    _playerHighlightAnim =
        ColorTween(begin: Colors.black12, end: Colors.black45)
            .animate(_playerHighlightAnimCont);
    _diceHighlightAnim =
        Tween(begin: 0.0, end: 2 * pi).animate(_diceHighlightAnimCont);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();

      _playerPaintNotifier.rebuildPaint();

      _highlightCurrentPlayer();
      _highlightDice();
    });
  }

  @override
  void dispose() {
    _playerAnimContList.forEach((controllerList) {
      controllerList.forEach((controller) {
        controller.dispose();
      });
    });
    _playerHighlightAnimCont.dispose();
    _diceHighlightAnimCont.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXO Ludo', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: const Color(0xff1f0d67),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'رجوع',
        ),
      ),
      body: MultiProvider(
        providers: [
          ChangeNotifierProvider<PlayersNotifier>(
              create: (_) => _playerPaintNotifier),
          ChangeNotifierProvider<ResultNotifier>(
              create: (_) => _resultNotifier),
          ChangeNotifierProvider<DiceNotifier>(create: (_) => _diceNotifier),
        ],
        child: Stack(
          children: <Widget>[
            SizedBox.expand(
                child: Container(
              color: const Color(0xff1f0d67),
            )),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    color: Colors.white,
                    margin: const EdgeInsets.all(20),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: <Widget>[
                          SizedBox.expand(
                            child: CustomPaint(
                              painter: BoardPainter(
                                  trackCalculationListener: (playerTracks) {
                                _playerTracks = playerTracks;
                              }),
                            ),
                          ),
                          SizedBox.expand(
                              child: AnimatedBuilder(
                            animation: _playerHighlightAnim,
                            builder: (_, __) => CustomPaint(
                              painter: OverlaySurface(
                                  highlightColor: _playerHighlightAnim.value!,
                                  selectedHomeIndex: _currentTurn,
                                  clickOffset: (clickOffset) {
                                    _handleClick(clickOffset);
                                  }),
                            ),
                          )),
                          Consumer<PlayersNotifier>(builder: (_, notifier, __) {
                            if (notifier.shoulPaintPlayers)
                              return SizedBox.expand(
                                child: Stack(
                                  children: _buildPawnWidgets(),
                                ),
                              );
                            else
                              return Container();
                          }),
                          Consumer<ResultNotifier>(builder: (_, notifier, __) {
                            return SizedBox.expand(
                                child: CustomPaint(
                              painter: ResultPainter(notifier.ranks),
                            ));
                          })
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_diceHighlightAnimCont.isAnimating) {
                        _playerHighlightAnimCont.reset();
                        _diceHighlightAnimCont.reset();
                        _diceNotifier.rollDice();
                      }
                    },
                    child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Stack(children: [
                          SizedBox.expand(
                            child: AnimatedBuilder(
                              animation: _diceHighlightAnim,
                              builder: (_, __) => CustomPaint(
                                painter:
                                    DiceBasePainter(_diceHighlightAnim.value),
                              ),
                            ),
                          ),
                          Consumer<DiceNotifier>(builder: (_, notifier, __) {
                            if (notifier.isRolled) {
                              _highlightCurrentPlayer();
                              _diceOutput = notifier.output;
                              if (_diceOutput == 6) _straightSixesCounter++;
                              _checkDiceResultValidity();
                            }
                            return SizedBox.expand(
                              child: CustomPaint(
                                painter: DicePaint(notifier.output),
                              ),
                            );
                          })
                        ])),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPawnWidgets() {
    List<Widget> playerPawns = [];

    for (int playerIndex = 0; playerIndex < 4; playerIndex++) {
      Color playerColor;
      switch (playerIndex) {
        case 0:
          playerColor = AppColors.player1;
          break;
        case 1:
          playerColor = AppColors.player2;
          break;
        case 2:
          playerColor = AppColors.player3;
          break;
        default:
          playerColor = AppColors.player4;
      }
      for (int pawnIndex = 0; pawnIndex < 4; pawnIndex++)
        playerPawns.add(SizedBox.expand(
          child: AnimatedBuilder(
            builder: (_, child) => CustomPaint(
                painter: PlayersPainter(
                    playerCurrentSpot:
                        _playerAnimList[playerIndex][pawnIndex].value,
                    playerColor: playerColor)),
            animation: _playerAnimList[playerIndex][pawnIndex],
          ),
        ));
    }

    return playerPawns;
  }

  _initData() {
    for (int playerIndex = 0;
        playerIndex < _playerTracks.length;
        playerIndex++) {
      List<Animation<Offset>> currentPlayerAnimList = [];
      List<AnimationController> currentPlayerAnimContList = [];
      List<MapEntry<int, Rect>> currentStepInfoList = [];

      for (int pawnIndex = 0;
          pawnIndex < _playerTracks[playerIndex].length;
          pawnIndex++) {
        AnimationController currentAnimCont = AnimationController(
            duration: Duration(milliseconds: _forwardStepAnimTimeInMillis),
            vsync: this)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              if (!_collisionDetails.isReverse) _stepCounter++;
              _movePawn();
            }
          });

        currentPlayerAnimContList.add(currentAnimCont);
        currentPlayerAnimList.add(Tween(
                begin: _playerTracks[playerIndex][pawnIndex][0].center,
                end: _playerTracks[playerIndex][pawnIndex][1].center)
            .animate(currentAnimCont));
        currentStepInfoList
            .add(MapEntry(0, _playerTracks[playerIndex][pawnIndex][0]));
      }
      _playerAnimContList.add(currentPlayerAnimContList);
      _playerAnimList.add(currentPlayerAnimList);
      _pawnCurrentStepInfo.add(currentStepInfoList);
      _winnerPawnList.add([]);
    }

    /**
     * Fetch all safe spot rects
     */
    var playerTrack = _playerTracks[0][0];

    _safeSpots = [
      playerTrack[1],
      playerTrack[9],
      playerTrack[14],
      playerTrack[22],
      playerTrack[27],
      playerTrack[35],
      playerTrack[40],
      playerTrack[48]
    ];
  }

  _handleClick(Offset clickOffset) {
    if (!_diceHighlightAnimCont.isAnimating) if (_stepCounter == 0) {
      for (int pawnIndex = 0;
          pawnIndex < _pawnCurrentStepInfo[_currentTurn].length;
          pawnIndex++)
        if (_pawnCurrentStepInfo[_currentTurn][pawnIndex]
            .value
            .contains(clickOffset)) {
          var clickedPawnIndex =
              _pawnCurrentStepInfo[_currentTurn][pawnIndex].key;

          if (clickedPawnIndex == 0) {
            if (_diceOutput == 6)
              _diceOutput = 1; //to move pawn out of the house when 6 is rolled
            else
              break; //disallow pawn selection because 6 is not rolled and the pawn is in house
          } else if (clickedPawnIndex + _diceOutput > _maxTrackIndex)
            break; //disallow pawn selection because dice number is more than step left

          _playerHighlightAnimCont.reset();
          _selectedPawnIndex = pawnIndex;

          _movePawn(considerCurrentStep: true);

          break;
        }
    }
  }

  _checkDiceResultValidity() {
    var isValid = false;

    for (var stepInfo in _pawnCurrentStepInfo[_currentTurn]) {
      if (_diceOutput == 6) {
        if (_straightSixesCounter ==
            3) //change turn in case of 3 straight sixes
          break;
        else if (stepInfo.key + _diceOutput >
            _maxTrackIndex) //ignore pawn if it can't move 6 steps
          continue;

        _provideFreeTurn = true;
        isValid = true;
        break;
      } else if (stepInfo.key != 0) {
        if (stepInfo.key + _diceOutput <= _maxTrackIndex) {
          isValid = true;
          break;
        }
      }
    }

    if (!isValid) _changeTurn();
  }

  _movePawn({bool considerCurrentStep = false}) {
    int playerIndex, pawnIndex, currentStepIndex;

    if (_collisionDetails.isReverse) {
      playerIndex = _collisionDetails.targetPlayerIndex;
      pawnIndex = _collisionDetails.pawnIndex;
      currentStepIndex = max(
          _pawnCurrentStepInfo[playerIndex][pawnIndex].key -
              (considerCurrentStep ? 0 : 1),
          0);
    } else {
      playerIndex = _currentTurn;
      pawnIndex = _selectedPawnIndex;
      currentStepIndex = min(
          _pawnCurrentStepInfo[playerIndex][pawnIndex].key +
              (considerCurrentStep
                  ? 0
                  : 1), //condition to avoid incrementing key for initial step
          _maxTrackIndex);
    }

    //update current step info in the [_pawnCurrentStepInfo] list
    var currentStepInfo = MapEntry(currentStepIndex,
        _playerTracks[playerIndex][pawnIndex][currentStepIndex]);
    _pawnCurrentStepInfo[playerIndex][pawnIndex] = currentStepInfo;

    var animCont = _playerAnimContList[playerIndex][pawnIndex];

    if (_collisionDetails.isReverse) {
      if (currentStepIndex > 0) {
        //animate one step reverse
        _playerAnimList[_collisionDetails.targetPlayerIndex]
            [_collisionDetails.pawnIndex] = Tween(
                begin: currentStepInfo.value.center,
                end: _playerTracks[_collisionDetails.targetPlayerIndex]
                        [_collisionDetails.pawnIndex][currentStepIndex - 1]
                    .center)
            .animate(animCont);
        animCont.forward(from: 0.0);
      } else {
        _playerAnimContList[playerIndex][pawnIndex].duration =
            Duration(milliseconds: _forwardStepAnimTimeInMillis);
        _collisionDetails.isReverse = false;
        _provideFreeTurn = true; //free turn for collision
        _changeTurn();
      }
    } else if (_stepCounter != _diceOutput) {
      //animate one step forward
      _playerAnimList[playerIndex][pawnIndex] = Tween(
              begin: currentStepInfo.value.center,
              end: _playerTracks[playerIndex][pawnIndex]
                      [min(currentStepIndex + 1, _maxTrackIndex)]
                  .center)
          .animate(CurvedAnimation(
              parent: animCont,
              curve: Interval(0.0, 0.5, curve: Curves.easeOutCubic)));
      animCont.forward(from: 0.0);
    } else {
      if (_checkCollision(currentStepInfo))
        _movePawn(considerCurrentStep: true);
      else {
        if (currentStepIndex == _maxTrackIndex) {
          _winnerPawnList[_currentTurn]
              .add(_selectedPawnIndex); //add pawn to [_winnerPawnList]

          if (_winnerPawnList[_currentTurn].length < 4)
            _provideFreeTurn =
                true; //if player has remaining pawns, provide free turn for reaching destination
          else {
            _resultNotifier.rebuildPaint(_currentTurn);
            _provideFreeTurn =
                false; //to discard free turn if he completes the game
          }
        }

        _changeTurn();
      }
    }
  }

  bool _checkCollision(MapEntry<int, Rect> currentStepInfo) {
    var currentStepCenter = currentStepInfo.value.center;

    if (currentStepInfo.key <
        52) //no need to check if the pawn has entered destination lane
    if (!_safeSpots.any((safeSpot) {
      //avoid checking if it has landed on a safe spot
      return safeSpot.contains(currentStepCenter);
    })) {
      List<CollisionDetails> collisions = [];
      for (int playerIndex = 0;
          playerIndex < _pawnCurrentStepInfo.length;
          playerIndex++) {
        for (int pawnIndex = 0;
            pawnIndex < _pawnCurrentStepInfo[playerIndex].length;
            pawnIndex++) {
          if (playerIndex != _currentTurn ||
              pawnIndex != _selectedPawnIndex) if (_pawnCurrentStepInfo[
                  playerIndex][pawnIndex]
              .value
              .contains(currentStepCenter)) {
            collisions.add(CollisionDetails()
              ..pawnIndex = pawnIndex
              ..targetPlayerIndex = playerIndex);
          }
        }
      }

      /**
       * Check if collision is valid
       */
      if (collisions.isEmpty ||
          collisions.any((collision) {
            return collision.targetPlayerIndex == _currentTurn;
          }) ||
          collisions.length >
              1) //conditions to no collision and group collisions
        _collisionDetails.isReverse = false;
      else {
        _collisionDetails = collisions.first;
        _playerAnimContList[_collisionDetails.targetPlayerIndex]
                [_collisionDetails.pawnIndex]
            .duration = Duration(milliseconds: _reverseStepAnimTimeInMillis);

        _collisionDetails.isReverse = true;
      }
    }
    return _collisionDetails.isReverse;
  }

  _changeTurn() {
    if (_winnerPawnList.where((playerPawns) {
          return playerPawns.length == 4;
        }).length !=
        3) //if any 3 players have completed
    {
      _highlightDice();

      _stepCounter = 0; //reset step counter for next turn
      if (!_provideFreeTurn) {
        do {
          //to ignore winners
          _currentTurn =
              (_currentTurn + 1) % 4; //change turn after animation completes
          if (_winnerPawnList[_currentTurn].length != 4)
            break; //select player if he is not yet a winner
        } while (true);
        _straightSixesCounter = 0;
      } else if (_diceOutput != 6)
        _straightSixesCounter =
            0; //reset 6s counter if free turn is provided by other means

      if (!_playerHighlightAnimCont.isAnimating) _highlightCurrentPlayer();

      _provideFreeTurn = false;
    }
  }

  _highlightCurrentPlayer() {
    _playerHighlightAnimCont.repeat(reverse: true);
  }

  _highlightDice() {
    _diceHighlightAnimCont.repeat();
  }
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<AnimationController>('_diceHighlightAnimCont', _diceHighlightAnimCont));
  }
}