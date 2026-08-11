import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Preloads short answer-feedback sounds so playback starts with the UI update.
class FeedbackAudioService {
  final Future<AudioPool> _correctPool = AudioPool.createFromAsset(
    path: 'audio/correct.wav',
    minPlayers: 1,
    maxPlayers: 2,
  );
  final Future<AudioPool> _wrongPool = AudioPool.createFromAsset(
    path: 'audio/wrong.wav',
    minPlayers: 1,
    maxPlayers: 2,
  );

  Future<void> get ready async {
    await Future.wait([_correctPool, _wrongPool]);
  }

  void play({required bool isCorrect}) {
    final pool = isCorrect ? _correctPool : _wrongPool;
    unawaited(
      pool
          .then<void>((audioPool) async {
            await audioPool.start();
          })
          .catchError((_) {
            // Audio feedback must never interrupt the quiz interaction.
          }),
    );
  }

  Future<void> dispose() async {
    final pools = await Future.wait([_correctPool, _wrongPool]);
    await Future.wait(pools.map((pool) => pool.dispose()));
  }
}
