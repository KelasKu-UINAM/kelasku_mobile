import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../models/task_model.dart';

@immutable
class TaskState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final String? error;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  TaskState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TaskNotifier extends StateNotifier<TaskState> {
  TaskNotifier(this._classId) : super(const TaskState());

  final int _classId;
  bool _loaded = false;

  Future<void> fetchTasks({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ApiClient.instance.get(
        '${ApiConstants.classes}/$_classId/tasks',
      );
      final data = extractData(response) as List<dynamic>;
      final tasks = data
          .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(tasks: tasks, isLoading: false);
      _loaded = true;
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: extractErrorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      );
    }
  }

  Future<void> createTask({
    required int subjectId,
    required String subjectName,
    String? subjectCode,
    required String title,
    String? description,
    required DateTime deadline,
    String? attachmentUrl,
  }) async {
    try {
      await ApiClient.instance.post(
        '/api/subjects/$subjectId/tasks',
        data: {
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          'deadline': deadline.toIso8601String(),
          if (attachmentUrl != null && attachmentUrl.isNotEmpty)
            'attachment_url': attachmentUrl,
        },
      );
      // Refetch to get JOINed subject fields.
      await fetchTasks(forceRefresh: true);
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }

  Future<void> updateTask(
    int id, {
    int? subjectId,
    String? subjectName,
    String? subjectCode,
    String? title,
    String? description,
    DateTime? deadline,
    String? attachmentUrl,
  }) async {
    try {
      await ApiClient.instance.put(
        '${ApiConstants.tasks}/$id',
        data: {
          'title': ?title,
          'description': description,
          if (deadline != null) 'deadline': deadline.toIso8601String(),
          'attachment_url': attachmentUrl,
        },
      );
      // Refetch to get updated JOINed data.
      await fetchTasks(forceRefresh: true);
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await ApiClient.instance.delete('${ApiConstants.tasks}/$id');
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != id).toList(),
      );
    } on DioException catch (e) {
      state = state.copyWith(error: extractErrorMessage(e));
    }
  }
}

final taskProvider =
    StateNotifierProvider.family<TaskNotifier, TaskState, int>(
  (ref, classId) => TaskNotifier(classId),
);

final taskListProvider = Provider.family<List<TaskModel>, int>(
  (ref, classId) {
    final tasks = ref.watch(taskProvider(classId)).tasks;
    final sorted = [...tasks]..sort((a, b) => a.deadline.compareTo(b.deadline));
    return List.unmodifiable(sorted);
  },
);

final taskByIdProvider =
    Provider.family<TaskModel?, ({int classId, int taskId})>(
  (ref, params) {
    final tasks = ref.watch(taskListProvider(params.classId));
    return tasks.cast<TaskModel?>().firstWhere(
          (t) => t?.id == params.taskId,
          orElse: () => null,
        );
  },
);
