import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_testing_project/bloc/bloc_actions.dart';
import 'package:bloc_testing_project/bloc/person.dart';
import 'package:flutter/foundation.dart' show immutable;

extension IsEqualToIgnoringOrdering<T> on Iterable<T> {
  bool isEqualToIgnoringOrdering(Iterable<T> other) =>
      length == other.length &&
      {...this}.intersection({...other}).length == length;
}

@immutable
class FetchResult {
  final Iterable<Person> persons;
  final bool isRetrievedFromCache;

  const FetchResult({
    required this.persons,
    required this.isRetrievedFromCache,
  });

  @override
  String toString() =>
      'FetchResult (is retrieved from cache = $isRetrievedFromCache, person = $persons';

  @override
  bool operator ==(covariant FetchResult other) =>
      persons.isEqualToIgnoringOrdering(other.persons) &&
      isRetrievedFromCache == other.isRetrievedFromCache;

  @override
  int get hashCode => Object.hash(persons, isRetrievedFromCache);
}

/// 1. take the url from the event (LoadPersonAction)
/// 2. look if that "url" already exists as key in the Map/cache
/// 3. if it does emit it
/// with emit you tell anyone who is listen to the bloc, that there is a new State
class PersonsBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<String, Iterable<Person>> _cache = {};
  PersonsBloc() : super(null) {
    on<LoadPersonsAction>(
      (event, emit) async {
        final url = event.url;
        if (_cache.containsKey(url)) {
          // you have the value in the cache
          final cachedPersons = _cache[url]!;
          final result = FetchResult(
            isRetrievedFromCache: true,
            persons: cachedPersons,
          );
          emit(result);
        } else {
          final loader = event.loader;
          final persons = await loader(url);
          _cache[url] = persons;
          final result = FetchResult(
            isRetrievedFromCache: false,
            persons: persons,
          );
          emit(result);
        }
      },
    );
  }
}
