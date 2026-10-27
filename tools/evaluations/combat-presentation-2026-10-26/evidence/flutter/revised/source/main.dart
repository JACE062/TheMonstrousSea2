import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

const parchment = Color(0xfff3ead7);
const ink = Color(0xff211d18);
const gold = Color(0xffb98b00);
const red = Color(0xff9c302e);
const blue = Color(0xff398a99);
const orange = Color(0xffc26a20);
const playbackSpeed = 2.0;
const barrierHullDelayMs = 240.0;
const impactFeedbackMs = 550.0;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final fixtureBytes = await rootBundle.load('assets/fixture.json');
  final bytes = fixtureBytes.buffer.asUint8List();
  final fixture = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  final game = CombatGame(fixture);
  final out = args.firstWhere((a) => a.startsWith('--out='), orElse: () => '--out=${Directory.current.path}/capture').substring(6);
  runApp(CaptureApp(game: game, output: out, fixtureHash: sha256.convert(bytes).toString()));
}

class CombatGame extends FlameGame {
  CombatGame(this.fixture) {
    final initial = fixture['initial'] as Map<String, dynamic>;
    shipHp = initial['ship_hp']; monsterHp = initial['monster_hp'];
    barrier = initial['barrier']; burn = initial['burn'];
    bearing = initial['bearing']; shipX = (initial['ship_x'] as num).toDouble();
    pauseEngine();
  }
  final Map<String, dynamic> fixture;
  final hud = ValueNotifier<int>(0);
  final artReady = Completer<void>();
  late ui.Image shipImage, monsterImage;
  late int shipHp, monsterHp, barrier;
  late bool burn;
  late String bearing;
  late double shipX;
  double timeMs = 0;
  int nextEvent = 0;
  final List<Map<String, dynamic>> observed = [];
  List<String> frameMarkers = [];
  Map<String, dynamic> displayedHud = {};
  String impact = '';
  double impactAt = -10000;
  bool impactOnMonster = false;
  double hitAt = -10000;
  Color impactColor = ink;
  final List<Map<String, dynamic>> pendingHull = [];

  Future<ui.Image> loadArt(String name) async {
    final data = await rootBundle.load('assets/$name.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    shipImage = await loadArt('ship');
    monsterImage = await loadArt('monster');
    artReady.complete();
  }
  @override
  Color backgroundColor() => parchment;
  @override
  void update(double dt) {
    super.update(dt);
    timeMs += dt * 1000;
    frameMarkers = [];
    final events = fixture['events'] as List;
    while (nextEvent < events.length && (events[nextEvent]['at_ms'] as num) <= timeMs + 0.001) {
      final e = events[nextEvent++] as Map<String, dynamic>;
      final id = e['id'] as String;
      frameMarkers.add(id);
      observed.add({'id': id, 'observed_at_ms': timeMs, 'scheduled_at_ms': e['at_ms']});
      switch (e['type']) {
        case 'monster_damage': monsterHp = e['monster_hp_after']; showImpact('-${e['damage']}', true); break;
        case 'barrier_granted': barrier = e['barrier_after']; showImpact('Barrier +$barrier', false); break;
        case 'status_applied': burn = true; showImpact('Burn applied', false); break;
        case 'ship_hit':
          barrier = e['barrier_after']; hitAt = timeMs;
          if ((e['absorbed'] as num) > 0) {
            showImpact('${id.toUpperCase()}  ${e['absorbed']} barrier absorbed', false, blue);
            pendingHull.add({...e, 'apply_at_ms': (e['at_ms'] as num) + barrierHullDelayMs});
          } else {
            shipHp = e['ship_hp_after'];
            showImpact('${id.toUpperCase()}  -${e['hull_damage']} hull', false, red);
          }
          break;
        case 'status_tick': shipHp = e['ship_hp_after']; showImpact('Burn -${e['damage']}', false); break;
        case 'status_expired': burn = false; showImpact('Burn expired', false); break;
      }
    }
    while (pendingHull.isNotEmpty && (pendingHull.first['apply_at_ms'] as num) <= timeMs + 0.001) {
      final e = pendingHull.removeAt(0);
      shipHp = e['ship_hp_after'];
      showImpact('${(e['id'] as String).toUpperCase()}  -${e['hull_damage']} hull', false, red);
      observed.add({'id': '${e['id']}_hull', 'observed_at_ms': timeMs, 'scheduled_at_ms': e['apply_at_ms']});
    }
    final movement = events.first as Map<String, dynamic>;
    final progress = ((timeMs - movement['at_ms']) / movement['duration_ms']).clamp(0.0, 1.0);
    shipX = movement['from_x'] + (movement['to_x'] - movement['from_x']) * progress;
    if (progress >= 1) bearing = movement['bearing_after'];
    hud.value++;
  }
  void showImpact(String text, bool monster, [Color color = ink]) { impact = text; impactAt = timeMs; impactOnMonster = monster; impactColor = color; }
  Map<String, dynamic> snapshot(int frame) => {
    'frame': frame, 'time_ms': timeMs, 'ship_hp': shipHp, 'monster_hp': monsterHp,
    'barrier': barrier, 'burn': burn, 'bearing': bearing, 'ship_x': shipX,
    'ship_hp_bar': displayedHud['ship_hp_bar'], 'monster_hp_bar': displayedHud['monster_hp_bar'],
    'displayed_hud': Map<String, dynamic>.of(displayedHud),
    'event_markers': List<String>.of(frameMarkers),
    'impact_text': timeMs - impactAt < impactFeedbackMs ? impact : '',
    'impact_color': timeMs - impactAt < impactFeedbackMs ? impactColor.toARGB32().toRadixString(16) : '',
  };
  void label(Canvas canvas, String text, Offset offset, {Color color = ink, double size = 24}) {
    final p = TextPainter(text: TextSpan(text: text, style: TextStyle(fontFamily: 'Fixture', fontSize: size, color: color)), textDirection: TextDirection.ltr)..layout();
    p.paint(canvas, offset);
  }
  void art(Canvas canvas, ui.Image image, double x, double y, double nudge) {
    final w = image.width * .24, h = image.height * .24;
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), Rect.fromCenter(center: Offset(x + nudge, y), width: w, height: h), Paint());
  }
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!artReady.isCompleted) return;
    final wave = Paint()..color = ink.withValues(alpha: .16)..strokeWidth = 1.5..style = PaintingStyle.stroke;
    for (var row = 0; row < 4; row++) {
      final path = Path()..moveTo(25, 395 + row * 13);
      for (var x = 25; x <= 975; x += 5) { path.lineTo(x.toDouble(), 395 + row * 13 + math.sin(x / 30 + timeMs / 600) * 3); }
      canvas.drawPath(path, wave);
    }
    final hitAge = timeMs - hitAt;
    final recoil = hitAge >= 0 && hitAge < 240 ? -8 * math.sin(hitAge / 240 * math.pi) : 0.0;
    art(canvas, shipImage, shipX, 335, recoil);
    art(canvas, monsterImage, 735, 335, 0);
    if (barrier > 0) { canvas.drawOval(Rect.fromCenter(center: Offset(shipX, 335), width: 220, height: 180), Paint()..color = blue.withValues(alpha: .65)..style = PaintingStyle.stroke..strokeWidth = 3); }
    if (hitAge >= 0 && hitAge < 220) {
      final p = Paint()..color = orange.withValues(alpha: 1-hitAge/220)..strokeWidth = 3;
      for (var i = 0; i < 8; i++) { final a = i*math.pi/4; canvas.drawLine(Offset(shipX+math.cos(a)*25, 335+math.sin(a)*25), Offset(shipX+math.cos(a)*52,335+math.sin(a)*52), p); }
    }
    if (timeMs - impactAt < impactFeedbackMs) {
      label(canvas, impact, Offset(impactOnMonster ? 640 : (shipX-170).clamp(30, 450), 245-(timeMs-impactAt)/40), color: impact.startsWith('Burn') ? orange : impactColor, size: 21);
    }
  }
}

class CaptureApp extends StatefulWidget {
  const CaptureApp({super.key, required this.game, required this.output, required this.fixtureHash});
  final CombatGame game;
  final String output, fixtureHash;
  @override State<CaptureApp> createState() => _CaptureAppState();
}
class _CaptureAppState extends State<CaptureApp> {
  final boundaryKey = GlobalKey();
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => capture()); }
  Future<void> capture() async {
    try {
      await widget.game.artReady.future;
      await WidgetsBinding.instance.endOfFrame;
      final dir = Directory('${widget.output}/frames'); await dir.create(recursive:true);
      final trace = <Map<String,dynamic>>[];
      for (var i=0; i<=300/playbackSpeed; i++) {
        if (i>0) widget.game.stepEngine(stepTime: 1/30 * playbackSpeed);
        setState(() {});
        await WidgetsBinding.instance.endOfFrame;
        final boundary = boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio:1);
        final data = await image.toByteData(format:ui.ImageByteFormat.png);
        await File('${dir.path}/frame_${i.toString().padLeft(4,'0')}.png').writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
        trace.add(widget.game.snapshot(i));
      }
      await File('${widget.output}/trace.json').writeAsString(const JsonEncoder.withIndent('  ').convert({
        'engine':'Flutter 3.47.0 + Flame 1.38.2', 'run':'revised',
        'platform':Platform.operatingSystem, 'renderer':'Native Windows Flutter engine; GameWidget Canvas + Flutter HUD; RepaintBoundary.toImage',
        'fixture_sha256':widget.fixtureHash,'speed':playbackSpeed,'impact_feedback_ms':impactFeedbackMs, 'barrier_hull_delay_ms':barrierHullDelayMs,
        'fps':30,'viewport':[1000,620], 'frames':trace,'observed_events':widget.game.observed,
      }));
      await File('${widget.output}/complete.txt').writeAsString('Capture complete: ${trace.length} native rendered frames.');
      exit(0);
    } catch(e,st) { await Directory(widget.output).create(recursive:true); await File('${widget.output}/error.txt').writeAsString('$e\n$st'); exit(1); }
  }
  Widget text(String text, double x, double y, {double size=24, Color color=ink}) => Positioned(left:x,top:y,child:Text(text,style:TextStyle(fontSize:size,color:color,fontFamily:'Fixture')));
  Widget bar(double x,double y,double width,double fraction,Color color) => Positioned(left:x,top:y,child:Container(width:width,height:20,decoration:BoxDecoration(border:Border.all(color:ink)),child:Align(alignment:Alignment.centerLeft,child:FractionallySizedBox(widthFactor:fraction,child:ColoredBox(color:color,child:const SizedBox.expand())))));
  @override Widget build(BuildContext context) => MaterialApp(debugShowCheckedModeBanner:false,theme:ThemeData(fontFamily:'Fixture'),home:Scaffold(backgroundColor:parchment,body:Center(child:RepaintBoundary(key:boundaryKey,child:SizedBox(width:1000,height:620,child:Stack(children:[
    Positioned.fill(child:GameWidget(game:widget.game)),
    ValueListenableBuilder<int>(valueListenable:widget.game.hud,builder:(context,_,__) { final g=widget.game; g.displayedHud = {'ship_hp_label':'Ship hull  ${g.shipHp} / 100','monster_hp_label':'Monster hull  ${g.monsterHp} / 60','barrier_label':'Barrier: ${g.barrier}','burn_label':g.burn ? 'Burn' : '', 'bearing_label':'Bearing: ${g.bearing}', 'ship_hp_bar':g.shipHp/100,'monster_hp_bar':g.monsterHp/60}; return Stack(children:[
      text('Flutter + Flame  |  Revised',30,24,size:30),
      text('Ship hull  ${g.shipHp} / 100',30,105),bar(30,145,440,g.shipHp/100,gold),
      text('Monster hull  ${g.monsterHp} / 60',560,105),bar(560,145,410,g.monsterHp/60,red),
      text('Bearing: ${g.bearing}',400,185,size:23),
      text('Barrier: ${g.barrier}',30,450,color:blue),
      if(g.burn) text('Burn',220,450,color:orange),
      text('Fixed presentation fixture  |  2x speed',30,552,size:21),
      text('${(g.timeMs/1000).toStringAsFixed(2)} s',860,552,size:21),
    ]);}),
  ]))))));
}



