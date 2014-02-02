Feature: change record's parent and save
  Background:
    Given tested model is "DefaultWithCounterCache"

  Scenario: move node without children to root
    Given the following tree exists:
    """
    root
      !node 1
      node 2
      node 3
        node 4
    """
    When I change "!node 1" to be root
    And I save record
    Then "!node 1" should be root
    And I should have following tree:
    """
    root
      node 2
      node 3
        node 4
    !node 1 / level = 0
    """

  Scenario: move node with descendants to root
    Given the following tree exists:
    """
    root
      node 1
      !node 2
        node 3
      node 4
    """
    When I change "!node 2" to be root
    And I save record
    Then "!node 2" should be root
    And I should have following tree:
    """
    root / position = 1
      node 1 / position = 1
      node 4 / position = 2
    !node 2 / level = 0 / position = 2
      node 3 / level = 1 / position = 1
    """

  Scenario: move node without descendants to empty non-root node
    Given the following tree exists:
    """
    root
      >node 1
      node 2
        node 3
        !node 4
        node 5
      node 6
    """
    When I change "!node 4" parent to ">node 1"
    And I save record
    Then I should have following tree:
    """
    root / level = 0 / position = 1
      >node 1 / level = 1 / position = 1
        !node 4 / level = 2 / position = 1
      node 2 / level = 1 / position = 2
        node 3 / level = 2 / position = 1
        node 5 / level = 2 / position = 2
      node 6 / level = 1 / position = 3
    """

  Scenario: mode node with descendants to empty non-root node
    Given the following tree exists:
    """
    root
      >node 1
      !node 2
        node 3
        node 4
      node 5
    """
    And I change "!node 2" parent to ">node 1"
    And I save record
    Then I should have following tree:
    """
    root
      >node 1 / level = 1 / position = 1
        !node 2 / level = 2 / position = 1
          node 3 / level = 3 / position = 1
          node 4 / level = 3 / position = 1
      node 5 / level = 1 / position = 2
    """

  Scenario: move node with descendants to non-root node with descendants
    Given the following tree exists:
    """
    root
      >node 1
        node 2
        node 3
      !node 4
        node 5
        node 6
      node 7
    """
    When I change "!node 4" parent to ">node 1"
    And I save record
    Then I should have following tree:
    """
    root / level = 0 / position = 1
      >node 1 / level = 1 / position = 1
        node 2 / level = 2 / position = 1
        node 3 / level = 2 / position = 2
        !node 4 / level = 2 / position = 3
          node 5 / level = 3 / position = 1
          node 6 / level = 3 / position = 2
      node 7 / level = 1 / position = 2
    """