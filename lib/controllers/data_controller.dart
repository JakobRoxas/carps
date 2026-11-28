import '../models/carps_models.dart';
import '../repositories/carps_repository.dart';

/// Read-only query access for presentation code.
/// Mutations must go through feature controllers and their domain services.
class DataController {
  DataController(this._repository);

  final CarpsRepository _repository;

  List<UserProfile> get users => List.unmodifiable(_repository.users);
  List<CarpsEvent> get events => List.unmodifiable(_repository.events);
  List<Registration> get registrations =>
      List.unmodifiable(_repository.registrations);
  List<Invitation> get invitations =>
      List.unmodifiable(_repository.invitations);
  List<GuestPass> get passes => List.unmodifiable(_repository.passes);
  List<EventReview> get reviews => List.unmodifiable(_repository.reviews);
  List<ExperiencePost> get posts => List.unmodifiable(_repository.posts);

  UserProfile? userById(String id) => _repository.user(id);
  CarpsEvent? eventById(String id) => _repository.event(id);
  ExperiencePost? postById(String id) => _repository.post(id);
  EventReview? reviewByAuthor(String eventId, String authorId) =>
      _repository.reviews
          .where((review) =>
              review.eventId == eventId && review.authorId == authorId)
          .firstOrNull;
}
