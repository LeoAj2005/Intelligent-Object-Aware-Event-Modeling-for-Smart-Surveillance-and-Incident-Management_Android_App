import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../settings_provider.dart';

class VideoUploadScreen extends StatefulWidget {
  final SettingsProvider settings;

  const VideoUploadScreen({Key? key, required this.settings}) : super(key: key);

  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  File? _selectedVideo;
  bool _isProcessing = false;
  String _statusMessage = 'Select a video to upload for analysis.';
  String? _processingResult;

  // Video player for the processed result
  VideoPlayerController? _resultVideoController;
  bool _isVideoReady = false;

  @override
  void dispose() {
    _resultVideoController?.dispose();
    super.dispose();
  }

  // 1. Pick the video from the device
  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedVideo = File(result.files.single.path!);
        _statusMessage = 'Video selected: ${result.files.single.name}\nReady to upload.';
        _processingResult = null;
        // Reset video player when a new video is selected
        _resultVideoController?.dispose();
        _isVideoReady = false;
        _resultVideoController = null;
      });
    }
  }

  // 2. Upload and wait for server processing
  Future<void> _uploadAndProcessVideo() async {
    if (_selectedVideo == null) return;
    if (widget.settings.serverUrl.isEmpty) {
      _showError('Server URL is not configured in Settings.');
      return;
    }

    // Reset previous video state
    _resultVideoController?.dispose();
    _isVideoReady = false;
    _resultVideoController = null;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Uploading and analyzing video...\nThis may take a few moments. Please do not close the app.';
      _processingResult = null;
    });

    try {
      // Clean up the URL just in case there's a trailing slash
      final baseUrl = widget.settings.serverUrl.replaceAll(RegExp(r'/$'), '');
      
      // Adjust the endpoint to match your Flask route (e.g., '/upload')
      var uri = Uri.parse('$baseUrl/upload'); 
      var request = http.MultipartRequest('POST', uri);

      // Add headers to bypass Cloudflare/Ngrok splash screens
      request.headers.addAll({
        'Accept': 'application/json',
        'User-Agent': 'SecurityApp/1.0',
        'ngrok-skip-browser-warning': 'true', // For Ngrok
        'bypass-tunnel-reminder': 'true',     // For Cloudflare/LocalTunnel
      });

      // Attach the file
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedVideo!.path),
      );

      print("Sending video to $uri...");

      // Send the request and wait for the server to process it
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Success! Server accepted and processed the video.
        print('Upload success: Video processed.');
        
        setState(() {
          _statusMessage = '✅ Upload complete! You can now check the processed video.';
          _processingResult = "Video successfully uploaded. Tap 'Check Status' to load the result.";
        });
      } else {
        print('❌ SERVER ERROR. Raw Server Response:\n${response.body}');
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error occurred: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 3. Load the processed video from the server
  Future<void> _loadProcessedVideo() async {
    final baseUrl = widget.settings.serverUrl.replaceAll(RegExp(r'/$'), '');
    // WARNING: Change this path to match exactly how Flask serves the video file!
    // For example, if your server serves the file at /static/final_stream.mp4, use that.
    final videoUrl = '$baseUrl/static/final_stream.mp4'; 

    setState(() {
      _statusMessage = 'Checking for processed video...';
    });

    _resultVideoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isVideoReady = true;
          _statusMessage = '✅ Video Ready! Playing result.';
        });
        _resultVideoController!.play();
      }).catchError((error) {
        _showError("Video is still processing on the server... Try again in a few seconds.");
      });
  }

  void _showError(String errorMsg) {
    setState(() {
      _statusMessage = '❌ Error occurred.';
      _processingResult = errorMsg;
    });
    print(errorMsg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyze Video')),
      // ✅ Wrap body in SingleChildScrollView to avoid overflow
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Icon / Loading Animation
            Center(
              child: _isProcessing
                  ? const SizedBox(
                      height: 80, width: 80,
                      child: CircularProgressIndicator(strokeWidth: 6),
                    )
                  : Icon(
                      _selectedVideo == null ? Icons.video_file_outlined : Icons.check_circle_outline,
                      size: 80,
                      color: _selectedVideo == null ? Colors.grey : Colors.green,
                    ),
            ),
            const SizedBox(height: 32),

            // Status Text
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),

            // Display Video if ready
            if (_isVideoReady && _resultVideoController != null) ...[
              AspectRatio(
                aspectRatio: _resultVideoController!.value.aspectRatio,
                child: VideoPlayer(_resultVideoController!),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      _resultVideoController!.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_resultVideoController!.value.isPlaying) {
                          _resultVideoController!.pause();
                        } else {
                          _resultVideoController!.play();
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ] 
            // After upload, show "Check Status" button and result message
            else if (_processingResult != null && !_isProcessing) ...[
              FilledButton.icon(
                onPressed: _loadProcessedVideo,
                icon: const Icon(Icons.refresh),
                label: const Text('Check if Processing is Done & Load Video'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              const SizedBox(height: 16),
              Container(
                height: 150, // Fixed height to avoid overflow
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _processingResult!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons (always at bottom)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _pickVideo,
                    icon: const Icon(Icons.folder),
                    label: const Text('Select Video'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_isProcessing || _selectedVideo == null) ? null : _uploadAndProcessVideo,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Analyze'),
                    style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}