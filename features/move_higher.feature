Feature: Move ordered tree node higher via #move_higher method
  Background:
    Given the following tree exists:
    """
    node 1
    node 2
    node 3
    """

  Scenario: Try to move highest node up
    When I move node "node 1" higher
    Then I should have following tree:
    """
    node 1 / position = 1
    node 2 / position = 2
    node 3 / position = 3
    """

  Scenario: Move not highest node up
    When I move node "node 2" higher
    Then I should have following tree:
    """
    node 2 / position = 1
    node 1 / position = 2
    node 3 / position = 3
    """