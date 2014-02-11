Feature:
  Move ordered tree node to left of (to above of)
  another node via #move_to_left_of method

  Background:
    Given tested model is "DefaultWithCounterCache"
    And the following tree exists:
    """
    root
      node 1
      node 2
      node 3
        node 4
    node 5
    """

  Scenario Outline: Moving to same parent
    When I move node "<node>" to child of <target>
    Then I expect tree to be the same

  Examples:
    | node    | target  |
    | node 2  | "root"  |
    | root    | Nothing |

  Scenario: Moving to nil
    When I move node "node 1" to child of Nothing
    Then I should have following tree:
    """
    root / categories_count = 2
      node 2 / position = 1
      node 3 / position = 2
        node 4
    node 5
    node 1 / position = 3
    """

  Scenario Outline: Attempt to perform impossible movement
    When I move node "<node>" to child of "<target>"
    Then I expect tree to be the same

  Examples:
    | node   | target |
    | node 1 | node 1 |
    | node 3 | node 4 |
    | root   | node 3 |

  Scenario: Moving inner node under another parent (deeper)
    When I move node "node 3" to child of "node 2"
    Then I should have following tree:
    """
    root / categories_count = 2
      node 1
      node 2 / categories_count = 1
        node 3 / categories_count = 1 / depth = 2 / position = 1
          node 4 / depth = 3 / position = 1
    node 5
    """

  Scenario: Moving inner node under another parent (shallower)
    When I move node "node 4" to child of "root"
    Then I should have following tree:
    """
    root / categories_count = 4
      node 1
      node 2
      node 3 / categories_count = 0
      node 4 / position = 4 / depth = 1
    node 5
    """