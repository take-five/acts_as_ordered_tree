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
    """

  Scenario Outline: Move node to same parent with same position
    When I move node "node 1" to child of "root" to <kind> <value>
    Then I expect tree to be the same

  Examples:
    | kind     | value |
    | position | 1     |
    | index    | 0     |

  Scenario: Move node to same parent with another position
    When I move node "node 1" to child of "root" to position 2
    Then I should have following tree:
    """
    root
      node 2 / position = 1
      node 1 / position = 2
      node 3 / position = 3
        node 4
    """

  Scenario: Move node to same parent to lowest position
    When I move node "node 1" to child of "root" to position 3
    Then I should have following tree:
    """
    root
      node 2 / position = 1
      node 3 / position = 2
        node 4
      node 1 / position = 3
    """

  Scenario: Move node to index starting from end
    When I move node "node 4" to child of "root" to index -2
    Then I should have following tree:
    """
    root / categories_count = 4
      node 1 / position = 1
      node 4 / position = 2 / depth = 1
      node 2 / position = 3
      node 3 / position = 4 / categories_count = 0
    """

  Scenario: Move node to root to index starting from end
    When I move node "node 4" to child of Nothing to index -1
    Then I should have following tree:
    """
    node 4 / position = 1 / depth = 0
    root / position = 2
      node 1
      node 2
      node 3 / categories_count = 0
    """

  Scenario: Move node to very large negative index
    When I move node "node 4" to child of "root" to index -100
    Then I should have following tree:
    """
    root
      node 4 / position = 1 / depth = 1
      node 1 / position = 2
      node 2 / position = 3
      node 3 / position = 4 / categories_count = 0
    """

  Scenario: Move to node to very large position
    When I move node "node 4" to child of "root" to position 100
    Then I should have following tree:
    """
    root
      node 1
      node 2
      node 3
      node 4 / position = 4 / depth = 1
    """