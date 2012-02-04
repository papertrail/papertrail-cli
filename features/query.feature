Feature: Search Queries
  In order to extract meaningful info from logs
  As a command line user
  I want to run search queries

  Scenario: Show recent log entries
    Given papertrail is configured correctly
    And the following server log:
      |received_at              |hostname|program|message|
      |2012-02-03T15:16:17+01:00|server1 |app1   |startup|
      |2012-02-04T02:22:22+01:00|server1 |app1   |disk space warning|
      |2012-03-05T03:33:33+01:00|server1 |app1   |crash|
    When I papertrail
    Then it should pass with exactly:
      """
      Feb  3 15:16:17 server1 app1: startup
      Feb  4 02:22:22 server1 app1: disk space warning
      Mar  5 03:33:33 server1 app1: crash

      """

  Scenario: Show recent log entries for given source name
    Given papertrail is configured correctly
    And the following systems:
      |name|hostname|id   |
      |s1  |server1 |9876 |
      |s2  |server2 |1234|
    And the following server log:
      |source_id|received_at              |hostname|program|message|
      |1234     |2012-02-03T15:16:17+01:00|server1 |app1   |startup|
      |0001     |2012-02-04T02:22:22+01:00|server2 |app1   |disk space warning|
      |1234     |2012-03-05T03:33:33+01:00|server2 |app1   |crash|
    When I papertrail with '--system server2'
    Then it should pass with exactly:
      """
      Feb  3 15:16:17 server1 app1: startup
      Mar  5 03:33:33 server2 app1: crash

      """
