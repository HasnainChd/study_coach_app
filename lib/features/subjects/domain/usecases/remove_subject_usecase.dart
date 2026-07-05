import '../repositories/subject_repository.dart';

class RemoveSubjectUseCase {
  final SubjectRepository repository;

  RemoveSubjectUseCase(this.repository);

  Future<void> call(String id) async {
    final subjects = await repository.getSubjects();
    final updatedSubjects = subjects.where((s) => s.id != id).toList();
    await repository.saveSubjects(updatedSubjects);
  }
}
