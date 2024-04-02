String runningMonth = 'AprilThroughJune';
Date startDate = Date.newInstance(2024, 4, 1);
Date endDate = Date.newInstance(2024, 7, 1);

List<String> lstEmailAddresses = new List<String>{ 'sserkin@asphaltgreen.org', 'afalco@asphaltgreen.org' };
String emailSubject = 'Booking Conflict Data: ' + runningMonth;

List<TREX1__Booking__c> lstBookings = [
    SELECT Id, TREX1__Start_Time__c, TREX1__End_Time__c, TREX1__Event_Name__c, Booking_Date__c, 
           TREX1__Facility__c, TREX1__Facility__r.Name, TREX1__Facility__r.TREX1__Location__c, 
           TREX1__Facility__r.TREX1__Location__r.Name, Exclude_From_Conflicts__c, TREX1__Start_Time_Block__c, 
           TREX1__End_Time_Block__c
      FROM TREX1__Booking__c 
     WHERE TREX1__Start_Time__c > today and TREX1__Facility__r.Exclude_Booking_Conflicts__c != true
       AND Booking_Date__c >= :startDate
       AND Booking_Date__c < :endDate
     ORDER BY TREX1__Start_Time__c 
];

Map<Date, List<TREX1__Booking__c>> mapBookingsByDate = new Map<Date, List<TREX1__Booking__c>>();
for (TREX1__Booking__c bk : lstBookings) {
    if (!mapBookingsByDate.containsKey(bk.Booking_Date__c)) {
        mapBookingsByDate.put(bk.Booking_Date__c, new List<TREX1__Booking__c>());
    }
    List<TREX1__Booking__c> lstDateBks = mapBookingsByDate.get(bk.Booking_Date__c);
    lstDateBks.add(bk);
    mapBookingsByDate.put(bk.Booking_Date__c, lstDateBks);
}

Set<TREX1__Booking__c> setConflicts = new Set<TREX1__Booking__c>();
for (TREX1__Booking__c bk : lstBookings) {
    List<TREX1__Booking__c> lstDailyBks = mapBookingsByDate.get(bk.Booking_Date__c);
    for (TREX1__Booking__c compareBk : lstDailyBks) {
        if (
            compareBk.Id != bk.Id && 
            compareBk.TREX1__Facility__c == bk.TREX1__Facility__c && 
            compareBk.TREX1__Start_Time__c < bk.TREX1__End_Time__c &&
            compareBk.TREX1__End_Time__c > bk.TREX1__Start_Time__c && 
            (!compareBk.Exclude_From_Conflicts__c || !bk.Exclude_From_Conflicts__c)
        ) {
            setConflicts.add(bk);
            setConflicts.add(compareBk);
        }
    }
}

String csvString = '';
csvString += 'Booking Id,Location Name,Facility Name,Start Date,Start Time,End Date,End Time,Start Date Block,Start Time Block,End Date Block,End Time Block,Event Name,Facility Id, Location Id\n';
System.debug(':::::::: number conflicts found --> ' + setConflicts.size());
Integer rowCount = 0;
for (TREX1__Booking__c bk : setConflicts) {
    csvString += bk.Id + ',' + bk.TREX1__Facility__r.TREX1__Location__r.Name + ',' + bk.TREX1__Facility__r.Name + ',' + 
        bk.TREX1__Start_Time__c.format() + ',' + bk.TREX1__End_Time__c.format() + ',' + bk.TREX1__Start_Time_Block__c.format() + ',' + bk.TREX1__End_Time_Block__c.format() + ',' +
        bk.TREX1__Event_Name__c + ',' + bk.TREX1__Facility__c + ',' + bk.TREX1__Facility__r.TREX1__Location__c;
    rowCount++;
    if (rowCount < setConflicts.size()) csvString += '\n';
}

// Create csv file attachment
Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
attachment.setFileName('Booking_Conflicts_' + runningMonth + '.csv');
attachment.setBody(Blob.valueOf(csvString));

// Create email with attachment
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
email.setToAddresses(lstEmailAddresses);
email.setSubject(emailSubject);
email.setSenderDisplayName('Asphalt Green Data Factory');
email.setPlainTextBody('Data is attached for the month of ' + runningMonth);
email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ 
    attachment 
});

// Send email
Messaging.sendEmail( new List<Messaging.SingleEmailMessage>{ email } );