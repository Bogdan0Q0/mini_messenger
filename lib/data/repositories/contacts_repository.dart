import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact.dart';

class ContactsRepository {
  Future<List<Contact>> fetchContacts() async {
    try {
      final res = await http
          .get(Uri.parse('https://jsonplaceholder.typicode.com/users'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return data.take(10).map((j) => Contact.fromJson(j)).toList();
      }
    } catch (e) {
      return kFallbackContacts;
    }
    return kFallbackContacts;
  }
}
