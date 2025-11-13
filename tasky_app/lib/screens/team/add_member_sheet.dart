import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/team_provider.dart';
import '../../services/api_service.dart';
import '../../theme/palette.dart';

class AddMemberSheet extends StatefulWidget {
  const AddMemberSheet({super.key, required this.teamId});

  final int teamId;

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final api = ApiService();
      final response = await api.get('/users/search', query: {'q': query});
      final List<dynamic> data = response['data'] as List<dynamic>;
      setState(() {
        _searchResults = data
            .map((item) => User.fromJson(item as Map<String, dynamic>))
            .toList();
        _isSearching = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isSearching = false;
      });
    }
  }

  Future<void> _addMember(User user) async {
    try {
      await context.read<TeamProvider>().addMember(
            teamId: widget.teamId,
            email: user.email,
          );
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${user.name} vào team 🎉')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 60,
              height: 5,
              decoration: BoxDecoration(
                color: TaskyPalette.midnight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Thêm thành viên 👥',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Tìm theo tên, email hoặc User ID',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _error = null;
                        });
                      },
                    )
                  : null,
            ),
            onChanged: _searchUsers,
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Text(
                'Lỗi: $_error',
                style: TextStyle(color: Colors.red[700]),
              ),
            )
          else if (_searchController.text.trim().length >= 2 &&
              _searchResults.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Không tìm thấy người dùng nào 😢'),
              ),
            )
          else if (_searchResults.isNotEmpty)
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: TaskyPalette.lavender,
                        child: Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      title: Text(user.name),
                      subtitle: Text('@${user.userId} • ${user.email}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add_rounded),
                        onPressed: () => _addMember(user),
                        color: TaskyPalette.mint,
                      ),
                    ),
                  );
                },
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Nhập tên hoặc email để tìm kiếm 🔍'),
              ),
            ),
        ],
      ),
    );
  }
}
