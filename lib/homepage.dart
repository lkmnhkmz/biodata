import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'biodataservice.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Biodataservice? service; // Service untuk mengelola biodata di Firestore
  String? selectedDocId; // ID dokumen yang dipilih untuk diupdate

  // Controller untuk mengelola input teks
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    service = Biodataservice(db: FirebaseFirestore.instance); // Inisialisasi service
    super.initState();
  }

  @override
  void dispose() {
    // Membersihkan controller saat widget dihapus
    nameController.dispose();
    ageController.dispose();
    addressController.dispose();
    super.dispose();
  }

  // Fungsi untuk menyimpan atau memperbarui data
  void _saveOrUpdateData() {
    final name = nameController.text.trim();
    final age = ageController.text.trim();
    final address = addressController.text.trim();

    if (name.isEmpty || age.isEmpty || address.isEmpty) {
      // Menampilkan pesan kesalahan jika ada input yang kosong
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua kolom")),
      );
      return;
    }

    if (selectedDocId != null) {
      // Jika ada ID dokumen yang dipilih, lakukan update
      service?.update(selectedDocId!, {'name': name, 'age': age, 'address': address});
    } else {
      // Jika tidak ada ID dokumen yang dipilih, tambahkan data baru
      service?.add({'name': name, 'age': age, 'address': address});
    }

    // Mengosongkan input setelah penyimpanan
    nameController.clear();
    ageController.clear();
    addressController.clear();
    selectedDocId = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Biodata")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Input nama
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 8),
              // Input usia
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Usia',
                  prefixIcon: Icon(Icons.numbers),
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 8),
              // Input alamat
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              // Menampilkan daftar biodata dari Firestore
              Expanded(
                child: StreamBuilder(
                  stream: service?.getBiodata(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text("Terjadi kesalahan: ${snapshot.error}");
                    } else if (!snapshot.hasData || snapshot.data?.docs.isEmpty == true) {
                      return const Text("Tidak ada biodata tersedia");
                    }

                    final documents = snapshot.data?.docs;

                    return ListView.builder(
                      itemCount: documents?.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(documents?[index]['name']),
                          subtitle: Text("Usia: ${documents?[index]['age']}"),
                          onTap: () {
                            // Memilih dokumen untuk diedit
                            setState(() {
                              nameController.text = documents?[index]['name'];
                              ageController.text = documents?[index]['age'];
                              addressController.text = documents?[index]['address'];
                              selectedDocId = documents?[index].id;
                            });
                          },
                          trailing: IconButton(
                            onPressed: () {
                              // Menghapus biodata berdasarkan ID dokumen
                              if (documents?[index].id != null) {
                                service?.delete(documents![index].id);
                              }
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveOrUpdateData, // Tombol untuk menyimpan data
        child: const Icon(Icons.save),
      ),
    );
  }
}
