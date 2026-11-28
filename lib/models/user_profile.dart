import 'carps_enums.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.username,
    required this.email,
    this.password = 'carps123',
    this.avatarAsset,
    this.bio = '',
    this.area,
    this.interests = const [],
    this.followingIds = const [],
    this.hostingEnabled = false,
    this.builderName,
    this.builderAbout,
    this.isAdmin = false,
    this.termsAccepted = false,
    this.primaryRole,
    this.profileComplete = false,
    this.discoveryDone = false,
    this.contactDiscoveryOptIn = false,
  });

  final String id;
  final String displayName;
  final String username;
  final String email;

  /// Mock credential only. Real auth is out of scope for this frontend.
  final String password;
  final String? avatarAsset;
  final String bio;
  final String? area;
  final List<String> interests;

  /// Builder accounts this user follows. Never touches registrations.
  final List<String> followingIds;

  /// Hosting tools enabled on this same account (no second account).
  final bool hostingEnabled;
  final String? builderName;
  final String? builderAbout;

  /// Assigned permission. Never selectable during onboarding.
  final bool isAdmin;

  final bool termsAccepted;
  final PrimaryRole? primaryRole;
  final bool profileComplete;
  final bool discoveryDone;
  final bool contactDiscoveryOptIn;

  bool get onboardingComplete =>
      termsAccepted && primaryRole != null && profileComplete && discoveryDone;

  String get handle => '@$username';

  UserProfile copyWith({
    String? displayName,
    String? username,
    String? avatarAsset,
    bool clearAvatar = false,
    String? bio,
    String? area,
    List<String>? interests,
    List<String>? followingIds,
    bool? hostingEnabled,
    String? builderName,
    String? builderAbout,
    bool? termsAccepted,
    PrimaryRole? primaryRole,
    bool? profileComplete,
    bool? discoveryDone,
    bool? contactDiscoveryOptIn,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      email: email,
      password: password,
      avatarAsset: clearAvatar ? null : (avatarAsset ?? this.avatarAsset),
      bio: bio ?? this.bio,
      area: area ?? this.area,
      interests: interests ?? this.interests,
      followingIds: followingIds ?? this.followingIds,
      hostingEnabled: hostingEnabled ?? this.hostingEnabled,
      builderName: builderName ?? this.builderName,
      builderAbout: builderAbout ?? this.builderAbout,
      isAdmin: isAdmin,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      primaryRole: primaryRole ?? this.primaryRole,
      profileComplete: profileComplete ?? this.profileComplete,
      discoveryDone: discoveryDone ?? this.discoveryDone,
      contactDiscoveryOptIn:
          contactDiscoveryOptIn ?? this.contactDiscoveryOptIn,
    );
  }
}
