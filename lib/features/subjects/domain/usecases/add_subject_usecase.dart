import '../entities/subject.dart';
import '../repositories/subject_repository.dart';

class AddSubjectUseCase {
  final SubjectRepository repository;

  AddSubjectUseCase(this.repository);

  Future<void> call(Subject subject) async {
    final name = subject.name.trim();
    if (name.isEmpty) {
      throw ArgumentError('Subject name cannot be empty');
    }
    if (name.length > 40) {
      throw ArgumentError('Subject name cannot exceed 40 characters');
    }

    final subjects = await repository.getSubjects();
    if (subjects.any((s) => s.name.toLowerCase() == name.toLowerCase())) {
      throw ArgumentError('Subject with this name already exists');
    }

    final updatedSubjects = List<Subject>.from(subjects)..add(subject);
    await repository.saveSubjects(updatedSubjects);
  }
}
