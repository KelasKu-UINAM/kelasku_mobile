import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../classes/models/class_model.dart';
import '../../classes/providers/class_provider.dart';
import '../models/subject_model.dart';
import '../providers/subject_provider.dart';

class SubjectListScreen extends ConsumerStatefulWidget {
  final int classId;

  const SubjectListScreen({super.key, required this.classId});

  @override
  ConsumerState<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends ConsumerState<SubjectListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(subjectProvider(widget.classId).notifier)
          .fetchSubjects(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subjectProvider(widget.classId));
    final subjects = ref.watch(subjectListProvider(widget.classId));
    final kelas = ref.watch(classByIdProvider(widget.classId));
    final isAdmin = kelas?.roleInClass == 'admin_komting';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_appBarTitle(kelas)),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'matkul_fab',
              onPressed: () async {
                // createSubject appends to state reactively; a forceRefresh
                // here would re-seed the dummy data and wipe the new subject.
                await context.push<bool>(
                  '/matkul/${widget.classId}/tambah',
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: state.isLoading && subjects.isEmpty
          ? const LoadingWidget(message: 'Memuat mata kuliah...')
          : subjects.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.menu_book_outlined,
                  title: 'Belum ada mata kuliah',
                  description: isAdmin
                      ? 'Tambahkan mata kuliah untuk kelas ini.'
                      : 'Komting belum menambahkan mata kuliah.',
                  actionLabel: isAdmin ? 'Tambah Sekarang' : null,
                  onAction: isAdmin
                      ? () => context.push('/matkul/${widget.classId}/tambah')
                      : null,
                )
              : _buildList(subjects, isAdmin),
    );
  }

  String _appBarTitle(ClassModel? kelas) {
    return kelas != null ? 'Mata Kuliah · ${kelas.name}' : 'Mata Kuliah';
  }

  Widget _buildList(List<SubjectModel> subjects, bool isAdmin) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
      itemCount: subjects.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${subjects.length} MATA KULIAH',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
              ),
            ),
          );
        }
        return _SubjectCard(
          subject: subjects[index - 1],
          isAdmin: isAdmin,
          classId: widget.classId,
        );
      },
    );
  }
}

// ── Subject card ───────────────────────────────────────────────

class _SubjectCard extends ConsumerWidget {
  final SubjectModel subject;
  final bool isAdmin;
  final int classId;

  const _SubjectCard({
    required this.subject,
    required this.isAdmin,
    required this.classId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subject.code != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subject.code!,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.4,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                if (subject.lecturer != null) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          subject.lecturer!,
                          style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(width: 6),
            _ActionIconBtn(
              icon: Icons.edit_outlined,
              onTap: () => context.push(
                '/matkul/${subject.id}/edit?classId=$classId',
              ),
            ),
            const SizedBox(width: 4),
            _ActionIconBtn(
              icon: Icons.delete_outline,
              onTap: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Mata Kuliah?'),
        content: Text(
          '"${subject.name}" akan dihapus bersama seluruh jadwalnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.dangerText),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(subjectProvider(classId).notifier)
        .deleteSubject(subject.id);
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.backgroundAlt,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.textMuted),
      ),
    );
  }
}
