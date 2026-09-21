void main() {
  var texts = [
    'Rs. 5,000.00 credited to a/c XX1234 on 01-Sep-26 by IMPS-123456789-JOHN DOE. Bal: Rs. 15,000.00',
    'Account XX1234 is credited with Rs 5000 on 01/09/2026 by UPI/123456789/JOHN DOE/HDFC/UPI. Bal: Rs 15000',
    'Dear Customer, Rs.5000 credited to a/c XXXXXX1234 on 01-09-26. Info: IMPS/JOHN DOE/123456. Bal: Rs 15000'
  ];
  
  var regex = RegExp(r'\b(?:by|from|info(?:\:|:?))\s+([A-Za-z0-9\s\*\-/@_]+?)(?:\s+(?:on|via|available|val|bal|limit|balance|rs\.?|inr|\$)|\.|\,|$)', caseSensitive: false);
  
  for (var text in texts) {
    var match = regex.firstMatch(text);
    if (match != null) {
      print('Matched: \');
    } else {
      print('Failed: \');
    }
  }
}
