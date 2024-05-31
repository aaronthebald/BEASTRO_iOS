# BEASTRO: a Purs Project
## Introduction
**Hello There! 👋🏼**

## Project Overview

The BEASTRO project focuses on creating a single-screen iOS application using SwiftUI for iOS. The application retrieves a business's hours of operation and displays them to the user, matching a provided Figma design.

## Technologies and Design Patterns Used

- **SwiftUI**: For UI development.
- **Async/Await**: For fetching business hours data.
- **Model-View-ViewModel** For keeping code neat and readable.  

## Assumptions

Several assumptions were made during the planning and execution of BEASTRO:

- **Assumption 1**: Days need to be coded dynamically. The days in which the business operates may change.
- **Assumption 2**: The Name of the business might change.
- **Assumption 3**: If no object for a day in the week is returned, `Closed` should be displayed.
- **Assumption 4**: All weekdays should be displayed regardless of open status.
- **Assumption 5**: The destination for the App is iPhone only on iOS.


## Edge Cases Considered

In developing BEASTRO, various edge cases were considered to ensure robustness and reliability. These include:
- **Case 1: Closed**
  - Input: 
     No JSON for that day.
  - Display: `Monday: Closed`

 - **Case 2: Open 24 Hours**
  - Input: 
    ```json
    {
      "day_of_week": "MON",
      "start_local_time": "00:00:00",
      "end_local_time": "24:00:00"
    }
    ```
  - Display: `Monday: Open 24hrs`
       
- **Case 3: Open Until Midnight Multiple Days in a row**
  - Input: 
    ```json
    {
      "day_of_week": "MON",
      "start_local_time": "00::00:00",
      "end_local_time": "24:00:00"
    },
    {
      "day_of_week": "TUE",
      "start_local_time": "00::00:00",
      "end_local_time": "24:00:00"
    }
    ```
  - Display: `Monday: Open 24 Hours`
  - Display `Tuesday: Open 24 Hours`
- **Case 4: Open Until Midnight**
  - Input: 
    ```json
    {
      "day_of_week": "MON",
      "start_local_time": "13:00:00",
      "end_local_time": "24:00:00"
    }
    ```
  - Display: `Monday: 1pm-12am`
  
- **Case 5: Open past Midnight**
  - Input: 
    ```json
    {
      "day_of_week": "MON",
      "start_local_time": "13:00:00",
      "end_local_time": "24:00:00"
    }, 
    {
      "day_of_week": "TUE",
      "start_local_time": "00:00:00",
      "end_local_time": "02:00:00"
    }
    ```
  - Display: `Monday: 1pm-2am``

 
## UI Considerations
**Fonts**: Imported and used the fonts specified in the Figma file.

**Animations**: Used a combination of animations and rotation effects when the accordion is expanded or collapsed 


