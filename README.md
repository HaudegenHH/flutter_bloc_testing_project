# bloc_testing_project

## Steps

1. define the actions (which will interact with the bloc)
2. Define a list of urls for the json files (in an oop way with enums)
3. Since these are just the definitions of the urls (..and Dart doesnt have
   enums with associated values like in Rust), define an
   extension to get the real urls for the enum values
4. concrete implementation of LoadAction class (notice the "implements"
   which indicates that the abstract class in dart is actually an interface)
5. create the model: Person class..and then allow that class to be initialized
   from a json object, which is usually a Map<String,dynamic>

6. download and parse the 2 json files. So create a helper function which
   gets an url and returns a Future<Iterable<Person\>>, means: this fn should
   download from that url, parse it as json, and then parse that json as a list
   or iterable of Person instances (use HttpClient for that instead of a 3rd
   party package, the io package already includes the neccessary functionality)

7. Define the result of the bloc.. because bloc has its input and a output and
   you already defined the input with LoadPersonsAction, now you have to specify the
   state of this bloc which is the object it actually hold onto (as the "application state")
   and you can call it: FetchResult
   also: introduce the caching algorythm by giving it the property isRetrievedByCache

8. Now that you have the input for the bloc (loadAction) and also the
   output (the fetch result) you can now define the 'bloc header'
   and you can call it: PersonsBloc
   and remember: bloc expects an event and a state (Bloc<Event,State>) in this case:
   Bloc<LoadAction, FetchResult?> and since the fetch result (state) is empty in
   the beginning the initial state is null
   also: dont forget the \_cache which is defined as a Map of PersonUrl as key and
   Iterable\<Person\> as value => Map\<PersonUrl, Iterable<Person\>\>

important part now: how to handle incoming actions?
The way you can do this is by using the method "on" inside the Bloc constructor
which has 2 parameters: event & emit
in other words: given a specific event/action, what state do you want to emit

- Now that you have a bloc, you need to somehow provide this bloc to the application
- that can be achieved with the BlocProvider which wraps the homepage and sub-widgets

---

### Install new package / Refactoring steps

1. install new dev dependency with

```sh
flutter pub add bloc_test
```

- refactor code - split the code into several files
- get rid of PersonUrl enum, which holds onto hardcoded urls and needs an extension
  make the 2 urls global const variables and in the LoadPersonAction you require a String url (instead of: PersonUrl url)

- in addition to the injected url the LoadPersonAction retrieves a loader
  -> otherwise you always need a webserver running in order to serve the data from a given url
  -> but to make it testible, you'd mock the data and fake an Http Request

- therefore you can make a typedef like

```sh
typedef PersonsLoader = Future<Iterable<Person>> Function(String url);
```

..which returns a Future of Iterable<Person\>
and in LoadPersonAction you add:

```sh
final PersonsLoader loader;
```

=> now you can inject ANY loader in this and mock that/make it testible with that dependency injection

- Define equality on Iterable
  -> write an extension so that the ordering of the elements inside an Iterable<Person\> doesnt matter
  -> length must be equal (comparing) to another Iterable AND using Sets and intersection to check in an
  -> easy way if they are equal (putting both in a set and then compare the length of the intersection with the original length)

```sh
extension IsEqualToIgnoringOrdering<T> on Iterable<T> {
  bool isEqualToIgnoringOrdering(Iterable<T> other) =>
    length == other.length && {...this}.intersect({...other}).length == length;
}
```

- then update the equality (and hashcode) on FetchResult

```sh
@override
bool operator ==(covariant Fetchresult other) =>
  persons.isEqualToIgnoringOrdering(other.persons) &&
  isRetrievedFromCache == other.isRetrievedFromCache;
```

- Update the PersonsBloc after these changes:
  -> take away the dependency of the bloc on the getPersons function
  -> cause as long as you have a hardcoded dependency on getPersons the bloc is NOT testible!
  => good thing is that every event/action (of type LoadPersonsAction) has a loader now!
  => thats why you could now write in the else block inside PersonsBloc (the caching part is fine as it is)...

```sh
final loader = event.loader;
final persons = await loader(url);
```

- finally in main.dart
  change to..
  LoadPersonsAction(loader: getPersons, url: persons1Url)

---

useful resources:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
