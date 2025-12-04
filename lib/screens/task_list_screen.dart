import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import 'create_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return Text(
                    authProvider.user?.name ?? 'User',
                    style: const TextStyle(fontSize: 14),
                  );
                },
              ),
            ),
          ),
          PopupMenuButton(
            itemBuilder: (BuildContext popupContext) => [
              PopupMenuItem(
                onTap: () async {
                  await popupContext.read<AuthProvider>().logout();
                  if (mounted) {
                    // ignore: use_build_context_synchronously
                    Navigator.of(popupContext).pushReplacementNamed('/login');
                  }
                },
                child: const Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          if (taskProvider.isLoading && taskProvider.tasks.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (taskProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${taskProvider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      taskProvider.fetchTasks();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final tasks = taskProvider.filteredTasks;

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    _buildStatusChip(
                      'All',
                      'all',
                      taskProvider,
                    ),
                    _buildStatusChip(
                      'Pending',
                      'pending',
                      taskProvider,
                    ),
                    _buildStatusChip(
                      'In Progress',
                      'in_progress',
                      taskProvider,
                    ),
                    _buildStatusChip(
                      'Completed',
                      'completed',
                      taskProvider,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inbox,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text('No tasks found'),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context)
                                    .push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const CreateTaskScreen(),
                                      ),
                                    )
                                    .then((_) {
                                  taskProvider.fetchTasks();
                                });
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Task'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            taskProvider.fetchTasks(),
                        child: ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                title: Text(task.title),
                                subtitle: Text(task.description),
                                trailing: Chip(
                                  label: Text(task.status),
                                  backgroundColor:
                                      _getStatusColor(task.status),
                                ),
                                onTap: () {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CreateTaskScreen(
                                                task: task,
                                              ),
                                        ),
                                      )
                                      .then((_) {
                                    taskProvider.fetchTasks();
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => const CreateTaskScreen(),
                ),
              );
          if (mounted) {
            // ignore: use_build_context_synchronously
            context.read<TaskProvider>().fetchTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    String status,
    TaskProvider taskProvider,
  ) {
    final isSelected = taskProvider.selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          taskProvider.setSelectedStatus(status);
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade100;
      case 'in_progress':
        return Colors.blue.shade100;
      case 'completed':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
