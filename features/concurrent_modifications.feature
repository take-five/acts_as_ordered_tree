@concurrent
Feature: update tree concurrently
  @wip
  Scenario: create root nodes in empty tree simultaneously
    When I create 3 root nodes simultaneously
    # FIXME: fails now because of #24
    Then root nodes sorted by "position" should have "position" attribute equal to "[1, 2, 3]"

  Scenario: add root nodes to existing tree simultaneously
    Given the node "root" exists
    When I create 3 root nodes simultaneously
    Then root nodes sorted by "position" should have "position" attribute equal to "[1, 2, 3, 4]"

  Scenario: create nodes on the same level simultaneously
    Given the node "root" exists
    When I create 3 children of "root" simultaneously
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
    When I move nodes "node 1, node 2, node 3" under "root" simultaneously
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

    When I move nodes "node 1, node 2, node 3" to left of "root" simultaneously
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

    When I move nodes "node 1, node 2, node 3" to left of "child" simultaneously
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

    When I move nodes "node 1, node 2, node 3" to right of "root" simultaneously
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

    When I move nodes "node 1, node 2, node 3" to right of "child" simultaneously
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
    When I move nodes "node 1, node 2, node 3" to root simultaneously
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
    When I move nodes "child 2, child 3" <position> simultaneously
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
    When I want to swap nodes "swap 1" and "swap 2" to indices 2 and 0 simultaneously
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