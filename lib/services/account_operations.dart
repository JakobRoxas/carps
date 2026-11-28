part of 'carps_domain_operations.dart';

mixin AccountOperations on CarpsServiceBase, EventQueryOperations {

  UserProfile? findByEmail(String email) {
    final e = email.trim().toLowerCase();
    for (final u in repo.users) {
      if (u.email.toLowerCase() == e) return u;
    }
    return null;
  }

  UserProfile logIn(String email, String password) {
    final user = findByEmail(email);
    if (user == null || user.password != password) {
      throw const RuleViolation('Email or password is incorrect.');
    }
    return user;
  }

  UserProfile signUp(String email, String password) {
    if (!CarpsValidation.isValidEmail(email)) throw const RuleViolation('Enter a valid email.');
    if (password.length < 8) {
      throw const RuleViolation('Use at least 8 characters for your password.');
    }
    if (findByEmail(email) != null) {
      throw const RuleViolation('An account with this email already exists.');
    }
    final local = email.split('@').first.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9_]'), '');
    final user = UserProfile(
      id: repo.nextId('u'),
      displayName: '',
      username: local.isEmpty ? 'newmember' : local,
      email: email.trim(),
      password: password,
    );
    repo.saveUser(user);
    return user;
  }

  String? usernameProblem(String username, {String? ownerId}) {
    final u = username.trim().replaceFirst('@', '');
    if (!CarpsValidation.usernamePattern.hasMatch(u)) {
      return 'Use 3–20 lowercase letters, numbers or underscores.';
    }
    final taken = repo.users.any((x) => x.username == u && x.id != ownerId);
    return taken ? 'That username is taken.' : null;
  }

  void updateUser(UserProfile user) => repo.saveUser(user);

  void enableHosting(String userId,
      {required String builderName, required String about}) {
    if (builderName.trim().length < 3) {
      throw const RuleViolation('Give your builder profile a name.');
    }
    final user = requireUser(userId);
    repo.saveUser(user.copyWith(
        hostingEnabled: true,
        builderName: builderName.trim(),
        builderAbout: about.trim()));
  }

  List<UserProfile> searchPeople(String query, {String? excludeId}) {
    final q = query.trim().toLowerCase().replaceFirst('@', '');
    return repo.users.where((u) {
      if (u.id == excludeId || u.displayName.isEmpty) return false;
      if (q.isEmpty) return true;
      return u.displayName.toLowerCase().contains(q) ||
          u.username.contains(q) ||
          (u.builderName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}
