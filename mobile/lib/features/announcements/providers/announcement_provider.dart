import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/announcement_model.dart';

@immutable
class AnnouncementState {
  final List<AnnouncementModel> announcements;
  final bool isLoading;
  final String? error;

  const AnnouncementState({
    this.announcements = const [],
    this.isLoading = false,
    this.error,
  });

  AnnouncementState copyWith({
    List<AnnouncementModel>? announcements,
    bool? isLoading,
    String? error,
  }) {
    return AnnouncementState(
      announcements: announcements ?? this.announcements,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AnnouncementNotifier extends StateNotifier<AnnouncementState> {
  AnnouncementNotifier(this._classId) : super(const AnnouncementState());

  final int _classId;
  bool _loaded = false;

  Future<void> fetchAnnouncements({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return;
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 400));

    if (_classId != 1) {
      state = state.copyWith(announcements: const [], isLoading: false);
      _loaded = true;
      return;
    }

    final now = DateTime.now();

    DateTime ts(int daysAgo, int hour, int minute) {
      final base = now.subtract(Duration(days: daysAgo));
      return DateTime(base.year, base.month, base.day, hour, minute);
    }

    final dummy = [
      AnnouncementModel(
        id: 1,
        classId: 1,
        subjectId: null,
        subjectName: null,
        title: 'Perubahan Jadwal UTS Semester Ini',
        content:
            'Diberitahukan bahwa jadwal UTS untuk semester ini mengalami perubahan sesuai surat edaran Dekan Fakultas Sains dan Teknologi.\n\n'
            'Jadwal baru akan diumumkan melalui portal SIAKAD paling lambat dua hari sebelum pelaksanaan. Harap pantau terus portal untuk informasi terbaru.',
        createdBy: 1,
        creatorName: 'Ahmad Fauzi',
        createdAt: ts(3, 10, 15),
      ),
      AnnouncementModel(
        id: 2,
        classId: 1,
        subjectId: 1,
        subjectName: 'Analisis Real',
        title: 'Tugas Tambahan Analisis Real',
        content:
            'Mohon dikerjakan soal Bab 5 nomor 1–10 sebagai pengganti pertemuan yang ditiadakan minggu lalu.\n\n'
            'Dikumpulkan paling lambat Senin depan pukul 23.59 melalui portal kelas. Format pengumpulan: PDF dengan nama file NIM_Nama_Tugas5.pdf.',
        createdBy: 1,
        creatorName: 'Ahmad Fauzi',
        createdAt: ts(4, 14, 30),
      ),
      AnnouncementModel(
        id: 3,
        classId: 1,
        subjectId: null,
        subjectName: null,
        title: 'Libur Hari Kebangkitan Nasional',
        content:
            'Sesuai surat keputusan rektor, perkuliahan diliburkan pada hari Rabu dalam rangka Hari Kebangkitan Nasional.\n\n'
            'Perkuliahan kembali normal pada hari Kamis. Dosen yang terdampak akan mengumumkan pengganti pertemuan masing-masing.',
        createdBy: 1,
        creatorName: 'Ahmad Fauzi',
        createdAt: ts(6, 08, 0),
      ),
      AnnouncementModel(
        id: 4,
        classId: 1,
        subjectId: 2,
        subjectName: 'Aljabar Linear',
        title: 'Quiz Aljabar Linear Minggu Depan',
        content:
            'Akan diadakan quiz pertemuan ke-10 yang mencakup materi: transformasi linear, ruang vektor, basis, dan dimensi.\n\n'
            'Quiz dilaksanakan di kelas, durasi 60 menit, 10 soal pilihan ganda + 2 soal essay. Buka buku tidak diperkenankan. '
            'Mohon hadir tepat waktu dan membawa kalkulator scientific.',
        createdBy: 1,
        creatorName: 'Ahmad Fauzi',
        createdAt: ts(7, 14, 32),
      ),
      AnnouncementModel(
        id: 5,
        classId: 1,
        subjectId: null,
        subjectName: null,
        title: 'Info Pendaftaran Beasiswa BAZNAS',
        content:
            'Pendaftaran beasiswa BAZNAS untuk semester ganjil dibuka mulai awal bulan depan.\n\n'
            'Persyaratan: IPK minimal 3.0, aktif kuliah, tidak sedang menerima beasiswa lain. '
            'Formulir dan informasi lengkap dapat diunduh di portal SIAKAD bagian Beasiswa.',
        createdBy: 1,
        creatorName: 'Ahmad Fauzi',
        createdAt: ts(9, 11, 45),
      ),
    ];

    state = state.copyWith(announcements: dummy, isLoading: false);
    _loaded = true;
  }

  Future<void> createAnnouncement({
    required int? subjectId,
    required String? subjectName,
    required String title,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newId = state.announcements.isEmpty
        ? 1
        : state.announcements.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
    final announcement = AnnouncementModel(
      id: newId,
      classId: _classId,
      subjectId: subjectId,
      subjectName: subjectName,
      title: title,
      content: content,
      createdBy: 1,
      creatorName: 'Ahmad Fauzi',
      createdAt: DateTime.now(),
    );
    // Newest first — prepend
    state = state.copyWith(
      announcements: [announcement, ...state.announcements],
    );
  }

  Future<void> updateAnnouncement(
    int id, {
    required int? subjectId,
    required String? subjectName,
    required String title,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(
      announcements: state.announcements.map((a) {
        if (a.id != id) return a;
        return AnnouncementModel(
          id: a.id,
          classId: a.classId,
          subjectId: subjectId,
          subjectName: subjectName,
          title: title,
          content: content,
          createdBy: a.createdBy,
          creatorName: a.creatorName,
          createdAt: a.createdAt,
          updatedAt: DateTime.now(),
        );
      }).toList(),
    );
  }

  Future<void> deleteAnnouncement(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(
      announcements: state.announcements.where((a) => a.id != id).toList(),
    );
  }
}

final announcementProvider =
    StateNotifierProvider.family<AnnouncementNotifier, AnnouncementState, int>(
  (ref, classId) => AnnouncementNotifier(classId),
);

// Sorted newest-first (mirrors backend ORDER BY created_at DESC).
final announcementListProvider =
    Provider.family<List<AnnouncementModel>, int>((ref, classId) {
  final items = ref.watch(announcementProvider(classId)).announcements;
  final sorted = [...items]
    ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
  return List.unmodifiable(sorted);
});

final announcementByIdProvider =
    Provider.family<AnnouncementModel?, ({int classId, int announcementId})>(
  (ref, params) {
    final items = ref.watch(announcementListProvider(params.classId));
    return items.cast<AnnouncementModel?>().firstWhere(
          (a) => a?.id == params.announcementId,
          orElse: () => null,
        );
  },
);
