# 2.0.0 (not released yet)

The library completely redesigned, tons of refactorings applied.

New features:

* Added method instance method `#move_to_child_with_position`
  which is similar to `#move_to_child_with_index` but is more human readable.
* Descendants now can be arranged into hash via `#arrange` method (#22).
* Flexible control over tree traversals via blocks passed to `#descendants`
  and `#ancestors` (#21)

Bug fixes:

* Fixed several issues that broke tree integrity
* Fixed bug when two root nodes could be created with same position (#24)