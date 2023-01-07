import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:developer' as devtools show log;

/// 1. define the actions (which will interact with the bloc)
///
/// 2. Define a list of urls for the json files (in an oop way with enums)
///
/// 3. Since these are just the definitions of the urls (..and Dart doesnt have
/// enums with associated values like in Rust), define an
/// extension to get the real urls for the enum values
///
/// 4. concrete implementation of LoadAction class (notice the "implements"
/// which indicates that the abstract class in dart is actually an interface)
///
/// 5. create the model: Person class..and then allow that class to be initialized
/// from a json object, which is usually a Map<String,dynamic>
///
/// 6. download and parse the 2 json files. So create a helper function which
/// gets an url and returns a Future<Iterable<Person>>, means: this fn should
/// download from that url, parse it as json, and then parse that json as a list
/// or iterable of Person instances (use HttpClient for that instead of a 3rd
/// party package, the io package already includes the neccessary functionality)
///
/// 7. Define the result of the bloc.. because bloc has its input and a output and
/// you already defined the input with LoadPersonsAction, now you have to specify the
/// state of this bloc which is the object it actually hold onto (as the "application state")
/// and you can call it: FetchResult
/// also: introduce the caching algorythm by giving it the property isRetrievedByCache
///
/// 8. Now that you have the input for the bloc (loadAction) and also the
/// output (the fetch result) you can now define the 'bloc header'
/// and you can call it: PersonsBloc
/// and remember: bloc expects an event and a state (Bloc<Event,State>) in this case:
/// Bloc<LoadAction, FetchResult?> and since the fetch result (state) is empty in
/// the beginning the initial state is null
/// also: dont forget the _cache which is defined as a Map of PersonUrl as key and
/// Iterable<Person> as value => Map<PersonUrl, Iterable<Person>>
///
/// important part now: how to handle incoming actions?
/// The way you can do this is by using the method "on" inside the Bloc constructor
/// which has 2 parameters: event & emit
/// in other words: given a specific event/action, what state do you want to emit
///
/// 9. Now that you have a bloc, you need to somehow provide this bloc to the
/// application
///

extension Log on Object {
  void log() => devtools.log(toString());
}

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => PersonsBloc(),
        child: const HomePage(),
      ),
    ),
  );
}

@immutable
abstract class LoadAction {
  const LoadAction();
}

@immutable
class LoadPersonsAction implements LoadAction {
  final PersonUrl url;
  const LoadPersonsAction({required this.url}) : super();
}

enum PersonUrl {
  persons1,
  persons2,
}

extension UrlString on PersonUrl {
  String get urlString {
    switch (this) {
      case PersonUrl.persons1:
        return 'http://10.0.2.2:5500/api/persons1.json';
      case PersonUrl.persons2:
        return 'http://10.0.2.2:5500/api/persons2.json';
    }
  }
}

// prefer iterable over list so that you return it lazily
// chaining together futures in dart..
// transform the response in order to get a string from it
// but not a json yet only the string representation of it.
// After decoding it, it is a List (List<Map<String,dynamic>>)
// which you can iterate over in order to create the iterable of Persons
// with the named constructor Person.fromJson
Future<Iterable<Person>> getPersons(String url) => HttpClient()
    .getUrl(Uri.parse(url)) // returns the request (as a promise/future)..
    .then((req) => req.close()) // closes the request & returns a response..
    .then((res) => res.transform(utf8.decoder).join()) // becomes a string..
    .then((str) => json.decode(str) as List<dynamic>) // s.o.
    .then((list) => list.map((e) => Person.fromJson(e))); // s.o.

@immutable
class Person {
  final String name;
  final int age;

  // const Person({required this.name, required this.age});

  // this will be the default constructor (thus no need for a regular constructor)
  Person.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;

  @override
  String toString() => 'Person (name = $name, age = $age';
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
}

/// 1. take the url from the event (LoadPersonAction)
/// 2. look if that "url" already exists as key in the Map/cache
/// 3. if it does emit it
/// with emit you tell anyone who is listen to the bloc, that there is a new State

class PersonsBloc extends Bloc<LoadAction, FetchResult?> {
  final Map<PersonUrl, Iterable<Person>> _cache = {};
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
          final persons = await getPersons(url.urlString);
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Home Page'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              TextButton(
                  onPressed: () {
                    context.read<PersonsBloc>().add(
                          const LoadPersonsAction(url: PersonUrl.persons1),
                        );
                  },
                  child: const Text('Load Json #1')),
              TextButton(
                  onPressed: () {
                    context.read<PersonsBloc>().add(
                          const LoadPersonsAction(url: PersonUrl.persons2),
                        );
                  },
                  child: const Text('Load Json #2')),
            ],
          ),
          BlocBuilder<PersonsBloc, FetchResult?>(
            buildWhen: ((previousResult, currentResult) {
              return previousResult?.persons != currentResult?.persons;
            }),
            builder: ((context, fetchResult) {
              fetchResult?.log();
              final persons = fetchResult?.persons;
              if (persons == null) {
                return const SizedBox();
              } else {
                return Expanded(
                  child: ListView.builder(
                    itemCount: persons.length,
                    itemBuilder: (context, index) {
                      final person = persons[index]!;
                      return ListTile(
                        title: Text(person.name),
                      );
                    },
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }
}

/* problem:
persons[index] => persons is an Iterable and the
operator [] isnt defined for the type 'Iterable<String>'

test:
const Iterable<String> names = ['foo', 'bar'];

..which surprises because List inherits from/is an Iterable

const List<String> names = ['foo', 'bar'];

-> baz in the void would be a String (though this index doesnt exist)

..which is the second problem: it should indicate, that baz should be an optional
String, because index 2 doesnt exist and thus should return null

void testIt() {
  final baz = names[2];
}

-> extension that solves that issue (note: T? => optionally return a value)
*/
extension Subscript<T> on Iterable<T> {
  T? operator [](int index) => length > index ? elementAt(index) : null;
}
