import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_constants.dart';

class StickerMakerScreen extends StatefulWidget {
  const StickerMakerScreen({super.key});

  @override
  State<StickerMakerScreen> createState() => _StickerMakerScreenState();
}

class _StickerMakerScreenState extends State<StickerMakerScreen> {
  File? _pickedImage;
  final TextEditingController _packNameController = TextEditingController(
    text: 'my_sticker_pack',
  );
  final TextEditingController _packTitleController = TextEditingController(
    text: 'My Sticker Pack',
  );
  final TextEditingController _emojiController = TextEditingController(
    text: '❤',
  );
  String _uploadStatus = 'Awaiting image selection.';
  String? _shareUrl;
  bool _isNewPack = true;

  // Function to launch the Telegram sticker URL
  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      setState(() => _uploadStatus = 'Could not launch URL.');
    }
  }

  // --- API AND IMAGE LOGIC (UNCHANGED) ---
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
        _uploadStatus = 'Image selected. Ready to prepare.';
        _shareUrl = null;
      });
    }
  }

  Future<File?> _prepareSticker(File originalFile) async {
    setState(() => _uploadStatus = 'Preparing image...');

    final bytes = await originalFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      setState(() => _uploadStatus = 'Error: Could not decode image.');
      return null;
    }

    // Resizing logic
    img.Image resizedImage = img.copyResize(
      originalImage,
      width: 512,
      height: (originalImage.height * 512 / originalImage.width).round(),
    );

    if (resizedImage.height > 512) {
      resizedImage = img.copyResize(
        originalImage,
        height: 512,
        width: (originalImage.width * 512 / originalImage.height).round(),
      );
    }

    final pngBytes = img.encodePng(resizedImage);
    final tempDir = await getTemporaryDirectory();
    final tempStickerFile = File('${tempDir.path}/temp_sticker.png');
    await tempStickerFile.writeAsBytes(pngBytes);

    setState(() => _uploadStatus = 'Image prepared as PNG (512xX).');
    return tempStickerFile;
  }

  Future<void> _addStickerToExistingSet(
    File stickerFile,
    String setName,
  ) async {
    setState(() => _uploadStatus = 'Adding sticker to existing set...');

    final emojis = _emojiController.text.isEmpty ? '⭐' : _emojiController.text;
    final url = 'https://api.telegram.org/bot$BOT_TOKEN/addStickerToSet';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['user_id'] = USER_ID.toString()
        ..fields['name'] = setName
        ..fields['emojis'] = emojis
        ..fields['sticker_format'] = 'static'
        ..files.add(
          await http.MultipartFile.fromPath('png_sticker', stickerFile.path),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200 && jsonResponse['ok'] == true) {
        setState(() {
          _uploadStatus = 'Success! Click or copy the link below.';
          _shareUrl = 'https://t.me/addstickers/$setName';
        });
      } else {
        setState(() {
          _uploadStatus =
              'Failed to add sticker: ${jsonResponse['description'] ?? 'Unknown API error'}';
          _shareUrl = null;
        });
      }
    } catch (e) {
      setState(
        () => _uploadStatus =
            '❌ An exception occurred during AddStickerToSet: $e',
      );
      _shareUrl = null;
    }
  }

  Future<void> _createNewStickerSet(
    File stickerFile,
    String setName,
    String setTitle,
  ) async {
    setState(() => _uploadStatus = 'Creating new sticker set...');

    final emojis = _emojiController.text.isEmpty ? '⭐' : _emojiController.text;
    final url = 'https://api.telegram.org/bot$BOT_TOKEN/createNewStickerSet';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['user_id'] = USER_ID.toString()
        ..fields['name'] = setName
        ..fields['title'] = setTitle
        ..fields['emojis'] = emojis
        ..fields['sticker_format'] = 'static'
        ..fields['sticker_type'] = 'regular'
        ..files.add(
          await http.MultipartFile.fromPath('png_sticker', stickerFile.path),
        );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200 && jsonResponse['ok'] == true) {
        setState(() {
          _uploadStatus = 'Success! Click or copy the link below.';
          _isNewPack = false;
          _shareUrl = 'https://t.me/addstickers/$setName';
        });
      } else {
        setState(() {
          _uploadStatus =
              'Failed to create pack: ${jsonResponse['description'] ?? 'Unknown API error'}';
          _shareUrl = null;
        });
      }
    } catch (e) {
      setState(
        () => _uploadStatus =
            'An exception occurred during CreateNewStickerSet: $e',
      );
      _shareUrl = null;
    }
  }

  Future<void> _processAndUpload() async {
    if (_pickedImage == null) {
      setState(() => _uploadStatus = 'Please select an image first.');
      return;
    }

    final preparedFile = await _prepareSticker(_pickedImage!);

    if (preparedFile == null) return;

    final setName = '${_packNameController.text}_by_$BOT_USERNAME';
    final setTitle = _packTitleController.text;

    if (_isNewPack) {
      await _createNewStickerSet(preparedFile, setName, setTitle);
    } else {
      await _addStickerToExistingSet(preparedFile, setName);
    }
  }

  // --- TELEGRAM STYLE WIDGETS ---

  // Renders a section header (like "STICKER DETAILS")
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 20.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: telegramBlue,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // Renders a clickable/selectable option row
  Widget _buildOptionRow({
    required String title,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Switch.adaptive(
            value: isSelected,
            onChanged: onChanged,
            activeColor: telegramBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildAppDrawer(BuildContext context) {
    String TELEGRAM_USERNAME = 'Kilo532';
    final String telegramUrl = 'https://t.me/$TELEGRAM_USERNAME';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // --- Drawer Header (Telegram Style) ---
          DrawerHeader(
            decoration: const BoxDecoration(color: telegramBlue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Center(
                  child: CircleAvatar(
                    radius: 33,
                    backgroundImage: AssetImage(
                      'lib/assets/images/pfp.jpg',
                    ), // Your asset path
                  ),
                ),

                const SizedBox(height: 8.0),
                // Telegram Username Text
                Center(
                  child: Text(
                    '@$TELEGRAM_USERNAME',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                Center(
                  child: const Text(
                    'Telegram Sticker Maker',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // --- Contact ListTile ---
          ListTile(
            leading: const Icon(Icons.send, color: telegramBlue),
            title: const Text('Contact Me (Telegram)'),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // Close the drawer before navigating
              Navigator.pop(context);
              // Launch the Telegram URL
              _launchUrl(telegramUrl);
            },
          ),

          // const Divider(height: 0, thickness: 1),
        ],
      ),
    );
  }

  // Renders the main build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildAppDrawer(context),
      appBar: AppBar(
        title: const Text('Telegram Sticker Maker'),
        iconTheme: const IconThemeData(
          color: Colors.white, // Change this to your desired color
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // --- 1. IMAGE PREVIEW SECTION ---
            _buildSectionHeader('1. IMPORT AN IMAGE'),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: _pickedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _pickedImage!,
                                fit: BoxFit.contain,
                              ),
                            )
                          : const Center(
                              child: Text(
                                '512x512 Preview',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick Image from Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: telegramBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. PACK TYPE SELECTION ---
            _buildSectionHeader('2. PACK TYPE'),
            // Use a Column of Containers for the card-like effect
            Column(
              children: [
                _buildOptionRow(
                  title: 'Create New Pack',
                  isSelected: _isNewPack,
                  onChanged: (val) => setState(() => _isNewPack = val!),
                ),
                const Divider(
                  height: 0,
                  thickness: 1,
                  indent: 16,
                  endIndent: 0,
                ),
                _buildOptionRow(
                  title: 'Add to Existing Pack',
                  isSelected: !_isNewPack,
                  onChanged: (val) => setState(() => _isNewPack = !val!),
                ),
              ],
            ),

            // --- 3. STICKER DETAILS SECTION ---
            _buildSectionHeader('3. STICKER DETAILS'),
            Column(
              children: [
                // Text fields use the style set in ThemeData
                TextField(
                  controller: _packNameController,
                  decoration: const InputDecoration(
                    labelText: 'Pack Short Name (a-z, 0-9, _)',
                    helperText: 'Required!',
                  ),
                ),
                const Divider(
                  height: 0,
                  thickness: 1,
                  indent: 16,
                  endIndent: 0,
                ),
                TextField(
                  controller: _packTitleController,
                  decoration: InputDecoration(
                    labelText: 'Pack Title',
                    hintText: _isNewPack
                        ? 'Visible to users, e.g., My Fun Stickers'
                        : 'Not used for adding to existing packs',
                  ),
                ),
                const Divider(
                  height: 0,
                  thickness: 1,
                  indent: 16,
                  endIndent: 0,
                ),
                TextField(
                  controller: _emojiController,
                  decoration: const InputDecoration(
                    labelText: 'Emoji for Sticker (e.g., 💔)',
                  ),
                ),
              ],
            ),

            // --- 4. UPLOAD BUTTON ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _processAndUpload,
                icon: const Icon(Icons.cloud_upload),
                label: Text(
                  _isNewPack
                      ? 'CREATE NEW PACK & UPLOAD'
                      : 'ADD STICKER TO PACK',
                ),
              ),
            ),

            // --- 5. STATUS AND LINK ---
            _buildSectionHeader('4. STATUS'),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 5),
                  SelectableText(
                    _uploadStatus,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),

                  if (_shareUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      // SelectableText wrapped in GestureDetector for click
                      child: GestureDetector(
                        onTap: () => _launchUrl(_shareUrl!),
                        child: SelectableText(
                          'Your Sticker Link - $_shareUrl',
                          style: const TextStyle(
                            color: telegramBlue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40), // Bottom spacing
          ],
        ),
      ),
    );
  }
}
