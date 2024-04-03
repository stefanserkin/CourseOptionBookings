// Prepare your list of sObjects.
List<sObject> lstObjs = [
    SELECT Id, Name 
      FROM TREX1__Course_Option__c 
     WHERE Id IN (SELECT TREX1__Course_Option__c 
                    FROM TREX1__Course_Session_Option__c 
                   WHERE TREX1__Course_Session__r.TREX1__Session__r.Name IN ('Summer 24','Fall 24'))
       AND Id NOT IN (SELECT TREX1__Course_Option__c
                        FROM TREX1__Booking__c)
];

// Create an instance of your batch class with the list as an argument.
TRecCourseOptionBookingBatch batch = new TRecCourseOptionBookingBatch(lstObjs);

// Execute batch
Database.executeBatch(batch, 200);
