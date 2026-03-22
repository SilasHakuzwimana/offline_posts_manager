import 'package:flutter/material.dart';
import 'package:offline_posts_manager/widgets/post_card_widget.dart';

import '../database/database_helper.dart';
import '../models/post.dart';
import 'post_detail_screen.dart';
import 'post_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController _searchController = TextEditingController();

  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  // Category filter chips
  final List<String> _categories = [
    'All',
    'News',
    'Technology',
    'Announcement',
    'General',
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Data loading
  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final posts = _searchQuery.isEmpty
          ? await _db.getAllPosts()
          : await _db.searchPosts(_searchQuery);

      final filtered = _selectedCategory == 'All'
          ? posts
          : posts.where((p) => p.category == _selectedCategory).toList();

      setState(() {
        _posts = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Delete
  Future<void> _deletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Post'),
        content: Text(
          'Are you sure you want to delete "${post.title}"?\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _db.deletePost(post.id!);
      _loadPosts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Post deleted successfully'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Category colour helper
  Color _categoryColor(String category) {
    switch (category) {
      case 'News':
        return const Color(0xFFE53935);
      case 'Technology':
        return const Color(0xFF1E88E5);
      case 'Announcement':
        return const Color(0xFF8E24AA);
      default:
        return const Color(0xFF43A047);
    }
  }

  // Build
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Offline Posts Manager',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPosts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Gradient header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search posts…',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadPosts();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    setState(() => _searchQuery = v);
                    _loadPosts();
                  },
                ),
                const SizedBox(height: 10),
                // Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final selected = cat == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedCategory = cat);
                            _loadPosts();
                          },
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color.fromARGB(179, 0, 8, 11),
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.transparent,
                          selectedColor: const Color(0xFFE94560),
                          checkmarkColor: Colors.white,
                          side: BorderSide(
                              color: selected
                                  ? const Color(0xFFE94560)
                                  : Colors.white38),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          //Body
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newPost = await Navigator.push<Post>(
            context,
            MaterialPageRoute(builder: (_) => const PostFormScreen()),
          );

          if (newPost != null) {
            setState(() {
              // Insert at the top
              _posts.insert(0, newPost);
            });
          }
        },
        backgroundColor: const Color(0xFFE94560),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'New Post',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE94560)),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadPosts, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No posts match your search'
                  : 'No posts yet.\nTap + to create one!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: const Color(0xFFE94560),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _posts.length,
        itemBuilder: (_, i) => PostCard(
          post: _posts[i],
          categoryColor: _categoryColor(_posts[i].category),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(post: _posts[i]),
              ),
            );
            _loadPosts();
          },
          onEdit: () async {
            final updatedPost = await Navigator.push<Post>(
              context,
              MaterialPageRoute(
                builder: (_) => PostFormScreen(post: _posts[i]),
              ),
            );

            if (updatedPost != null) {
              setState(() {
                final index = _posts.indexWhere((p) => p.id == updatedPost.id);
                if (index != -1) {
                  _posts[index] = updatedPost;
                }
              });
            }
          },
          onDelete: () => _deletePost(_posts[i]),
        ),
      ),
    );
  }
}
