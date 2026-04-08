import 'package:file_streamer/file_streamer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(home: MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage();

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _allowMultiple = true;
  FileTypeFilter _selectedFilter = FileTypeFilter.any;
  double _chunkSizeKb = 256.0;

  final List<UploadTask> _tasks = [];
  bool _isPicking = false;

  Future<void> _pickFiles() async {
    setState(() => _isPicking = true);

    try {
      final options = PickerOptions(
        allowMultiple: _allowMultiple,
        filters: [_selectedFilter],
      );

      final result = await FileStreamer.pickFiles(options);
      if (result.isEmpty) return;

      setState(() {
        for (final file in result.files) {
          _tasks.add(UploadTask(file: file));
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectableText('Error picking files: $e')),
        );
      }
    } finally {
      setState(() => _isPicking = false);
    }
  }

  Future<void> _uploadAll() async {
    final pendingTasks = _tasks
        .where((t) => !t.isDone && !t.isUploading)
        .toList();
    if (pendingTasks.isEmpty) return;

    for (final task in pendingTasks) {
      _uploadFile(task);
    }
  }

  Future<void> _uploadFile(UploadTask task) async {
    setState(() {
      task.isUploading = true;
      task.progress = 0;
      task.error = null;
    });

    try {
      final stream = FileStreamer.openReadStream(
        task.file,
        options: ReadStreamOptions(chunkSize: (_chunkSizeKb * 1024).toInt()),
      );

      final request = http.StreamedRequest(
        'POST',
        Uri.parse('https://httpbin.org/post'),
      );

      request.headers['Content-Type'] = 'application/octet-stream';
      request.contentLength = task.file.size;

      int uploaded = 0;
      final progressStream = stream.map((chunk) {
        uploaded += chunk.length;
        if (mounted) {
          setState(() {
            task.progress = uploaded / task.file.size;
          });
        }
        return chunk;
      });

      final responseFuture = request.send();

      await request.sink.addStream(progressStream);
      await request.sink.close();

      final response = await responseFuture;
      if (mounted) {
        setState(() {
          task.isUploading = false;
          task.isDone = response.statusCode == 200;
          if (!task.isDone) {
            task.error = 'Upload failed: ${response.statusCode}';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          task.isUploading = false;
          task.error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUpload = _tasks.any((t) => !t.isDone && !t.isUploading);

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Streamer Upload Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildConfigurationCard(),
          const Divider(),
          Expanded(
            child: _tasks.isEmpty
                ? const Align(child: Text('No files picked yet.'))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (_, i) {
                      final task = _tasks[i];
                      return BuildTaskTile(
                        key: ValueKey(task),
                        task: task,
                        onRemove: () {
                          setState(() => _tasks.removeAt(i));
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPicking ? null : _pickFiles,
                    icon: _isPicking
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Pick Files'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canUpload ? _uploadAll : null,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
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

  Widget _buildConfigurationCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Allow Multiple'),
              value: _allowMultiple,
              onChanged: (val) => setState(() => _allowMultiple = val),
            ),
            ListTile(
              title: const Text('Filter'),
              trailing: DropdownButton<FileTypeFilter>(
                value: _selectedFilter,
                items: [
                  const DropdownMenuItem(
                    value: FileTypeFilter.any,
                    child: Text('Any'),
                  ),
                  const DropdownMenuItem(
                    value: FileTypeFilter.images,
                    child: Text('Images'),
                  ),
                  const DropdownMenuItem(
                    value: FileTypeFilter.videos,
                    child: Text('Videos'),
                  ),
                  DropdownMenuItem(
                    value: FileTypeFilter.fromExtension('pdf'),
                    child: const Text('PDF'),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedFilter = val!),
              ),
            ),
            ListTile(
              title: Text('Chunk Size: ${_chunkSizeKb.toInt()} KB'),
              subtitle: Slider(
                value: _chunkSizeKb,
                min: 4,
                max: 1024,
                divisions: 100,
                onChanged: (val) => setState(() => _chunkSizeKb = val),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BuildTaskTile extends StatelessWidget {
  const BuildTaskTile({super.key, required this.task, required this.onRemove});

  final UploadTask task;
  final void Function() onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        task.isDone ? Icons.check_circle : Icons.insert_drive_file,
        color: task.isDone ? Colors.green : null,
      ),
      title: Text(task.file.name, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${(task.file.size / 1024).toStringAsFixed(2)} KB • ${task.file.mimeType}',
          ),
          if (task.error != null)
            Text(
              task.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            )
          else if (task.isUploading || task.progress > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: LinearProgressIndicator(value: task.progress),
            ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: task.isUploading ? null : onRemove,
      ),
    );
  }
}

class UploadTask {
  UploadTask({required this.file});

  final PickedFile<Object> file;
  double progress = 0;
  bool isUploading = false;
  bool isDone = false;
  String? error;
}
