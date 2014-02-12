@concurrent
Feature: update tree concurrently
  Scenario: create root nodes in empty tree simultaneously
    When I want to create root node 3 times
    And I perform these actions simultaneously
    Then I should have following tree:
    """
    * / position = 1
    * / position = 2
    * / position = 3
    """

  Scenario: add root nodes to existing tree simultaneously
    Given I create root node "root"
    When I want to create root node 3 times
    And I perform these actions simultaneously
    Then I should have following tree:
    """
    root
    * / position = 2
    * / position = 3
    * / position = 4
    """

  Scenario: create nodes on the same level simultaneously
    Given I create root node "root"
    When I want to create node under "root" 3 times
    And I perform these actions simultaneously
    Then I should have following tree:
    """
    root
      * / position = 1
      * / position = 2
      * / position = 3
    """

  Scenario: move nodes to same parent simultaneously
    Given the following tree exists:
    """
    root
    node 1
    node 2
    node 3
    """
    When I want to move node "node 1" under "root"
    And I want to move node "node 2" under "root"
    And I want to move node "node 3" under "root"
    And I perform these actions simultaneously
    Then I should have following tree:
    """
    root
      * / position = 1
      * / position = 2
      * / position = 3
    """

  Scenario: move nodes to left of same root node simultaneously
    Given the following tree exists:
    """
    root
      node 1
      node 2
      node 3
    """

    When I want to move node "node 1" to left of "root"
    And I want to move node "node 2" to left of "root"
    And I want to move node "node 3" to left of "root"
    And I perform these actions simultaneously
    Then I should have following tree:
    """
    * / position = 1
    * / position = 2
    * / position = 3
    root / position = 4
    """

  Scenario: move nodes to left of same non-root node simultaneously
    Given the following tree exists:
    """
    root
      child
        node 1
        node 2
        node 3
    """

    When I want to move node "node 1" to left of "child"
    And I want to move node "node 2" to left of "child"
    And I want to move node "node 3" to left of "child"
    And I perform these actions simultaneously
    Then I should have following tree:
    """
    root
      * / position = 1
      * / position = 2
      * / position = 3
      child / position = 4
    """

  Scenario: move node to right of same root node simultaneously
    Given the following tree exists:
    """
    root
      node 1
      node 2
      node 3
    """

    When I want to move node "node 1" to right of "root"
    And I want to move node "node 2" to right of "root"
    And I want to move node "node 3" to right of "root"
    And I perform these actions simultaneously
    Then I should have following tree:
    """
    root / position = 1
    * / position = 2
    * / position = 3
    * / position = 4
    """

  Scenario: move nodes to right of same non-root node simultaneously
    Given the following tree exists:
    """
    root
      child
        node 1
        node 2
        node 3
    """

    When I want to move node "node 1" to right of "child"
    And I want to move node "node 2" to right of "child"
    And I want to move node "node 3" to right of "child"
    And I perform these actions simultaneously
    Then I should have following tree:
    """
    root
      child / position = 1
      * / position = 2
      * / position = 3
      * / position = 4
    """

  Scenario: move nodes to root simultaneously
    Given the following tree exists:
    """
    root
      node 1
      node 2
      node 3
    """
    When I want to move node "node 1" to root
    And I want to move node "node 2" to root
    And I want to move node "node 3" to root
    And I perform these actions simultaneously
    Then I should have following tree:
    """
    root / position = 1
    * / position = 2
    * / position = 3
    * / position = 4
    """

  Scenario Outline: move nodes left/right simultaneously
    Given the following tree exists:
    """
    root
      child 1
      child 2
      child 3
      child 4
    """
    When I want to move node "child 2" <position>
    And I want to move node "child 3" <position>
    And I perform these actions simultaneously
    Then I should have following tree:
    """
    root
      * / position = 1
      * / position = 2
      * / position = 3
      * / position = 4
    """

    Examples:
    | position |
    | higher   |
    | lower    |

  Scenario: swap nodes between different branches simultaneously
    Given the following tree exists:
    """
    root
      child 1
        swap 1
        *
      child 2
        *
        swap 2
    """
    When I want to move node "swap 1" under "child 2" to position 2
    When I want to move node "swap 2" under "child 1" to position 1
    And I perform these actions simultaneously
    Then I should have following tree:
    """
    root
      child 1
        swap 2
        *
      child 2
        *
        swap 1
    """