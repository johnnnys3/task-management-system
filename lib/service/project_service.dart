import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/models/project.dart';


class ProjectService {
  final CollectionReference projectsCollection =
      FirebaseFirestore.instance.collection('projects');

  Future<List<Project>> getProjects({required String userId}) async {
  try {
    QuerySnapshot projectsSnapshot = await projectsCollection.get();
    List<Project> projects = [];

    for (QueryDocumentSnapshot<Object?> doc in projectsSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      projects.add(Project(
        id: doc.id, 
        name: data['name'].toString(), 
        description: '', 
        dueDate: DateTime.now(), 
        tasks: [], isCompleted: false, 
      ));
    }

    return projects;
  } catch (error) {
    print('Error fetching projects: $error');
    throw Exception('Failed to fetch projects');
  }
}

  Future<void> addProject(String projectName) async {
    try {
      await projectsCollection.add({'name': projectName});
    } catch (error) {
      print('Error adding project: $error');
      throw Exception('Failed to add project');
    }
  }

  Future<void> updateProject(String projectId, String newName) async {
    try {
      await projectsCollection.doc(projectId).update({'name': newName});
    } catch (error) {
      print('Error updating project: $error');
      throw Exception('Failed to update project');
    }
  }

  Future<void> deleteProject({required String projectId, required String userId}) async {
  try {
    await projectsCollection.doc(projectId).delete();
  } catch (error) {
    print('Error deleting project: $error');
    throw Exception('Failed to delete project');
  }
}

}
