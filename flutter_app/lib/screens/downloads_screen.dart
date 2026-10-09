// Developed by S. M. Mahmud Iqbal
// SnapFlow Swiss Brutalist Downloads Manager Screen

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../models/media_item.dart';

class DownloadsScreen extends StatefulWidget {
  final List<DownloadedTask> tasks;
  final VoidCallback onClear;

  const DownloadsScreen({
    super.key,
    required this.tasks,
    required this.onClear,
  });

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
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
        title: const Text(
          'ARCHIVE & CACHE',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          if (widget.tasks.isNotEmpty)
            TextButton(
              onPressed: () {
                widget.onClear();
                setState(() {});
              },
              child: const Text('PURGE', style: TextStyle(color: Color(0xFFDB4A2B), fontWeight: FontWeight.w900)),
            ),
        ],
      ),
      body: widget.tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    '[ EMPTY ARCHIVE ]',
                    style: TextStyle(color: Color(0xFF1E1E1E), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'NO DECODED STREAMS CURRENTLY STORED IN LOCAL CACHE.',
                    style: TextStyle(color: Color(0xFF777777), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'DEVELOPED BY S. M. MAHMUD IQBAL',
                    style: TextStyle(color: Color(0xFFDB4A2B), fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.tasks.length,
              itemBuilder: (context, index) {
                final task = widget.tasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF1E1E1E), offset: Offset(3, 3)),
                    ],
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: task.isAudio ? const Color(0xFFF8A348) : const Color(0xFF1E1E1E),
                      child: Text(
                        task.isAudio ? 'MP3' : 'MP4',
                        style: TextStyle(
                          color: task.isAudio ? const Color(0xFF1E1E1E) : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    title: Text(
                      task.title.toUpperCase(),
                      maxLines: 1,
                      overflow: TextTransitions.ellipsis,
                      style: const TextStyle(color: Color(0xFF1E1E1E), fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    subtitle: Text(
                      '${task.qualityLabel.toUpperCase()} // LOGGED AT ${task.date.hour}:${task.date.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Color(0xFF666666), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDB4A2B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      onPressed: () async {
                        if (File(task.filePath).existsSync()) {
                          await OpenFilex.open(task.filePath);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('FILE REMOVED FROM STORAGE')),
                          );
                        }
                      },
                      child: const Text('OPEN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
