import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webview_windows/webview_windows.dart' as webview_win;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final webview_win.WebviewController _controller =
      webview_win.WebviewController();
  bool _isWebViewReady = false;
  String _currentUrl = 'Loading...';
  String _currentView = 'home';
  bool _isPanelCollapsed = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initWebView() async {
    try {
      await _controller.initialize();

      _controller.url.listen((url) {
        debugPrint('URL changed: $url');
        if (mounted) {
          setState(() {
            _currentUrl = url;
          });
        }
      });

      await _controller.setBackgroundColor(Colors.black);
      await _controller.setPopupWindowPolicy(
        webview_win.WebviewPopupWindowPolicy.deny,
      );
      await _controller.loadUrl('https://www.youtube.com');

      if (mounted) {
        setState(() {
          _isWebViewReady = true;
          _currentUrl = 'https://www.youtube.com';
        });
      }

      debugPrint('WebView initialized successfully');
    } catch (e) {
      debugPrint('Error initializing WebView: $e');
      if (mounted) {
        _showMessage('Failed to initialize WebView: $e');
      }
    }
  }

  bool _isYouTubeVideoUrl(String url) {
    return url.contains('youtube.com/watch?v=') || url.contains('youtu.be/');
  }

  /*
  String _sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
*/

  Future<bool> _checkYtDlpInstalled() async {
    try {
      final result = await Process.run('yt-dlp', ['--version']);
      debugPrint('yt-dlp version: ${result.stdout}');
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('yt-dlp not found: $e');
      return false;
    }
  }

  void _downloadVideo() async {
    debugPrint('Download video called');

    if (!_isWebViewReady) {
      _showMessage('WebView is not ready');
      return;
    }

    if (!_isYouTubeVideoUrl(_currentUrl)) {
      _showMessage('Please navigate to a YouTube video');
      return;
    }

    // Check if yt-dlp is installed
    final isInstalled = await _checkYtDlpInstalled();
    if (!isInstalled) {
      _showMessage(
        'yt-dlp is not installed!\n\n'
        'Install it using:\n'
        'Windows: winget install yt-dlp\n'
        'or download from: https://github.com/yt-dlp/yt-dlp/releases',
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
        _downloadStatus = 'Initializing...';
      });
    }

    try {
      // Get Downloads folder as default
      final downloadsDir = await getDownloadsDirectory();
      final outputDir = downloadsDir?.path ?? Directory.current.path;

      if (mounted) {
        setState(() {
          _downloadStatus = 'Starting download...';
        });
      }

      debugPrint('Starting yt-dlp download to: $outputDir');

      // Run yt-dlp with progress - matching C# format
      final process = await Process.start('yt-dlp', [
        '--cookies',
        'cookies.txt',
        '--format',
        'bv*+ba/b',
        '--merge-output-format',
        'mkv',
        '--output',
        p.join(outputDir, '%(title)s.%(ext)s'),
        '--newline',
        '--no-playlist',
        _currentUrl,
      ]);

      process.stdout.transform(const SystemEncoding().decoder).listen((data) {
        debugPrint('yt-dlp stdout: $data');

        // Parse progress from yt-dlp output
        if (data.contains('%')) {
          final percentMatch = RegExp(r'(\d+\.?\d*)%').firstMatch(data);
          if (percentMatch != null && mounted) {
            final percent = double.tryParse(percentMatch.group(1)!) ?? 0;
            setState(() {
              _downloadProgress = percent / 100;
              _downloadStatus = data.trim();
            });
          }
        } else if (mounted) {
          setState(() {
            _downloadStatus = data.trim();
          });
        }
      });

      process.stderr.transform(const SystemEncoding().decoder).listen((data) {
        debugPrint('yt-dlp stderr: $data');
      });

      final exitCode = await process.exitCode;

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatus = '';
        });
      }

      if (exitCode == 0) {
        _showMessage('Video downloaded successfully to:\n$outputDir');
      } else {
        _showMessage('Download failed with exit code: $exitCode');
      }
    } catch (e, stackTrace) {
      debugPrint('Error downloading video: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatus = '';
        });
      }
      _showMessage('Failed to download video: $e');
    }
  }

  void _downloadAudio() async {
    debugPrint('Download audio called');

    if (!_isWebViewReady) {
      _showMessage('WebView is not ready');
      return;
    }

    if (!_isYouTubeVideoUrl(_currentUrl)) {
      _showMessage('Please navigate to a YouTube video');
      return;
    }

    // Check if yt-dlp is installed
    final isInstalled = await _checkYtDlpInstalled();
    if (!isInstalled) {
      _showMessage(
        'yt-dlp is not installed!\n\n'
        'Install it using:\n'
        'Windows: winget install yt-dlp\n'
        'or download from: https://github.com/yt-dlp/yt-dlp/releases',
      );
      return;
    }

    if (mounted) {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
        _downloadStatus = 'Initializing...';
      });
    }

    try {
      // Get Downloads folder as default
      final downloadsDir = await getDownloadsDirectory();
      final outputDir = downloadsDir?.path ?? Directory.current.path;

      if (mounted) {
        setState(() {
          _downloadStatus = 'Starting download...';
        });
      }

      debugPrint('Starting yt-dlp audio download to: $outputDir');

      // Get the executable directory for cookies.txt
      final exeDir = Directory.current.path;
      final cookiesPath = p.join(exeDir, 'cookies.txt');

      // Check if cookies file exists
      final cookiesFile = File(cookiesPath);
      final hasCookies = await cookiesFile.exists();

      debugPrint('Cookies path: $cookiesPath');
      debugPrint('Cookies exist: $hasCookies');

      // Build arguments list
      final args = <String>[
        if (hasCookies) ...['--cookies', cookiesPath],
        '--format',
        'bestaudio',
        '--extract-audio',
        '--audio-format',
        'opus',
        '--output',
        p.join(outputDir, '%(title)s.%(ext)s'),
        '--newline',
        '--no-playlist',
        _currentUrl,
      ];

      // Run yt-dlp for audio extraction
      final process = await Process.start('yt-dlp', args);

      String fullOutput = '';
      String fullError = '';

      process.stdout.transform(const SystemEncoding().decoder).listen((data) {
        debugPrint('yt-dlp stdout: $data');
        fullOutput += data;

        // Parse progress from yt-dlp output
        if (data.contains('%')) {
          final percentMatch = RegExp(r'(\d+\.?\d*)%').firstMatch(data);
          if (percentMatch != null && mounted) {
            final percent = double.tryParse(percentMatch.group(1)!) ?? 0;
            setState(() {
              _downloadProgress = percent / 100;
              _downloadStatus = data.trim();
            });
          }
        } else if (mounted) {
          setState(() {
            _downloadStatus = data.trim();
          });
        }
      });

      process.stderr.transform(const SystemEncoding().decoder).listen((data) {
        debugPrint('yt-dlp stderr: $data');
        fullError += data;

        // Show cookie-related errors to user
        if (data.contains('403') || data.contains('Forbidden')) {
          if (mounted) {
            setState(() {
              _downloadStatus = 'Authentication error - cookies needed';
            });
          }
        }
      });

      final exitCode = await process.exitCode;

      debugPrint('OUTPUT:');
      debugPrint(fullOutput);
      if (fullError.isNotEmpty) {
        debugPrint('ERROR:');
        debugPrint(fullError);
      }

      // Post-processing based on output
      if (exitCode == 0) {
        if (fullOutput.toLowerCase().contains(
          'already in target format opus',
        )) {
          await _deleteLatestOpus(outputDir);
        } else {
          await _handleAudioPostProcessing(outputDir);
        }
      }

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatus = '';
        });
      }

      if (exitCode == 0) {
        _showMessage('Audio downloaded successfully to:\n$outputDir');
      } else if (exitCode == 1) {
        _showMessage(
          'Download failed - HTTP 403 Forbidden\n\n'
          'You need to export cookies from your browser:\n'
          '1. Install "Get cookies.txt LOCALLY" browser extension\n'
          '2. Go to YouTube and log in\n'
          '3. Click the extension and export cookies\n'
          '4. Save as "cookies.txt" in the app folder:\n'
          '$exeDir',
        );
      } else {
        _showMessage('Download failed with exit code: $exitCode');
      }
    } catch (e, stackTrace) {
      debugPrint('Error downloading audio: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _downloadStatus = '';
        });
      }
      _showMessage('Failed to download audio: $e');
    }
  }

  Future<void> _handleAudioPostProcessing(String outputDir) async {
    try {
      final dir = Directory(outputDir);
      final opusFiles = dir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.opus'))
          .toList();

      if (opusFiles.isEmpty) {
        debugPrint('No opus files found');
        return;
      }

      // Sort by creation time (newest first)
      opusFiles.sort(
        (a, b) => b.statSync().changed.compareTo(a.statSync().changed),
      );

      final latestOpus = opusFiles.first;
      final mp3Path = latestOpus.path.replaceAll('.opus', '.mp3');

      // Rename opus to mp3
      await latestOpus.rename(mp3Path);
      debugPrint('Audio saved as: ${p.basename(mp3Path)}');
    } catch (e) {
      debugPrint('Error in post-processing: $e');
    }
  }

  Future<void> _deleteLatestOpus(String outputDir) async {
    try {
      final dir = Directory(outputDir);
      final opusFiles = dir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.opus'))
          .toList();

      if (opusFiles.isEmpty) {
        debugPrint('No opus files to delete');
        return;
      }

      // Sort by creation time (newest first)
      opusFiles.sort(
        (a, b) => b.statSync().changed.compareTo(a.statSync().changed),
      );

      final latestOpus = opusFiles.first;
      await latestOpus.delete();
      debugPrint('Deleted redundant file: ${p.basename(latestOpus.path)}');
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _goBack() async {
    await _controller.goBack();
  }

  Future<void> _goForward() async {
    await _controller.goForward();
  }

  Future<void> _reload() async {
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Desktop'),
        centerTitle: true,
        leading: _currentView != 'home'
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _currentView = 'home';
                  });
                },
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              _isPanelCollapsed ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () {
              setState(() {
                _isPanelCollapsed = !_isPanelCollapsed;
              });
            },
            tooltip: _isPanelCollapsed ? 'Show Panel' : 'Hide Panel',
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: _isWebViewReady
                ? webview_win.Webview(_controller)
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading YouTube...'),
                      ],
                    ),
                  ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isPanelCollapsed ? 0 : 400,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                right: BorderSide(
                  color: _isPanelCollapsed
                      ? Colors.transparent
                      : Colors.grey[700]!,
                  width: 1,
                ),
              ),
            ),
            child: _isPanelCollapsed
                ? const SizedBox.shrink()
                : _currentView == 'home'
                ? _buildHomePanel()
                : _buildAlbumMakerPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomePanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusWidget(),
          const SizedBox(height: 24),
          _buildNavigationControls(),
          const SizedBox(height: 24),
          _buildUrlDisplay(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildAlbumMakerPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(76),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: const Row(
              children: [
                Icon(Icons.album, color: Colors.orange, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Album Maker',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildUrlDisplay(),
          const SizedBox(height: 24),
          const Text(
            'Album Metadata',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Album Title',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[850],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Artist',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[850],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Year',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[850],
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Genre',
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[850],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Album Art',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showMessage('Image picker not implemented yet');
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Album Art'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isWebViewReady && _isYouTubeVideoUrl(_currentUrl)
                ? () {
                    _showMessage('Album maker download not implemented yet');
                  }
                : null,
            icon: const Icon(Icons.download),
            label: const Text('Download as Album'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isWebViewReady
            ? Colors.green.withAlpha(76)
            : Colors.orange.withAlpha(76),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isWebViewReady ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isWebViewReady ? Icons.check_circle : Icons.hourglass_empty,
            color: _isWebViewReady ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isWebViewReady ? 'WebView Active' : 'Initializing...',
              style: TextStyle(
                color: _isWebViewReady ? Colors.green : Colors.orange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Navigation',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isWebViewReady ? _goBack : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isWebViewReady ? _goForward : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Forward'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isWebViewReady ? _reload : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(12),
              ),
              child: const Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUrlDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current URL:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(_currentUrl, style: const TextStyle(fontSize: 13)),
          if (_isYouTubeVideoUrl(_currentUrl)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(76),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.video_library, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Video detected - ready to download',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final buttonsEnabled =
        _isWebViewReady && _isYouTubeVideoUrl(_currentUrl) && !_isDownloading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Download Options',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        if (_isDownloading) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(76),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 8),
                Text(
                  _downloadStatus,
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_downloadProgress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
          onPressed: buttonsEnabled ? _downloadVideo : null,
          icon: _isDownloading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.video_file),
          label: const Text('Download Video'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue[700],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: buttonsEnabled ? _downloadAudio : null,
          icon: _isDownloading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.audiotrack),
          label: const Text('Download Audio'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.purple[700],
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _currentView = 'album_maker';
            });
          },
          icon: const Icon(Icons.album),
          label: const Text('Album Maker'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.orange[700],
          ),
        ),
      ],
    );
  }
}
