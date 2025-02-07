import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_colors.dart';

class WhiteSpotSyndromeVirusInformationScreen extends StatefulWidget {
  const WhiteSpotSyndromeVirusInformationScreen({super.key});

  @override
  _WhiteSpotSyndromeVirusInformationScreenState createState() =>
      _WhiteSpotSyndromeVirusInformationScreenState();
}

class _WhiteSpotSyndromeVirusInformationScreenState
    extends State<WhiteSpotSyndromeVirusInformationScreen> with SingleTickerProviderStateMixin {
  String? localPath;
  bool isLoading = true;
  int? totalPages;
  int? currentPage;
  late AnimationController _loadingController;
  bool _isToolbarVisible = true;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    loadPDF();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> loadPDF() async {
    try {
      final bytes = await rootBundle.load('lib/assets/pdfs/white_spot_syndrome_virus.pdf');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/white_spot_syndrome_virus.pdf');

      await file.writeAsBytes(bytes.buffer.asUint8List());

      setState(() {
        localPath = file.path;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        _showErrorDialog();
      }
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 8),
            Text('Error Loading PDF'),
          ],
        ),
        content: const Text(
          'Unable to load the document. Please check your internet connection and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              loadPDF();
            },
            child: const Text('RETRY'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePDF() async {
    if (localPath != null) {
      await Share.shareXFiles([XFile(localPath!)],
        subject: 'White Spot Syndrome Virus Information',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'lib/assets/images/primary-logo.png',
          height: 32,
        ),
        centerTitle: true,
        actions: [
          if (!isLoading && localPath != null)
            IconButton(
              icon: const Icon(Icons.share, color: AppColors.text),
              onPressed: _sharePDF,
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          // Title with icon
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.article_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'WHITE SPOT SYNDROME VIRUS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // PDF View
          Expanded(
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: _loadingController.drive(
                      ColorTween(
                        begin: AppColors.primary,
                        end: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading document...',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : localPath == null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load PDF',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: loadPDF,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            )
                : GestureDetector(
              onTap: () {
                setState(() {
                  _isToolbarVisible = !_isToolbarVisible;
                });
              },
              child: Stack(
                children: [
                  PDFView(
                    filePath: localPath!,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: true,
                    pageSnap: true,
                    defaultPage: 0,
                    fitPolicy: FitPolicy.BOTH,
                    preventLinkNavigation: false,
                    onRender: (pages) {
                      setState(() {
                        totalPages = pages;
                      });
                    },
                    onError: (error) {
                      _showErrorDialog();
                    },
                    onPageError: (page, error) {
                      _showErrorDialog();
                    },
                    onPageChanged: (page, total) {
                      setState(() {
                        currentPage = page;
                      });
                    },
                  ),
                  if (_isToolbarVisible && currentPage != null && totalPages != null)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Page ${currentPage! + 1} of $totalPages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}