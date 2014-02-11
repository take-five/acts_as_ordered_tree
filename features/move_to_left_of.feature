Feature:
  Move ordered tree node to left of (to above of)
  another node via #move_to_left_of method

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

  Scenario: Move node to next position
    When I move node "child 1" to left of "child 2"
    Then I should have following tree:
    """
    root
      child 1 / position = 1
      child 2 / position = 2
      child 3 / position = 3
        child 4
    """

  Scenario: Move node to same parent higher
    When I move node "child 3" to left of "child 1"
    Then I should have following tree:
    """
    root
      child 3 / position = 1 / depth = 1
        child 4 / depth = 2
      child 1 / position = 2
      child 2 / position = 3
    """

  Scenario: Move node to same parent lower
    When I move node "child 1" to left of "child 3"
    Then I should have following tree:
    """
    root
      child 2 / position = 1
      child 1 / position = 2
      child 3 / position = 3
        child 4
    """

  Scenario Outline: Attempt to perform impossible movement
    When I move node "<node>" to left of "<target>"
    Then I expect tree to be the same

  Examples:
    | node    | target  |
    | root    | child 1 |
    | child 3 | child 4 |
    | child 1 | child 1 |
    | child 3 | child 3 |

  Scenario: Move inner node to left of root node
    When I move node "child 3" to left of "root"
    Then I should have following tree:
    """
    child 3 / position = 1 / depth = 0
      child 4 / depth = 1
    root / position = 2 / categories_count = 2
      child 1
      child 2
    """

  Scenario: Move inner node to left of another inner node (shallower)
    When I move node "child 4" to left of "child 1"
    Then I should have following tree:
    """
    root
      child 4 / depth = 1 / position = 1
      child 1 / position = 2
      child 2 / position = 3
      child 3 / position = 4 / categories_count = 0
    """

  Scenario: Move inner node to left of another inner node (deeper)
    When I move node "child 1" to left of "child 4"
    Then I should have following tree:
    """
    root
      child 2 / position = 1
      child 3 / position = 2 / categories_count = 2
        child 1 / position = 1 / depth = 2
        child 4 / position = 2 / depth = 2
    """