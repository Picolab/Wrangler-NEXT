# Registration system

This is a pico based system for handling student registrations in classes.
A class is a section of a course.

A web interface would provide a way for the registrar to add (or remove) sections as needed for a particular term.
This interface would also allow the registrar to see the roster for each section.

Another web interface would accept students arriving for registration and then allow them to add and drop classes.
This interface would also allow each student to see a list of their courses.

## Components

The system consists of multiple picos, each playing a particular role,
and each exposing channels as needed for operations.

### Picos

- the root pico would hold the `app_system` ruleset
    - the Registration pico would hold the `app_registration` ruleset
        - the Section Collection pico would hold the `app_section_collection` ruleset
            - each section pico would hold the `app_section` ruleset
    - each student pico would hold the `app_student` ruleset

Indentation shows the parent/child relationships.
I.e. the Registration Pico is a direct child of the root pico, as are the student picos, etc.

### Channels

Each pico (except the root pico) has a channel tagged by the name of its ruleset.
These channels are primarily for use by the developer in the Testing tab for each pico.

## Installation

The `app_system` ruleset is intalled in the root pico by human action.

Upon installation it causes the creation of the Registration pico, installing in it the `app_registration` ruleset.

Upon installation it causes the creation of the Section Collection pico, installing in it the `app_section_collection` ruleset.

That concludes the installation phase.
The last two rulesets also create a channel tagged with the ruleset ID.

## Operation

### Preparation

The Section Collection pico provides a way to create the section picos.
This is done by hitting its API.
For example:
```
/sky/event/ckiruqfzz000pdb2ra6ub3ky8/none/section/needed?section_id=C S 462-1
```
would create a section pico named "Section C S 462-1 Pico" installing in it the `app_section` ruleset.
Upon creation, the new section pico will communicate the ID of its "wellKnown_Rx" channel
for use in creating subscriptions.

Once all the section picos have been created, registration can begin.

### Registration

The Registration pico provides an API for the creation of student picos.
For example:
```
/sky/event/ckiruqfxx000fdb2re4bb4kdl/none/student/arrives?name=Bob
```
would create a student pico named "Bob" installing in it the `app_student` ruleset.
The student pico is given the "wellKnown_Rx" channel ID for the Section Collection pico.

Each student pico provides an API for adding and dropping sections.
For example:
```
/sky/event/ckirwlui2007udb2rd5bc77uy/none/section/add?section_id=C S 462-1
```
would create a subscription between Bob's student pico and the section pico.

During registration, Bob would be able to see his courses with an API call like:
```
/sky/cloud/ckiry80b600c7db2rb0ncagsg/app_student/courses
```

The registrar would be able to see the class roster for a section with an API call like:
```
/sky/cloud/ckiry80b600c7db2rb0ncagsg/app_section/roster
```
