import 'package:flutter/material.dart';

class CreatePostPage extends StatefulWidget {
  final String communityId;

  const CreatePostPage({Key? key, required this.communityId}) : super(key: key);

  @override
  _CreatePostPageState createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  String postType = 'text'; // 'text', 'image', or 'link'
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('Text'),
                  selected: postType == 'text',
                  onSelected: (_) => setState(() => postType = 'text'),
                ),
                ChoiceChip(
                  label: const Text('Image'),
                  selected: postType == 'image',
                  onSelected: (_) => setState(() => postType = 'image'),
                ),
                ChoiceChip(
                  label: const Text('Link'),
                  selected: postType == 'link',
                  onSelected: (_) => setState(() => postType = 'link'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            if (postType == 'text')
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Content'),
              ),
            if (postType == 'image')
              ElevatedButton(
                onPressed: () {
                  // TODO: Pick and preview image
                },
                child: const Text('Upload Image'),
              ),
            if (postType == 'link')
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Paste Link'),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement post creation
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
