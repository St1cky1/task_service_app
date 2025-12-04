import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  String _selectedStatus = 'all';

  TaskProvider({required ApiService apiService}) : _apiService = apiService;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedStatus => _selectedStatus;

  List<Task> get filteredTasks {
    if (_selectedStatus == 'all') {
      return _tasks;
    }
    return _tasks.where((task) => task.status == _selectedStatus).toList();
  }

  Future<void> fetchTasks({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== Fetching tasks (status: $status) ===');
      _tasks = await _apiService.getTasks(status: status);
      _tasks.sort((a, b) => b.id.compareTo(a.id));
      print('✓ Fetched ${_tasks.length} tasks: ${_tasks.map((t) => t.id).toList()}');
      _error = null;
    } catch (e) {
      print('✗ Error fetching tasks: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTask({
    required String title,
    required String description,
    required String status,
    required int ownerId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== Creating task: title=$title, status=$status, ownerId=$ownerId ===');
      final newTask = await _apiService.createTask(
        title: title,
        description: description,
        status: status,
        ownerId: ownerId,
      );
      print('✓ Task created with id: ${newTask.id}');
      _tasks.add(newTask);
      _tasks.sort((a, b) => b.id.compareTo(a.id));
      print('✓ Tasks after creation (count: ${_tasks.length}): ${_tasks.map((t) => t.id).toList()}');
      _error = null;
    } catch (e) {
      print('✗ Error creating task: $e');
      _error = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTask({
    required int taskId,
    required String title,
    required String description,
    required String status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedTask = await _apiService.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        status: status,
      );

      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        _tasks.sort((a, b) => b.id.compareTo(a.id));
        developer.log('Tasks after update: ${_tasks.map((t) => t.id).toList()}');
      }
      _error = null;
    } catch (e) {
      developer.log('Error updating task: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTask(int taskId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
