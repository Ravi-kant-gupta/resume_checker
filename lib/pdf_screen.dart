import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';

import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:resume_checker/widget/textfields_widget.dart';

class PDFReaderHome extends StatefulWidget {
  const PDFReaderHome({super.key});

  @override
  _PDFReaderHomeState createState() => _PDFReaderHomeState();
}

class _PDFReaderHomeState extends State<PDFReaderHome> {
  String _pdfText = 'No PDF selected';
  TextEditingController _textEditingController = TextEditingController();
  List<String> _textList = [];
  double _matchedPercentage = 0.0;
  String _pdfFileName = '';
  String? _pdfFilePath; // Added for PDF preview
  bool _isLoading = false;
  bool _showPreview = false; // Toggle between text and preview
  
  // PDF Preview related variables
  PDFViewController? _pdfController;
  int _totalPages = 0;
  int _currentPage = 0;

  List<String> skillsHint = [
    'Flutter',
    'Dart',
    'OOP',
    'Firebase',
    'Python',
    'Java',
    'C++',
    'JavaScript',
    'React',
    'Node.js',
    'SQL',
    'NoSQL',
    'HTML',
    'CSS',
    'Angular',
    'Vue.js',
    'Kotlin',
    'Swift',
    'AWS',
    'Docker',
    'Kubernetes',
    'Git',
    'Linux',
    'REST API',
    'GraphQL',
    'CI/CD',
    'MongoDB',
    'PostgreSQL',
    'MySQL',
    'Express.js',
    'TypeScript',
    'Jira',
    'Figma',
    'UI/UX Design',
  ];

  String extractSkillsSection(String text) {
    final lowerText = text.toLowerCase();
    final lines = text.split('\n');

    final startKeywords = ['skills', 'technical skills'];
    final endKeywords = [
      'experience',
      'education',
      'projects',
      'certifications'
    ];

    bool inSkillsSection = false;
    List<String> skillsSection = [];

    for (var line in lines) {
      final lineLower = line.toLowerCase().trim();

      if (!inSkillsSection &&
          startKeywords.any((keyword) => lineLower.contains(keyword))) {
        inSkillsSection = true;
        continue;
      }

      if (inSkillsSection &&
          endKeywords.any((keyword) => lineLower.contains(keyword))) {
        break;
      }

      if (inSkillsSection) {
        skillsSection.add(line);
      }
    }

    return skillsSection.join('\n').trim();
  }

  Future<double> _matchedItemsPercentage() async {
    if (_textList.isEmpty || _pdfText.isEmpty) return 0.0;

    String lowerText = _pdfText.toLowerCase();

    bool containsPartialWord(String text, String phrase) {
      List<String> words = phrase.toLowerCase().split(' ');
      List<String> textWords = text.split(' ');
      return words.any((word) => textWords.any((textWord) => textWord.contains(word) || word.contains(textWord)));
    }

    int matchedCount = _textList.where((item) => containsPartialWord(lowerText, item)).length;

    return (matchedCount / _textList.length) * 100;
  }

  Future<void> _pickAndReadPDF() async {
    if (_textList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add required skills first'),
          backgroundColor: Colors.pink[400],
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      
      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        _pdfText = await ReadPdfText.getPDFtext(file.path);
        _pdfFileName = result.files.single.name;
        _pdfFilePath = result.files.single.path; // Store file path for preview
        _matchedPercentage = await _matchedItemsPercentage();
        
        setState(() {
          // PDF loaded successfully
        });
      } else {
        setState(() {
          _pdfText = 'No file selected';
          _pdfFilePath = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearPDF() {
    setState(() {
      _pdfText = 'No PDF selected';
      _pdfFileName = '';
      _pdfFilePath = null;
      _matchedPercentage = 0.0;
      _totalPages = 0;
      _currentPage = 0;
      _showPreview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text('PDF Text Reader'),
        backgroundColor: Colors.pink[300],
        foregroundColor: Colors.white,
        actions: [
          if (_pdfFilePath != null) ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _showPreview = !_showPreview;
                });
              },
              icon: Icon(_showPreview ? Icons.text_fields : Icons.preview),
              tooltip: _showPreview ? 'Show Text' : 'Show Preview',
            ),
            IconButton(
              onPressed: _clearPDF,
              icon: Icon(Icons.clear),
              tooltip: 'Clear PDF',
            ),
          ],
          IconButton(
            onPressed: () async {
              if (_pdfFilePath != null) {
                _matchedPercentage = await _matchedItemsPercentage();
                setState(() {});
              }
            },
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Skills input section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 6,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SuggestionTextField(
                          controller: _textEditingController,
                          suggestions: skillsHint,
                          maxSuggestions: skillsHint.length,
                          hintText: 'Enter Skills...',
                          onSuggestionSelected: (suggestion) {
                            _textEditingController.text = suggestion;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          if (_textEditingController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('Please enter some text'),
                                  ],
                                ),
                                backgroundColor: Colors.pink[400],
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            if (!_textList.contains(_textEditingController.text.trim())) {
                              _textList.add(_textEditingController.text.trim());
                            }
                            _textEditingController.clear();
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.pink[400]!, Colors.pink[300]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.pinkAccent, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pinkAccent.withOpacity(0.18),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: Offset(1, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Skills display section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  (_textList.isEmpty)
                      ? Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.pink[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.pink[200]!, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withOpacity(0.08),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, color: Colors.pink[400], size: 20),
                              SizedBox(width: 8),
                              Text(
                                "No Skills Selected",
                                style: TextStyle(
                                  color: Colors.pink[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _textList
                              .map((item) => Chip(
                                    label: Text(
                                      item,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    backgroundColor: Colors.pink[400],
                                    deleteIcon: Icon(Icons.cancel, size: 18),
                                    onDeleted: () {
                                      setState(() {
                                        _textList.remove(item);
                                      });
                                    },
                                    deleteIconColor: Colors.white,
                                    elevation: 3,
                                    padding: EdgeInsets.symmetric(horizontal: 2),
                                  ))
                              .toList(),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // PDF info section
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
            //   child: Container(
            //     decoration: BoxDecoration(
            //       color: Colors.white,
            //       borderRadius: BorderRadius.circular(15),
            //       border: Border.all(color: Colors.pink[300]!, width: 1),
            //       boxShadow: [
            //         BoxShadow(
            //           color: Colors.pink.withOpacity(0.1),
            //           blurRadius: 8,
            //           offset: Offset(0, 2),
            //         ),
            //       ],
            //     ),
            //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            //     child: Row(
            //       children: [
            //         Container(
            //           padding: EdgeInsets.all(8),
            //           decoration: BoxDecoration(
            //             color: Colors.pink[100],
            //             borderRadius: BorderRadius.circular(10),
            //           ),
            //           child: Icon(Icons.picture_as_pdf,
            //               color: Colors.pink[600], size: 20),
            //         ),
            //         SizedBox(width: 12),
            //         Expanded(
            //           child: Text(
            //             _pdfFileName.isNotEmpty
            //                 ? _pdfFileName
            //                 : 'No PDF selected',
            //             style: TextStyle(
            //               color: Colors.grey[700],
            //               fontSize: 15,
            //               fontWeight: FontWeight.w500,
            //             ),
            //             overflow: TextOverflow.ellipsis,
            //           ),
            //         ),
            //         SizedBox(width: 12),
            //         Container(
            //           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //           decoration: BoxDecoration(
            //             gradient: LinearGradient(
            //               colors: [Colors.pink[300]!, Colors.pink[400]!],
            //               begin: Alignment.topLeft,
            //               end: Alignment.bottomRight,
            //             ),
            //             borderRadius: BorderRadius.circular(12),
            //             boxShadow: [
            //               BoxShadow(
            //                 color: Colors.pink.withOpacity(0.3),
            //                 blurRadius: 6,
            //                 offset: Offset(0, 2),
            //               ),
            //             ],
            //           ),
            //           child: Row(
            //             mainAxisSize: MainAxisSize.min,
            //             children: [
            //               Icon(Icons.analytics_outlined,
            //                   color: Colors.white, size: 18),
            //               SizedBox(width: 8),
            //               Text(
            //                 '${_matchedPercentage.toStringAsFixed(1)}%',
            //                 style: TextStyle(
            //                   fontSize: 14,
            //                   fontWeight: FontWeight.w600,
            //                   color: Colors.white,
            //                   letterSpacing: 0.5,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.pink[300]!, Colors.pink[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.3),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.analytics_outlined,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '${_matchedPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // PDF content section (Preview or Text)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 6,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _pdfFilePath != null
                        ? (_showPreview ? _buildPDFPreview() : _buildTextView())
                        : _buildEmptyState(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: _isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.upload_file, color: Colors.white),
        backgroundColor: Colors.pink[400],
        elevation: 6,
        onPressed: _isLoading ? null : _pickAndReadPDF,
        tooltip: 'Pick PDF File',
      ),
    );
  }

  Widget _buildPDFPreview() {
    return Column(
      children: [
        // Page navigation
        if (_totalPages > 0)
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentPage > 0
                      ? () {
                          _pdfController?.setPage(_currentPage - 1);
                        }
                      : null,
                  icon: Icon(Icons.chevron_left),
                ),
                Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  onPressed: _currentPage < _totalPages - 1
                      ? () {
                          _pdfController?.setPage(_currentPage + 1);
                        }
                      : null,
                  icon: Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        // PDF viewer
        Expanded(
          child: PDFView(
            filePath: _pdfFilePath!,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: 0,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              setState(() {
                _totalPages = pages!;
              });
            },
            onViewCreated: (PDFViewController controller) {
              _pdfController = controller;
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                _currentPage = page!;
              });
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error loading PDF: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextView() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink[300]!.withOpacity(0.3), width: 1),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Text(
          _pdfText,
          style: TextStyle(
            height: 1.6,
            color: Colors.grey[700],
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 20),
          Text(
            'Select a PDF file to analyze',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Add skills first, then upload your PDF',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}