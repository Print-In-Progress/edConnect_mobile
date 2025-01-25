import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edconnect_mobile/constants.dart';
import 'package:edconnect_mobile/delegates/search_delegates/abstract_search_delegate.dart';
import 'package:edconnect_mobile/models/user.dart';
import 'package:edconnect_mobile/pages/messaging_pages/chatroom_page.dart';
import 'package:edconnect_mobile/services/data_services.dart';
import 'package:provider/provider.dart';

class MessagingContactsSearchDelegate extends PIPSearchDelegate {
  final DataService _dataService = DataService();
  late Future<List<AppUser>> _futureUsers;
  final DatabaseCollectionProvider databaseProvider;

  MessagingContactsSearchDelegate(this.databaseProvider)
      : super(
          searchFieldLabel: 'Search...',
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
        ) {
    _futureUsers = _fetchAllUsers();
  }

  Future<List<AppUser>> _fetchAllUsers() async {
    try {
      final users = await _dataService.fetchAllUsers(databaseProvider);
      // Ensure no null values are returned
      return users;
    } catch (e) {
      // Handle any errors that occur during the fetch
      print('Error fetching users: $e');
      return [];
    }
  }

  List<AppUser> _filterUsers(List<AppUser> users, String currentUserId) {
    return users.where((user) {
      return user.id != currentUserId &&
          '${user.firstName} ${user.lastName}'
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [];
  }

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_rounded));

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<AppUser>>(
      future: _futureUsers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No users found.'));
        } else {
          final filteredUsers = _filterUsers(
              snapshot.data!, FirebaseAuth.instance.currentUser!.uid);
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return ListTile(
                textColor: Colors.white,
                leading: CircleAvatar(
                  child: Text(user.firstName[0] + user.lastName[0]),
                ),
                title: Text('${user.firstName} ${user.lastName}'),
                onTap: () {
                  // Create ChatRoom with user
                },
              );
            },
          );
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final databaseProvider = Provider.of<DatabaseCollectionProvider>(context);
    return FutureBuilder<List<AppUser>>(
      future: _futureUsers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No users found.'));
        } else {
          final users = snapshot.data!;
          final currentUser = users.firstWhere(
              (user) => user.id == FirebaseAuth.instance.currentUser!.uid);

          final filteredUsers = _filterUsers(users, currentUser.id);
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return ListTile(
                textColor: Colors.white,
                leading: CircleAvatar(
                  child: Text(user.firstName[0] + user.lastName[0]),
                ),
                title: Text('${user.firstName} ${user.lastName}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        settings: const RouteSettings(name: 'chat_room_page'),
                        builder: (context) => ChatPage(
                            currentUser: currentUser,
                            recipient: user,
                            orgName: databaseProvider
                                .customerSpecificRootCollectionName,
                            userCollection: databaseProvider
                                .customerSpecificCollectionUsers,
                            messageCollection: databaseProvider
                                .customerSpecificCollectionMessaging)),
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}
