import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:biometric_storage/biometric_storage.dart';

void main() {
  runApp(const BioVaultApp());
}

class BioVaultApp extends StatelessWidget {
  const BioVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BioVault',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        fontFamily: 'Roboto',
      ),
      home: const LockScreen(),
    );
  }
}

class SecureNote {
  String id;
  String title;
  String content;
  DateTime updatedAt;

  SecureNote({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory SecureNote.fromJson(Map<String, dynamic> json) {
    return SecureNote(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      updatedAt: DateTime.tryParse(
        json['updatedAt'] ?? '',
      ) ??
          DateTime.now(),
    );
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool isLoading = false;

  Future<void> authenticate() async {
    if (isLoading) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await BiometricStorage().canAuthenticate();

      if (response != CanAuthenticateResponse.success) {
        showMessage(
          'Thiết bị chưa sẵn sàng cho xác thực sinh trắc học.',
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final storage = await BiometricStorage().getStorage(
        'bio_vault',
        options: StorageFileInitOptions(
          authenticationRequired: true,
          androidBiometricOnly: true,
        ),
      );

      String? savedData = await storage.read();

      List<SecureNote> notes = [];

      if (savedData != null && savedData.isNotEmpty) {
        try {
          final decoded = jsonDecode(savedData);

          if (decoded is List) {
            notes = decoded
                .map(
                  (item) => SecureNote.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
                .toList();
          }
        } catch (_) {
          notes = [];
        }
      }

      if (notes.isEmpty) {
        notes = [
          SecureNote(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: 'Welcome to BioVault',
            content:
            'Đây là ghi chú bảo mật đầu tiên của bạn. '
                'Bạn có thể chỉnh sửa hoặc xóa ghi chú này.',
            updatedAt: DateTime.now(),
          ),
        ];

        await saveNotes(storage, notes);
      }

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            storage: storage,
            notes: notes,
          ),
        ),
      );
    } on AuthException catch (e) {
      showMessage(
        e.message ?? 'Xác thực sinh trắc học thất bại.',
      );
    } on BiometricStorageException catch (e) {
      showMessage(
        e.message ?? 'Không thể truy cập Secure Storage.',
      );
    } catch (e) {
      showMessage(
        'Có lỗi xảy ra khi mở BioVault.',
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5)
                            .withOpacity(0.25),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'BioVault',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Secure Notes',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 42,
                        color: Color(0xFF4F46E5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your vault is locked',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Xác thực sinh trắc học để truy cập '
                            'các ghi chú bảo mật.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: isLoading
                              ? null
                              : authenticate,
                          icon: isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.fingerprint),
                          label: Text(
                            isLoading
                                ? 'Đang xác thực...'
                                : 'Xác thực bằng sinh trắc học',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: securityMiniCard(
                        Icons.security,
                        'Secure',
                        'Protected',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: securityMiniCard(
                        Icons.fingerprint,
                        'Biometric',
                        'Enabled',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget securityMiniCard(
      IconData icon,
      String title,
      String subtitle,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF4F46E5),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final BiometricStorageFile storage;
  final List<SecureNote> notes;

  const HomeScreen({
    super.key,
    required this.storage,
    required this.notes,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<SecureNote> notes;

  @override
  void initState() {
    super.initState();
    notes = List.from(widget.notes);
  }

  Future<void> saveCurrentNotes() async {
    await saveNotes(widget.storage, notes);
  }

  Future<void> addNote() async {
    final result = await showNoteDialog(context);

    if (result == null) {
      return;
    }

    final note = SecureNote(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: result['title']!,
      content: result['content']!,
      updatedAt: DateTime.now(),
    );

    setState(() {
      notes.insert(0, note);
    });

    await saveCurrentNotes();

    showMessage('Đã thêm ghi chú bảo mật.');
  }

  Future<void> editNote(SecureNote note) async {
    final result = await showNoteDialog(
      context,
      note: note,
    );

    if (result == null) {
      return;
    }

    setState(() {
      note.title = result['title']!;
      note.content = result['content']!;
      note.updatedAt = DateTime.now();
    });

    await saveCurrentNotes();

    showMessage('Đã cập nhật ghi chú.');
  }

  Future<void> deleteNote(SecureNote note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa ghi chú?'),
          content: Text(
            'Bạn có chắc muốn xóa "${note.title}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('HỦY'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('XÓA'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    setState(() {
      notes.removeWhere((item) => item.id == note.id);
    });

    await saveCurrentNotes();

    showMessage('Đã xóa ghi chú.');
  }

  void lockVault() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LockScreen(),
      ),
          (route) => false,
    );
  }

  void openDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SecurityDashboard(
          notesCount: notes.length,
        ),
      ),
    );
  }

  void showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} • $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BioVault',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Secure Notes',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Security Dashboard',
            onPressed: openDashboard,
            icon: const Icon(Icons.dashboard_outlined),
          ),
          IconButton(
            tooltip: 'Khóa Vault',
            onPressed: lockVault,
            icon: const Icon(Icons.lock_outline),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addNote,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Thêm note'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(
            const Duration(milliseconds: 300),
          );
          setState(() {});
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            100,
          ),
          children: [
            buildWelcomeCard(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Secure Notes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${notes.length} notes',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...notes.map(buildNoteCard),
            const SizedBox(height: 20),
            buildSecurityInfo(),
          ],
        ),
      ),
    );
  }

  Widget buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF6366F1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5)
                .withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Vault Unlocked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Your private information is protected.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.lock_open,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget buildNoteCard(SecureNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showNoteDetails(note);
        },
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF4F46E5),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      note.content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDate(note.updatedAt),
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    editNote(note);
                  } else if (value == 'delete') {
                    deleteNote(note);
                  }
                },
                itemBuilder: (context) {
                  return const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 10),
                          Text('Chỉnh sửa'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          SizedBox(width: 10),
                          Text('Xóa'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showNoteDetails(SecureNote note) {
    bool isVisible = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(
                    Icons.lock,
                    color: Color(0xFF4F46E5),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(note.title),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nội dung bảo mật',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            isVisible
                                ? note.content
                                : '••••••••••••••••',
                            style: const TextStyle(
                              height: 1.5,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              isVisible = !isVisible;
                            });
                          },
                          icon: Icon(
                            isVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cập nhật: ${formatDate(note.updatedAt)}',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('ĐÓNG'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    editNote(note);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('SỬA'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Status',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          securityRow(
            Icons.fingerprint,
            'Biometric Authentication',
            'Enabled',
          ),
          securityRow(
            Icons.lock,
            'Secure Storage',
            'Protected',
          ),
          securityRow(
            Icons.shield_outlined,
            'Vault Status',
            'Unlocked',
          ),
        ],
      ),
    );
  }

  Widget securityRow(
      IconData icon,
      String title,
      String status,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: const Color(0xFF4F46E5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Color(0xFF15803D),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SecurityDashboard extends StatelessWidget {
  final int notesCount;

  const SecurityDashboard({
    super.key,
    required this.notesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius:
                    BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.verified_user,
                    color: Color(0xFF16A34A),
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Vault Secure',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'All security systems are operational.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          dashboardItem(
            Icons.fingerprint,
            'Biometric Authentication',
            'Enabled',
            'Fingerprint authentication is required.',
            Colors.green,
          ),
          dashboardItem(
            Icons.storage_rounded,
            'Secure Storage',
            'Protected',
            'Sensitive data is stored using BioVault storage.',
            Colors.green,
          ),
          dashboardItem(
            Icons.note_alt_outlined,
            'Secure Notes',
            '$notesCount',
            'Total notes currently stored in your vault.',
            const Color(0xFF4F46E5),
          ),
          dashboardItem(
            Icons.lock_outline,
            'Vault Protection',
            'Active',
            'Vault can be locked at any time.',
            Colors.green,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF4F46E5),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'BioVault sử dụng xác thực sinh trắc học '
                        'và secure storage để bảo vệ dữ liệu '
                        'nhạy cảm trên thiết bị.',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget dashboardItem(
      IconData icon,
      String title,
      String status,
      String description,
      Color statusColor,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

Future<Map<String, String>?> showNoteDialog(
    BuildContext context, {
      SecureNote? note,
    }) async {
  final titleController = TextEditingController(
    text: note?.title ?? '',
  );

  final contentController = TextEditingController(
    text: note?.content ?? '',
  );

  return showDialog<Map<String, String>>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          note == null
              ? 'Thêm Secure Note'
              : 'Chỉnh sửa Secure Note',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                textCapitalization:
                TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  hintText: 'Ví dụ: WiFi Password',
                  prefixIcon:
                  const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: contentController,
                textCapitalization:
                TextCapitalization.sentences,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Nội dung',
                  hintText:
                  'Nhập thông tin cần bảo mật...',
                  prefixIcon:
                  const Icon(Icons.notes),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('HỦY'),
          ),
          FilledButton.icon(
            onPressed: () {
              final title =
              titleController.text.trim();
              final content =
              contentController.text.trim();

              if (title.isEmpty || content.isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Vui lòng nhập đầy đủ thông tin.',
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(
                dialogContext,
                {
                  'title': title,
                  'content': content,
                },
              );
            },
            icon: const Icon(Icons.save),
            label: const Text('LƯU'),
          ),
        ],
      );
    },
  );
}

Future<void> saveNotes(
    BiometricStorageFile storage,
    List<SecureNote> notes,
    ) async {
  final data = jsonEncode(
    notes.map((note) => note.toJson()).toList(),
  );

  await storage.write(data);
}