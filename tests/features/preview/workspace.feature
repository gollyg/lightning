@lightning @preview @api
Feature: Workspaces

  Scenario: Locking a workspace by publishing it
    Given I am logged in as a user with the content_manager,workspace_reviewer roles
    When I visit "/admin/structure/workspace/2/edit"
    And I press "Save and Publish"
    And I visit "/admin/structure/workspace/2/activate"
    And I press "Activate"
    And I go to "/node/add/page"
    Then I should not see the button "Save"
    And I visit "/admin/structure/workspace/2/edit"
    And I press "Save and Create New Draft"

  Scenario: Configuration entities are unconditionally locked in every workspace except the Live workspace
    Given I am logged in as a user with the administrator role
    When I visit "/admin/structure/workspace/2/activate"
    And I press "Activate"
    And I visit "/admin/structure/block"
    And I press "Save blocks"
    Then the response status code should be 500
    And I should see "Configuration can only be modified in the Live workspace"

  Scenario: Configuration entity form routes cannot be accessed in any workspace except the Live workspace
    Given I am logged in as a user with the administrator role
    When I visit "/admin/structure/workspace/2/activate"
    And I press "Activate"
    And I visit "/admin/config/content/formats"
    Then I should not see an "Add text format" link

  Scenario: Configuration entity forms protected by standard permissions cannot be accessed in any workspace except the Live workspace
    Given I am logged in as a user with the administrator role
    When I visit "/admin/structure/workspace/2/activate"
    And I press "Activate"
    And I visit "/admin/structure/workbench-moderation/states/draft"
    Then I should see "Configuration can only be modified in the Live workspace."
    And I should not see the button "Save"

  Scenario: Moderation states available to Workspace entities can be marked as Locked
    # * Confirm that the checkbox appears on the given moderation state's config page

  Scenario: The "Draft" state that ships with Lightning is not a locked state
    # * Step for returning a given moderation state's "locked" state - bool

  Scenario The Live workspace that ships with Lightning is live
    # * Step that returns whether a given workspace is live

  Scenario: The default "Stage" workspace that ships with Lightning is not the Live workspace nor is in a Locked state
    # * Should be able to assert this with the steps above

  Scenario: Privileged users can create content on the Live workspace
    # * switch to the live workspace step

  Scenario: Privileged users can create content on a non-live and non-locked workspace
    # * Switch to the default stage workspace (but then we really need to test if the Default Stage workspace is none-live
    #   and non-locked - which is why we have the firt four scenarios here)

  Scenario: Privileged users can not create content on a workspace in the Locked state
    # * Can we do a "switch to non-live & non-locked workspace" step?

  Scenario: Content is not editable after the content's workspace has been moved from unlocked to locked state
    # * Switch to Live workspace
    # * Edit content
    # * Switch to Stage workspace
    # * Update workspace from live (@STEP)
    # * Create (published) content on Stage
    # * Publish Stage
    # * Switch to (ensure currently on?) Workspace stage
    # * Assert: can't edit content

  Scenario: Content is editable after the content's workspace has been moved from locked to unlocked
    # Basically reverse^^