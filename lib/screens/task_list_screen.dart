import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../theme/theme.dart';
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
      print('TaskListScreen: Fetching tasks...');
      context.read<TaskProvider>().fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                  ]
                : [
                    Colors.blue.shade50,
                    Colors.purple.shade50,
                  ],
          ),
        ),
        child: Consumer<TaskProvider>(
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  child: Row(
                    children: [
                      _buildStatusChip(
                        'All',
                        'all',
                        taskProvider,
                        context,
                      ),
                      _buildStatusChip(
                        'Pending',
                        'pending',
                        taskProvider,
                        context,
                      ),
                      _buildStatusChip(
                        'In Progress',
                        'in_progress',
                        taskProvider,
                        context,
                      ),
                      _buildStatusChip(
                        'Completed',
                        'completed',
                        taskProvider,
                        context,
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
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const CreateTaskScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Create Task'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => taskProvider.fetchTasks(),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Container(
                                  decoration: AppTheme.glassmorphicCardDecoration(
                                    context: context,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CreateTaskScreen(
                                                  task: task,
                                                ),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        task.title,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                            ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        task.description,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall,
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                        task.status),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    _formatStatus(task.status),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  Widget _buildStatusChip(
    String label,
    String status,
    TaskProvider taskProvider,
    BuildContext context,
  ) {
    final isSelected = taskProvider.selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          taskProvider.setSelectedStatus(status);
        },
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : null,
        ),
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
