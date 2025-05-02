import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const FlipCardGameApp());
}

class FlipCardGameApp extends StatelessWidget {
  const FlipCardGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flip Card Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final List<String> emojis = ['🍎','🍌','🍇','🍓','🍉','🍍','🥝','🍒'];
  List<String> cards = [];
  List<bool> flipped = [];
  List<bool> matched = [];
  int? firstIndex;
  int? secondIndex;
  bool lock = false;
  int moves = 15;
  int time = 30;
  int hintsUsed = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  void startGame() {
    final shuffled = [...emojis, ...emojis]..shuffle(Random());
    setState(() {
      cards = shuffled;
      flipped = List.filled(cards.length, false);
      matched = List.filled(cards.length, false);
      firstIndex = null;
      secondIndex = null;
      lock = false;
      moves = 15;
      time = 30;
      hintsUsed = 0;
    });

    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (time > 0) {
          time--;
        } else {
          timer.cancel();
          _showEndDialog('Time\'s up! You made ${15 - moves} moves.');
        }
      });
    });
  }

  void flipCard(int index) {
    if (lock || flipped[index] || matched[index] || moves <= 0) return;

    setState(() {
      flipped[index] = true;
    });

    if (firstIndex == null) {
      firstIndex = index;
    } else {
      secondIndex = index;
      lock = true;
      moves--;

      if (cards[firstIndex!] == cards[secondIndex!]) {
        setState(() {
          matched[firstIndex!] = true;
          matched[secondIndex!] = true;
        });
        _clearSelection();
        if (matched.every((e) => e)) {
          timer?.cancel();
          Future.delayed(const Duration(milliseconds: 300), () {
            _showEndDialog('You won in ${15 - moves} moves and ${30 - time} seconds!');
          });
        }
      } else {
        Future.delayed(const Duration(seconds: 1), () {
          setState(() {
            flipped[firstIndex!] = false;
            flipped[secondIndex!] = false;
          });
          _clearSelection();
        });
      }
    }

    if (moves <= 0 && matched.contains(false)) {
      timer?.cancel();
      Future.delayed(const Duration(milliseconds: 1000), () {
        _showEndDialog('Game over! You ran out of moves.');
      });
    }
  }

  void _clearSelection() {
    firstIndex = null;
    secondIndex = null;
    lock = false;
  }

  void useHint() {
    if (hintsUsed >= 5 || lock || moves <= 0) return;
    final unflippedIndexes = List.generate(cards.length, (i) => i)
        .where((i) => !flipped[i] && !matched[i])
        .toList();

    if (unflippedIndexes.isEmpty) return;
    final randIndex = unflippedIndexes[Random().nextInt(unflippedIndexes.length)];
    setState(() {
      flipped[randIndex] = true;
    });
    lock = true;
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        flipped[randIndex] = false;
        lock = false;
      });
    });
    setState(() {
      hintsUsed++;
    });
  }

  void _showEndDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Game Over'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              startGame();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF141e30), Color(0xFF243b55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            Text(
              'Flip Card Game',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                  ).createShader(const Rect.fromLTWH(0, 0, 300, 70)),
              ),
            ),
            const SizedBox(height: 10),
            Text('Moves Left: $moves'),
            Text('Time: ${time}s'),
            const SizedBox(height: 10),
            if (hintsUsed < 5)
              ElevatedButton(
                onPressed: useHint,
                child: Text('Hint (${5 - hintsUsed})'),
              ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => flipCard(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: matched[index]
                            ? Colors.green
                            : flipped[index]
                            ? Colors.yellow
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          flipped[index] || matched[index] ? cards[index] : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
