// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_application_11/static_data.dart';
// import 'package:flutter_application_11/l10n/app_localizations.dart';

// class Editprofile extends StatefulWidget {
//   const Editprofile({super.key});

//   @override
//   State<Editprofile> createState() => _EditprofileState();
// }

// class _EditprofileState extends State<Editprofile> {
//   TextEditingController NameController = TextEditingController();
//   TextEditingController numberController = TextEditingController();
//   TextEditingController emailController = TextEditingController();

//   @override
//   void initState() {
//     NameController.text = StaticData.model!.name!;
//     numberController.text = StaticData.model!.number!;
//     emailController.text = StaticData.model!.email!;
//     super.initState();
//   }

//   void update() async {
//     DocumentReference documentReference = FirebaseFirestore.instance
//         .collection("muazam users")
//         .doc(StaticData.model!.userId);

//     Map<String, dynamic> updatedetails = {
//       "name": NameController.text,
//       "number": numberController.text,
//       "email": emailController.text,
//     };

//     await documentReference
//         .set(updatedetails, SetOptions(merge: true))
//         .then((value) {
//           print("Data has been updated");
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(AppLocalizations.of(context)!.accountCreated),
//             ),
//           );
//         })
//         .onError((error, stackTrace) {
//           print(error.toString());
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(AppLocalizations.of(context)!.somethingWentWrong),
//             ),
//           );
//         });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;

//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text(l10n.editProfile),
//           backgroundColor: Colors.blue,
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.start,
//             children: [
//               TextField(
//                 controller: NameController,
//                 decoration: InputDecoration(hintText: l10n.name),
//               ),
//               const SizedBox(height: 20),
//               TextField(
//                 controller: numberController,
//                 decoration: InputDecoration(hintText: l10n.number),
//               ),
//               const SizedBox(height: 20),
//               TextField(
//                 controller: emailController,
//                 decoration: InputDecoration(hintText: l10n.email),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(onPressed: update, child: Text(l10n.editProfile)),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_11/static_data.dart';
import 'package:flutter_application_11/l10n/app_localizations.dart';

class Editprofile extends StatefulWidget {
  const Editprofile({super.key});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  final TextEditingController NameController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  static const _primaryBlue = Color(0xFF246BFD);
  static const _bg = Color(0xFFF4F7FC);
  static const _fieldBg = Colors.white;

  File? _imageFile;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    NameController.text = StaticData.model!.name ?? '';
    numberController.text = StaticData.model!.number ?? '';
    emailController.text = StaticData.model!.email ?? '';
  }

  @override
  void dispose() {
    NameController.dispose();
    numberController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: _primaryBlue),
              title: const Text('Pick from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _primaryBlue),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getProfileImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (StaticData.model!.imageUrl != null && StaticData.model!.imageUrl!.isNotEmpty) {
      return NetworkImage(StaticData.model!.imageUrl!);
    } else {
      return const AssetImage('images/person2.jpeg');
    }
  }

  void update() async {
    setState(() {
      _isUploading = true;
    });

    final l10n = AppLocalizations.of(context)!;
    String? finalImageUrl = StaticData.model!.imageUrl;

    try {
      if (_imageFile != null) {
        String fileName = 'profile_images/${StaticData.model!.userId}.jpg';
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = ref.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        finalImageUrl = await snapshot.ref.getDownloadURL();
      }

      DocumentReference documentReference = FirebaseFirestore.instance
          .collection("muazam users")
          .doc(StaticData.model!.userId);

      Map<String, dynamic> updatedetails = {
        "name": NameController.text,
        "number": numberController.text,
        "email": emailController.text,
      };

      if (finalImageUrl != null) {
        updatedetails["imageUrl"] = finalImageUrl;
      }

      await documentReference.set(updatedetails, SetOptions(merge: true));
      
      StaticData.model!.name = NameController.text;
      StaticData.model!.number = numberController.text;
      StaticData.model!.email = emailController.text;
      if (finalImageUrl != null) {
        StaticData.model!.imageUrl = finalImageUrl;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Profile Updated Successfully!"),
            backgroundColor: _primaryBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          l10n.editProfile,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30, top: 20),
              decoration: const BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            image: DecorationImage(
                              image: _getProfileImage(),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: _primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    StaticData.model!.name ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    StaticData.model!.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Information",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildField(
                    controller: NameController,
                    hint: l10n.name,
                    icon: Icons.person_outline,
                    keyboard: TextInputType.name,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: numberController,
                    hint: l10n.number,
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: emailController,
                    hint: l10n.email,
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : update,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        disabledBackgroundColor: _primaryBlue.withOpacity(0.6),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              l10n.editProfile.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: _primaryBlue.withOpacity(0.7), size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
