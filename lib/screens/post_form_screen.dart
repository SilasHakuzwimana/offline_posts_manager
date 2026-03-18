// screens/post_form_screen.dart
// Reusable form screen for both CREATE and EDIT operations.
// When [post] is null → create mode; otherwise → edit mode.

import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/post.dart';

class PostFormScreen extends StatefulWidget {
  final Post? post; // null = create mode
  const PostFormScreen({super.key, this.post});

  @override
  State<PostFormScreen> createState() => _PostFormScreenState();
}

class _PostFormScreenState extends State<PostFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _db = DatabaseHelper();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late final TextEditingController _authorCtrl;
  String _selectedCategory = 'General';
  bool _isSaving = false;

  bool get _isEditMode => widget.post != null;

  final List<String> _categories = [
    'General',
    'News',
    'Technology',
    'Announcement',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.post?.title ?? '');
    _bodyCtrl = TextEditingController(text: widget.post?.body ?? '');
    _authorCtrl = TextEditingController(text: widget.post?.author ?? '');
    _selectedCategory = widget.post?.category ?? 'General';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  // ── Save ─────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      Post resultPost;

      if (_isEditMode) {
        final updated = widget.post!.copyWith(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          author: _authorCtrl.text.trim(),
          category: _selectedCategory,
          updatedAt: now,
        );
        await _db.updatePost(updated);
        resultPost = updated; // return updated post
      } else {
        final newPost = Post(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          author: _authorCtrl.text.trim(),
          category: _selectedCategory,
          createdAt: now,
          updatedAt: now,
        );
        final id = await _db.insertPost(newPost);
        resultPost = newPost.copyWith(id: id); // include generated id
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Post updated!' : 'Post created!'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Return the post to HomeScreen for instant update
        Navigator.pop(context, resultPost);
      }
    } on DatabaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Database error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Text(
          _isEditMode ? 'Edit Post' : 'New Post',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded, color: Color(0xFFE94560)),
              label: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFFE94560),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ──────────────────────────────────────────────────
              _buildLabel('Post Title *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                decoration: _inputDecoration(
                  'Enter a compelling title…',
                  Icons.title_rounded,
                ),
                maxLength: 120,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.trim().length < 3)
                    return 'Title must be at least 3 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Author ─────────────────────────────────────────────────
              _buildLabel('Author *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _authorCtrl,
                decoration: _inputDecoration(
                  'Your name or pen name…',
                  Icons.person_rounded,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Author is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Category ────────────────────────────────────────────────
              _buildLabel('Category'),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.category_rounded,
                      color: Color(0xFFE94560),
                    ),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
              ),
              const SizedBox(height: 16),

              // ── Body ────────────────────────────────────────────────────
              _buildLabel('Content *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bodyCtrl,
                decoration: _inputDecoration(
                  'Write your post content here…',
                  Icons.article_rounded,
                ),
                maxLines: 10,
                maxLength: 5000,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Content is required';
                  if (v.trim().length < 10)
                    return 'Content must be at least 10 characters';
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // ── Submit button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _isEditMode ? Icons.save_rounded : Icons.add_rounded,
                  ),
                  label: Text(
                    _isEditMode ? 'Update Post' : 'Publish Post',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFF555555),
          letterSpacing: 0.3,
        ),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFE94560)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE94560), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
      );
}
