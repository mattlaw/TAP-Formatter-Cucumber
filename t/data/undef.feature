Feature: undefined step
  In order to know which steps need to be defined
  As a tester
  I want to be able to see undefined tests in output

  Scenario:
    Given A test
     When a step is undefined
     Then it is formatted nicely
      But no more steps are run
