import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:video_player/video_player.dart';
import '../settings_provider.dart';

class VideoFeedScreen extends StatefulWidget {
  final SettingsProvider settings;

  const VideoFeedScreen({super.key, required this.settings});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  // Toggle State: true = Live MJPEG, false = Processed MP4
  bool _isLiveFeed = true; 
  bool _isMjpegPlaying = true;

  // Video Player State
  VideoPlayerController? _videoController;
  bool _isVideoLoading = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  // Fetches the final_stream.mp4 from the server
  Future<void> _loadProcessedVideo() async {
    if (widget.settings.serverUrl.isEmpty) return;

    setState(() {
      _isVideoLoading = true;
      _videoError = false;
    });

    // Clean up old controller if replacing
    await _videoController?.dispose();

    final baseUrl = widget.settings.serverUrl.replaceAll(RegExp(r'/$'), '');
    final videoUrl = '$baseUrl/static/final_stream.mp4';

    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
        });
        _videoController!.play();
        _videoController!.setLooping(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _videoError = true;
        });
        print("Error loading processed video: $e");
      }
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = widget.settings.serverUrl.replaceAll(RegExp(r'/$'), '');
    final liveStreamUrl = '$baseUrl/live'; 

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Feed Monitor'),
        actions: [
          // Play/Pause button only shows when in Live mode
          if (_isLiveFeed && widget.settings.serverUrl.isNotEmpty)
            IconButton(
              icon: Icon(_isMjpegPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () => setState(() => _isMjpegPlaying = !_isMjpegPlaying),
            )
        ],
      ),
      body: widget.settings.serverUrl.isEmpty
          ? const Center(child: Text('Please set the Server URL in Settings first.'))
          : Column(
              children: [
                // 🎛️ 1. THE TOGGLE SWITCH
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Live (MJPEG)'),
                        icon: Icon(Icons.videocam),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Processed (MP4)'),
                        icon: Icon(Icons.movie),
                      ),
                    ],
                    selected: {_isLiveFeed},
                    onSelectionChanged: (Set<bool> newSelection) {
                      setState(() {
                        _isLiveFeed = newSelection.first;
                        if (!_isLiveFeed) {
                          _loadProcessedVideo(); // Fetch MP4 when switched
                        } else {
                          _videoController?.pause(); // Pause MP4 if going back to live
                        }
                      });
                    },
                  ),
                ),

                // 📺 2. THE VIDEO VIEWER
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        color: Colors.black87, // Makes it look like a security monitor
                        child: _isLiveFeed
                            ? _buildLiveFeed(liveStreamUrl)
                            : _buildProcessedVideo(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildLiveFeed(String url) {
    return Mjpeg(
      isLive: _isMjpegPlaying,
      stream: url,
      error: (context, error, stack) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'Live Feed Offline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            const Text('Switch to Processed (MP4) to view last clip', style: TextStyle(color: Colors.white54)),
          ],
        );
      },
      loading: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildProcessedVideo() {
    if (_isVideoLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching latest processed video...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (_videoError || _videoController == null || !_videoController!.value.isInitialized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'Processed Video Not Found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.redAccent),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _loadProcessedVideo,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          )
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        // Simple tap-to-play/pause overlay
        GestureDetector(
          onTap: () {
            setState(() {
              _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
            });
          },
          child: AnimatedOpacity(
            opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: const Icon(Icons.play_arrow, size: 48, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}