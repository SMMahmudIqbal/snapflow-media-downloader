// Developed by S. M. Mahmud Iqbal
// SnapFlow Swiss Brutalist Home Screen

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final Function(DownloadedTask) onDownloadComplete;

  const HomeScreen({super.key, required this.onDownloadComplete});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  MediaInfo? _mediaInfo;
  String? _errorMessage;

  // Downloading state
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatusText = '';

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null) {
      setState(() {
        _urlController.text = data.text!.trim();
      });
    }
  }

  Future<void> _extractMedia() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'SPECIFY A VALID TARGET URL.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mediaInfo = null;
    });

    try {
      final info = await _apiService.extractMedia(url);
      setState(() {
        _mediaInfo = info;
      });
      if (mounted) {
        _showFormatPicker(info);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim().toUpperCase();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showFormatPicker(MediaInfo info) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFE4E2DD),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Color(0xFF1E1E1E), width: 3),
        borderRadius: BorderRadius.zero,
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 4,
                  color: const Color(0xFF1E1E1E),
                ),
                const SizedBox(height: 12),
                const Text(
                  'SELECT DECODED STREAM',
                  style: TextStyle(
                    color: Color(0xFF1E1E1E),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'DEVELOPED BY S. M. MAHMUD IQBAL',
                  style: TextStyle(
                    color: Color(0xFFDB4A2B),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                const TabBar(
                  indicatorColor: Color(0xFFDB4A2B),
                  labelColor: Color(0xFFDB4A2B),
                  unselectedLabelColor: Color(0xFF1E1E1E),
                  indicatorWeight: 3,
                  tabs: [
                    Tab(text: '01 // VIDEO (MP4)'),
                    Tab(text: '02 // AUDIO (MP3)'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  child: TabBarView(
                    children: [
                      // Video formats
                      ListView.builder(
                        itemCount: info.videoFormats.length,
                        itemBuilder: (c, i) {
                          final f = info.videoFormats[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
                              boxShadow: const [
                                BoxShadow(color: Color(0xFF1E1E1E), offset: Offset(2, 2)),
                              ],
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                color: const Color(0xFF1E1E1E),
                                child: Text(
                                  f.resolution ?? 'HD',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                                ),
                              ),
                              title: Text(
                                f.label.toUpperCase(),
                                style: const TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              subtitle: Text(
                                '${f.filesizeStr} // ${f.ext.toUpperCase()}',
                                style: const TextStyle(color: Color(0xFF555555), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDB4A2B),
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _startDownload(info, f, isAudio: false);
                                },
                                child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                          );
                        },
                      ),
                      // Audio formats
                      ListView.builder(
                        itemCount: info.audioFormats.length,
                        itemBuilder: (c, i) {
                          final f = info.audioFormats[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
                              boxShadow: const [
                                BoxShadow(color: Color(0xFF1E1E1E), offset: Offset(2, 2)),
                              ],
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                color: const Color(0xFFF8A348),
                                child: const Text(
                                  'MP3',
                                  style: TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.w900, fontSize: 11),
                                ),
                              ),
                              title: Text(
                                f.label.toUpperCase(),
                                style: const TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                              subtitle: Text(
                                '${f.filesizeStr} // ${f.quality ?? ""}',
                                style: const TextStyle(color: Color(0xFF555555), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDB4A2B),
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _startDownload(info, f, isAudio: true);
                                },
                                child: const Text('EXTRACT', style: TextStyle(fontWeight: FontWeight.w900)),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startDownload(MediaInfo info, FormatOption format, {required bool isAudio}) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatusText = 'INITIALIZING STREAM PIPELINE...';
    });

    try {
      final savedPath = await _apiService.downloadMedia(
        mediaUrl: info.url,
        formatId: format.formatId,
        isAudio: isAudio,
        title: info.title,
        onProgress: (progress, status) {
          setState(() {
            _downloadProgress = progress;
            _downloadStatusText = status.toUpperCase();
          });
        },
      );

      final task = DownloadedTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: info.title,
        filePath: savedPath,
        qualityLabel: format.label,
        isAudio: isAudio,
        date: DateTime.now(),
      );

      widget.onDownloadComplete(task);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E1E1E),
            content: Text(
              'SAVED TO ARCHIVE: ${info.title.toUpperCase()}',
              style: const TextStyle(color: Color(0xFFE4E2DD), fontWeight: FontWeight.w800),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDB4A2B),
            content: Text(
              'TRANSMISSION ERROR: $e',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E2DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE4E2DD),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: const Color(0xFF1E1E1E), height: 3),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: const Color(0xFFDB4A2B),
              child: const Text('✕', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'SNAPFLOW',
                  style: TextStyle(
                    fontFamily: 'Clash Display',
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Color(0xFF1E1E1E),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'DEVELOPED BY S. M. MAHMUD IQBAL',
                  style: TextStyle(
                    color: Color(0xFFDB4A2B),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: const Color(0xFFDB4A2B),
                  child: const Text('SWISS BRUTALIST ENGINE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1E1E1E), width: 1.5)),
                  child: const Text('NO ADS // PRIVACY-FIRST', style: TextStyle(color: Color(0xFF1E1E1E), fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'EXTRACT.\nDOWNLOAD.\nANY MEDIA.',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E1E1E),
                height: 0.88,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            // Input Box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF1E1E1E), width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF1E1E1E), offset: Offset(4, 4)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: const Color(0xFF1E1E1E),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('TARGET RESOURCE URL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        Text('INPUT_01', style: TextStyle(color: Color(0xFFF8A348), fontSize: 10, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          style: const TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            hintText: 'PASTE LINK HERE...',
                            hintStyle: TextStyle(color: Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.w600),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: _pasteFromClipboard,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          color: const Color(0xFFE4E2DD),
                          child: const Text('PASTE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF1E1E1E))),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _isLoading ? null : _extractMedia,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: const Color(0xFFDB4A2B),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : const Text(
                                'INITIALIZE EXTRACTION',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.2),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFDB4A2B),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ],
            if (_isDownloading) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF1E1E1E), width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1E1E1E), offset: Offset(4, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TRANSMITTING STREAM...', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        Text('${(_downloadProgress * 100).toInt()}%', style: const TextStyle(color: Color(0xFFDB4A2B), fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                      backgroundColor: const Color(0xFFE4E2DD),
                      color: const Color(0xFFDB4A2B),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 6),
                    Text(_downloadStatusText, style: const TextStyle(color: Color(0xFF666666), fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
            if (_mediaInfo != null) ...[
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF1E1E1E), width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFF1E1E1E), offset: Offset(4, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_mediaInfo!.thumbnail.isNotEmpty)
                      Image.network(
                        _mediaInfo!.thumbnail,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                color: const Color(0xFF1E1E1E),
                                child: Text(_mediaInfo!.platform.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                              ),
                              const SizedBox(width: 8),
                              Text(_mediaInfo!.durationStr, style: const TextStyle(color: Color(0xFF666666), fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _mediaInfo!.title.toUpperCase(),
                            maxLines: 2,
                            overflow: TextTransitions.ellipsis,
                            style: const TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.w900, fontSize: 16, height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          Text('SOURCE: ${_mediaInfo!.uploader.toUpperCase()}', style: const TextStyle(color: Color(0xFF666666), fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDB4A2B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                              ),
                              onPressed: () => _showFormatPicker(_mediaInfo!),
                              child: const Text('SELECT QUALITY & DOWNLOAD', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 36),
            // Footer Attribution
            Center(
              child: Column(
                children: const [
                  Text(
                    'DEVELOPED BY S. M. MAHMUD IQBAL',
                    style: TextStyle(color: Color(0xFFDB4A2B), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                  ),
                  SizedBox(height: 4),
                  Text('SWISS BRUTALIST SPECIFICATION • ARCHIVE ED.', style: TextStyle(color: Color(0xFF777777), fontSize: 10, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
