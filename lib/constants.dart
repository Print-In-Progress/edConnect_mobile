import 'package:flutter/material.dart';

class DatabaseCollectionProvider extends ChangeNotifier {
  String _customerSpecificCollectionArticles = '';
  String _customerSpecificCollectionEvents = '';
  String _customerSpecificCollectionUsers = '';
  String _customerSpecificCollectionComments = '';
  String _customerSpecificCollectionFiles = '';
  String _customerSpecificRootCollectionName = '';
  String _customerSpecificCollectionSurveys = '';
  String _customerSpecificCollectionSortingAlg = '';
  String _customerSpecificCollectionRegistration = '';
  String _customerSpecificCollectionMessaging = '';

  String get customerSpecificCollectionArticles =>
      _customerSpecificCollectionArticles;

  String get customerSpecificCollectionEvents =>
      _customerSpecificCollectionEvents;

  String get customerSpecificCollectionUsers =>
      _customerSpecificCollectionUsers;

  String get customerSpecificCollectionComments =>
      _customerSpecificCollectionComments;

  String get customerSpecificCollectionFiles =>
      _customerSpecificCollectionFiles;

  String get customerSpecificRootCollectionName =>
      _customerSpecificRootCollectionName;

  String get customerSpecificCollectionSurveys =>
      _customerSpecificCollectionSurveys;

  String get customerSpecificCollectionSortingAlg =>
      _customerSpecificCollectionSortingAlg;

  String get customerSpecificCollectionRegistration =>
      _customerSpecificCollectionRegistration;

  String get customerSpecificCollectionMessaging =>
      _customerSpecificCollectionMessaging;

  void setRootCollection(String collection) {
    _customerSpecificCollectionArticles = '/$collection/newsapp/articles';
    _customerSpecificCollectionEvents = '/$collection/newsapp/events';
    _customerSpecificCollectionUsers = '/$collection/newsapp/users';
    _customerSpecificCollectionComments = '/$collection/newsapp/comments';
    _customerSpecificCollectionSurveys = '/$collection/newsapp/surveys';
    _customerSpecificCollectionSortingAlg = '/$collection/newsapp/sorting_alg';
    _customerSpecificCollectionMessaging = '/$collection/newsapp/messaging';
    _customerSpecificCollectionFiles = 'files_$collection';
    _customerSpecificCollectionRegistration =
        '/$collection/newsapp/registration_page';
    _customerSpecificRootCollectionName = collection;
    notifyListeners();
  }
}
