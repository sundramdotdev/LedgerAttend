class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String email;
  final String phone;
  final String classSection;
  final String post;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.email,
    required this.phone,
    this.classSection = '',
    this.post = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rollNumber': rollNumber,
      'email': email,
      'phone': phone,
      'classSection': classSection,
      'post': post,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map, String documentId) {
    return Student(
      id: documentId,
      name: map['name'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      classSection: map['classSection'] ?? '',
      post: map['post'] ?? '',
    );
  }
}
