# 2.0.0 (not released yet)

The library completely redesigned, tons of refactorings applied.

New features:

* Added ability to explicitly set left/right sibling for node via
  `#left_sibling=` and `#right_sibling=` methods (#30).
* `.leaves` scope now works even with models that don't have `counter_cache` column (#29).
* Added method instance method `#move_to_child_with_position`
  which is similar to `#move_to_child_with_index` but is more human readable.
* Full support for `before_add`, `after_add`, `before_remove` and `after_remove`
  callbacks (#25).
* Descendants now can be arranged into hash with `#arrange` method (#22).
* Flexible control over tree traversals via blocks passed to `#descendants`
  and `#ancestors` (#21).

Bug fixes:

* Fixed several issues that broke tree integrity.
* Fixed bug when two root nodes could be created with same position (#24).
* Fixed support of STI and basic inheritance.
* Fixed bug when user validations and callbacks weren't invoked on movements
  via `move_to_*` methods (#23).