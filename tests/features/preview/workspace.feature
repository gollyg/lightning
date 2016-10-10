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

  Scenario: Workspaces are allowed to be in the Draft, Needs Review, and Published states, but not Archived
    Given I am logged in as a user with the administrator role
    When I visit "/admin/structure/workspace/types/basic/edit/moderation"
    And the "Draft" checkbox should be checked
    And the "Needs Review" checkbox should be checked
    And the "Published" checkbox should be checked
    Then the "Archived" checkbox should not be checked

  Scenario: Moderation states available to Workspace entities can be marked as Locked and others cannot
    Given I am logged in as a user with the administrator role
    When I visit "/admin/structure/workbench-moderation/states/needs_review"
    And I should see "Lock workspaces in this state"
    And I visit "/admin/structure/workbench-moderation/states/archived"
    Then I should not see "Lock workspaces in this state"

  Scenario: The Needs Review and Published states that ship with Lightning are Locked but Draft is not
    Given I am logged in as a user with the administrator role
    And the "needs_review" state should be locked
    And the "published" state should be locked
    Then the "draft" state should not be locked

  Scenario: The Live workspace that ships with Lightning is live
    Given I am logged in as a user with the administrator role
    When I visit "/node/add/page"
    And I fill in "WPS Test Title" for "Title"
    And I select "Published" from "Moderation state"
    And I fill in "/wps-test" for "URL alias"
    And I press "Save"
    And I queue the latest "node" entity for deletion
    And I visit "/user/logout"
    And I visit "/wps-test"
    Then I should see "WPS Test Title"

  Scenario: The Stage workspace that ships with Lightning is not the Live workspace
    Given I am logged in as a user with the administrator role
    When I switch to the "Stage" workspace
    And I visit "/node/add/page"
    And I fill in "WPS Test Title" for "Title"
    And I select "Published" from "Moderation state"
    And I fill in "/wps-test" for "URL alias"
    And I press "Save"
    And I queue the latest "node" entity for deletion
    And I am on "/wps-test"
    And the response status code should be 200
    And I visit "/user/logout"
    And I am on "/wps-test"
    Then the response status code should be 404

  Scenario: The Stage workspace that ships with Lightning has Live as its Upstream
    Given I am logged in as a user with the administrator role
    And I navigate to the "Stage" workspace config form
    # These are actually radio button by the checkbox steps work
    And the "Stage" checkbox should not be checked
    Then the "Live" checkbox should be checked

  Scenario: Privileged users can create content on the Live workspace
    # * switch to the live workspace step

  Scenario: Privileged users can create content on a non-live and non-locked workspace
    # * Switch to the default stage workspace (but then we really need to test if the Default Stage workspace is none-live
    #   and non-locked - which is why we have the firt four scenarios here)

  Scenario: Privileged users can not create content on a workspace in the Locked state
    # * Can we do a "switch to non-live & non-locked workspace" step?

  Scenario: Content is not editable after the content's workspace has been moved from unlocked to locked state
    Given I am logged in as a user with the administrator role
    And I create a new draft of the "Stage" workspace
    And I switch to the "Stage" workspace
    And I visit "/node/add/page"
    And I fill in "WPS Test Title" for "Title"
    And I select "Published" from "Moderation state"
    And I fill in "/wps-test" for "URL alias"
    And I press "Save"
    And I queue the latest "node" entity for deletion
    And I am on "/wps-test"
    And I click "New draft"
    And I fill in "WPS Test Title: edited1" for "Title"
    And I select "Published" from "Moderation state"
    And I press "Save"
    And I should be on "/wps-test"
    And I should see "WPS Test Title: edited1"
    And I publish the "Stage" workspace
    And I am on "/wps-test"
    And I click "New draft"
    And I should see "Content cannot be modified in a locked workspace"
    Then I should not see the "Save" button
    And I create a new draft of the "Stage" workspace

  @test
  Scenario: Content is editable after the content's workspace has been moved from locked to unlocked
    Given I am logged in as a user with the administrator role
    And I create a new draft of the "Stage" workspace
    And I switch to the "Stage" workspace
    And I visit "/node/add/page"
    And I fill in "WPS Test Title" for "Title"
    And I select "Published" from "Moderation state"
    And I fill in "/wps-test" for "URL alias"
    And I press "Save"
    And I queue the latest "node" entity for deletion
    And I am on "/wps-test"
    And I click "New draft"
    And I fill in "WPS Test Title: edited1" for "Title"
    And I select "Published" from "Moderation state"
    And I press "Save"
    And I should be on "/wps-test"
    And I should see "WPS Test Title: edited1"
    And I publish the "Stage" workspace
    And I am on "/wps-test"
    And I click "New draft"
    And I should see "Content cannot be modified in a locked workspace"
    And I should not see the "Save" button
    And I create a new draft of the "Stage" workspace
    And I am on "/wps-test"
    And I click "New draft"
    And I fill in "WPS Test Title: edited2" for "Title"
    And I select "Published" from "Moderation state"
    And I press "Save"
    And I should be on "/wps-test"
    Then I should see "WPS Test Title: edited2"
