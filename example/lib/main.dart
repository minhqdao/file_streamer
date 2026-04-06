import 'package:flutter/material.dart';
import 'package:streamed_file_uploader/streamed_file_uploader.dart';

void main() {
  // Platform is now automatically registered via conditional imports.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streamed File Uploader Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Configurable options
  bool _allowMultiple = false;
  FileTypeFilter _selectedFilter = FileTypeFilter.any;
  double _chunkSizeKb = 256.0;

  // Status and results
  final List<UploadTask> _tasks = [];
  bool _isPicking = false;

  Future<void> _pickAndStream() async {
    setState(() {
      _isPicking = true;
      _tasks.clear();
    });

    try {
      final options = PickerOptions(
        allowMultiple: _allowMultiple,
        filters: [_selectedFilter],
      );

      final result = await StreamedFileUploader.pickFiles(options);

      if (result.isEmpty) {
        setState(() => _isPicking = false);
        return;
      }

      for (final file in result.files) {
        final task = UploadTask(file: file);
        setState(() => _tasks.add(task));
        _startStreaming(task);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Note: $e')));
      }
    } finally {
      setState(() => _isPicking = false);
    }
  }

  Future<void> _startStreaming(UploadTask task) async {
    final stream = StreamedFileUploader.openReadStream(
      task.file,
      options: ReadStreamOptions(chunkSize: (_chunkSizeKb * 1024).toInt()),
    );

    try {
      int totalRead = 0;
      await for (final chunk in stream) {
        totalRead += chunk.length;
        setState(() {
          task.progress = totalRead / task.file.size;
          task.chunksCount++;
        });

        if (task.file.size < 1024 * 1024) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
      setState(() => task.isDone = true);
    } catch (e) {
      setState(() => task.error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streamed File Uploader'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          _buildConfigurationCard(),
          const Divider(),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('No files picked yet.'))
                : ListView.builder(
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) =>
                        _buildTaskTile(_tasks[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isPicking ? null : _pickAndStream,
        label: _isPicking
            ? const CircularProgressIndicator()
            : const Text('Pick Files'),
        icon: _isPicking ? null : const Icon(Icons.file_upload),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Picker Configuration',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SwitchListTile(
              title: const Text('Allow Multiple'),
              value: _allowMultiple,
              onChanged: (val) => setState(() => _allowMultiple = val),
            ),
            ListTile(
              title: const Text('File Type Filter'),
              trailing: DropdownButton<FileTypeFilter>(
                value: _selectedFilter,
                items: const [
                  DropdownMenuItem(
                    value: FileTypeFilter.any,
                    child: Text('Any'),
                  ),
                  DropdownMenuItem(
                    value: FileTypeFilter.images,
                    child: Text('Images'),
                  ),
                  DropdownMenuItem(
                    value: FileTypeFilter.videos,
                    child: Text('Videos'),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedFilter = val!),
              ),
            ),
            const Divider(),
            const Text(
              'Streaming Configuration',
              style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildTaskTile(UploadTask task) {
    return ListTile(
      title: Text(task.file.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${(task.file.size / 1024).toStringAsFixed(2)} KB • Chunks: ${task.chunksCount}',
          ),
          if (task.error != null)
            Text(
              'Error: ${task.error}',
              style: const TextStyle(color: Colors.red),
            )
          else if (!task.isDone)
            LinearProgressIndicator(value: task.progress)
          else
            const Text(
              'Done!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
      trailing: task.isDone
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
    );
  }
}

class UploadTask {
  final PickedFile<Object> file;
  double progress = 0;
  int chunksCount = 0;
  bool isDone = false;
  String? error;

  UploadTask({required this.file});
}
