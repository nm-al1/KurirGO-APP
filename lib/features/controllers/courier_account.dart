class CourierAccount {
  String username = 'ardiansyah';
  String fullName = 'Ardiansyah';
  bool loggedIn = false;
  String? get phone => _accounts[username]?.phone;

  void updateProfile(String name, String phone) {
    if (!loggedIn) throw StateError('Masuk dahulu.');
    if (name.trim().isEmpty) throw ArgumentError('Isi nama lengkap.');
    if (phone.trim().isNotEmpty &&
        !RegExp(r'^\+?[0-9 -]{8,20}$').hasMatch(phone.trim())) {
      throw ArgumentError('Nomor WhatsApp tidak valid.');
    }
    final previous = _accounts[username]!;
    fullName = name.trim();
    _accounts[username] = (
      pin: previous.pin,
      name: fullName,
      phone: phone.trim(),
    );
  }

  final _accounts = <String, ({String pin, String name, String? phone})>{
    'ardiansyah': (pin: '1234', name: 'Ardiansyah', phone: null),
  };

  bool isAvailable(String username) => !_accounts.containsKey(username.trim());

  void login(String user, String pin) {
    final account = _accounts[user.trim()];
    if (account == null || account.pin != pin) {
      throw ArgumentError('Username atau PIN tidak cocok.');
    }
    username = user.trim();
    fullName = account.name;
    loggedIn = true;
  }

  void register({
    required String name,
    required String username,
    required String pin,
    String? whatsapp,
  }) {
    if (name.trim().isEmpty ||
        !RegExp(r'^[a-zA-Z0-9_]{3,}$').hasMatch(username.trim()) ||
        !RegExp(r'^\d{4,6}$').hasMatch(pin) ||
        !isAvailable(username)) {
      throw ArgumentError('Periksa nama, username dan PIN 4–6 digit.');
    }
    final phone = whatsapp?.trim();
    if (phone != null &&
        phone.isNotEmpty &&
        !RegExp(r'^\+?[0-9 -]{8,20}$').hasMatch(phone)) {
      throw ArgumentError('Nomor WhatsApp tidak valid.');
    }
    _accounts[username.trim()] = (pin: pin, name: name.trim(), phone: phone);
    login(username, pin);
  }
}
