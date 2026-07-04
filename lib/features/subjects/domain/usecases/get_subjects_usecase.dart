import '../entities/subject.dart';
import '../repositories/subject_repository.dart';

class GetSubjectsUseCase {
  final SubjectRepository repository;

  GetSubjectsUseCase(this.repository);

  Future<List<Subject>> call() async {
    return await repository.getSubjects();
  }
}
