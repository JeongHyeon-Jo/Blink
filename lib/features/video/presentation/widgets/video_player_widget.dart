import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isPlaying;
  final Function()? onVideoComplete;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.isPlaying,
    this.onVideoComplete,
  });

  @override
  State<VideoPlayerWidget> createState() => VideoPlayerWidgetState();
}

class VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;
  bool _isPaused = false;
  late AnimationController _animationController;
  bool _showPlayPauseIcon = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _initializeVideo() async {
    try {
      _controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          widget.onVideoComplete?.call();
        }
      });

      await _controller.initialize();
      setState(() {
        _isInitialized = true;
        _error = null;
      });
      if (widget.isPlaying) {
        _controller.play();
        _controller.setLooping(true);
      }
    } catch (e) {
      setState(() {
        _error = '비디오를 로드할 수 없습니다: $e';
      });
    }
  }

  void togglePlayPause() {
    if (_isInitialized) {
      setState(() {
        _isPaused = !_isPaused;
        _showPlayPauseIcon = true;
        if (_isPaused) {
          _controller.pause();
        } else {
          _controller.play();
          _controller.setLooping(true);
        }
      });

      // 아이콘 애니메이션 시작
      _animationController.forward(from: 0.0).then((_) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _showPlayPauseIcon = false;
            });
          }
        });
      });
    }
  }

  void pause() {
    if (_isInitialized && _controller.value.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isPaused = true;
            _controller.pause();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying && !_isPaused) {
        _controller.play();
        _controller.setLooping(true);
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get isPlaying => _isInitialized && _controller.value.isPlaying;

  void resume() {
    if (_isInitialized && !_controller.value.isPlaying) {
      setState(() {
        _isPaused = false;
        _controller.play();
        _controller.setLooping(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
        ),
        if (_showPlayPauseIcon)
          FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOut,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPaused ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
      ],
    );
  }
}
