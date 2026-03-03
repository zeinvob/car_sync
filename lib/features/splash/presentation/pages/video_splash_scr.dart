import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:car_sync/core/constants/app_colors.dart';

class VideoSplashScreen extends StatefulWidget {
  final VoidCallback onVideoFinished;
  
  const VideoSplashScreen({
    super.key,
    required this.onVideoFinished,
  });

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // start video player - asssets
    _controller = VideoPlayerController.asset(
      'assets/video/intro.mp4', 
    )..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        
        // start playing
        _controller.play();
        
        // listen for video completion
        _controller.addListener(() {
          if (_controller.value.position == _controller.value.duration) {
            // Video finished - navigate
            widget.onVideoFinished();
          }
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Video Background
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover, //full screen
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            /// Loading while video initializes
            Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}