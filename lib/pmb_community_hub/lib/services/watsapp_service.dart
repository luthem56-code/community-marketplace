import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Converts numbers like "082 123 4567" into international "27821234567"
  static String formatSouthAfricanNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0') && clean.length == 10) {
      return '27${clean.substring(1)}';
    }
    return clean;
  }

  static Future<void> openChat({
    required String rawPhone,
    required String businessName,
  }) async {
    final String formattedNumber = formatSouthAfricanNumber(rawPhone);
    final String message = Uri.encodeComponent(
      "Hi $businessName, I found your listing on the PMB Community Hub and would like to inquire about your services.",
    );
    final Uri url = Uri.parse("https://wa.me/$formattedNumber?text=$message");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> makePhoneCall(String phone) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}