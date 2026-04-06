import 'package:flutter/material.dart';
import 'package:audios_resolver/audios_resolver.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Resolver Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AudioResolverDemo(),
    );
  }
}

class AudioResolverDemo extends StatefulWidget {
  const AudioResolverDemo({super.key});

  @override
  State<AudioResolverDemo> createState() => _AudioResolverDemoState();
}

class _AudioResolverDemoState extends State<AudioResolverDemo> {
  final TextEditingController _videoIdController = TextEditingController();
  final List<String> _batchIds = [];
  final TextEditingController _batchController = TextEditingController();

  AudioResolverResult? _singleResult;
  Map<String, AudioResolverResult?> _batchResults = {};
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _videoIdController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSingle() async {
    final videoId = _videoIdController.text.trim();
    if (videoId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _singleResult = null;
    });

    try {
      final result = await AudiosResolver.fetchSingle(videoId: videoId);
      setState(() {
        _singleResult = result;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addBatchId() async {
    final id = _batchController.text.trim();
    if (id.isEmpty || _batchIds.contains(id)) return;

    setState(() {
      _batchIds.add(id);
      _batchController.clear();
    });
  }

  void _removeBatchId(String id) {
    setState(() {
      _batchIds.remove(id);
    });
  }

  Future<void> _fetchBatch() async {
    if (_batchIds.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _batchResults = {};
    });

    try {
      final results = await AudiosResolver.fetchBatch(
        videoIds: _batchIds,
        forceRefresh: false,
        concurrency: 3,
      );
      setState(() {
        _batchResults = results;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearCache() async {
    await AudiosResolver.clearCache();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Resolver Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all_outlined),
            onPressed: _clearCache,
            tooltip: 'Clear cache',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Single video section
            const Text(
              'Single Video',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _videoIdController,
                    decoration: const InputDecoration(
                      hintText: 'Enter YouTube video ID (e.g., dQw4w9WgXcQ)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _fetchSingle,
                  child: const Text('Resolve'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Error: $_error'),
              ),
            if (_singleResult != null) ...[
              const SizedBox(height: 12),
              _buildResultCard(_singleResult!),
            ],

            const Divider(height: 32),

            // Batch section
            const Text(
              'Batch Resolution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _batchController,
                    decoration: const InputDecoration(
                      hintText: 'Enter video ID',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addBatchId(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addBatchId,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _batchIds
                  .map(
                    (id) => Chip(
                      label: Text(id),
                      onDeleted: () => _removeBatchId(id),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _batchIds.isEmpty || _isLoading ? null : _fetchBatch,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Resolve Batch'),
            ),
            const SizedBox(height: 12),

            if (_batchResults.isNotEmpty) ...[
              const Text(
                'Results:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._batchResults.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildResultCard(entry.value, title: entry.key),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(AudioResolverResult? result, {String? title}) {
    if (result == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Failed to resolve: $title'),
        ),
      );
    }

    return Card(
      child: ExpansionTile(
        title: Text(result.videoId),
        subtitle: Text(
          '${result.codec} • ${result.bitrate ~/ 1000}kbps • ${result.clientUsed}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Format', result.mimeType),
                _buildInfoRow('Codec', result.codec),
                _buildInfoRow('Bitrate', '${result.bitrate ~/ 1000} kbps'),
                _buildInfoRow(
                  'Content Length',
                  result.contentLength != null
                      ? '${(result.contentLength! / 1024 / 1024).toStringAsFixed(2)} MB'
                      : 'Unknown',
                ),
                _buildInfoRow(
                  'Loudness',
                  result.loudnessDb != null
                      ? '${result.loudnessDb} dB'
                      : 'Unknown',
                ),
                _buildInfoRow('Expires', '${result.expiresAt.toLocal()}'),
                _buildInfoRow('Expired', result.isExpired ? 'Yes' : 'No'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(
                    result.url,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
