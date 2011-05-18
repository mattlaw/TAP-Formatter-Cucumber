Feature: fail
  In order to know about failure conditions
  As a tester
  I want to be able to see errors

  Scenario: failure
    Given FAIL
    When I receive the output
    Then it is formatted nicely
