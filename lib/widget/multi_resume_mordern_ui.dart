// ignore_for_file: deprecated_member_use

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';

import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:resume_checker/widget/textfields_widget.dart';

class PDFReaderHome extends StatefulWidget {
  const PDFReaderHome({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PDFReaderHomeState createState() => _PDFReaderHomeState();
}

class _PDFReaderHomeState extends State<PDFReaderHome>
    with TickerProviderStateMixin {
  String _pdfText = 'No PDF selected';
  TextEditingController _textEditingController = TextEditingController();
  List<String> _textList = [];
  double _matchedPercentage = 0.0;
  String _pdfFileName = '';
  String? _pdfFilePath;
  bool _isLoading = false;
  
  // Animation controllers
  late AnimationController _fabAnimationController;
  late AnimationController _cardAnimationController;
  late AnimationController _skillsAnimationController;
  late AnimationController _percentageAnimationController;
  
  // Animations
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _percentageAnimation;
  
  // PDF Preview related variables
  PDFViewController? _pdfController;
  int _totalPages = 0;
  int _currentPage = 0;

  List<String> skillsHint = [
    'Flutter', 'Dart', 'OOP', 'Firebase', 'Python', 'Java', 'C++',
    'JavaScript', 'React', 'Node.js', 'SQL', 'NoSQL', 'HTML', 'CSS',
    'Angular', 'Vue.js', 'Kotlin', 'Swift', 'AWS', 'Docker', 'Kubernetes',
    'Git', 'Linux', 'REST API', 'GraphQL', 'CI/CD', 'MongoDB', 'PostgreSQL',
    'MySQL', 'Express.js', 'TypeScript', 'Jira', 'Figma', 'UI/UX Design',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _skillsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _percentageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));


    _percentageAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _percentageAnimationController,
      curve: Curves.easeOutQuart,
    ));

    // Start animations
    _fabAnimationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _cardAnimationController.dispose();
    _skillsAnimationController.dispose();
    _percentageAnimationController.dispose();
    super.dispose();
  }

 // Optimized and corrected version

String extractSkillsSection(String text) {
  if (text.isEmpty) return '';
  
  final lines = text.split('\n');
  final startKeywords = ['skills', 'technical skills', 'core competencies', 'expertise'];
  final endKeywords = ['experience', 'education', 'projects', 'certifications', 'awards', 'achievements'];

  int? startIndex;
  int? endIndex;

  // Find start of skills section
  for (int i = 0; i < lines.length; i++) {
    final lineLower = lines[i].toLowerCase().trim();
    if (startKeywords.any((keyword) => lineLower.contains(keyword))) {
      startIndex = i + 1; // Start from next line after header
      break;
    }
  }

  if (startIndex == null) return '';

  // Find end of skills section
  for (int i = startIndex; i < lines.length; i++) {
    final lineLower = lines[i].toLowerCase().trim();
    if (endKeywords.any((keyword) => lineLower.contains(keyword))) {
      endIndex = i;
      break;
    }
  }

  // Extract skills section
  final skillsLines = lines.sublist(
    startIndex, 
    endIndex ?? lines.length
  ).where((line) => line.trim().isNotEmpty); // Filter empty lines

  return skillsLines.join('\n').trim();
}

// Extract individual skills from the skills section
List<String> extractIndividualSkills(String skillsSection) {
  if (skillsSection.isEmpty) return [];
  
  List<String> skills = [];
  List<String> lines = skillsSection.split('\n');
  
  for (String line in lines) {
    if (line.trim().isEmpty) continue;
    
    // Clean the line and split by common separators
    String cleanLine = line
        .replaceAll(RegExp(r'[•▪▫◦‣⁃→]'), ',') // Replace bullet points
        .replaceAll(RegExp(r'[-–—]'), ',') // Replace dashes
        .replaceAll(RegExp(r'[:\(\)]'), ','); // Replace colons and parentheses
    
    // Split by common separators
    List<String> lineSkills = cleanLine
        .split(RegExp(r'[,;|&]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 2) // Filter short/empty strings
        .map((s) => s.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '')) // Remove leading/trailing non-word chars
        .where((s) => s.isNotEmpty)
        .toList();
    
    skills.addAll(lineSkills);
  }
  
  // Remove duplicates and return
  return skills.toSet().toList();
}

// Get skills that don't match current skills
List<String> getNonMatchingSkills(List<String> pdfSkills, List<String> currentSkills) {
  List<String> nonMatching = [];
  
  for (String pdfSkill in pdfSkills) {
    bool isMatched = false;
    String lowerPdfSkill = pdfSkill.toLowerCase();
    
    for (String currentSkill in currentSkills) {
      String lowerCurrentSkill = currentSkill.toLowerCase();
      
      // Check for various types of matches
      if (_skillsMatch(lowerPdfSkill, lowerCurrentSkill)) {
        isMatched = true;
        break;
      }
    }
    
    if (!isMatched) {
      nonMatching.add(pdfSkill);
    }
  }
  
  return nonMatching;
}

// Enhanced skill matching logic
bool _skillsMatch(String skill1, String skill2) {
  // Exact match
  if (skill1 == skill2) return true;
  
  // Contains match
  if (skill1.contains(skill2) || skill2.contains(skill1)) return true;
  
  // Word-level matching
  List<String> words1 = skill1.split(RegExp(r'[^\w]+'));
  List<String> words2 = skill2.split(RegExp(r'[^\w]+'));
  
  // Check if any significant words match
  for (String word1 in words1) {
    if (word1.length > 2) {
      for (String word2 in words2) {
        if (word2.length > 2) {
          if (word1 == word2 || 
              word1.contains(word2) || 
              word2.contains(word1) ||
              _calculateSimilarity(word1, word2) > 0.8) {
            return true;
          }
        }
      }
    }
  }
  
  return false;
}

double _calculateMatchPercentage() {
  if (_textList.isEmpty || _pdfText.isEmpty) return 0.0;

  final lowerPdfText = _pdfText.toLowerCase();
  final pdfWords = Set<String>.from(
    lowerPdfText.split(RegExp(r'[^\w]+'))
        .where((word) => word.length > 2) // Filter short words
  );

  int matchedCount = 0;
  
  for (final skill in _textList) {
    final skillWords = skill.toLowerCase().split(RegExp(r'[^\w]+'));
    
    // Check if any skill word matches (partial or complete)
    bool hasMatch = skillWords.any((skillWord) {
      if (skillWord.length <= 2) return false;
      
      return pdfWords.any((pdfWord) => 
        pdfWord.contains(skillWord) || 
        skillWord.contains(pdfWord) ||
        _calculateSimilarity(skillWord, pdfWord) > 0.8
      );
    });
    
    if (hasMatch) matchedCount++;
  }

  return (matchedCount / _textList.length) * 100;
}

// Helper method for fuzzy matching
double _calculateSimilarity(String a, String b) {
  if (a == b) return 1.0;
  if (a.length < 3 || b.length < 3) return 0.0;
  
  final longer = a.length > b.length ? a : b;
  final shorter = a.length > b.length ? b : a;
  
  if (longer.isEmpty) return 1.0;
  
  return (longer.length - _levenshteinDistance(longer, shorter)) / longer.length;
}

int _levenshteinDistance(String s1, String s2) {
  if (s1 == s2) return 0;
  if (s1.isEmpty) return s2.length;
  if (s2.isEmpty) return s1.length;

  List<List<int>> matrix = List.generate(
    s1.length + 1, 
    (i) => List.filled(s2.length + 1, 0)
  );

  for (int i = 0; i <= s1.length; i++) {
    matrix[i][0] = i;
  }
  for (int j = 0; j <= s2.length; j++) {
    matrix[0][j] = j;
  }

  for (int i = 1; i <= s1.length; i++) {
    for (int j = 1; j <= s2.length; j++) {
      int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
      matrix[i][j] = [
        matrix[i - 1][j] + 1,     // deletion
        matrix[i][j - 1] + 1,     // insertion
        matrix[i - 1][j - 1] + cost // substitution
      ].reduce((a, b) => a < b ? a : b);
    }
  }

  return matrix[s1.length][s2.length];
}

Future<void> _pickAndReadPDF() async {
  // Early validation
  if (_textList.isEmpty) {
    _showSnackBar(
      'Please add required skills first',
      Colors.amber,
      Icons.warning_amber_rounded,
    );
    return;
  }

  setState(() {
    _isLoading = true;
// Reset preview state
    _nonMatchingSkills = []; // Reset non-matching skills
  });

  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result?.files.single.path == null) {
      // User cancelled selection
      _resetPdfState();
      return;
    }

    final file = File(result!.files.single.path!);
    
    // Validate file exists and is readable
    if (!await file.exists()) {
      throw Exception('Selected file does not exist');
    }

    // Extract text from PDF
    final extractedText = await ReadPdfText.getPDFtext(file.path);
    
    if (extractedText.trim().isEmpty) {
      throw Exception('PDF appears to be empty or text could not be extracted');
    }

    // Update state with extracted data
    _pdfText = extractedText;
    _pdfFileName = result.files.single.name;
    _pdfFilePath = result.files.single.path;
    
    // Calculate match percentage
    _matchedPercentage = _calculateMatchPercentage();
    
    // Extract and analyze skills for non-matching ones
    String skillsSection = extractSkillsSection(_pdfText);
    List<String> pdfSkills = extractIndividualSkills(skillsSection);
    _nonMatchingSkills = getNonMatchingSkills(pdfSkills, _textList);
    
    // Animate percentage change
    _percentageAnimationController.reset();
    _percentageAnimationController.forward();
    
    String message = 'PDF analyzed successfully! Match: ${_matchedPercentage.toStringAsFixed(1)}%';
    // if (_nonMatchingSkills.isNotEmpty) {
    //   message += '\n${_nonMatchingSkills.length} additional skills found';
    // }
    
    _showSnackBar(
      message,
      Colors.green,
      Icons.check_circle_rounded,
    );
    
  } catch (e) {
    _resetPdfState();
    _showSnackBar(
      'Error processing PDF: ${e.toString()}',
      Colors.red,
      Icons.error_rounded,
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

// Widget to display non-matching skills in red color
Widget buildNonMatchingSkillsWidget() {
  if (_nonMatchingSkills.isEmpty) {
    return const SizedBox.shrink();
  }
  
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Additional Skills Found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Skills present in PDF but not in your current requirements:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _nonMatchingSkills.map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                skill,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Consider adding these skills to your requirements if relevant.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ),
  );
}

// Helper method to reset PDF state
void _resetPdfState() {
  setState(() {
    _pdfText = '';
    _pdfFileName = '';
    _pdfFilePath = null;
    _matchedPercentage = 0.0;
    _nonMatchingSkills = [];
  });
}

// Add this variable to your class state variables
List<String> _nonMatchingSkills = [];

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  void _clearPDF() {
    setState(() {
      _pdfText = 'No PDF selected';
      _pdfFileName = '';
      _pdfFilePath = null;
      _matchedPercentage = 0.0;
      _totalPages = 0;
      _currentPage = 0;
    });
    _percentageAnimationController.reset();
  }

  void _addSkill() {
    if (_textEditingController.text.trim().isEmpty) {
      _showSnackBar(
        'Please enter a skill',
        Colors.orange,
        Icons.info_rounded,
      );
      return;
    }

    setState(() {
      if (!_textList.contains(_textEditingController.text.trim())) {
        _textList.add(_textEditingController.text.trim());
        _skillsAnimationController.forward();
      }
      _textEditingController.clear();
    });

    // Haptic feedback simulation
    Future.delayed(const Duration(milliseconds: 100), () {
      _skillsAnimationController.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, 
      backgroundColor: const Color(0xFF0A0E21),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildSkillsSection(),
                      _buildAnalyticsSection(),
                      _buildContentSection(),
                      const SizedBox(height: 100,)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:MediaQuery.of(context).viewInsets.bottom > 0
      ? null // Hide FAB when keyboard is visible
      : ScaleTransition(
        scale: _fabScaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _isLoading ? null : _pickAndReadPDF,
            backgroundColor: const Color(0xFF00D4FF),
            elevation: 0,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.upload_file_rounded, color: Colors.white),
            label: Text(
              _isLoading ? 'Analyzing...' : 'Upload PDF',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4FF), Color(0xFF5B86E5)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00D4FF).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume Analyzer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
            IconButton(
            icon: Icon(Icons.lightbulb_outline_rounded, color: Colors.yellow[700]),
            tooltip: 'AI Feature (Coming Soon)',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Colors.yellow[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                  child: Text(
                    'AI feature coming soon!',
                    style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    ),
                  ),
                  ),
                ],
                ),
                backgroundColor: Colors.black87,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.all(16),
                elevation: 8,
              ),
              );
            },
            )
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, String tooltip, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return SlideTransition(
      position: _cardSlideAnimation,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Required Skills',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SuggestionTextField(
              controller: _textEditingController,
              suggestions: skillsHint,
              maxSuggestions: skillsHint.length,
              hintText: 'Type to add skills...',
              onSuggestionSelected: (suggestion) {
                _textEditingController.text = suggestion;
              },
            ),
            const SizedBox(height: 16),
            _buildAddButton(),
            const SizedBox(height: 20),
            _buildSkillsDisplay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _addSkill,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'Add Skill',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.list_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Added Skills (${_textList.length})',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _textList.isEmpty
            ? _buildEmptySkillsState()
            : Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _textList.asMap().entries.map((entry) {
                int index = entry.key;
                String item = entry.value;
                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: _buildSkillChip(item),
                    );
                  },
                );
              }).toList(),
            ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _nonMatchingSkills.contains(skill)? 
          [const Color.fromARGB(255, 252, 29, 29), const Color.fromARGB(255, 253, 4, 4)]:
          [const Color(0xFF00D4FF), const Color(0xFF5B86E5)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4FF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            skill,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _textList.remove(skill);
              });
            },
            child: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySkillsState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.white.withOpacity(0.6),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No skills added yet. Start by adding required skills.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF667eea).withOpacity(0.1),
            const Color(0xFF764ba2).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Match Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_pdfFilePath != null) ...[
                const Spacer(),
                _buildHeaderAction(
                  Icons.refresh_rounded,
                  'Refresh',
                  () async {
                    if (_pdfFilePath != null) {
                      _matchedPercentage = _calculateMatchPercentage();
                      _percentageAnimationController.reset();
                      _percentageAnimationController.forward();
                      setState(() {});
                    }
                  },
                ),
              ]
            ],
          ),
          const SizedBox(height: 20),
          _buildPercentageIndicator(),
          const SizedBox(height: 16),
          if (_pdfFileName.isNotEmpty) _buildFileInfo(),
        ],
      ),
    );
  }

  Widget _buildPercentageIndicator() {
    return AnimatedBuilder(
      animation: _percentageAnimation,
      builder: (context, child) {
        double animatedPercentage = _percentageAnimation.value * _matchedPercentage;
        return SizedBox(
          height: 120,
          width: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(
                  value: animatedPercentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    animatedPercentage > 70
                        ? const Color(0xFF4CAF50)
                        : animatedPercentage > 40
                            ? const Color(0xFFFF9800)
                            : const Color(0xFFf44336),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${animatedPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Match Rate',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_rounded,
            color: Color(0xFF00D4FF),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Text(
            _pdfFileName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'PDF Document',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
              ],
            ),
          ),
          InkWell(
            onTap: _clearPDF,
            borderRadius: BorderRadius.circular(24),
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
          Icons.clear,
          color: Colors.white,
              ),
            ),
            // Optionally add tooltip using Tooltip widget
            // child: Tooltip(
            //   message: 'Clear PDF',
            //   child: Icon(Icons.clear, color: Colors.white),
            // ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      margin: const EdgeInsets.all(10),
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _pdfFilePath != null
            ? _buildPDFPreview() 
            // (_showPreview ? _buildPDFPreview() : _buildTextView())
            : _buildEmptyContentState(),
      ),
    );
  }

  Widget _buildPDFPreview() {
    return Column(
      children: [
        if (_totalPages > 0) _buildPageNavigation(),
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
              _showSnackBar(
                'Error loading PDF: $error',
                Colors.red,
                Icons.error_rounded,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPageNavigation() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 0
                ? () {
                    _pdfController?.setPage(_currentPage - 1);
                  }
                : null,
            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page ${_currentPage + 1} of $_totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages - 1
                ? () {
                    _pdfController?.setPage(_currentPage + 1);
                  }
                : null,
            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContentState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Select a PDF file to analyze',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
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