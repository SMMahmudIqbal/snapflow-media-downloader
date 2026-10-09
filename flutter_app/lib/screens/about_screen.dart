// Developed by S. M. Mahmud Iqbal
// SnapFlow Swiss Brutalist About Screen

import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          'SPEC // ATTRIBUTION',
          style: TextStyle(
            color: Color(0xFF1E1E1E),
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'REV 1.0',
                style: TextStyle(color: Color(0xFFDB4A2B), fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFF1E1E1E), width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF1E1E1E), offset: Offset(5, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: const Color(0xFFDB4A2B),
                    child: const Text(
                      'DEVELOPED BY S. M. MAHMUD IQBAL',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'SNAPFLOW // ENGINE',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1E1E),
                      height: 0.9,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Crafted under Swiss Brutalism principles: stark contrast, raw typographic energy, and functional beauty. An independent media harvesting architecture engineered as an ad-free, non-tracking alternative to legacy downloaders.',
                    style: TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSpecTile('DESIGN PRINCIPLE', 'Swiss Brutalism / Clash Display & Satoshi'),
            _buildSpecTile('PRIMARY PALETTE', '#E4E2DD (Base) • #1E1E1E (Ink) • #DB4A2B (Accent)'),
            _buildSpecTile('EXTRACTION ENGINE', 'Python 3 / yt-dlp Microservice'),
            _buildSpecTile('CLIENT RUNTIME', 'Flutter & Progressive Web Client'),
            _buildSpecTile('AUTHOR', 'Developed by S. M. Mahmud Iqbal'),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: const [
                  Text(
                    'DEVELOPED BY S. M. MAHMUD IQBAL',
                    style: TextStyle(
                      color: Color(0xFFDB4A2B),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ALL RIGHTS RESERVED • PRODUCTION RELEASE',
                    style: TextStyle(color: Color(0xFF777777), fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecTile(String key, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF1E1E1E), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF1E1E1E), offset: Offset(3, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(key, style: const TextStyle(color: Color(0xFFDB4A2B), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
