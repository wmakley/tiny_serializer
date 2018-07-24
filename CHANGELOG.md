# SimpleSerializer Change Log

## 0.4.0

* Raises ArgumentError if a specified serializer is not actually a
  SimpleSerializer subclass.
* Add note to README.md about attribute inheritance.

## 0.3.1

* Fix bug where collections would be checked for existence before serialization,
  causing unnecessary database queries.

## 0.3.0

* Fix blocks not being passed on to the #sub_record method.
* Major documentation improvements.
* Code cleanup and simplification.
* Travis CI config improvements.
* Allow #as_json and #to_json to take arguments.

## 0.2.1

* Remove lack of inheritance as a downside!

## 0.2.0

* Implement serialized attribute inheritance.
* README improvements.
* Add this CHANGELOG.

## 0.1.0

* Initial post to Reddit.
