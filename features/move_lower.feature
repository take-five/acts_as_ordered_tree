Feature: Move ordered tree node lower via #move_lower method
  Background:
    Given the following tree exists:
    """
    node 1
    node 2
    node 3
    """

  Scenario: Try to move lowest node down
    When I move node "node 3" lower
    Then I should have following tree:
    """
    node 1 / position = 1
    node 2 / position = 2
    node 3 / position = 3
    """

  Scenario: Move not lowest node down
    When I move node "node 2" lower
    Then I should have following tree:
    """
    node 1 / position = 1
    node 3 / position = 2
    node 2 / position = 3
    """