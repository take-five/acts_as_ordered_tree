Feature: Move ordered tree node to root via #move_to_root method
  Background:
    Given tested model is "DefaultWithCounterCache"
    And the following tree exists:
    """
    root
      child 1
      child 2
      child 3
        child 4
    """

  Scenario: Move already-root node to root
    When I move node "root" to root
    Then I expect tree to be the same

  Scenario: Move inner node to root
    When I move node "child 2" to root
    Then I should have following tree:
    """
    root / categories_count = 2 / position = 1
      child 1 / position = 1
      child 3 / position = 2 / categories_count = 1
        child 4 / position = 1
    child 2 / depth = 0
    """

  Scenario: Move inner node with descendants to root
    When I move node "child 3" to root
    Then I should have following tree:
    """
    root / categories_count = 2 / position = 1
      child 1
      child 2
    child 3 / depth = 0 / position = 2
      child 4 / depth = 1 / position = 1
    """